---
--- Battle Buff Module
--- 战斗Buff模块 - 管理英雄身上的Buff效果
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")

-- 确保枚举已加载
if not E_BUFF_SPEC_SUBTYPE then
    require("core.battle_enum")
end

local BattleBuff = {}

-- Buff存储表: { [heroId] = { buff1, buff2, ... } }
local heroBuffs = {}

-- Buff ID计数器
local buffIdCounter = 0

local function GetHeroBuffKey(target)
    if not target then
        return nil
    end
    return target.id or target.instanceId
end

-- Buff效果触发时机
local E_BUFF_TIMING = {
    ON_ADD = 1,           -- 添加时
    ON_REMOVE = 2,        -- 移除时
    ON_ROUND_BEGIN = 3,   -- 回合开始
    ON_ROUND_END = 4,     -- 回合结束
    ON_ATTACK = 5,        -- 攻击时
    ON_DEFEND = 6,        -- 受击时
    ON_DAMAGE = 7,        -- 造成伤害时
    ON_RECEIVE_DAMAGE = 8,-- 受到伤害时
    ON_HEAL = 9,          -- 治疗时
    ON_RECEIVE_HEAL = 10, -- 受到治疗时
    ON_KILL = 11,         -- 击杀时
    ON_DEATH = 12,        -- 死亡时
}

-- 控制类Buff子类型
local CONTROL_SUBTYPES = {}

-- 延迟初始化控制类Buff子类型（确保枚举已加载）
local function InitControlSubtypes()
    if E_BUFF_SPEC_SUBTYPE then
        CONTROL_SUBTYPES = {
            [E_BUFF_SPEC_SUBTYPE.STUN] = true,
            [E_BUFF_SPEC_SUBTYPE.Frozen] = true,
            [E_BUFF_SPEC_SUBTYPE.SILENT] = true,
            [E_BUFF_SPEC_SUBTYPE.Charm] = true,
            [E_BUFF_SPEC_SUBTYPE.Charm2] = true,
        }
    end
end

--- 初始化Buff系统
function BattleBuff.Init()
    -- 清空所有英雄的Buff
    for k, _ in pairs(heroBuffs) do
        heroBuffs[k] = nil
    end
    buffIdCounter = 0
    -- 初始化控制类Buff子类型
    InitControlSubtypes()
    Logger.Debug("BattleBuff.Init() - Buff系统已初始化")
end

--- 清理Buff系统
function BattleBuff.OnFinal()
    for k, _ in pairs(heroBuffs) do
        heroBuffs[k] = nil
    end
    buffIdCounter = 0
    Logger.Debug("BattleBuff.OnFinal() - Buff系统已清理")
end

--- 生成唯一Buff ID
---@return number Buff ID
local function GenerateBuffId()
    buffIdCounter = buffIdCounter + 1
    return buffIdCounter
end

--- 获取英雄的Buff列表
---@param target table 目标英雄
---@return table Buff列表
local function GetHeroBuffList(target)
    local key = GetHeroBuffKey(target)
    if not key then
        return nil
    end
    if not heroBuffs[key] then
        heroBuffs[key] = {}
    end
    return heroBuffs[key]
end

--- 创建Buff实例
---@param caster table 施法者
---@param target table 目标
---@param buffConfig table Buff配置
---@return table Buff实例
local function CreateBuff(caster, target, buffConfig)
    local buff = {
        id = GenerateBuffId(),
        buffId = buffConfig.buffId or 0,
        mainType = buffConfig.mainType or E_BUFF_MAIN_TYPE.GOOD,
        subType = buffConfig.subType or 0,
        name = buffConfig.name or "UnknownBuff",
        stackCount = buffConfig.initialStack or 1,
        maxStack = buffConfig.maxStack or 1,
        value = buffConfig.value,
        maxValue = buffConfig.maxValue or buffConfig.value,
        displayMode = buffConfig.displayMode,
        duration = buffConfig.duration or 1,
        maxDuration = buffConfig.duration or 1,
        caster = caster,
        target = target,
        effects = buffConfig.effects or {},
        isPermanent = buffConfig.isPermanent or false,
        canStack = buffConfig.canStack ~= false,
        stackRule = buffConfig.stackRule or "refresh", -- refresh, add, independent
        icon = buffConfig.icon or "",
        desc = buffConfig.desc or "",
        createTime = os.time(),
    }
    return buff
end

--- 查找相同类型的Buff
---@param buffList table Buff列表
---@param buffConfig table Buff配置
---@return table|nil 找到的Buff
local function FindSameBuff(buffList, buffConfig)
    for _, buff in ipairs(buffList) do
        if buff.buffId == buffConfig.buffId then
            return buff
        end
    end
    return nil
