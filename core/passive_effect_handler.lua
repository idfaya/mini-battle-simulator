---
--- 被动技能效果处理器
--- 处理被动技能触发的各种效果
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleBuff = require("modules.battle_buff")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleAttribute = require("modules.battle_attribute")

---@class PassiveEffectHandler
local PassiveEffectHandler = {}

-- 是否已初始化
local isInitialized = false

--- 初始化被动技能效果处理器
function PassiveEffectHandler.Init()
    if isInitialized then
        return
    end
    
    -- 订阅被动技能相关事件
    BattleEvent.AddListener("PASSIVE_ADD_BUFF", PassiveEffectHandler.OnAddBuff)
    BattleEvent.AddListener("PASSIVE_HEAL", PassiveEffectHandler.OnHeal)
    BattleEvent.AddListener("PASSIVE_DAMAGE", PassiveEffectHandler.OnDamage)
    BattleEvent.AddListener("PASSIVE_ATTR_CHANGE", PassiveEffectHandler.OnAttrChange)
    BattleEvent.AddListener("PASSIVE_ENERGY_CHANGE", PassiveEffectHandler.OnEnergyChange)
    BattleEvent.AddListener("PASSIVE_DISPEL", PassiveEffectHandler.OnDispel)
    
    isInitialized = true
    Logger.Log("[PassiveEffectHandler] 被动技能效果处理器初始化完成")
end

--- 清理被动技能效果处理器
function PassiveEffectHandler.OnFinal()
    -- 取消订阅事件
    BattleEvent.RemoveListener("PASSIVE_ADD_BUFF", PassiveEffectHandler.OnAddBuff)
    BattleEvent.RemoveListener("PASSIVE_HEAL", PassiveEffectHandler.OnHeal)
    BattleEvent.RemoveListener("PASSIVE_DAMAGE", PassiveEffectHandler.OnDamage)
    BattleEvent.RemoveListener("PASSIVE_ATTR_CHANGE", PassiveEffectHandler.OnAttrChange)
    BattleEvent.RemoveListener("PASSIVE_ENERGY_CHANGE", PassiveEffectHandler.OnEnergyChange)
    BattleEvent.RemoveListener("PASSIVE_DISPEL", PassiveEffectHandler.OnDispel)
    
    isInitialized = false
    Logger.Log("[PassiveEffectHandler] 被动技能效果处理器已清理")
end

--- 获取目标英雄
---@param sourceHero table 源英雄
---@param targetType string 目标类型 ("self", "enemy", "ally", "all")
---@return table 目标英雄列表
local function GetTargetHeroes(sourceHero, targetType)
    if not sourceHero or not sourceHero.formation then
        return {sourceHero}
    end
    
    local BattleFormation = require("modules.battle_formation")
    
    if targetType == "self" then
        return {sourceHero}
    elseif targetType == "enemy" then
        -- 获取随机敌人
        local enemyId = BattleFormation.GetRandomEnemyInstanceId(sourceHero)
        if enemyId then
            local enemy = BattleFormation.FindHeroByInstanceId(enemyId)
            if enemy then
                return {enemy}
            end
        end
        return {}
    elseif targetType == "ally" then
        -- 获取友方（不包括自己）
        local allies = {}
        local allHeroes = BattleFormation.GetAllHeros()
        for _, hero in ipairs(allHeroes) do
            if hero.formation == sourceHero.formation and hero.id ~= sourceHero.id and hero.isAlive then
                table.insert(allies, hero)
            end
        end
        return allies
    elseif targetType == "all" then
        -- 所有英雄
        return BattleFormation.GetAllHeros() or {}
    end
    
    return {sourceHero}
end

--- 处理添加Buff效果
---@param hero table 触发被动技能的英雄
---@param buffId number Buff ID
---@param targetType string 目标类型
---@param duration number 持续时间
---@param stack number 层数
function PassiveEffectHandler.OnAddBuff(hero, buffId, targetType, duration, stack)
    if not hero or not buffId then
        return
    end
    
    local targets = GetTargetHeroes(hero, targetType or "self")
    if #targets == 0 then
        return
    end
    
    Logger.Log(string.format("[PassiveEffectHandler.OnAddBuff] %s 触发被动Buff效果: BuffID=%d, 目标=%s",
        hero.name or "Unknown", buffId, targetType or "self"))
    
    -- 获取Buff配置
    local BuffConfig = require("config.buff_config")
    local battleBuffConfig = BuffConfig.ConvertToBattleBuffConfig(buffId)
    
    if not battleBuffConfig then
        Logger.Log(string.format("[PassiveEffectHandler.OnAddBuff] 无法找到Buff配置: %d", buffId))
        return
    end
    
    -- 给所有目标添加Buff
    for _, target in ipairs(targets) do
        if target.isAlive then
            BattleBuff.Add(hero, target, battleBuffConfig)
            Logger.Log(string.format("  -> %s 获得被动Buff [%s]", 
                target.name or "Unknown", battleBuffConfig.name or "Unknown"))
        end
    end
