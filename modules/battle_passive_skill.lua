---
--- Battle Passive Skill Module
--- 战斗被动技能模块 - 管理英雄的被动技能触发
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")

---@class BattlePassiveSkill
local BattlePassiveSkill = {}

-- 被动技能触发时机枚举
BattlePassiveSkill.E_TRIGGER_TIMING = {
    BATTLE_BEGIN = 1,       -- 战斗开始时
    BATTLE_END = 2,         -- 战斗结束时
    ROUND_BEGIN = 3,        -- 回合开始时
    ROUND_END = 4,          -- 回合结束时
    ACTION_BEGIN = 5,       -- 英雄行动开始时
    ACTION_END = 6,         -- 英雄行动结束时
    HP_CHANGE = 7,          -- HP变化时
    MP_CHANGE = 8,          -- MP变化时
    ENERGY_CHANGE = 9,      -- 能量变化时
    ON_ATTACK = 10,         -- 攻击时
    ON_DEFEND = 11,         -- 受击时
    ON_DAMAGE = 12,         -- 造成伤害时
    ON_RECEIVE_DAMAGE = 13, -- 受到伤害时
    ON_HEAL = 14,           -- 治疗时
    ON_RECEIVE_HEAL = 15,   -- 受到治疗时
    ON_KILL = 16,           -- 击杀时
    ON_DEATH = 17,          -- 死亡时
    ON_BUFF_ADD = 18,       -- Buff添加时
    ON_BUFF_REMOVE = 19,    -- Buff移除时
    ON_SKILL_CAST = 20,     -- 技能释放时
}

-- 英雄被动技能存储表: { [heroId] = { skill1, skill2, ... } }
local heroPassiveSkills = {}

-- 技能实例ID计数器
local skillInstanceIdCounter = 0

--- 生成唯一技能实例ID
---@return number 技能实例ID
local function GenerateSkillInstanceId()
    skillInstanceIdCounter = skillInstanceIdCounter + 1
    return skillInstanceIdCounter
end

--- 初始化被动技能系统
function BattlePassiveSkill.Init()
    -- 清空所有英雄的被动技能
    for k, _ in pairs(heroPassiveSkills) do
        heroPassiveSkills[k] = nil
    end
    skillInstanceIdCounter = 0
    Logger.Debug("BattlePassiveSkill.Init() - 被动技能系统已初始化")
end

--- 清理被动技能系统
function BattlePassiveSkill.OnFinal()
    for k, _ in pairs(heroPassiveSkills) do
        heroPassiveSkills[k] = nil
    end
    skillInstanceIdCounter = 0
    Logger.Debug("BattlePassiveSkill.OnFinal() - 被动技能系统已清理")
end

--- 获取英雄的被动技能列表
---@param hero table 英雄对象
---@return table|nil 被动技能列表
local function GetHeroPassiveSkillList(hero)
    if not hero or not hero.id then
        return nil
    end
    if not heroPassiveSkills[hero.id] then
        heroPassiveSkills[hero.id] = {}
    end
    return heroPassiveSkills[hero.id]
end

--- 创建被动技能实例
---@param hero table 英雄对象
---@param skillConfig table 技能配置
---@return table|nil 被动技能实例
local function CreatePassiveSkillInstance(hero, skillConfig)
    if not skillConfig or not skillConfig.skillId then
        Logger.Error("[BattlePassiveSkill.CreatePassiveSkillInstance] 无效的技能配置")
        return nil
    end

    local skill = {
        instanceId = GenerateSkillInstanceId(),
        skillId = skillConfig.skillId,
        name = skillConfig.name or "Unknown Passive Skill",
        desc = skillConfig.desc or "",
        level = skillConfig.level or 1,
        triggerTiming = skillConfig.triggerTiming or {},
        triggerCondition = skillConfig.triggerCondition or {},
        effects = skillConfig.effects or {},
        luaFile = skillConfig.luaFile or skillConfig.LuaFile or "",
        luaFuncName = skillConfig.luaFuncName or "",
        buffSubType = skillConfig.buffSubType or 0,
        maxTriggerCount = skillConfig.maxTriggerCount or -1, -- -1表示无限制
        curTriggerCount = 0,
        cooldown = skillConfig.cooldown or 0,
        curCooldown = 0,
        owner = hero,
        config = skillConfig,
    }

    return skill