end

--- 添加Buff到目标
---@param caster table 施法者
---@param target table 目标英雄
---@param buffConfig table Buff配置 {buffId, mainType, subType, duration, effects, ...}
---@return boolean 是否成功添加
function BattleBuff.Add(caster, target, buffConfig)
    if not target or (not target.id and not target.instanceId) then
        Logger.LogError("BattleBuff.Add: 无效的目标")
        return false
    end
    
    if not buffConfig or not buffConfig.buffId then
        Logger.LogError("BattleBuff.Add: 无效的Buff配置")
        return false
    end
    
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return false
    end
    
    -- 检查是否已有相同Buff
    local existingBuff = FindSameBuff(buffList, buffConfig)
    
    if existingBuff then
        -- 处理叠加逻辑
        if existingBuff.canStack then
            if existingBuff.stackRule == "refresh" then
                -- 刷新持续时间和层数
                existingBuff.duration = buffConfig.duration or existingBuff.maxDuration
                existingBuff.stackCount = math.min(existingBuff.stackCount + (buffConfig.initialStack or 1), existingBuff.maxStack)
                Logger.Debug(string.format("BattleBuff.Add: 刷新Buff [%s] 层数=%d 持续时间=%d", 
                    existingBuff.name, existingBuff.stackCount, existingBuff.duration))
            elseif existingBuff.stackRule == "add" then
                -- 只增加层数
                existingBuff.stackCount = math.min(existingBuff.stackCount + (buffConfig.initialStack or 1), existingBuff.maxStack)
                Logger.Debug(string.format("BattleBuff.Add: 叠加Buff [%s] 层数=%d", 
                    existingBuff.name, existingBuff.stackCount))
            elseif existingBuff.stackRule == "independent" then
                -- 独立Buff，创建新的
                local newBuff = CreateBuff(caster, target, buffConfig)
                table.insert(buffList, newBuff)
                Logger.Debug(string.format("BattleBuff.Add: 添加独立Buff [%s] ID=%d", 
                    newBuff.name, newBuff.id))
                -- 触发添加时效果
                BattleBuff.ProcessBuffEffect(newBuff, target, E_BUFF_TIMING.ON_ADD)
            end
        else
            -- 不可叠加，刷新持续时间
            existingBuff.duration = buffConfig.duration or existingBuff.maxDuration
            existingBuff.caster = caster
            existingBuff.stackCount = buffConfig.initialStack or existingBuff.stackCount
            if buffConfig.value ~= nil then
                existingBuff.value = buffConfig.value
                existingBuff.maxValue = buffConfig.maxValue or buffConfig.value
            end
            Logger.Debug(string.format("BattleBuff.Add: 刷新不可叠加Buff [%s] 持续时间=%d", 
                existingBuff.name, existingBuff.duration))
        end
        return true
    else
        -- 创建新Buff
        local newBuff = CreateBuff(caster, target, buffConfig)
        table.insert(buffList, newBuff)
        Logger.Debug(string.format("BattleBuff.Add: 添加新Buff [%s] ID=%d 类型=%d", 
            newBuff.name, newBuff.id, newBuff.mainType))

        -- 5e-style: hard control immediately interrupts chanting.
        if target.__pendingCast and tonumber(newBuff.mainType) == 3 then
            Logger.Log(string.format("[CHANT] %s 吟唱被控制打断: %s", target.name or "Unknown", tostring(target.__pendingCast.skillName or target.__pendingCast.skillId)))
            target.__pendingCast = nil
        end
        
        -- 触发添加时效果
        BattleBuff.ProcessBuffEffect(newBuff, target, E_BUFF_TIMING.ON_ADD)
        
        -- 发布Buff添加事件（旧版兼容）
        BattleEvent.Publish("BUFF_ADDED", caster, target, newBuff)
        
        -- 触发可视化Buff添加事件
        BattleEvent.Publish(BattleVisualEvents.BUFF_ADDED, BattleVisualEvents.BuildBuffEvent(
            BattleVisualEvents.BUFF_ADDED, caster, target, newBuff))
        
        -- 触发目标状态变化事件
        BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(target))
        
        return true
    end
end

