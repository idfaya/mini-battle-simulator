---
--- Battle Logic Module
--- 核心战斗逻辑控制器，管理战斗流程、回合控制和技能释放
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleActionOrder = require("modules.battle_action_order")
local BattleSkill = require("modules.battle_skill")
local BattleAttribute = require("modules.battle_attribute")
local BattleBuff = require("modules.battle_buff")
local BattlePassiveSkill = require("modules.battle_passive_skill")

---@class BattleLogic
local BattleLogic = {}

-- ==================== 状态变量 ====================

-- 回合相关
local _maxRound = 50          -- 最大回合数
local _curRound = 0           -- 当前回合数

-- 战斗状态
local _beginState = nil       -- 战斗初始状态
local _isBattleFinish = false -- 战斗是否结束
local _win = false            -- 战斗结果（true=胜利, false=失败）
local _isPause = false        -- 是否暂停

-- 行动计数
local _actionCount = 0        -- 行动次数计数

-- 队伍引用
local _teamLeft = nil         -- 左侧队伍
local _teamRight = nil        -- 右侧队伍

-- 回调函数
local _onHeroCastSmallSkillBegin = nil  -- 英雄开始释放小技能回调
local _onHeroCastSmallSkillEnd = nil    -- 英雄结束释放小技能回调
local _onBattleResult = nil             -- 战斗结果回调

-- ==================== 初始化与清理 ====================

--- 初始化战斗逻辑
---@param beginState table 战斗初始状态，包含队伍信息等
function BattleLogic.Init(beginState)
    Logger.Log("BattleLogic.Init - 初始化战斗逻辑")

    _beginState = beginState or {}
    _maxRound = _beginState.maxRound or 50
    _curRound = 0
    _isBattleFinish = false
    _win = false
    _isPause = false
    _actionCount = 0

    -- 获取队伍信息
    _teamLeft = _beginState.teamLeft or {}
    _teamRight = _beginState.teamRight or {}

    -- 初始化行动顺序系统
    BattleActionOrder.Init(_teamLeft, _teamRight)

    -- 初始化事件系统
    BattleEvent.Init()

    -- 注册被动技能触发事件
    BattleLogic.RegisterPassiveSkillEvents()

    Logger.Log(string.format("BattleLogic.Init - 战斗初始化完成，最大回合数: %d", _maxRound))
end

--- 清理战斗逻辑
function BattleLogic.OnFinal()
    Logger.Log("BattleLogic.OnFinal - 清理战斗逻辑")

    -- 清理行动顺序系统
    BattleActionOrder.OnFinal()

    -- 清理事件系统
    BattleEvent.OnFinal()

    -- 清理Buff系统
    if BattleBuff and BattleBuff.OnFinal then
        BattleBuff.OnFinal()
    end

    -- 重置状态变量
    _maxRound = 50
    _curRound = 0
    _beginState = nil
    _isBattleFinish = false
    _win = false
    _isPause = false
    _actionCount = 0
    _teamLeft = nil
    _teamRight = nil
    _onHeroCastSmallSkillBegin = nil
    _onHeroCastSmallSkillEnd = nil
    _onBattleResult = nil
end

--- 注册被动技能触发事件
function BattleLogic.RegisterPassiveSkillEvents()
    -- 战斗开始时触发
    BattleEvent.AddListener("BattleBegin", function()
        BattlePassiveSkill.TriggerPassiveSkill(E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin, nil)
    end)

    -- 回合开始时触发
    BattleEvent.AddListener("RoundBegin", function(hero)
        BattlePassiveSkill.TriggerPassiveSkill(E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin, hero)
    end)

    -- 回合结束时触发
    BattleEvent.AddListener("RoundEnd", function(hero)
        BattlePassiveSkill.TriggerPassiveSkill(E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnEnd, hero)
    end)

    -- 普通攻击开始时触发
    BattleEvent.AddListener("NormalAtkStart", function(hero)
        BattlePassiveSkill.TriggerPassiveSkill(E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkStart, hero)
    end)

    -- 普通攻击结束时触发
    BattleEvent.AddListener("NormalAtkFinish", function(hero)
        BattlePassiveSkill.TriggerPassiveSkill(E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkFinish, hero)
    end)
end

-- ==================== 战斗控制 ====================