end

--- 添加被动技能到英雄
---@param hero table 英雄对象
---@param skillConfig table 技能配置 {skillId, name, triggerTiming, effects, ...}
---@return boolean 是否成功添加
function BattlePassiveSkill.InsertPassiveSkill(hero, skillConfig)
    if not hero or not hero.id then
        Logger.Error("[BattlePassiveSkill.InsertPassiveSkill] 无效的英雄对象")
        return false
    end

    if not skillConfig or not skillConfig.skillId then
        Logger.Error("[BattlePassiveSkill.InsertPassiveSkill] 无效的技能配置")
        return false
    end

    local skillList = GetHeroPassiveSkillList(hero)
    if not skillList then
        return false
    end

    -- 检查是否已存在相同技能
    for _, existingSkill in ipairs(skillList) do
        if existingSkill.skillId == skillConfig.skillId then
            Logger.Warn(string.format("[BattlePassiveSkill.InsertPassiveSkill] 英雄 [%s] 已存在被动技能 [%s]",
                tostring(hero.name), tostring(skillConfig.name)))
            return false
        end
    end

    -- 创建被动技能实例
    local skill = CreatePassiveSkillInstance(hero, skillConfig)
    if not skill then
        return false
    end

    table.insert(skillList, skill)
    Logger.Info(string.format("[BattlePassiveSkill.InsertPassiveSkill] 英雄 [%s] 添加被动技能 [%s] ID=%d",
        tostring(hero.name), tostring(skill.name), skill.instanceId))

    -- 发布被动技能添加事件
    BattleEvent.Publish("PASSIVE_SKILL_ADDED", hero, skill)

    return true
end

--- 从英雄移除被动技能
---@param hero table 英雄对象
---@param skillId number 技能ID
---@return boolean 是否成功移除
function BattlePassiveSkill.RemovePassiveSkill(hero, skillId)
    if not hero or not hero.id then
        Logger.Error("[BattlePassiveSkill.RemovePassiveSkill] 无效的英雄对象")
        return false
    end

    local skillList = GetHeroPassiveSkillList(hero)
    if not skillList then
        return false
    end

    for i, skill in ipairs(skillList) do
        if skill.skillId == skillId then
            -- 发布被动技能移除事件
            BattleEvent.Publish("PASSIVE_SKILL_REMOVED", hero, skill)

            table.remove(skillList, i)
            Logger.Info(string.format("[BattlePassiveSkill.RemovePassiveSkill] 英雄 [%s] 移除被动技能 [%s] ID=%d",
                tostring(hero.name), tostring(skill.name), skill.instanceId))
            return true
        end
    end

    Logger.Warn(string.format("[BattlePassiveSkill.RemovePassiveSkill] 英雄 [%s] 未找到技能ID=%d",
        tostring(hero.name), skillId))
    return false
end