--- 根据Buff ID移除Buff
---@param target table 目标英雄
---@param buffId number Buff ID
---@return boolean 是否成功移除
local function RemoveBuffById(target, buffId)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return false
    end
    
    for i, buff in ipairs(buffList) do
        if buff.id == buffId then
            -- 触发移除时效果
            BattleBuff.ProcessBuffEffect(buff, target, E_BUFF_TIMING.ON_REMOVE)
            
            -- 发布Buff移除事件（旧版兼容）
            BattleEvent.Publish("BUFF_REMOVED", buff.caster, target, buff)
            
            -- 触发可视化Buff移除事件
            BattleEvent.Publish(BattleVisualEvents.BUFF_REMOVED, BattleVisualEvents.BuildBuffEvent(
                BattleVisualEvents.BUFF_REMOVED, buff.caster, target, buff))
            
            -- 触发目标状态变化事件
            BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(target))
            
            table.remove(buffList, i)
            Logger.Debug(string.format("BattleBuff.RemoveBuffById: 移除Buff [%s] ID=%d", 
                buff.name, buffId))
            return true
        end
    end
    return false
end

--- 根据主类型删除Buff
---@param target table 目标英雄
---@param mainType number 主类型
---@return number 移除的Buff数量
function BattleBuff.DelBuffByMainType(target, mainType)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return 0
    end
    
    local removedCount = 0
    for i = #buffList, 1, -1 do
        local buff = buffList[i]
        if buff.mainType == mainType then
            -- 触发移除时效果
            BattleBuff.ProcessBuffEffect(buff, target, E_BUFF_TIMING.ON_REMOVE)
            
            -- 发布Buff移除事件
            BattleEvent.Publish("BUFF_REMOVED", buff.caster, target, buff)
            
            table.remove(buffList, i)
            removedCount = removedCount + 1
            Logger.Debug(string.format("BattleBuff.DelBuffByMainType: 移除Buff [%s] 主类型=%d", 
                buff.name, mainType))
        end
    end
    
    return removedCount
end

--- 根据子类型删除Buff
---@param target table 目标英雄
---@param subType number 子类型
---@param count number 删除数量 (nil表示删除所有)
---@return number 实际移除的Buff数量
function BattleBuff.DelBuffBySubType(target, subType, count)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return 0
    end
    
    local removedCount = 0
    local maxRemove = count or #buffList
    
    for i = #buffList, 1, -1 do
        if removedCount >= maxRemove then
            break
        end
        
        local buff = buffList[i]
        if buff.subType == subType then
            -- 触发移除时效果
            BattleBuff.ProcessBuffEffect(buff, target, E_BUFF_TIMING.ON_REMOVE)
            
            -- 发布Buff移除事件
            BattleEvent.Publish("BUFF_REMOVED", buff.caster, target, buff)
            
            table.remove(buffList, i)
            removedCount = removedCount + 1
            Logger.Debug(string.format("BattleBuff.DelBuffBySubType: 移除Buff [%s] 子类型=%d", 
                buff.name, subType))
        end
    end
    
    return removedCount
end

--- 根据主类型获取Buff层数
---@param target table 目标英雄
---@param mainType number 主类型
---@return number 总层数
function BattleBuff.GetBuffStackNumByMainType(target, mainType)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return 0
    end
    
    local totalStack = 0
    for _, buff in ipairs(buffList) do
        if buff.mainType == mainType then
            totalStack = totalStack + buff.stackCount
        end
    end
    
    return totalStack
end

--- 根据子类型获取Buff层数
---@param target table 目标英雄
---@param subType number 子类型
---@return number 总层数
function BattleBuff.GetBuffStackNumBySubType(target, subType)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return 0
    end
    
    local totalStack = 0
    for _, buff in ipairs(buffList) do
        if buff.subType == subType then
            totalStack = totalStack + buff.stackCount
        end
    end
    
    return totalStack
end

--- 根据子类型获取Buff数值参数
---@param target table 目标英雄
---@param subType number 子类型
---@return number 总数值
function BattleBuff.GetBuffValueBySubType(target, subType)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return 0
    end

    local totalValue = 0
    for _, buff in ipairs(buffList) do
        if buff.subType == subType and type(buff.value) == "number" then
            totalValue = totalValue + buff.value
        end
    end

    return totalValue
end