--- 开始战斗
function BattleLogic.Start()
    Logger.Log("BattleLogic.Start - 战斗开始")

    if _isBattleFinish then
        Logger.LogWarning("BattleLogic.Start - 战斗已结束，无法开始")
        return
    end

    -- 触发战斗开始事件
    BattleEvent.Publish("BattleBegin")

    -- 开始第一回合
    _curRound = 1
    Logger.Log(string.format("BattleLogic.Start - 第 %d 回合开始", _curRound))

    -- 开始第一个行动
    BattleLogic.BeginNextAction()
end

--- 核心战斗循环 - 选择下一个英雄并处理行动
function BattleLogic.BeginNextAction()
    -- 检查战斗是否已结束
    if BattleLogic.CheckBattleFinish() then
        return
    end

    -- 检查是否暂停
    if _isPause then
        Logger.Debug("BattleLogic.BeginNextAction - 战斗已暂停")
        return
    end

    -- 选择下一个行动的英雄
    local hero = BattleActionOrder.Run()

    if not hero then
        -- 没有英雄准备好行动，继续更新行动条
        Logger.Debug("BattleLogic.BeginNextAction - 没有英雄准备好，继续更新行动条")

        -- 延迟后再次尝试
        BattleLogic.ScheduleNextAction()
        return
    end

    -- 增加行动计数
    _actionCount = _actionCount + 1

    Logger.Log(string.format("BattleLogic.BeginNextAction - 第 %d 回合，英雄 %s 开始行动 (行动次数: %d)",
        _curRound, hero.name or "Unknown", _actionCount))

    -- 触发回合开始事件
    BattleEvent.Publish("RoundBegin", hero)

    -- 处理英雄行动
    BattleLogic.ProcessHeroAction(hero)
end

--- 安排下一次行动
function BattleLogic.ScheduleNextAction()
    -- 使用定时器延迟执行下一次行动检查
    -- 这里使用简单的递归调用，实际项目中可能使用 BattleTimer
    local timer = require("core.battle_timer")
    timer.Delay(0.1, function()
        if not _isPause and not _isBattleFinish then
            BattleLogic.BeginNextAction()
        end
    end)
end

--- 处理英雄行动
---@param hero table 行动的英雄
function BattleLogic.ProcessHeroAction(hero)
    if not hero then
        Logger.LogError("BattleLogic.ProcessHeroAction - hero 为空")
        BattleLogic.OnHeroActionFinish(hero)
        return
    end

    -- 检查英雄是否存活
    if not BattleAttribute.IsAlive(hero) then
        Logger.LogWarning(string.format("BattleLogic.ProcessHeroAction - 英雄 %s 已死亡，跳过行动", hero.name or "Unknown"))
        BattleLogic.OnHeroActionFinish(hero)
        return
    end

    -- 检查英雄是否被控制（眩晕、冰冻等）
    if BattleLogic.IsHeroControlled(hero) then
        Logger.Log(string.format("BattleLogic.ProcessHeroAction - 英雄 %s 被控制，跳过行动", hero.name or "Unknown"))
        BattleLogic.OnHeroActionFinish(hero)
        return
    end

    -- 释放普通攻击（小技能）
    BattleLogic.CastSmallSkill(hero)
end

--- 检查英雄是否被控制
---@param hero table 英雄对象
---@return boolean 是否被控制
function BattleLogic.IsHeroControlled(hero)
    -- 检查Buff中是否有控制效果
    if BattleBuff and BattleBuff.HasControlBuff then
        return BattleBuff.HasControlBuff(hero)
    end
    return false
end

--- 英雄行动结束处理
---@param hero table 完成行动的英雄
function BattleLogic.OnHeroActionFinish(hero)
    if hero then
        Logger.Log(string.format("BattleLogic.OnHeroActionFinish - 英雄 %s 行动结束", hero.name or "Unknown"))

        -- 触发回合结束事件
        BattleEvent.Publish("RoundEnd", hero)

        -- 通知行动顺序系统
        BattleActionOrder.OnHeroActionFinish(hero)
    end

    -- 减少技能冷却
    if hero then
        BattleSkill.ReduceCoolDown(hero, 1)
    end

    -- 更新Buff持续时间
    if BattleBuff and BattleBuff.OnRoundEnd then
        BattleBuff.OnRoundEnd(hero)
    end

    -- 检查战斗是否结束
    if BattleLogic.CheckBattleFinish() then
        return
    end

    -- 更新回合数（根据行动次数判断）
    local aliveHeroCount = #BattleActionOrder.GetAliveHeroes()
    if aliveHeroCount > 0 and _actionCount % aliveHeroCount == 0 then
        _curRound = _curRound + 1
        Logger.Log(string.format("BattleLogic.OnHeroActionFinish - 第 %d 回合开始", _curRound))

        -- 触发新回合事件
        BattleEvent.Publish("NewRound", _curRound)
    end

    -- 继续下一个行动
    BattleLogic.ScheduleNextAction()