--- 检查技能触发条件
---@param hero table 英雄对象
---@param skill table 被动技能
---@param context table 触发上下文
---@return boolean 是否满足条件
local function CheckTriggerCondition(hero, skill, context)
    if not skill.triggerCondition then
        return true
    end

    local condition = skill.triggerCondition

    -- 检查最大触发次数
    if skill.maxTriggerCount > 0 and skill.curTriggerCount >= skill.maxTriggerCount then
        return false
    end

    -- 检查冷却
    if skill.curCooldown > 0 then
        return false
    end

    -- 检查HP条件
    if condition.hpPercent then
        local hpPercent = hero.hp and hero.maxHp and (hero.hp / hero.maxHp * 100) or 100
        if condition.hpPercent.min and hpPercent < condition.hpPercent.min then
            return false
        end
        if condition.hpPercent.max and hpPercent > condition.hpPercent.max then
            return false
        end
    end

    -- 检查MP条件
    if condition.mpPercent then
        local mpPercent = hero.mp and hero.maxMp and (hero.mp / hero.maxMp * 100) or 100
        if condition.mpPercent.min and mpPercent < condition.mpPercent.min then
            return false
        end
        if condition.mpPercent.max and mpPercent > condition.mpPercent.max then
            return false
        end
    end

    -- 检查能量条件
    if condition.energy then
        local energy = hero.energy or 0
        if condition.energy.min and energy < condition.energy.min then
            return false
        end
        if condition.energy.max and energy > condition.energy.max then
            return false
        end
    end

    -- 检查回合条件
    if condition.round then
        local round = context and context.round or 0
        if condition.round.min and round < condition.round.min then
            return false
        end
        if condition.round.max and round > condition.round.max then
            return false
        end
    end

    -- 检查自定义条件
    if condition.customCheck and type(condition.customCheck) == "function" then
        if not condition.customCheck(hero, skill, context) then
            return false
        end
    end

    return true
end

--- 加载被动技能Lua脚本
---@param skill table 被动技能
---@return table|nil Lua脚本模块
local function LoadPassiveSkillLua(skill)
    if not skill or not skill.luaFile or skill.luaFile == "" then
        return nil
    end

    local luaFile = skill.luaFile
    -- 移除.lua后缀（如果有）
    luaFile = string.gsub(luaFile, "%.lua$", "")

    local success, skillModule = pcall(require, luaFile)
    if not success then
        Logger.Error("[BattlePassiveSkill.LoadPassiveSkillLua] 加载技能Lua失败: " .. luaFile .. ", 错误: " .. tostring(skillModule))
        return nil
    end

    return skillModule
end

--- 调用被动技能
---@param hero table 英雄对象
---@param skill table 被动技能
---@param buffSubType number Buff子类型 (可选)
---@param funcName string 要调用的函数名 (可选)
---@param context table 触发上下文 (可选)
---@return boolean 是否调用成功
function BattlePassiveSkill.CallPassiveSkill(hero, skill, buffSubType, funcName, context)
    if not hero or not skill then
        Logger.Error("[BattlePassiveSkill.CallPassiveSkill] 英雄或技能为空")
        return false
    end

    -- 检查英雄状态
    if hero.isDead or hero.isAlive == false then
        return false
    end

    -- 检查Buff子类型匹配 (如果指定了)
    if buffSubType and buffSubType ~= 0 and skill.buffSubType ~= buffSubType then
        return false
    end

    -- 检查触发条件
    if not CheckTriggerCondition(hero, skill, context) then
        return false
    end

    Logger.Info(string.format("[BattlePassiveSkill.CallPassiveSkill] 英雄 [%s] 触发被动技能 [%s]",
        tostring(hero.name), tostring(skill.name)))

    local success = false

    -- 1. 执行Lua脚本中的函数
    if skill.luaFile and skill.luaFile ~= "" then
        local skillLua = LoadPassiveSkillLua(skill)
        if skillLua then
            local targetFunc = funcName or skill.luaFuncName or "Execute"
            if skillLua[targetFunc] and type(skillLua[targetFunc]) == "function" then
                local result = skillLua[targetFunc](hero, skill, context)
                if result then
                    success = true
                end
            elseif skillLua.Execute and type(skillLua.Execute) == "function" then
                local result = skillLua.Execute(hero, skill, context)
                if result then
                    success = true
                end
            end
        end
    end

    -- 2. 执行配置的效果
    if skill.effects then
        for _, effect in ipairs(skill.effects) do
            BattlePassiveSkill.ProcessPassiveEffect(hero, skill, effect, context)
            success = true
        end
    end

    -- 更新触发计数和冷却
    if success then
        skill.curTriggerCount = skill.curTriggerCount + 1
        skill.curCooldown = skill.cooldown

        -- 发布被动技能触发事件
        BattleEvent.Publish("PASSIVE_SKILL_TRIGGERED", hero, skill, context)
    end

    return success