--- 处理Buff效果
---@param buff table Buff实例
---@param hero table 目标英雄
---@param timing number 触发时机
function BattleBuff.ProcessBuffEffect(buff, hero, timing)
    if not buff or not buff.effects then
        return
    end
    
    for _, effect in ipairs(buff.effects) do
        if effect.timing == timing then
            -- 根据效果类型处理
            local effectType = effect.type
            if effectType == "damage" then
                -- 造成伤害
                Logger.Debug(string.format("BattleBuff.ProcessBuffEffect: Buff [%s] 造成 %d 伤害", 
                    buff.name, effect.value * buff.stackCount))
                BattleEvent.Publish("BUFF_DAMAGE", buff.caster, hero, effect.value * buff.stackCount, effect.damageType)
                    
            elseif effectType == "heal" then
                -- 治疗
                Logger.Debug(string.format("BattleBuff.ProcessBuffEffect: Buff [%s] 恢复 %d 生命", 
                    buff.name, effect.value * buff.stackCount))
                BattleEvent.Publish("BUFF_HEAL", buff.caster, hero, effect.value * buff.stackCount)
                    
            elseif effectType == "attr_change" then
                -- 属性变更
                Logger.Debug(string.format("BattleBuff.ProcessBuffEffect: Buff [%s] 改变属性 %s %+d", 
                    buff.name, effect.attr, effect.value * buff.stackCount))
                BattleEvent.Publish("BUFF_ATTR_CHANGE", hero, effect.attr, effect.value * buff.stackCount, true)
                    
            elseif effectType == "dispel" then
                -- 驱散
                Logger.Debug(string.format("BattleBuff.ProcessBuffEffect: Buff [%s] 驱散效果", buff.name))
                BattleEvent.Publish("BUFF_DISPEL", buff.caster, hero, effect.targetType)
                    
            elseif effectType == "energy" then
                -- 能量变化
                Logger.Debug(string.format("BattleBuff.ProcessBuffEffect: Buff [%s] 能量变化 %+d", 
                    buff.name, effect.value * buff.stackCount))
                BattleEvent.Publish("BUFF_ENERGY_CHANGE", hero, effect.value * buff.stackCount)
                    
            elseif effectType == "custom" then
                -- 自定义效果
                if effect.func and type(effect.func) == "function" then
                    effect.func(buff, hero, effect)
                end
            end
        end
    end
end

--- 回合开始处理
function BattleBuff.OnRoundBegin(hero)
    Logger.Debug("BattleBuff.OnRoundBegin: 回合开始处理Buff效果")

    if hero then
        local buffList = GetHeroBuffList(hero)
        for _, buff in ipairs(buffList) do
            BattleBuff.ProcessBuffEffect(buff, buff.target, E_BUFF_TIMING.ON_ROUND_BEGIN)
        end
        return
    end

    for _, buffList in pairs(heroBuffs) do
        for _, buff in ipairs(buffList) do
            BattleBuff.ProcessBuffEffect(buff, buff.target, E_BUFF_TIMING.ON_ROUND_BEGIN)
        end
    end
end

--- 回合结束处理 (减少持续时间)
function BattleBuff.OnRoundEnd(hero)
    Logger.Debug("BattleBuff.OnRoundEnd: 回合结束处理Buff持续时间")

    local targetBuffs = hero and { [GetHeroBuffKey(hero)] = GetHeroBuffList(hero) } or heroBuffs
    for heroId, buffList in pairs(targetBuffs) do
        local expiredBuffs = {}
        
        for i, buff in ipairs(buffList) do
            -- 触发回合结束效果
            BattleBuff.ProcessBuffEffect(buff, buff.target, E_BUFF_TIMING.ON_ROUND_END)
            
            -- 减少持续时间
            if not buff.isPermanent then
                buff.duration = buff.duration - 1
                
                if buff.duration <= 0 then
                    table.insert(expiredBuffs, i)
                    Logger.Debug(string.format("BattleBuff.OnRoundEnd: Buff [%s] 已过期", buff.name))
                end
            end
        end
        
        -- 移除过期的Buff (从后往前移除)
        for i = #expiredBuffs, 1, -1 do
            local buffIndex = expiredBuffs[i]
            local buff = buffList[buffIndex]
            
            -- 触发移除时效果
            BattleBuff.ProcessBuffEffect(buff, buff.target, E_BUFF_TIMING.ON_REMOVE)
            
            -- 发布Buff过期事件
            BattleEvent.Publish("BUFF_EXPIRED", buff.caster, buff.target, buff)
            
            table.remove(buffList, buffIndex)
        end
        
        -- 如果该英雄没有Buff了，清理表
        if #buffList == 0 then
            heroBuffs[heroId] = nil
        end
    end
end

function BattleBuff.HasControlBuff(target)
    return BattleBuff.IsHeroUnderControl(target)
end

--- 检查英雄是否处于控制状态 (眩晕/魅惑等)
---@param target table 目标英雄
---@return boolean 是否被控制
function BattleBuff.IsHeroUnderControl(target)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return false
    end
    
    for _, buff in ipairs(buffList) do
        if CONTROL_SUBTYPES[buff.subType] then
            return true
        end
        -- 控制主类型也判定为控制
        if buff.mainType == E_BUFF_MAIN_TYPE.CONTROL then
            return true
        end
    end
    
    return false