end

-- ==================== 技能释放 ====================

--- 释放普通攻击（小技能）
---@param hero table 攻击者
function BattleLogic.CastSmallSkill(hero)
    if not hero then
        Logger.LogError("BattleLogic.CastSmallSkill - hero 为空")
        BattleLogic.OnHeroActionFinish(hero)
        return
    end

    Logger.Log(string.format("BattleLogic.CastSmallSkill - 英雄 %s 释放普通攻击", hero.name or "Unknown"))

    -- 触发普通攻击开始回调
    if _onHeroCastSmallSkillBegin then
        _onHeroCastSmallSkillBegin(hero)
    end

    -- 触发普通攻击开始事件
    BattleEvent.Publish("NormalAtkStart", hero)

    -- 获取目标
    local target = BattleLogic.SelectDefaultTarget(hero)

    -- 释放普通攻击技能
    local success = BattleSkill.CastSmallSkill(hero, target)

    -- 触发普通攻击结束事件
    BattleEvent.Publish("NormalAtkFinish", hero)

    -- 触发普通攻击结束回调
    if _onHeroCastSmallSkillEnd then
        _onHeroCastSmallSkillEnd(hero, success)
    end

    -- 行动结束
    BattleLogic.OnHeroActionFinish(hero)
end

--- 按顺序释放指定技能
---@param hero table 攻击者
---@param target table 目标
---@param skillId number 技能ID
---@param callback function 释放完成回调
function BattleLogic.CastHeroSkillInSeq(hero, target, skillId, callback)
    if not hero then
        Logger.LogError("BattleLogic.CastHeroSkillInSeq - hero 为空")
        if callback then callback(false) end
        return
    end

    if not skillId then
        Logger.LogError("BattleLogic.CastHeroSkillInSeq - skillId 为空")
        if callback then callback(false) end
        return
    end

    Logger.Log(string.format("BattleLogic.CastHeroSkillInSeq - 英雄 %s 释放技能 %d", hero.name or "Unknown", skillId))

    -- 释放技能
    local success = BattleSkill.CastSkillInSeq(hero, target, skillId)

    -- 检查战斗是否结束
    BattleLogic.CheckBattleFinish()

    -- 执行回调
    if callback then
        callback(success)
    end
end

--- 选择默认目标
---@param hero table 攻击者
---@return table|nil 目标英雄
function BattleLogic.SelectDefaultTarget(hero)
    -- 根据英雄阵营选择敌方目标
    local isLeftTeam = false
    for _, h in ipairs(_teamLeft or {}) do
        if h == hero or (h.id and hero.id and h.id == hero.id) then
            isLeftTeam = true
            break
        end
    end

    -- 选择对方队伍的存活英雄
    local enemyTeam = isLeftTeam and _teamRight or _teamLeft
    if not enemyTeam then
        return nil
    end

    -- 找到第一个存活的敌方英雄
    for _, enemy in ipairs(enemyTeam) do
        if BattleAttribute.IsAlive(enemy) then
            return enemy
        end
    end

    return nil
end

-- ==================== 战斗结束检查 ====================

--- 检查战斗是否应该结束
---@return boolean 战斗是否已结束
function BattleLogic.CheckBattleFinish()
    if _isBattleFinish then
        return true
    end

    -- 检查回合数是否超过最大限制
    if _curRound > _maxRound then
        Logger.Log(string.format("BattleLogic.CheckBattleFinish - 回合数超过限制 (%d > %d)，战斗结束", _curRound, _maxRound))
        BattleLogic.OnBattleResult(false, { reason = "max_round_reached" })
        return true
    end

    -- 检查左侧队伍是否全灭
    local hasLeftAlive = BattleActionOrder.HasAliveHeroes("left")
    local hasRightAlive = BattleActionOrder.HasAliveHeroes("right")

    if not hasLeftAlive then
        Logger.Log("BattleLogic.CheckBattleFinish - 左侧队伍全灭，右侧胜利")
        BattleLogic.OnBattleResult(false, { reason = "team_defeated", defeatedTeam = "left" })
        return true
    end

    if not hasRightAlive then
        Logger.Log("BattleLogic.CheckBattleFinish - 右侧队伍全灭，左侧胜利")
        BattleLogic.OnBattleResult(true, { reason = "victory", defeatedTeam = "right" })
        return true
    end

    return false