end

--- 处理被动技能效果
---@param hero table 英雄对象
---@param skill table 被动技能
---@param effect table 效果配置
---@param context table 触发上下文
function BattlePassiveSkill.ProcessPassiveEffect(hero, skill, effect, context)
    if not effect or not effect.type then
        return
    end

    local effectType = effect.type

    if effectType == "buff" then
        -- 添加Buff效果
        Logger.Debug(string.format("[BattlePassiveSkill.ProcessPassiveEffect] 技能 [%s] 添加Buff效果", skill.name))
        BattleEvent.Publish("PASSIVE_ADD_BUFF", hero, effect.buffId, effect.target or "self", effect.duration, effect.stack)

    elseif effectType == "heal" then
        -- 治疗效果
        local healValue = effect.value or 0
        if effect.percent then
            healValue = (hero.maxHp or 0) * effect.percent / 100
        end
        Logger.Debug(string.format("[BattlePassiveSkill.ProcessPassiveEffect] 技能 [%s] 治疗效果 %d", skill.name, healValue))
        BattleEvent.Publish("PASSIVE_HEAL", hero, healValue, effect.target or "self")

    elseif effectType == "damage" then
        -- 伤害效果
        local damageValue = effect.value or 0
        if effect.percent then
            damageValue = (hero.maxHp or 0) * effect.percent / 100
        end
        Logger.Debug(string.format("[BattlePassiveSkill.ProcessPassiveEffect] 技能 [%s] 伤害效果 %d", skill.name, damageValue))
        BattleEvent.Publish("PASSIVE_DAMAGE", hero, damageValue, effect.target or "enemy", effect.damageType)

    elseif effectType == "attr_change" then
        -- 属性变更
        Logger.Debug(string.format("[BattlePassiveSkill.ProcessPassiveEffect] 技能 [%s] 属性变更 %s %+d",
            skill.name, tostring(effect.attr), effect.value or 0))
        BattleEvent.Publish("PASSIVE_ATTR_CHANGE", hero, effect.attr, effect.value or 0, effect.target or "self")

    elseif effectType == "energy" then
        -- 能量变化
        Logger.Debug(string.format("[BattlePassiveSkill.ProcessPassiveEffect] 技能 [%s] 能量变化 %+d",
            skill.name, effect.value or 0))
        BattleEvent.Publish("PASSIVE_ENERGY_CHANGE", hero, effect.value or 0, effect.target or "self")

    elseif effectType == "dispel" then
        -- 驱散效果
        Logger.Debug(string.format("[BattlePassiveSkill.ProcessPassiveEffect] 技能 [%s] 驱散效果", skill.name))
        BattleEvent.Publish("PASSIVE_DISPEL", hero, effect.targetType or "all", effect.target or "self")

    elseif effectType == "custom" then
        -- 自定义效果
        if effect.func and type(effect.func) == "function" then
            effect.func(hero, skill, effect, context)
        end
    end
end

--- 减少所有被动技能的冷却
---@param hero table 英雄对象
function BattlePassiveSkill.ReduceCooldowns(hero)
    if not hero or not hero.id then
        return
    end

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.curCooldown > 0 then
            skill.curCooldown = skill.curCooldown - 1
        end
    end
end