end

--- 获取英雄的控制Buff列表
---@param target table 目标英雄
---@return table 控制Buff列表
function BattleBuff.GetControlBuffs(target)
    local buffList = GetHeroBuffList(target)
    if not buffList then
        return {}
    end
    
    local controlBuffs = {}
    for _, buff in ipairs(buffList) do
        if CONTROL_SUBTYPES[buff.subType] or buff.mainType == E_BUFF_MAIN_TYPE.CONTROL then
            table.insert(controlBuffs, buff)
        end
    end
    
    return controlBuffs
end

--- 清除英雄所有Buff
---@param hero table 目标英雄
function BattleBuff.ClearAllBuffs(hero)
    local buffList = GetHeroBuffList(hero)
    if not buffList then
        return
    end
    
    -- 触发所有Buff的移除效果
    for _, buff in ipairs(buffList) do
        BattleBuff.ProcessBuffEffect(buff, hero, E_BUFF_TIMING.ON_REMOVE)
        BattleEvent.Publish("BUFF_REMOVED", buff.caster, hero, buff)
    end
    
    local key = GetHeroBuffKey(hero)
    heroBuffs[key] = nil

    Logger.Debug(string.format("BattleBuff.ClearAllBuffs: 清除英雄 [%s] 所有Buff", tostring(key)))
end

function BattleBuff.RemoveAllDebuffs(hero)
    local buffList = GetHeroBuffList(hero)
    if not buffList then
        return 0
    end

    local removed = 0
    for i = #buffList, 1, -1 do
        local buff = buffList[i]
        if buff.mainType == E_BUFF_MAIN_TYPE.BAD or buff.mainType == E_BUFF_MAIN_TYPE.CONTROL then
            BattleBuff.ProcessBuffEffect(buff, hero, E_BUFF_TIMING.ON_REMOVE)
            BattleEvent.Publish("BUFF_REMOVED", buff.caster, hero, buff)
            table.remove(buffList, i)
            removed = removed + 1
        end
    end
    if #buffList == 0 then
        heroBuffs[GetHeroBuffKey(hero)] = nil
    end
    return removed
end

--- 获取英雄所有Buff
---@param hero table 目标英雄
---@return table Buff列表
function BattleBuff.GetAllBuffs(hero)
    local buffList = GetHeroBuffList(hero)
    if not buffList then
        return {}
    end
    return buffList
end

--- 获取指定Buff
---@param hero table 目标英雄
---@param buffId number Buff ID
---@return table|nil Buff实例
function BattleBuff.GetBuff(hero, buffId)
    local buffList = GetHeroBuffList(hero)
    if not buffList then
        return nil
    end
    
    for _, buff in ipairs(buffList) do
        if buff.buffId == buffId then
            return buff
        end
    end
    return nil
end

function BattleBuff.GetBuffBySubType(hero, subType)
    local buffList = GetHeroBuffList(hero)
    if not buffList then
        return nil
    end

    for _, buff in ipairs(buffList) do
        if buff.subType == subType then
            return buff
        end
    end
    return nil
end

--- 修改Buff层数
---@param hero table 目标英雄
---@param buffId number Buff ID
---@param delta number 变化量 (正数增加，负数减少)
---@return boolean 是否成功
function BattleBuff.ModifyBuffStack(hero, buffId, delta)
    local buff = BattleBuff.GetBuff(hero, buffId)
    if not buff then
        return false
    end
    
    buff.stackCount = math.max(1, math.min(buff.stackCount + delta, buff.maxStack))
    Logger.Debug(string.format("BattleBuff.ModifyBuffStack: Buff [%s] 层数变为 %d", 
        buff.name, buff.stackCount))
    
    return true
end

--- 获取Buff统计信息 (用于调试)
---@return table 统计信息
function BattleBuff.GetStats()
    local stats = {
        heroCount = 0,
        totalBuffCount = 0,
        buffsByMainType = {},
        buffsBySubType = {},
    }
    
    for heroId, buffList in pairs(heroBuffs) do
        stats.heroCount = stats.heroCount + 1
        stats.totalBuffCount = stats.totalBuffCount + #buffList
        
        for _, buff in ipairs(buffList) do
            stats.buffsByMainType[buff.mainType] = (stats.buffsByMainType[buff.mainType] or 0) + 1
            stats.buffsBySubType[buff.subType] = (stats.buffsBySubType[buff.subType] or 0) + 1
        end
    end
    
    return stats
end

return BattleBuff
