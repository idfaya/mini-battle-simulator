---
--- Battle Action Order Module
--- 管理战斗中的行动顺序系统，基于 5e 先攻的行动条/进度机制
---

local Logger = require("utils.logger")
local BattleAttribute = require("modules.battle_attribute")
local Dice = require("core.dice")

---@class BattleActionOrder
local BattleActionOrder = {}

-- 行动条阈值常量
local ACTION_BAR_THRESHOLD = 1000
local ACTION_BAR_STEP = 100
local INITIATIVE_MIN = -5
local INITIATIVE_MAX = 25

-- 内部数据存储
local _heroes = {}           -- 所有英雄列表
local _actionBars = {}       -- 英雄行动条进度 { [heroId] = progress }
local _initiative = {}        -- 5e 先攻结果 { [heroId] = {roll, mod, total} }
local _isRunning = false     -- 是否正在运行
local _currentHero = nil     -- 当前正在行动的英雄
local _teamLeft = nil        -- 左侧队伍
local _teamRight = nil       -- 右侧队伍

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function getDexMod(hero)
    if not hero then
        return 0
    end
    return tonumber(hero.dexMod) or 0
end

local function rollInitiative(hero)
    local roll = Dice.RollD20("normal")
    local mod = getDexMod(hero)
    local total = roll + mod
    return {
        roll = roll,
        mod = mod,
        total = total,
    }
end

local function getInitialActionBar(initiativeTotal)
    local normalized = (clamp(initiativeTotal, INITIATIVE_MIN, INITIATIVE_MAX) - INITIATIVE_MIN) / (INITIATIVE_MAX - INITIATIVE_MIN)
    return math.floor(normalized * ACTION_BAR_THRESHOLD)
end