--- 通用触发函数
---@param triggerTime number 触发时机 (E_PASSIVE_SKILL_TRIGGER_TIME)
---@param hero table 英雄对象 (可选)
---@param context table 触发上下文 (可选)
function BattlePassiveSkill.Trigger(triggerTime, hero, context)
    if not triggerTime then
        return
    end

    -- 根据触发时机调用相应的处理函数
    if triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin then
        BattlePassiveSkill.RunSkillOnBattleBegin()
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin then
        if hero then
            BattlePassiveSkill.RunSkillOnHeroActionBegin(hero)
        end
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnEnd then
        if hero then
            BattlePassiveSkill.RunSkillOnHeroActionEnd(hero)
        end
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.RoundBegin then
        BattlePassiveSkill.RunSkillOnRoundBegin()
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.RoundEnd then
        BattlePassiveSkill.RunSkillOnRoundEnd()
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.HpChg then
        if hero and context and context.delta then
            BattlePassiveSkill.RunSkillOnHeroHpChange(hero, context.delta)
        end
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.ON_ATTACK or triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkStart then
        if hero and context and context.target then
            BattlePassiveSkill.RunSkillOnHeroAttack(hero, context.target)
        end
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.ON_DAMAGE or triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkFinish then
        if hero and context and context.target and context.damage then
            BattlePassiveSkill.RunSkillOnHeroDealDamage(hero, context.target, context.damage)
        end
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.ON_RECEIVE_DAMAGE or triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmg then
        if hero and context and context.attacker and context.damage then
            BattlePassiveSkill.RunSkillOnHeroReceiveDamage(hero, context.attacker, context.damage)
        end
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.ON_DEATH or triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.Died then
        if hero and context and context.killer then
            BattlePassiveSkill.RunSkillOnHeroDeath(hero, context.killer)
        end
    elseif triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.ON_KILL or triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill then
        if hero and context and context.victim then
            BattlePassiveSkill.RunSkillOnHeroKill(hero, context.victim)
        end
    end
end

--- 触发战斗开始时的被动技能
function BattlePassiveSkill.RunSkillOnBattleBegin()
    Logger.Debug("[BattlePassiveSkill.RunSkillOnBattleBegin] 触发战斗开始被动技能")

    for heroId, skillList in pairs(heroPassiveSkills) do
        for _, skill in ipairs(skillList) do
            -- 检查是否包含战斗开始时触发时机
            if skill.triggerTiming then
                for _, timing in ipairs(skill.triggerTiming) do
                    if timing == BattlePassiveSkill.E_TRIGGER_TIMING.BATTLE_BEGIN then
                        BattlePassiveSkill.CallPassiveSkill(skill.owner, skill, nil, nil, { timing = timing })
                        break
                    end
                end
            end
        end
    end
end

--- 触发战斗结束时的被动技能
function BattlePassiveSkill.RunSkillOnBattleEnd()
    Logger.Debug("[BattlePassiveSkill.RunSkillOnBattleEnd] 触发战斗结束被动技能")

    for heroId, skillList in pairs(heroPassiveSkills) do
        for _, skill in ipairs(skillList) do
            if skill.triggerTiming then
                for _, timing in ipairs(skill.triggerTiming) do
                    if timing == BattlePassiveSkill.E_TRIGGER_TIMING.BATTLE_END then
                        BattlePassiveSkill.CallPassiveSkill(skill.owner, skill, nil, nil, { timing = timing })
                        break
                    end
                end
            end
        end
    end
end

--- 触发回合开始时的被动技能
function BattlePassiveSkill.RunSkillOnRoundBegin()
    Logger.Debug("[BattlePassiveSkill.RunSkillOnRoundBegin] 触发回合开始被动技能")

    -- 先减少所有被动技能的冷却
    for heroId, skillList in pairs(heroPassiveSkills) do
        for _, skill in ipairs(skillList) do
            if skill.curCooldown > 0 then
                skill.curCooldown = skill.curCooldown - 1
            end
        end
    end

    -- 触发回合开始被动技能
    for heroId, skillList in pairs(heroPassiveSkills) do
        for _, skill in ipairs(skillList) do
            if skill.triggerTiming then
                for _, timing in ipairs(skill.triggerTiming) do
                    if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ROUND_BEGIN then
                        BattlePassiveSkill.CallPassiveSkill(skill.owner, skill, nil, nil, { timing = timing })
                        break
                    end
                end
            end
        end
    end
end

--- 触发回合结束时的被动技能
function BattlePassiveSkill.RunSkillOnRoundEnd()
    Logger.Debug("[BattlePassiveSkill.RunSkillOnRoundEnd] 触发回合结束被动技能")

    for heroId, skillList in pairs(heroPassiveSkills) do
        for _, skill in ipairs(skillList) do
            if skill.triggerTiming then
                for _, timing in ipairs(skill.triggerTiming) do
                    if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ROUND_END then
                        BattlePassiveSkill.CallPassiveSkill(skill.owner, skill, nil, nil, { timing = timing })
                        break
                    end
                end
            end
        end
    end