end

--- 处理治疗效果
---@param hero table 触发被动技能的英雄
---@param healValue number 治疗值
---@param targetType string 目标类型
function PassiveEffectHandler.OnHeal(hero, healValue, targetType)
    if not hero or not healValue or healValue <= 0 then
        return
    end
    
    local targets = GetTargetHeroes(hero, targetType or "self")
    if #targets == 0 then
        return
    end
    
    Logger.Log(string.format("[PassiveEffectHandler.OnHeal] %s 触发被动治疗效果: %d, 目标=%s",
        hero.name or "Unknown", healValue, targetType or "self"))
    
    -- 治疗所有目标
    for _, target in ipairs(targets) do
        if target.isAlive then
            BattleDmgHeal.ApplyHeal(target, healValue, hero)
            Logger.Log(string.format("  -> %s 受到 %d 点被动治疗", 
                target.name or "Unknown", healValue))
        end
    end
end

--- 处理伤害效果
---@param hero table 触发被动技能的英雄
---@param damageValue number 伤害值
---@param targetType string 目标类型
---@param damageType number 伤害类型
function PassiveEffectHandler.OnDamage(hero, damageValue, targetType, damageType)
    if not hero or not damageValue or damageValue <= 0 then
        return
    end
    
    local targets = GetTargetHeroes(hero, targetType or "enemy")
    if #targets == 0 then
        return
    end
    
    Logger.Log(string.format("[PassiveEffectHandler.OnDamage] %s 触发被动伤害效果: %d, 目标=%s",
        hero.name or "Unknown", damageValue, targetType or "enemy"))
    
    -- 对所有目标造成伤害
    for _, target in ipairs(targets) do
        if target.isAlive then
            BattleDmgHeal.ApplyDamage(target, damageValue, hero)
            Logger.Log(string.format("  -> %s 受到 %d 点被动伤害", 
                target.name or "Unknown", damageValue))
        end
    end
end

--- 处理属性变更效果
---@param hero table 触发被动技能的英雄
---@param attrName string 属性名
---@param value number 变更值
---@param targetType string 目标类型
function PassiveEffectHandler.OnAttrChange(hero, attrName, value, targetType)
    if not hero or not attrName or not value then
        return
    end
    
    local targets = GetTargetHeroes(hero, targetType or "self")
    if #targets == 0 then
        return
    end
    
    Logger.Log(string.format("[PassiveEffectHandler.OnAttrChange] %s 触发被动属性变更: %s %+d, 目标=%s",
        hero.name or "Unknown", attrName, value, targetType or "self"))
    
    -- 变更所有目标的属性
    for _, target in ipairs(targets) do
        if target.isAlive then
            local oldValue = target[attrName] or 0
            target[attrName] = oldValue + value
            Logger.Log(string.format("  -> %s %s: %d -> %d", 
                target.name or "Unknown", attrName, oldValue, target[attrName]))
        end
    end
end

--- 处理能量变化效果
---@param hero table 触发被动技能的英雄
---@param value number 能量变化值
---@param targetType string 目标类型
function PassiveEffectHandler.OnEnergyChange(hero, value, targetType)
    if not hero or not value then
        return
    end
    
    local targets = GetTargetHeroes(hero, targetType or "self")
    if #targets == 0 then
        return
    end
    
    Logger.Log(string.format("[PassiveEffectHandler.OnEnergyChange] %s 触发被动能量变化: %+d, 目标=%s",
        hero.name or "Unknown", value, targetType or "self"))
    
    -- 变更所有目标的能量
    for _, target in ipairs(targets) do
        if target.isAlive then
            local oldEnergy = target.curEnergy or 0
            target.curEnergy = math.max(0, oldEnergy + value)
            Logger.Log(string.format("  -> %s 能量: %d -> %d", 
                target.name or "Unknown", oldEnergy, target.curEnergy))
        end
    end
end

--- 处理驱散效果
---@param hero table 触发被动技能的英雄
---@param targetType string 目标类型
function PassiveEffectHandler.OnDispel(hero, targetType)
    if not hero then
        return
    end
    
    local targets = GetTargetHeroes(hero, targetType or "self")
    if #targets == 0 then
        return
    end
    
    Logger.Log(string.format("[PassiveEffectHandler.OnDispel] %s 触发被动驱散效果, 目标=%s",
        hero.name or "Unknown", targetType or "self"))
    
    -- 驱散所有目标的Buff
    for _, target in ipairs(targets) do
        if target.isAlive then
            -- 获取所有Buff并移除
            local buffs = BattleBuff.GetAllBuffs(target)
            for _, buff in ipairs(buffs) do
                BattleBuff.Remove(target, buff.buffId)
            end
            Logger.Log(string.format("  -> %s 被驱散 %d 个Buff", 
                target.name or "Unknown", #buffs))
        end
    end
end

return PassiveEffectHandler