end

--- 处理战斗结束
---@param win boolean 是否胜利
---@param endState table 结束状态信息
function BattleLogic.OnBattleResult(win, endState)
    if _isBattleFinish then
        return
    end

    _isBattleFinish = true
    _win = win
    endState = endState or {}

    Logger.Log(string.format("BattleLogic.OnBattleResult - 战斗结束，结果: %s", win and "胜利" or "失败"))

    -- 触发战斗结束事件
    BattleEvent.Publish("BattleEnd", {
        win = win,
        round = _curRound,
        actionCount = _actionCount,
        endState = endState
    })

    -- 执行结果回调
    if _onBattleResult then
        _onBattleResult(win, endState)
    end
end

-- ==================== 暂停/恢复 ====================

--- 暂停战斗
function BattleLogic.Pause()
    if not _isPause then
        _isPause = true
        Logger.Log("BattleLogic.Pause - 战斗已暂停")
        BattleEvent.Publish("BattlePause")
    end
end

--- 恢复战斗
function BattleLogic.Resume()
    if _isPause then
        _isPause = false
        Logger.Log("BattleLogic.Resume - 战斗已恢复")
        BattleEvent.Publish("BattleResume")

        -- 恢复后继续下一个行动
        BattleLogic.BeginNextAction()
    end
end

--- 检查是否处于暂停状态
---@return boolean 是否暂停
function BattleLogic.IsPaused()
    return _isPause
end

-- ==================== 查询函数 ====================

--- 检查战斗是否已结束
---@return boolean 战斗是否已结束
function BattleLogic.IsBattleFinish()
    return _isBattleFinish
end

--- 获取当前回合数
---@return number 当前回合数
function BattleLogic.GetCurRound()
    return _curRound
end

--- 获取战斗结果
---@return boolean|nil 胜利=true, 失败=false, 进行中=nil
function BattleLogic.GetBattleResult()
    if not _isBattleFinish then
        return nil
    end
    return _win
end

--- 获取行动次数
---@return number 行动次数
function BattleLogic.GetActionCount()
    return _actionCount
end

--- 获取最大回合数
---@return number 最大回合数
function BattleLogic.GetMaxRound()
    return _maxRound
end

--- 设置最大回合数
---@param maxRound number 最大回合数
function BattleLogic.SetMaxRound(maxRound)
    if maxRound and maxRound > 0 then
        _maxRound = maxRound
        Logger.Log(string.format("BattleLogic.SetMaxRound - 最大回合数设置为 %d", _maxRound))
    end
end

--- 设置普通攻击开始回调
---@param callback function 回调函数 function(hero)
function BattleLogic.SetOnHeroCastSmallSkillBegin(callback)
    _onHeroCastSmallSkillBegin = callback
end

--- 设置普通攻击结束回调
---@param callback function 回调函数 function(hero, success)
function BattleLogic.SetOnHeroCastSmallSkillEnd(callback)
    _onHeroCastSmallSkillEnd = callback
end

--- 设置战斗结果回调
---@param callback function 回调函数 function(win, endState)
function BattleLogic.SetOnBattleResult(callback)
    _onBattleResult = callback
end

--- 获取队伍信息
---@return table, table 左侧队伍, 右侧队伍
function BattleLogic.GetTeams()
    return _teamLeft, _teamRight
end

--- 获取战斗状态信息（用于调试）
---@return table 战斗状态信息
function BattleLogic.GetBattleStatus()
    return {
        curRound = _curRound,
        maxRound = _maxRound,
        actionCount = _actionCount,
        isBattleFinish = _isBattleFinish,
        win = _win,
        isPause = _isPause,
        leftTeamAlive = BattleActionOrder.HasAliveHeroes("left"),
        rightTeamAlive = BattleActionOrder.HasAliveHeroes("right"),
    }
end

return BattleLogic