--- 初始化行动顺序系统
---@param teamLeft table 左侧队伍英雄列表
---@param teamRight table 右侧队伍英雄列表
function BattleActionOrder.Init(teamLeft, teamRight)
    Logger.Debug("BattleActionOrder.Init - 初始化行动顺序系统")

    _teamLeft = teamLeft or {}
    _teamRight = teamRight or {}
    _heroes = {}
    _actionBars = {}
    _initiative = {}
    _isRunning = false
    _currentHero = nil

    -- 收集所有英雄
    for _, hero in ipairs(_teamLeft) do
        if hero and hero.instanceId then
            table.insert(_heroes, hero)
            _initiative[hero.instanceId] = rollInitiative(hero)
            _actionBars[hero.instanceId] = getInitialActionBar(_initiative[hero.instanceId].total)
            Logger.Debug(string.format("  添加左侧英雄: %s (ID: %s, 先攻: %d = d20(%d) %+d)",
                hero.name or "Unknown", hero.instanceId, _initiative[hero.instanceId].total,
                _initiative[hero.instanceId].roll, _initiative[hero.instanceId].mod))
        end
    end

    for _, hero in ipairs(_teamRight) do
        if hero and hero.instanceId then
            table.insert(_heroes, hero)
            _initiative[hero.instanceId] = rollInitiative(hero)
            _actionBars[hero.instanceId] = getInitialActionBar(_initiative[hero.instanceId].total)
            Logger.Debug(string.format("  添加右侧英雄: %s (ID: %s, 先攻: %d = d20(%d) %+d)",
                hero.name or "Unknown", hero.instanceId, _initiative[hero.instanceId].total,
                _initiative[hero.instanceId].roll, _initiative[hero.instanceId].mod))
        end
    end

    Logger.Log(string.format("BattleActionOrder.Init - 共初始化 %d 名英雄", #_heroes))
end

--- 清理行动顺序系统
function BattleActionOrder.OnFinal()
    Logger.Debug("BattleActionOrder.OnFinal - 清理行动顺序系统")

    _heroes = {}
    _actionBars = {}
    _initiative = {}
    _isRunning = false
    _currentHero = nil
    _teamLeft = nil
    _teamRight = nil
end

--- 更新所有英雄的行动条
--- 5e 先攻只决定开场顺序；战斗中所有单位等速推进，避免旧 speed 造成多动
function BattleActionOrder.UpdateActionBars()
    for _, hero in ipairs(_heroes) do
        if hero and hero.instanceId and BattleAttribute.IsAlive(hero) then
            local currentProgress = _actionBars[hero.instanceId] or 0
            _actionBars[hero.instanceId] = currentProgress + ACTION_BAR_STEP
        end
    end
end

--- 检查英雄是否准备好行动
---@param hero table 英雄对象
---@return boolean 是否准备好行动
function BattleActionOrder.IsHeroReady(hero)
    if not hero or not hero.instanceId then
        return false
    end

    if not BattleAttribute.IsAlive(hero) then
        return false
    end

    local progress = _actionBars[hero.instanceId] or 0
    return progress >= ACTION_BAR_THRESHOLD
end

--- 获取当前行动顺序列表
--- 按行动条进度降序排列，只包含存活的英雄
---@return table 行动顺序列表 { {hero = hero, progress = progress}, ... }
function BattleActionOrder.GetActionOrder()
    local orderList = {}

    for _, hero in ipairs(_heroes) do
        if hero and hero.instanceId and BattleAttribute.IsAlive(hero) then
            table.insert(orderList, {
                hero = hero,
                progress = _actionBars[hero.instanceId] or 0,
                initiative = _initiative[hero.instanceId] and _initiative[hero.instanceId].total or 0,
            })
        end
    end

    -- 按行动条进度降序排序；进度相同按 5e 先攻高者优先
    table.sort(orderList, function(a, b)
        if a.progress ~= b.progress then
            return a.progress > b.progress
        end
        return (a.initiative or 0) > (b.initiative or 0)
    end)

    return orderList
end

--- 选择下一个行动的英雄
--- 基于 5e 先攻初始位置的行动条机制，返回行动条已满且进度最高的英雄
---@return table|nil 下一个行动的英雄，如果没有英雄准备好则返回nil
function BattleActionOrder.Run()
    if not _isRunning then
        _isRunning = true
    end

    -- 更新所有英雄的行动条
    BattleActionOrder.UpdateActionBars()

    -- 获取按行动条排序的英雄列表
    local orderList = BattleActionOrder.GetActionOrder()

    -- 找到第一个行动条达到阈值的英雄
    for _, item in ipairs(orderList) do
        if item.progress >= ACTION_BAR_THRESHOLD then
            _currentHero = item.hero
            Logger.Log(string.format("[行动] 英雄 %s 准备行动 (行动条: %d, 先攻: %d)",
                item.hero.name or "Unknown", item.progress, item.initiative or 0))
            return _currentHero
        end
    end

    -- 没有英雄准备好行动
    return nil
end

--- 英雄行动结束后的回调
--- 重置该英雄的行动条
---@param hero table 完成行动的英雄
function BattleActionOrder.OnHeroActionFinish(hero)
    if not hero or not hero.instanceId then
        Logger.LogWarning("BattleActionOrder.OnHeroActionFinish - hero 为空或没有instanceId")
        return
    end

    -- 重置行动条
    BattleActionOrder.ResetActionBar(hero)

    -- 清除当前英雄
    if _currentHero and _currentHero.instanceId == hero.instanceId then
        _currentHero = nil
    end

    Logger.Log(string.format("BattleActionOrder.OnHeroActionFinish - 英雄 %s 行动结束，行动条已重置", hero.name or "Unknown"))
end

--- 修改英雄的行动条进度
--- 可用于技能效果（如加速、减速、拉条、推条等）
---@param hero table 目标英雄
---@param distance number 变化值（正数为增加，负数为减少）
function BattleActionOrder.ChangeHeroDistance(hero, distance)
    if not hero or not hero.instanceId then
        Logger.LogWarning("BattleActionOrder.ChangeHeroDistance - hero 为空或没有instanceId")
        return
    end

    if not BattleAttribute.IsAlive(hero) then
        Logger.Debug(string.format("BattleActionOrder.ChangeHeroDistance - 英雄 %s 已死亡，无法修改行动条", hero.name or "Unknown"))
        return
    end

    local oldProgress = _actionBars[hero.instanceId] or 0
    local newProgress = oldProgress + distance

    -- 限制行动条范围 [0, ACTION_BAR_THRESHOLD * 2]（允许超过阈值，方便计算）
    newProgress = math.max(0, math.min(newProgress, ACTION_BAR_THRESHOLD * 2))

    _actionBars[hero.instanceId] = newProgress

    local action = distance > 0 and "增加" or "减少"
    Logger.Log(string.format("BattleActionOrder.ChangeHeroDistance - 英雄 %s 行动条%s: %d %+d = %d",
        hero.name or "Unknown", action, oldProgress, distance, newProgress))
end

--- 重置英雄的行动条
--- 英雄行动后调用，将其行动条归零
---@param hero table 目标英雄
function BattleActionOrder.ResetActionBar(hero)
    if not hero or not hero.instanceId then
        Logger.LogWarning("BattleActionOrder.ResetActionBar - hero 为空或没有instanceId")
        return
    end

    local oldProgress = _actionBars[hero.instanceId] or 0
    _actionBars[hero.instanceId] = 0

    Logger.Debug(string.format("BattleActionOrder.ResetActionBar - 英雄 %s 行动条重置: %d -> 0",
        hero.name or "Unknown", oldProgress))
end

--- 获取指定英雄的行动条进度
---@param hero table 英雄对象
---@return number 行动条进度
function BattleActionOrder.GetHeroActionBar(hero)
    if not hero or not hero.instanceId then
        return 0
    end
    return _actionBars[hero.instanceId] or 0
end

--- 获取指定英雄的 5e 先攻信息
---@param hero table 英雄对象
---@return table 先攻信息 {roll, mod, total}
function BattleActionOrder.GetHeroInitiative(hero)
    if not hero or not hero.instanceId then
        return { roll = 0, mod = 0, total = 0 }
    end
    return _initiative[hero.instanceId] or { roll = 0, mod = getDexMod(hero), total = getDexMod(hero) }
end

--- 获取行动条阈值
---@return number 行动条阈值
function BattleActionOrder.GetActionBarThreshold()
    return ACTION_BAR_THRESHOLD
end

--- 设置行动条阈值（用于特殊战斗规则）
---@param threshold number 新的阈值
function BattleActionOrder.SetActionBarThreshold(threshold)
    if threshold and threshold > 0 then
        ACTION_BAR_THRESHOLD = threshold
        Logger.Debug(string.format("BattleActionOrder.SetActionBarThreshold - 行动条阈值设置为: %d", threshold))
    end
end

--- 获取当前正在行动的英雄
---@return table|nil 当前英雄
function BattleActionOrder.GetCurrentHero()
    return _currentHero
end

--- 获取所有存活的英雄
---@return table 存活英雄列表
function BattleActionOrder.GetAliveHeroes()
    local aliveHeroes = {}
    for _, hero in ipairs(_heroes) do
        if BattleAttribute.IsAlive(hero) then
            table.insert(aliveHeroes, hero)
        end
    end
    return aliveHeroes
end

--- 检查是否还有存活的英雄
---@param team string 队伍标识 "left" 或 "right"
---@return boolean 该队伍是否有存活英雄
function BattleActionOrder.HasAliveHeroes(team)
    local targetTeam = (team == "left") and _teamLeft or _teamRight

    if not targetTeam then
        return false
    end

    for _, hero in ipairs(targetTeam) do
        if BattleAttribute.IsAlive(hero) then
            return true
        end
    end

    return false
end

--- 打印当前行动条状态（用于调试）
function BattleActionOrder.PrintActionBarStatus()
    Logger.Log("========== 行动条状态 ==========")

    local orderList = BattleActionOrder.GetActionOrder()

    for i, item in ipairs(orderList) do
        local status = item.progress >= ACTION_BAR_THRESHOLD and "[READY]" or ""
        Logger.Log(string.format("%d. %s - 行动条: %d/%d %s",
            i, item.hero.name or "Unknown", item.progress, ACTION_BAR_THRESHOLD, status))
    end

    Logger.Log("================================")
end

return BattleActionOrder