end

--- 触发英雄行动开始时的被动技能
---@param hero table 英雄对象
function BattlePassiveSkill.RunSkillOnHeroActionBegin(hero)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroActionBegin] 英雄 [%s] 行动开始触发被动技能", tostring(hero.name)))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ACTION_BEGIN then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil, { timing = timing, hero = hero })
                    break
                end
            end
        end
    end
end

--- 触发英雄行动结束时的被动技能
---@param hero table 英雄对象
function BattlePassiveSkill.RunSkillOnHeroActionEnd(hero)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroActionEnd] 英雄 [%s] 行动结束触发被动技能", tostring(hero.name)))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ACTION_END then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil, { timing = timing, hero = hero })
                    break
                end
            end
        end
    end
end

--- 触发英雄HP变化时的被动技能
---@param hero table 英雄对象
---@param delta number HP变化量 (正数为增加，负数为减少)
function BattlePassiveSkill.RunSkillOnHeroHpChange(hero, delta)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroHpChange] 英雄 [%s] HP变化 %+d 触发被动技能",
        tostring(hero.name), delta))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.HP_CHANGE then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, delta = delta, hpPercent = hero.hp / hero.maxHp * 100 })
                    break
                end
            end
        end
    end
end

--- 触发英雄MP变化时的被动技能
---@param hero table 英雄对象
---@param delta number MP变化量
function BattlePassiveSkill.RunSkillOnHeroMpChange(hero, delta)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroMpChange] 英雄 [%s] MP变化 %+d 触发被动技能",
        tostring(hero.name), delta))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.MP_CHANGE then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, delta = delta, mpPercent = hero.mp / hero.maxMp * 100 })
                    break
                end
            end
        end
    end
end

--- 触发英雄能量变化时的被动技能
---@param hero table 英雄对象
---@param delta number 能量变化量
function BattlePassiveSkill.RunSkillOnHeroEnergyChange(hero, delta)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroEnergyChange] 英雄 [%s] 能量变化 %+d 触发被动技能",
        tostring(hero.name), delta))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ENERGY_CHANGE then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, delta = delta })
                    break
                end
            end
        end
    end
end

--- 触发英雄攻击时的被动技能
---@param hero table 英雄对象
---@param target table 目标对象
function BattlePassiveSkill.RunSkillOnHeroAttack(hero, target)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroAttack] 英雄 [%s] 攻击触发被动技能", tostring(hero.name)))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ON_ATTACK then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, target = target })
                    break
                end
            end
        end
    end
end

--- 触发英雄受击时的被动技能
---@param hero table 英雄对象
---@param attacker table 攻击者
function BattlePassiveSkill.RunSkillOnHeroDefend(hero, attacker)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroDefend] 英雄 [%s] 受击触发被动技能", tostring(hero.name)))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ON_DEFEND then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, attacker = attacker })
                    break
                end
            end
        end
    end
end

--- 触发英雄造成伤害时的被动技能
---@param hero table 英雄对象
---@param target table 目标对象
---@param damage number 伤害值
function BattlePassiveSkill.RunSkillOnHeroDealDamage(hero, target, damage)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroDealDamage] 英雄 [%s] 造成伤害 %d 触发被动技能",
        tostring(hero.name), damage))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ON_DAMAGE then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, target = target, damage = damage })
                    break
                end
            end
        end
    end
end

--- 触发英雄受到伤害时的被动技能
---@param hero table 英雄对象
---@param attacker table 攻击者
---@param damage number 伤害值
function BattlePassiveSkill.RunSkillOnHeroReceiveDamage(hero, attacker, damage)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroReceiveDamage] 英雄 [%s] 受到伤害 %d 触发被动技能",
        tostring(hero.name), damage))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ON_RECEIVE_DAMAGE then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, attacker = attacker, damage = damage })
                    break
                end
            end
        end
    end
end

--- 触发英雄击杀时的被动技能
---@param hero table 英雄对象
---@param victim table 被击杀者
function BattlePassiveSkill.RunSkillOnHeroKill(hero, victim)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroKill] 英雄 [%s] 击杀触发被动技能", tostring(hero.name)))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ON_KILL then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, victim = victim })
                    break
                end
            end
        end
    end
end

--- 触发英雄死亡时的被动技能
---@param hero table 英雄对象
---@param killer table 击杀者
function BattlePassiveSkill.RunSkillOnHeroDeath(hero, killer)
    if not hero or not hero.id then
        return
    end

    Logger.Debug(string.format("[BattlePassiveSkill.RunSkillOnHeroDeath] 英雄 [%s] 死亡触发被动技能", tostring(hero.name)))

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return
    end

    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, timing in ipairs(skill.triggerTiming) do
                if timing == BattlePassiveSkill.E_TRIGGER_TIMING.ON_DEATH then
                    BattlePassiveSkill.CallPassiveSkill(hero, skill, nil, nil,
                        { timing = timing, hero = hero, killer = killer })
                    break
                end
            end
        end
    end
end

--- 获取英雄的所有被动技能
---@param hero table 英雄对象
---@return table 被动技能列表
function BattlePassiveSkill.GetHeroPassiveSkills(hero)
    if not hero or not hero.id then
        return {}
    end
    return heroPassiveSkills[hero.id] or {}
end

--- 获取英雄指定触发时机的被动技能
---@param hero table 英雄对象
---@param timing number 触发时机
---@return table 被动技能列表
function BattlePassiveSkill.GetPassiveSkillsByTiming(hero, timing)
    if not hero or not hero.id or not timing then
        return {}
    end

    local skillList = heroPassiveSkills[hero.id]
    if not skillList then
        return {}
    end

    local result = {}
    for _, skill in ipairs(skillList) do
        if skill.triggerTiming then
            for _, skillTiming in ipairs(skill.triggerTiming) do
                if skillTiming == timing then
                    table.insert(result, skill)
                    break
                end
            end
        end
    end

    return result
end

--- 清除英雄所有被动技能
---@param hero table 英雄对象
function BattlePassiveSkill.ClearHeroPassiveSkills(hero)
    if not hero or not hero.id then
        return
    end

    local skillList = heroPassiveSkills[hero.id]
    if skillList then
        for _, skill in ipairs(skillList) do
            BattleEvent.Publish("PASSIVE_SKILL_REMOVED", hero, skill)
        end
    end

    heroPassiveSkills[hero.id] = nil
    Logger.Debug(string.format("[BattlePassiveSkill.ClearHeroPassiveSkills] 清除英雄 [%s] 所有被动技能", tostring(hero.name)))
end

--- 重置所有被动技能的触发计数
function BattlePassiveSkill.ResetAllTriggerCounts()
    for heroId, skillList in pairs(heroPassiveSkills) do
        for _, skill in ipairs(skillList) do
            skill.curTriggerCount = 0
            skill.curCooldown = 0
        end
    end
    Logger.Debug("[BattlePassiveSkill.ResetAllTriggerCounts] 重置所有被动技能触发计数")
end

--- 获取被动技能统计信息 (用于调试)
---@return table 统计信息
function BattlePassiveSkill.GetStats()
    local stats = {
        heroCount = 0,
        totalSkillCount = 0,
        skillsByTiming = {},
    }

    for heroId, skillList in pairs(heroPassiveSkills) do
        stats.heroCount = stats.heroCount + 1
        stats.totalSkillCount = stats.totalSkillCount + #skillList

        for _, skill in ipairs(skillList) do
            if skill.triggerTiming then
                for _, timing in ipairs(skill.triggerTiming) do
                    stats.skillsByTiming[timing] = (stats.skillsByTiming[timing] or 0) + 1
                end
            end
        end
    end

    return stats
end

return BattlePassiveSkill
