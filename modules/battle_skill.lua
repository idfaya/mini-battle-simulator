---
--- Battle Skill Module
--- 管理九流派技能、冷却和技能释放
---

-- 确保枚举已加载
if not E_CAST_TARGET then
    require("core.battle_enum")
end

local Logger = require("utils.logger")
local SkillConfig = require("config.skill_config")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")
local ClassRoleConfig = require("config.class_role_config")

---@class BattleSkill
local BattleSkill = {}

-- 技能配置缓存
BattleSkill.skillConfigCache = {}

-- 技能Lua脚本缓存
BattleSkill.skillLuaCache = {}

-- 技能实例计数器（用于生成唯一技能实例ID）
BattleSkill.skillInstanceIdCounter = 0

local InferTargetsSelections

local SPECIAL_EFFECT_TAGS = {
    [80004003] = "battle_intent_buff",
    [80004004] = "battle_intent_buff",
    [80005004] = "poison_burst",
    [80006001] = "holy_light",
    [80006003] = "group_heal",
    [80006004] = "full_heal_cleanse",
}

-- 是否已初始化
local isInitialized = false

--- 初始化技能模块
function BattleSkill.InitModule()
    if isInitialized then
        return
    end
    SkillConfig.Init()
    isInitialized = true
    Logger.Log("[BattleSkill] 模块初始化完成 (九流派单轨)")
end

--- 生成唯一技能实例ID
---@return number 技能实例ID
local function GenerateSkillInstanceId()
    BattleSkill.skillInstanceIdCounter = BattleSkill.skillInstanceIdCounter + 1
    return BattleSkill.skillInstanceIdCounter
end

local function InferSpecialEffectTag(skillId, skillCfg, mergedConfig)
    if mergedConfig and mergedConfig.specialEffectTag then
        return mergedConfig.specialEffectTag
    end
    return SPECIAL_EFFECT_TAGS[skillId]
        or (skillCfg and skillCfg.SpecialEffectTag)
        or nil
end

-- ---------------------------------------------------------------------------
-- 5e-style unified dice helpers
-- ---------------------------------------------------------------------------

local function IsSpellClass(hero)
    local classId = tonumber(hero and (hero.class or hero.Class)) or 0
    return not ClassRoleConfig.IsMelee(classId)
end

function BattleSkill.GetPhysicalDamageDice(hero, skill, damageKind)
    local sid = skill and skill.skillId or 0
    local stype = skill and skill.skillType or E_SKILL_TYPE_NORMAL
    if stype == E_SKILL_TYPE_ULTIMATE then
        return "2d8+4"
    end
    if sid == 80003003 then
        return "1d6+3"
    end
    return "1d8+3"
end

function BattleSkill.GetSpellDamageDice(hero, skill, isMultiTarget, damageKind)
    local stype = skill and skill.skillType or E_SKILL_TYPE_NORMAL
    if stype == E_SKILL_TYPE_ULTIMATE then
        if isMultiTarget then
            return "4d6"
        end
        return "4d8"
    end
    if isMultiTarget then
        return "3d6"
    end
    return "2d8"
end

function BattleSkill.ApplyUnifiedDamageScale(attacker, defender, rawDamage, damageKind)
    local value = math.max(0, math.floor(tonumber(rawDamage) or 0))
    if value <= 0 then
        return 0
    end
    local kind = damageKind or "direct"
    local resist = defender and defender.resistances
    local vuln = defender and defender.vulnerabilities
    local immune = defender and defender.immunities
    if type(immune) == "table" and immune[kind] then
        return 0
    end
    if type(resist) == "table" and resist[kind] then
        value = math.floor(value * 0.5)
    end
    if type(vuln) == "table" and vuln[kind] then
        value = value * 2
    end
    return math.max(0, value)
end

-- Called after target takes damage. Used for 5e-style concentration/chant interruption.
function BattleSkill.OnDamagedInterrupt(target, damage)
    if not target or (tonumber(damage) or 0) <= 0 then
        return
    end
    local BattleFormula = require("core.battle_formula")
    if target.__pendingCast then
        local r = BattleFormula.RollConcentration(target, damage, { ignoreNatRules = target.__ignoreNatRules == true })
        if not r.success then
            Logger.Log(string.format("[CHANT] %s 吟唱被伤害打断 (DC=%d, total=%d)", target.name or "Unknown", r.dc or 0, r.total or 0))
            target.__pendingCast = nil
        end
    end
    if target.__concentrationSkillId then
        local r = BattleFormula.RollConcentration(target, damage, { ignoreNatRules = target.__ignoreNatRules == true })
        if not r.success then
            Logger.Log(string.format("[CONC] %s 专注被打断 (skill=%s, DC=%d, total=%d)", target.name or "Unknown", tostring(target.__concentrationSkillId), r.dc or 0, r.total or 0))
            target.__concentrationSkillId = nil
        end
    end
end

--- 初始化英雄技能
---@param hero table 英雄对象
---@param skillsConfig table 技能配置列表
function BattleSkill.Init(hero, skillsConfig)
    if not hero then
        Logger.LogError("[BattleSkill.Init] hero is nil")
        return
    end

    hero.skills = hero.skills or {}
    hero.skillData = hero.skillData or {}
    hero.skillData.skillInstances = {}
    hero.skillData.coolDowns = {}

    -- 如果 skillsConfig 为空，尝试从 hero.skills 构建
    if not skillsConfig or #skillsConfig == 0 then
        Logger.LogWarning("[BattleSkill.Init] skillsConfig is empty for hero: " .. tostring(hero.name))
        
        -- 从 hero.skills 构建 skillsConfig
        if hero.skills and #hero.skills > 0 then
            skillsConfig = {}
            for _, skillData in ipairs(hero.skills) do
                local skillId
                if type(skillData) == "table" then
                    skillId = skillData.skillId
                else
                    skillId = skillData
                end
                
                if skillId then
                    table.insert(skillsConfig, {
                        skillId = skillId,
                        skillType = E_SKILL_TYPE_NORMAL,
                        name = "Skill_" .. tostring(skillId),
                        skillCost = 0
                    })
                end
            end
            Logger.Log(string.format("[BattleSkill.Init] 从 hero.skills 构建了 %d 个技能配置", #skillsConfig))
        else
            -- 没有技能时报错
            local errorMsg = string.format("[BattleSkill.Init] 错误：英雄 %s 没有配置任何技能！请检查英雄数据配置。", tostring(hero.name))
            Logger.LogError(errorMsg)
            error(errorMsg)
        end
    end

    Logger.Log(string.format("[BattleSkill.Init] %s 接收到 %d 个技能配置", tostring(hero.name), #skillsConfig))

    for i, skillConfig in ipairs(skillsConfig) do
        local skillId = skillConfig.skillId or skillConfig.id
        Logger.Log(string.format("[BattleSkill.Init] 处理技能配置 [%d]: skillId=%s, name=%s, type=%s", 
            i, tostring(skillId), tostring(skillConfig.name), tostring(skillConfig.skillType)))
        if skillId then
            local skill = BattleSkill.CreateSkillInstance(skillId, skillConfig)
            if skill then
                table.insert(hero.skills, skill)
                hero.skillData.skillInstances[skillId] = skill
                hero.skillData.coolDowns[skillId] = 0
                Logger.Log(string.format("[BattleSkill.Init] 成功创建技能实例: %s (type=%s)", 
                    tostring(skill.name), tostring(skill.skillType)))

                -- 被动技能注册到触发器系统
                if skill.skillType == E_SKILL_TYPE_PASSIVE or skill.isPassiveActive then
                    local BattlePassiveSkill = require("modules.battle_passive_skill")
                    local skillCfg = skill.skillConfig or SkillConfig.GetSkillConfig(skillId)
                    local passiveSkillData = {
                        skillId = skillId,
                        classId = skillCfg and skillCfg.ClassID or skillId,
                        isPassiveActive = true,
                        name = skill.name,
                    }
                    BattlePassiveSkill.AddPassiveSkill2TriggerTime(hero, passiveSkillData)
                    Logger.Log(string.format("[BattleSkill.Init] 注册被动技能: %s (classId=%s)", 
                        skill.name, tostring(passiveSkillData.classId)))
                end
            else
                Logger.LogWarning(string.format("[BattleSkill.Init] 技能 %s 创建失败，跳过", tostring(skillId)))
            end
        end
    end

    Logger.Log("[BattleSkill.Init] Initialized " .. #hero.skills .. " skills for hero: " .. tostring(hero.name))
end

--- 创建技能实例
---@param skillId number 技能ID
---@param skillConfig table 技能配置
---@return table 技能实例
function BattleSkill.CreateSkillInstance(skillId, skillConfig)
    -- 确保模块已初始化
    BattleSkill.InitModule()
    
    local configModule = SkillConfig
    
    -- 从配置模块获取配置
    local skillType = configModule.GetSkillType(skillId)
    local skillParam = configModule.GetSkillParam(skillId)
    local skillBuffs = configModule.GetSkillBuffs(skillId)
    local skillCooldown = configModule.GetSkillCooldown(skillId)
    local skillCost = configModule.GetSkillCost(skillId)
    local luaPath = configModule.GetSkillLuaPath(skillId)
    
    -- 合并配置
    local config = BattleSkill.GetSkillConfig(skillId)
    local mergedConfig = BattleSkill.MergeSkillConfig(config, skillConfig)
    
    -- 确定技能类型
    local finalSkillType = mergedConfig.skillType or E_SKILL_TYPE_NORMAL
    if skillType then
        -- Type 1=普通攻击, 2=主动技能, 3=大招, 4=被动
        if skillType == 1 then
            finalSkillType = E_SKILL_TYPE_NORMAL
        elseif skillType == 2 then
            finalSkillType = E_SKILL_TYPE_ACTIVE
        elseif skillType == 3 then
            finalSkillType = E_SKILL_TYPE_ULTIMATE
        elseif skillType == 4 then
            finalSkillType = E_SKILL_TYPE_PASSIVE
        end
    end
    
    local isPassiveActive = false
    if finalSkillType == E_SKILL_TYPE_PASSIVE then
        isPassiveActive = true
    end

    -- 确定技能名称：
    -- 1. 优先使用九流派配置 Name
    -- 2. 否则使用传入的 name
    -- 3. 最后使用默认格式
    local skillName = nil
    local skillCfg = configModule.GetSkillConfig(skillId)
    if skillCfg and skillCfg.Name then
        skillName = skillCfg.Name
    end
    if not skillName then
        skillName = mergedConfig.name
    end
    if not skillName then
        skillName = "Skill_" .. skillId
    end

    local skill = {
        -- 基础信息
        instanceId = GenerateSkillInstanceId(),
        skillId = skillId,
        skillType = finalSkillType,
        level = mergedConfig.level or 1,
        name = skillName,

        -- 冷却相关
        coolDown = 0,
        maxCoolDown = skillCooldown or mergedConfig.coolDown or mergedConfig.cd or 0,

        -- 配置数据
        config = mergedConfig,
        
        -- 从 res_skill.json 加载的数据
        skillParam = skillParam,
        skillBuffs = skillBuffs,
        -- 优先使用传入的 skillConfig.skillCost，否则使用配置表中的值
        skillCost = mergedConfig.skillCost or skillCost or 0,

        -- 技能目标配置
        castTarget = mergedConfig.castTarget or E_CAST_TARGET.Enemy,
        targetsSelections = mergedConfig.targetsSelections or TargetsSelections_Default,

        -- 技能效果配置
        damageData = mergedConfig.damageData,
        healData = mergedConfig.healData,
        buffData = mergedConfig.buffData,
        energyData = mergedConfig.energyData,

        -- 技能条件
        conditions = mergedConfig.conditions or {},

        -- Lua脚本路径
        luaFile = luaPath or mergedConfig.luaFile or mergedConfig.LuaFile or "",
        luaFuncName = mergedConfig.luaFuncName or "",

        -- 额外数据
        extraData = mergedConfig.extraData or {},
        
        -- 当前技能配置附带数据
        isConfigSkill = true,
        isPassiveActive = isPassiveActive,
        skillConfig = configModule.GetSkillConfig(skillId),
    }

    if skill.skillConfig then
        if (not skill.maxCoolDown or skill.maxCoolDown <= 0) and (skill.skillConfig.CoolDownR or 0) > 0 then
            skill.maxCoolDown = skill.skillConfig.CoolDownR
        end
        if not skill.damageData and skill.skillConfig.SkillParam and skill.skillConfig.SkillParam[1] then
            skill.damageData = {
                damageRate = skill.skillConfig.SkillParam[1] / 100
            }
        end
    end

    skill.targetsSelections = InferTargetsSelections(skill.skillConfig, mergedConfig, finalSkillType)
    skill.castTarget = skill.targetsSelections.castTarget or skill.castTarget
    skill.specialEffectTag = InferSpecialEffectTag(skillId, skill.skillConfig, mergedConfig)
    
    Logger.Log(string.format("[BattleSkill.CreateSkillInstance] 技能 %d: skillConfig=%s",
        skillId, tostring(skill.skillConfig)))
    if skill.skillConfig then
        Logger.Log(string.format("[BattleSkill.CreateSkillInstance]   ClassID=%s, Name=%s",
            tostring(skill.skillConfig.ClassID), tostring(skill.skillConfig.Name)))
    end

    Logger.Log(string.format("[BattleSkill.CreateSkillInstance] 技能 %d (类型:%d) Lua路径: %s",
        skillId, skillType or 0, skill.luaFile or "nil"))

    return skill
end

--- 合并技能配置
---@param baseConfig table 基础配置
---@param overrideConfig table 覆盖配置
---@return table 合并后的配置
function BattleSkill.MergeSkillConfig(baseConfig, overrideConfig)
    baseConfig = baseConfig or {}
    overrideConfig = overrideConfig or {}

    local merged = {}
    for k, v in pairs(baseConfig) do
        merged[k] = v
    end
    for k, v in pairs(overrideConfig) do
        merged[k] = v
    end

    return merged
end

--- 获取技能当前冷却时间
---@param hero table 英雄对象
---@param skillId number 技能ID
---@return number 当前冷却时间
function BattleSkill.GetSkillCurCoolDown(hero, skillId)
    if not hero or not hero.skillData or not hero.skillData.coolDowns then
        return 0
    end
    return hero.skillData.coolDowns[skillId] or 0
end

--- 设置技能冷却时间
---@param hero table 英雄对象
---@param skillId number 技能ID
---@param cd number 冷却时间
function BattleSkill.SetSkillCurCoolDown(hero, skillId, cd)
    if not hero or not hero.skillData then
        Logger.LogError("[BattleSkill.SetSkillCurCoolDown] hero or hero.skillData is nil")
        return
    end

    hero.skillData.coolDowns = hero.skillData.coolDowns or {}
    hero.skillData.coolDowns[skillId] = math.max(0, cd)

    local skill = hero.skillData.skillInstances and hero.skillData.skillInstances[skillId]
    if skill then
        skill.coolDown = hero.skillData.coolDowns[skillId]
    end
end

--- 减少所有技能冷却时间
---@param hero table 英雄对象
---@param amount number 减少的冷却时间
function BattleSkill.ReduceCoolDown(hero, amount)
    if not hero or not hero.skillData or not hero.skillData.coolDowns then
        return
    end

    amount = amount or 1
    for skillId, cd in pairs(hero.skillData.coolDowns) do
        if cd > 0 then
            local newCd = math.max(0, cd - amount)
            hero.skillData.coolDowns[skillId] = newCd

            local skill = hero.skillData.skillInstances and hero.skillData.skillInstances[skillId]
            if skill then
                skill.coolDown = newCd
            end
        end
    end
end

local function BuildFallbackTimeline(hero, targets, skill)
    return {
        { frame = 0, op = "cast", effect = "cast_basic" },
        {
            frame = 10,
            op = "attack",
            execute = function()
                local dmg = BattleSkill.ExecuteDefaultAttackWithPassive(hero, targets, skill) or 0
                return { damage = dmg }
            end
        }
    }
end

local function FinalizeSkillCast(hero, skill, totalDamage, onComplete)
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local BattleEnergy = require("modules.battle_energy")

    BattlePassiveSkill.RunSkillOnNormalAtkFinish(hero, { damageDealt = totalDamage or 0 })

    local energyStats = hero and hero.__energyCastStats or nil
    if energyStats and (
        (energyStats.successfulHits or 0) > 0
        or (energyStats.killCount or 0) > 0
        or energyStats.didCrit
    ) then
        BattleEnergy.OnSkillHit(hero, skill, energyStats)
    elseif (totalDamage or 0) > 0 then
        BattleEnergy.OnSkillHit(hero, skill, { successfulHits = 1 })
    end

    if hero then
        hero.__energyCastStats = nil
    end

    BattleSkill.SetSkillCurCoolDown(hero, skill.skillId, skill.maxCoolDown)

    if skill.skillType == E_SKILL_TYPE_ULTIMATE and skill.skillCost and skill.skillCost > 0 then
        BattleEnergy.ConsumeEnergy(hero, skill.skillCost)
        Logger.Log(string.format("[CastSkillInSeq] %s 释放大招消耗能量: %d, 剩余能量: %d",
            hero.name or "Unknown", skill.skillCost, hero.curEnergy))
    end

    Logger.Log("[BattleSkill.CastSkillInSeq] Skill cast success: " .. tostring(skill.skillId) .. ", hero: " .. tostring(hero.name))
    if type(onComplete) == "function" then
        onComplete(true, {
            totalDamage = totalDamage or 0,
            succeeded = true,
        })
    end
end

local function PrepareSkillCast(hero, target, skillId)
    if not hero then
        Logger.LogError("[BattleSkill.CastSkillInSeq] hero is nil")
        return nil
    end

    local skill = hero.skillData and hero.skillData.skillInstances and hero.skillData.skillInstances[skillId]
    if not skill then
        Logger.LogError("[BattleSkill.CastSkillInSeq] Skill not found: " .. tostring(skillId))
        return nil
    end

    if not BattleSkill.CheckSkillCondition(hero, skill) then
        Logger.Log("[BattleSkill.CastSkillInSeq] Skill condition check failed: " .. tostring(skillId))
        return nil
    end

    local curCd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
    if curCd > 0 then
        Logger.Log("[BattleSkill.CastSkillInSeq] Skill in cooldown: " .. tostring(skillId) .. ", cd: " .. curCd)
        return nil
    end

    local targets = target and { target } or BattleSkill.SelectTarget(hero, skill)
    if not targets or #targets == 0 then
        Logger.LogWarning("[BattleSkill.CastSkillInSeq] No valid targets for skill: " .. tostring(skillId))
        return nil
    end

    hero.__energyCastStats = {
        successfulHits = 0,
        killCount = 0,
        didCrit = false,
    }

    return skill, targets
end

--- 释放普通攻击（小技能）
---@param hero table 攻击者
---@param target table 目标
---@return boolean 是否释放成功
function BattleSkill.CastSmallSkill(hero, target)
    if not hero or not hero.skills then
        Logger.LogError("[BattleSkill.CastSmallSkill] hero or hero.skills is nil")
        return false
    end

    -- 查找普通攻击技能
    local normalSkill = nil
    for _, skill in ipairs(hero.skills) do
        if skill.skillType == E_SKILL_TYPE_NORMAL then
            normalSkill = skill
            break
        end
    end

    if not normalSkill then
        Logger.LogWarning("[BattleSkill.CastSmallSkill] No normal skill found for hero: " .. tostring(hero.name))
        return false
    end

    return BattleSkill.CastSkillInSeq(hero, target, normalSkill.skillId)
end

function BattleSkill.StartSkillCastInSeq(hero, target, skillId, onComplete, opts)
    opts = opts or {}
    if hero and hero.__pendingCast and not opts.ignoreChant then
        if type(onComplete) == "function" then
            onComplete(false, { totalDamage = 0, succeeded = false, reason = "pending_cast" })
        end
        return false
    end

    local skill, targets = PrepareSkillCast(hero, target, skillId)
    if not skill then
        if type(onComplete) == "function" then
            onComplete(false, { totalDamage = 0, succeeded = false })
        end
        return false
    end

    -- Chanting: delay execution and create an interruptible window.
    local Skill5eMeta = require("config.skill_5e_meta")
    local meta = Skill5eMeta.Get(skillId)
    if not opts.ignoreChant and meta and tonumber(meta.chantTurns) and tonumber(meta.chantTurns) > 0 then
        -- Do not start timeline now. The battle loop will count down and release later.
        hero.__pendingCast = {
            skillId = skillId,
            skillName = skill and skill.name,
            targetId = targets and targets[1] and (targets[1].instanceId or targets[1].id) or nil,
            remainTurns = tonumber(meta.chantTurns),
        }
        Logger.Log(string.format("[CHANT] %s 开始吟唱 %s (%d)",
            hero.name or "Unknown",
            tostring(skill and skill.name or skillId),
            hero.__pendingCast.remainTurns))
        if type(onComplete) == "function" then
            onComplete(true, { totalDamage = 0, succeeded = true, chanting = true })
        end
        return true
    end

    BattleSkill.TriggerSkillCastEvent(hero, skill, targets)

    local BattlePassiveSkill = require("modules.battle_passive_skill")
    BattlePassiveSkill.RunSkillOnNormalAtkStart(hero, { target = targets[1] })

    local skillLua = BattleSkill.LoadSkillLua(skillId)
    local timeline = nil
    if skillLua and skillLua.BuildTimeline then
        local ok, builtTimeline = pcall(skillLua.BuildTimeline, hero, targets, skill)
        if ok and type(builtTimeline) == "table" and #builtTimeline > 0 then
            timeline = builtTimeline
        else
            Logger.LogWarning(string.format("[BattleSkill.CastSkillInSeq] BuildTimeline failed or empty: %s", tostring(skillId)))
        end
    end

    if not timeline or #timeline == 0 then
        Logger.Log("[BattleSkill.CastSkillInSeq] 执行默认普通攻击 (timeline)")
        timeline = BuildFallbackTimeline(hero, targets, skill)
    end

    local SkillTimeline = require("core.skill_timeline")
    local started = SkillTimeline.Start(hero, targets, skill, timeline, function(succeeded, result)
        if not succeeded then
            if type(onComplete) == "function" then
                onComplete(false, result or { totalDamage = 0, succeeded = false })
            end
            return
        end

        local totalDamage = (result and result.totalDamage or 0)
        FinalizeSkillCast(hero, skill, totalDamage, onComplete)
    end)

    if not started then
        if type(onComplete) == "function" then
            onComplete(false, { totalDamage = 0, succeeded = false })
        end
        return false
    end

    return true
end

--- 释放指定技能
---@param hero table 攻击者
---@param target table 目标
---@param skillId number 技能ID
---@return boolean 是否释放成功
function BattleSkill.CastSkillInSeq(hero, target, skillId, opts)
    local completed = nil
    local started = BattleSkill.StartSkillCastInSeq(hero, target, skillId, function(succeeded, result)
        completed = {
            succeeded = succeeded,
            result = result,
        }
    end, opts)
    if not started then
        return false
    end

    local SkillTimeline = require("core.skill_timeline")
    while SkillTimeline.IsRunning() do
        SkillTimeline.Update()
    end

    return completed and completed.succeeded or false
end

--- 执行默认普通攻击（带被动技能触发）
---@param hero table 攻击者
---@param targets table 目标列表
---@param skill table 技能对象
---@return number 总伤害值（用于吸血等被动技能）
function BattleSkill.ExecuteDefaultAttackWithPassive(hero, targets, skill)
    if not hero or not targets or #targets == 0 then
        return 0
    end

    local BattleAttribute = require("modules.battle_attribute")
    local BattlePassiveSkill = require("modules.battle_passive_skill")

    -- 获取技能的伤害倍率（优先使用技能对象中的配置）
    local damageRate = 10000  -- 默认100%（万分比）
    if skill and skill.damageData and skill.damageData.damageRate then
        -- 使用技能对象中的damageData（百分比转万分比）
        damageRate = skill.damageData.damageRate * 100
        Logger.Log(string.format("[ExecuteDefaultAttackWithPassive] 使用技能配置伤害倍率: %d%%", skill.damageData.damageRate))
    end
    
    -- 检查是否是治疗技能
    local isHealSkill = skill and skill.healData and skill.healData.healRate
    local healRate = isHealSkill and skill.healData.healRate * 100 or 0

    local totalDamage = 0
    local energyStats = hero.__energyCastStats

    -- 对每个目标执行效果
    for _, target in ipairs(targets) do
        if target and not target.isDead then
            if isHealSkill then
                -- 执行治疗
                local healAmount = BattleSkill.CalculateHeal(hero, target, healRate)
                
                -- 使用 ApplyHeal 应用治疗（会触发事件）
                local BattleDmgHeal = require("modules.battle_dmg_heal")
                BattleDmgHeal.ApplyHeal(target, healAmount, hero)
                if healAmount > 0 and energyStats then
                    energyStats.successfulHits = (energyStats.successfulHits or 0) + 1
                end
                
                Logger.Log(string.format("[ExecuteDefaultAttackWithPassive] %s 对 %s 治疗 %d 点生命",
                    hero.name or "Unknown",
                    target.name or "Unknown",
                    healAmount))
            else
                -- 5e-style default attack: hit check vs AC + dice damage (scaled),
                -- keeping legacy damageRate as a multiplier so existing balance knobs still work.
                local BattleFormula = require("core.battle_formula")
                local Dice = require("core.dice")
                local Skill5eMeta = require("config.skill_5e_meta")
                local diceScale = (BattleFormula.GetDiceScale and BattleFormula.GetDiceScale()) or 1

                local damage = 0
                local damageResult = {}
                local meta = Skill5eMeta.Get(skill and skill.skillId)

                if meta and meta.kind == "spell" then
                    local dc = tonumber(hero and hero.spellDC) or 10
                    local saveType = meta.saveType or "ref"
                    local saveBonus = 0
                    if saveType == "fort" then
                        saveBonus = tonumber(target.saveFort) or 0
                    elseif saveType == "will" then
                        saveBonus = tonumber(target.saveWill) or 0
                    else
                        saveBonus = tonumber(target.saveRef) or 0
                    end
                    local saveResult = BattleFormula.RollSave(target, dc, saveBonus, {
                        ignoreNatRules = (target.__ignoreNatRules == true) or (hero and hero.__ignoreNatRules == true),
                    })
                    damageResult.save = saveResult
                    local diceExpr = (meta and meta.damageDice) or (BattleSkill.GetSpellDamageDice and BattleSkill.GetSpellDamageDice(hero, skill, meta and meta.isAOE, "direct")) or "1d6+3"
                    local full = Dice.Roll(diceExpr, { crit = false }) * diceScale
                    local successMode = meta.onSaveSuccess or "half"
                    if saveResult.success then
                        damage = (successMode == "half") and math.floor(full / 2) or 0
                    else
                        damage = full
                    end
                else
                    local hitResult = BattleFormula.RollHit(hero, target, {
                        mode = "normal",
                        ignoreNatRules = (target.__ignoreNatRules == true) or (hero and hero.__ignoreNatRules == true),
                    })
                    damageResult.hit = hitResult
                    if hitResult.hit then
                        local diceExpr = (meta and meta.damageDice) or (BattleSkill.GetPhysicalDamageDice and BattleSkill.GetPhysicalDamageDice(hero, skill, "direct")) or "1d6+2"
                        local rolled = Dice.Roll(diceExpr, { crit = hitResult.crit == true }) * diceScale
                        damage = rolled
                        damageResult.isCrit = hitResult.crit == true
                    else
                        damage = 0
                        damageResult.isDodged = true
                    end
                end

                if damageRate and damageRate > 0 then
                    damage = math.floor((tonumber(damage) or 0) * damageRate / 10000)
                end
                local damageContext = {
                    attacker = hero,
                    target = target,
                    damage = damage,
                }
                
                BattlePassiveSkill.RunSkillOnDefBeforeDmg(target, damageContext)
                damage = math.max(0, math.floor(damageContext.damage or damage))
                totalDamage = totalDamage + damage
                
                -- 使用 ApplyDamage 应用伤害（会触发事件）
                local BattleDmgHeal = require("modules.battle_dmg_heal")
                if damage > 0 then
                    BattleDmgHeal.ApplyDamage(target, damage, hero, {
                        isCrit = damageResult and damageResult.isCrit or false,
                        isDodged = damageResult and damageResult.isDodged or false,
                        isBlocked = damageResult and damageResult.isBlock or false,
                        skillId = skill and skill.skillId or nil,
                        skillName = skill and skill.name or nil,
                        damageKind = "direct",
                    })
                else
                    -- Log miss/save for readability (design goal: readable outcomes).
                    if damageResult and damageResult.hit and damageResult.hit.hit == false then
                        Logger.Log(string.format("[HIT] %s 对 %s 未命中 (roll=%d total=%d vs AC=%d)",
                            hero.name or "Unknown",
                            target.name or "Unknown",
                            damageResult.hit.roll or 0,
                            damageResult.hit.total or 0,
                            damageResult.hit.targetAC or 0))
                    elseif damageResult and damageResult.save then
                        Logger.Log(string.format("[SAVE] %s 对 %s 豁免%s (roll=%d total=%d vs DC=%d)",
                            target.name or "Unknown",
                            hero.name or "Unknown",
                            (damageResult.save.success and "成功" or "失败"),
                            damageResult.save.roll or 0,
                            damageResult.save.total or 0,
                            damageResult.save.dc or 0))
                    end
                end

                Logger.Log(string.format("[ExecuteDefaultAttackWithPassive] %s 对 %s 造成 %d 点伤害",
                    hero.name or "Unknown",
                    target.name or "Unknown",
                    damage))
                
                -- 触发目标受击后被动技能 (DefAfterDmg)
                BattlePassiveSkill.RunSkillOnDefAfterDmg(target, {attacker = hero, damage = damage})
                
                -- 触发伤害相关Buff
                BattleSkill.TriggerDamageBuffs(hero, target, damage)
                
                -- 检查是否击杀
                if target.isDead or target.hp <= 0 then
                    -- 触发击杀被动技能 (DmgMakeKill)
                    BattlePassiveSkill.RunSkillOnDmgMakeKill(hero, {target = target})
                end
            end
        end
    end
    
    -- 触发技能附加Buff
    if spellConfig and spellConfig.launchBuff and spellConfig.launchBuff.AssociateBuff then
        local buffId = spellConfig.launchBuff.AssociateBuff
        if buffId and buffId > 0 then
            for _, target in ipairs(targets) do
                BattleSkill.ApplyBuffFromSkill(hero, target, buffId, skill)
            end
        end
    end

    return totalDamage
end

--- 执行默认普通攻击（向后兼容）
---@param hero table 攻击者
---@param targets table 目标列表
---@param skill table 技能对象
function BattleSkill.ExecuteDefaultAttack(hero, targets, skill)
    BattleSkill.ExecuteDefaultAttackWithPassive(hero, targets, skill)
end

--- 计算伤害
---@param attacker table 攻击者
---@param defender table 防御者
---@param spellConfig table 技能配置
---@return number 伤害值
function BattleSkill.CalculateDamage(attacker, defender, spellConfig)
    local BattleAttribute = require("modules.battle_attribute")
    local BattleBuff = require("modules.battle_buff")
    local BattleFormula = require("core.battle_formula")
    
    -- 确保 BattleFormula 已初始化
    if not BattleFormula.GetConfig() then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
    
    -- 从Spell配置读取伤害倍率
    local damageRate = 10000  -- 默认100%（万分比）
    if spellConfig and spellConfig.Trigger and spellConfig.Trigger.damageData then
        damageRate = spellConfig.Trigger.damageData.damageRate or 10000
    end
    
    -- 获取配置
    local config = BattleFormula.GetConfig()
    
    -- 构建 BattleFormula 需要的属性格式
    local attackerData = {
        attrs = {
            [config.attrType.ATK] = BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.ATK) or attacker.atk or 0,
            [config.attrType.CRIT] = (BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.CRIT_RATE) or attacker.critRate or 0)
                + (attacker.__timelineCritRateBonus or 0),
        },
        damageBonus = attacker.damageIncrease or 0,
    }
    local attackerBuffPct = (BattleBuff.GetBuffStackNumBySubType(attacker, 840001) * 500)
    if BattleBuff.GetBuffBySubType(attacker, 840003) then
        attackerBuffPct = attackerBuffPct + 5000
    elseif BattleBuff.GetBuffBySubType(attacker, 840002) then
        attackerBuffPct = attackerBuffPct + 2000
    end
    attackerData.attrs[config.attrType.ATK] = math.floor(attackerData.attrs[config.attrType.ATK] * (1 + attackerBuffPct / 10000))
    
    local defenderData = {
        attrs = {
            [config.attrType.DEF] = BattleAttribute.GetAttribute(defender, BattleAttribute.ATTR_ID.DEF) or defender.def or 0,
            [config.attrType.BLOCK] = defender.blockRate or 0,
        },
        damageReduction = defender.damageReduce or 0,
    }
    local defenderBuffPct = (BattleBuff.GetBuffStackNumBySubType(defender, 840001) * 500)
    if BattleBuff.GetBuffBySubType(defender, 840003) then
        defenderBuffPct = defenderBuffPct + 5000
    end
    defenderData.attrs[config.attrType.DEF] = math.floor(defenderData.attrs[config.attrType.DEF] * (1 + defenderBuffPct / 10000))
    
    -- 使用 BattleFormula 计算伤害
    local damageResult = BattleFormula.CalcDamage(
        attackerData,
        defenderData,
        damageRate,
        E_ATTACK_TYPE.Physical,  -- 默认为物理伤害
        nil  -- 自动判定暴击
    )
    
    if damageResult.isCrit then
        Logger.Log(string.format("[CalculateDamage] 暴击! 伤害: %d", damageResult.damage))
    elseif damageResult.isBlock then
        Logger.Log(string.format("[CalculateDamage] 格挡! 伤害: %d", damageResult.damage))
    end
    
    return damageResult.damage, damageResult
end

--- 使用指定倍率计算伤害
---@param attacker table 攻击者
---@param defender table 防御者
---@param damageRate number 伤害倍率（万分比）
---@return number 伤害值
function BattleSkill.CalculateDamageWithRate(attacker, defender, damageRate)
    local BattleAttribute = require("modules.battle_attribute")
    local BattleBuff = require("modules.battle_buff")
    local BattleFormula = require("core.battle_formula")
    
    -- 确保 BattleFormula 已初始化
    if not BattleFormula.GetConfig() then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
    
    -- 获取配置
    local config = BattleFormula.GetConfig()
    
    -- 构建 BattleFormula 需要的属性格式
    local attackerData = {
        attrs = {
            [config.attrType.ATK] = BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.ATK) or attacker.atk or 0,
            [config.attrType.CRIT] = (BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.CRIT_RATE) or attacker.critRate or 0)
                + (attacker.__timelineCritRateBonus or 0),
        },
        damageBonus = attacker.damageIncrease or 0,
    }
    local attackerWarSpirit = BattleBuff.GetBuffStackNumBySubType(attacker, 840001)
    local attackerAuraAtk = 0
    if BattleBuff.GetBuffBySubType(attacker, 840003) then
        attackerAuraAtk = 5000
    elseif BattleBuff.GetBuffBySubType(attacker, 840002) then
        attackerAuraAtk = 2000
    end
    attackerData.attrs[config.attrType.ATK] = math.floor(attackerData.attrs[config.attrType.ATK] * (1 + ((attackerWarSpirit * 500) + attackerAuraAtk) / 10000))
    
    local defenderData = {
        attrs = {
            [config.attrType.DEF] = BattleAttribute.GetAttribute(defender, BattleAttribute.ATTR_ID.DEF) or defender.def or 0,
            [config.attrType.BLOCK] = defender.blockRate or 0,
        },
        damageReduction = defender.damageReduce or 0,
    }
    local defenderWarSpirit = BattleBuff.GetBuffStackNumBySubType(defender, 840001)
    local defenderAuraDef = 0
    if BattleBuff.GetBuffBySubType(defender, 840003) then
        defenderAuraDef = 5000
    end
    defenderData.attrs[config.attrType.DEF] = math.floor(defenderData.attrs[config.attrType.DEF] * (1 + ((defenderWarSpirit * 500) + defenderAuraDef) / 10000))
    
    -- 使用 BattleFormula 计算伤害
    local damageResult = BattleFormula.CalcDamage(
        attackerData,
        defenderData,
        damageRate,
        E_ATTACK_TYPE.Physical,
        nil
    )
    
    if damageResult.isCrit then
        Logger.Log(string.format("[CalculateDamageWithRate] 暴击! 伤害: %d", damageResult.damage))
    end
    
    return damageResult.damage, damageResult
end

--- 计算治疗量
---@param healer table 治疗者
---@param target table 目标
---@param healRate number 治疗倍率（万分比，按目标最大生命值计算）
---@return number 治疗量
function BattleSkill.CalculateHeal(healer, target, healRate)
    local maxHp = target and target.maxHp or 0
    if maxHp <= 0 then
        return 0
    end

    local healAmount = math.floor(maxHp * (tonumber(healRate) or 0) / 10000)

    -- Keep legacy aura / war-spirit interactions (used by B1 passives) even though
    -- base heal is MaxHP% in the new balance model.
    local BattleBuff = require("modules.battle_buff")
    local warSpiritPct = (BattleBuff.GetBuffStackNumBySubType(healer, 840001) or 0) * 500
    local auraPct = 0
    if BattleBuff.GetBuffBySubType(healer, 840003) then
        auraPct = 5000
    elseif BattleBuff.GetBuffBySubType(healer, 840002) then
        auraPct = 2000
    end
    local auraTotal = warSpiritPct + auraPct
    if auraTotal ~= 0 then
        healAmount = math.floor(healAmount * (1 + auraTotal / 10000))
    end

    local healBonus = healer and healer.healBonus or 0
    if healBonus ~= 0 then
        healAmount = math.floor(healAmount * (1 + healBonus / 10000))
    end

    Logger.Log(string.format("[CalculateHeal] %s 治疗 %s: 目标MaxHp=%d, 倍率=%.2f%%, 治疗加成=%.2f%%, 最终=%d",
        healer.name or "Unknown",
        target.name or "Unknown",
        maxHp,
        healRate / 100,
        healBonus / 100,
        healAmount))

    return math.max(1, healAmount)
end

--- 触发伤害相关Buff
---@param attacker table 攻击者
---@param defender table 防御者
---@param damage number 伤害值
function BattleSkill.TriggerDamageBuffs(attacker, defender, damage)
    local BattleBuff = require("modules.battle_buff")
    local ON_ATTACK = 5
    local ON_RECEIVE_DAMAGE = 8
    
    -- 获取双方的Buff并触发效果
    local attackerBuffs = BattleBuff.GetAllBuffs(attacker)
    local defenderBuffs = BattleBuff.GetAllBuffs(defender)
    
    -- 触发攻击者攻击时Buff效果
    if attackerBuffs then
        for _, buff in ipairs(attackerBuffs) do
            if buff.effects then
                for _, effect in ipairs(buff.effects) do
                    if effect.timing == ON_ATTACK then
                        BattleBuff.ProcessBuffEffect(buff, attacker, ON_ATTACK)
                    end
                end
            end
        end
    end
    
    -- 触发防御者受击时Buff效果
    if defenderBuffs then
        for _, buff in ipairs(defenderBuffs) do
            if buff.effects then
                for _, effect in ipairs(buff.effects) do
                    if effect.timing == ON_RECEIVE_DAMAGE then
                        BattleBuff.ProcessBuffEffect(buff, defender, ON_RECEIVE_DAMAGE)
                    end
                end
            end
        end
    end
end

--- 从技能应用Buff
---@param caster table 施法者
---@param target table 目标
---@param buffId number Buff ID
---@param skill table 技能对象
function BattleSkill.ApplyBuffFromSkill(caster, target, buffId, skill, override)
    local BattleBuff = require("modules.battle_buff")
    local buffConfig = BattleSkill.LoadBuffConfig(buffId)
    if not buffConfig then
        Logger.LogWarning(string.format("[ApplyBuffFromSkill] 无法加载Buff配置: %d", buffId))
        return
    end

    if override then
        local merged = {}
        for k, v in pairs(buffConfig) do
            merged[k] = v
        end
        for k, v in pairs(override) do
            merged[k] = v
        end
        buffConfig = merged
    end

    BattleBuff.Add(caster, target, buffConfig)

    Logger.Log(string.format("[ApplyBuffFromSkill] %s 对 %s 施加Buff [%s]",
        caster.name or "Unknown",
        target.name or "Unknown",
        buffConfig.name or buffConfig.Name or "Unknown"))
end

--- 加载Buff配置
---@param buffId number Buff ID
---@return table|nil Buff配置
function BattleSkill.LoadBuffConfig(buffId)
    local cacheKey = "buff_" .. tostring(buffId)
    
    -- 检查缓存
    if BattleSkill.buffConfigCache and BattleSkill.buffConfigCache[cacheKey] then
        return BattleSkill.buffConfigCache[cacheKey]
    end
    
    -- 加载配置文件
    local filePath = "config.buff.buff_" .. tostring(buffId)
    local success, result = pcall(require, filePath)

    if success then
        local varName = "buff_" .. tostring(buffId)
        local buffConfig = nil
        if type(result) == "table" then
            buffConfig = result[varName] or result
        else
            buffConfig = _G[varName]
        end
        if buffConfig then
            BattleSkill.buffConfigCache = BattleSkill.buffConfigCache or {}
            BattleSkill.buffConfigCache[cacheKey] = buffConfig
            return buffConfig
        end
    end

    return nil
end

--- 检查技能释放条件
---@param hero table 英雄对象
---@param skill table 技能对象
---@return boolean 是否可以释放
function BattleSkill.CheckSkillCondition(hero, skill)
    if not hero or not skill then
        return false
    end

    -- 检查英雄状态
    if hero.isDead or not hero.isAlive then
        return false
    end

    -- 检查技能条件配置
    local conditions = skill.conditions or skill.config and skill.config.conditions
    if not conditions or #conditions == 0 then
        return true
    end

    for _, condition in ipairs(conditions) do
        if not BattleSkill.CheckSingleCondition(hero, skill, condition) then
            return false
        end
    end

    return true
end

--- 检查单个条件
---@param hero table 英雄对象
---@param skill table 技能对象
---@param condition table 条件配置
---@return boolean 条件是否满足
function BattleSkill.CheckSingleCondition(hero, skill, condition)
    if not condition then
        return true
    end

    local conditionType = condition.type or condition.conditionType

    if conditionType == E_SKILL_CONDITION.Round then
        -- 回合数条件
        local round = condition.round or condition.value or 0
        -- 获取当前回合数进行判断
        local BattleMain = require("modules.battle_main")
        local currentRound = BattleMain.GetCurrentRound and BattleMain.GetCurrentRound() or 0
        return currentRound >= round

    elseif conditionType == E_SKILL_CONDITION.EnemyRowCount then
        -- 敌方行数条件
        local count = condition.count or condition.value or 0
        -- 获取敌方行数进行判断
        local BattleFormation = require("modules.battle_formation")
        local enemyRowCount = BattleFormation.GetEnemyRowCount and BattleFormation.GetEnemyRowCount(hero) or 0
        return enemyRowCount >= count

    elseif conditionType == E_SKILL_CONDITION.FriendDiedNumLargerThan then
        -- 友方死亡数量条件
        local num = condition.num or condition.value or 0
        -- 获取友方死亡数量进行判断
        local BattleFormation = require("modules.battle_formation")
        local diedCount = BattleFormation.GetFriendDiedCount and BattleFormation.GetFriendDiedCount(hero) or 0
        return diedCount >= num

    else
        -- 自定义条件，尝试调用Lua脚本中的条件检查函数
        if skill.luaFile and skill.luaFile ~= "" then
            local skillLua = BattleSkill.LoadSkillLua(skill.skillId)
            if skillLua and skillLua.CheckCondition then
                return skillLua.CheckCondition(hero, skill, condition)
            end
        end
    end

    return true
end

--- 根据技能配置选择目标
---@param hero table 攻击者
---@param skill table 技能对象
---@return table 目标列表
local function ShuffleTargets(targets)
    local shuffled = {}
    for index, target in ipairs(targets or {}) do
        shuffled[index] = target
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

local function DeepCopyTable(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = DeepCopyTable(item)
    end
    return result
end

local function CollectAliveTargets(units, includeSelf, selfInstanceId)
    local targets = {}
    for _, unit in ipairs(units or {}) do
        if unit and unit.isAlive and not unit.isDead then
            if includeSelf or unit.instanceId ~= selfInstanceId then
                table.insert(targets, unit)
            end
        end
    end
    return targets
end

local function ReadTargetCount(targetsSelections)
    local tSConditions = targetsSelections and targetsSelections.tSConditions or nil
    local value = targetsSelections and (targetsSelections.count or targetsSelections.targetCount)
    if value == nil and tSConditions then
        value = tSConditions.Num or tSConditions.count or tSConditions.value
    end
    value = tonumber(value) or 1
    return math.max(1, math.floor(value))
end

local function ReadMeasureType(targetsSelections)
    local tSConditions = targetsSelections and targetsSelections.tSConditions or nil
    return (targetsSelections and targetsSelections.measureType)
        or (tSConditions and tSConditions.measureType)
        or E_MEASURE_TYPE.NA
end

local function ReadWpTypeFilter(targetsSelections)
    local tSConditions = targetsSelections and targetsSelections.tSConditions or nil
    local filter = tSConditions and tSConditions.tSFilter or nil
    local wpType = (targetsSelections and (targetsSelections.wpType or targetsSelections.targetWpType))
        or (filter and filter.wpType)
    wpType = tonumber(wpType)
    if wpType and wpType >= 1 and wpType <= 6 then
        return math.floor(wpType)
    end
    return nil
end

local function ReadTargetRow(targetsSelections, battleFormation)
    local explicitRow = tonumber(targetsSelections and (targetsSelections.row or targetsSelections.targetRow))
    if explicitRow then
        explicitRow = math.floor(explicitRow)
        if explicitRow >= 1 and explicitRow <= 2 then
            return explicitRow
        end
    end

    local wpType = ReadWpTypeFilter(targetsSelections)
    if wpType and battleFormation and battleFormation.GetHeroRow then
        return battleFormation.GetHeroRow(wpType)
    end

    return nil
end

local function ShouldIgnoreFrontProtection(targetsSelections)
    if not targetsSelections then
        return false
    end
    return targetsSelections.ignoreFrontProtection == true
        or targetsSelections.ignoreFrontRow == true
        or targetsSelections.breakFrontProtection == true
end

local function ShouldPreferLowestHp(targetsSelections)
    if not targetsSelections then
        return false
    end
    return targetsSelections.preferLowestHp == true
        or targetsSelections.lowestHpFirst == true
        or targetsSelections.pickLowestHp == true
end

local function ShouldPreferAllyIfInjured(targetsSelections)
    if not targetsSelections then
        return false
    end
    return targetsSelections.preferAllyIfInjured == true
        or targetsSelections.dualHolyLight == true
end

local function SortTargetsByLowestHp(targets)
    local sorted = {}
    for index, target in ipairs(targets or {}) do
        sorted[index] = target
    end
    table.sort(sorted, function(a, b)
        local aRatio = (a and a.hp and a.maxHp and a.maxHp > 0) and (a.hp / a.maxHp) or 1
        local bRatio = (b and b.hp and b.maxHp and b.maxHp > 0) and (b.hp / b.maxHp) or 1
        if aRatio == bRatio then
            return (a.hp or 0) < (b.hp or 0)
        end
        return aRatio < bRatio
    end)
    return sorted
end

local function PickTopTargets(targets, count)
    local result = {}
    for i = 1, math.min(count or #targets, #targets) do
        table.insert(result, targets[i])
    end
    return result
end

local function BuildTargetSelection(overrides)
    local selection = DeepCopyTable(TargetsSelections_Default or {})
    selection.tSConditions = DeepCopyTable(selection.tSConditions or {})
    for key, value in pairs(overrides or {}) do
        selection[key] = value
    end
    return selection
end

InferTargetsSelections = function(skillCfg, mergedConfig, finalSkillType)
    if mergedConfig and mergedConfig.targetsSelections then
        return mergedConfig.targetsSelections
    end

    local name = (skillCfg and skillCfg.Name) or (mergedConfig and mergedConfig.name) or ""
    local skillParam = (skillCfg and skillCfg.SkillParam) or {}

    if name == "斩杀" then
        return BuildTargetSelection({
            castTarget = E_CAST_TARGET.Enemy,
            preferLowestHp = true,
        })
    end
    if name == "双连斩" or name == "毒雾" then
        return BuildTargetSelection({
            castTarget = E_CAST_TARGET.Enemy,
            measureType = E_MEASURE_TYPE.Muti,
            count = skillParam[2] or 2,
        })
    end
    if name == "收割" or name == "陨石术" or name == "暴风雪" or name == "雷暴术" or name == "毒性爆发" then
        return BuildTargetSelection({
            castTarget = E_CAST_TARGET.Enemy,
            measureType = E_MEASURE_TYPE.AOE,
            ignoreFrontProtection = true,
        })
    end
    if name == "群疗" then
        return BuildTargetSelection({
            castTarget = E_CAST_TARGET.Alias,
            measureType = E_MEASURE_TYPE.Muti,
            count = skillParam[2] or 3,
            includeSelf = true,
            preferLowestHp = true,
        })
    end
    if name == "圣光" then
        return BuildTargetSelection({
            castTarget = E_CAST_TARGET.Enemy,
            preferAllyIfInjured = true,
            includeSelf = true,
        })
    end
    if name == "全军突击" or name == "战神降临" or name == "圣光普照" then
        return BuildTargetSelection({
            castTarget = E_CAST_TARGET.Alias,
            measureType = E_MEASURE_TYPE.AOE,
            includeSelf = true,
        })
    end

    if finalSkillType == E_SKILL_TYPE_ULTIMATE then
        return BuildTargetSelection({
            castTarget = E_CAST_TARGET.Enemy,
            measureType = E_MEASURE_TYPE.AOE,
            ignoreFrontProtection = true,
        })
    end

    return BuildTargetSelection({
        castTarget = E_CAST_TARGET.Enemy,
    })
end

local function SelectTargetByWpType(isLeft, targetsSelections)
    local BattleFormation = require("modules.battle_formation")
    local wpType = ReadWpTypeFilter(targetsSelections)
    if not wpType then
        return {}
    end

    local target = BattleFormation.FindHeroByCampAndPos(isLeft, wpType)
    if target and target.isAlive and not target.isDead then
        return { target }
    end
    return {}
end

function BattleSkill.SelectTarget(hero, skill)
    if not hero or not skill then
        return {}
    end

    local targets = {}
    local targetsSelections = skill.targetsSelections or skill.config and skill.config.targetsSelections

    if not targetsSelections then
        Logger.LogWarning("[BattleSkill.SelectTarget] No targetsSelections config for skill: " .. tostring(skill.skillId))
        return targets
    end

    local castTarget = targetsSelections.castTarget or E_CAST_TARGET.Enemy

    if ShouldPreferAllyIfInjured(targetsSelections) then
        local ally = BattleSkill.SelectLowestHpAlly(hero)
        if ally then
            return { ally }
        end
    end

    -- 根据目标类型选择目标
    if castTarget == E_CAST_TARGET.Self then
        -- 选择自己
        table.insert(targets, hero)

    elseif castTarget == E_CAST_TARGET.Enemy then
        -- 选择敌方
        targets = BattleSkill.SelectEnemyTargets(hero, skill, targetsSelections)

    elseif castTarget == E_CAST_TARGET.Alias then
        -- 选择友方（默认包含自己）
        targets = BattleSkill.SelectAllyTargets(hero, skill, targetsSelections, targetsSelections.includeSelf ~= false)

    elseif castTarget == E_CAST_TARGET.AlliesExcludeSelf then
        -- 选择友方（不含自己）
        targets = BattleSkill.SelectAllyTargets(hero, skill, targetsSelections, false)

    elseif castTarget == E_CAST_TARGET.AliasPos then
        targets = SelectTargetByWpType(hero.isLeft, targetsSelections)

    elseif castTarget == E_CAST_TARGET.EnemyPos then
        targets = SelectTargetByWpType(not hero.isLeft, targetsSelections)

    elseif castTarget == E_CAST_TARGET.EveryOne then
        -- 选择所有人
        targets = BattleSkill.SelectAllTargets(hero, skill, targetsSelections)

    elseif castTarget == E_CAST_TARGET.EveryOneExcludeSelf then
        -- 选择所有人（不含自己）
        targets = BattleSkill.SelectAllTargets(hero, skill, targetsSelections)
        -- 移除自己
        for i, target in ipairs(targets) do
            if target.instanceId == hero.instanceId then
                table.remove(targets, i)
                break
            end
        end

    else
        -- 其他目标类型，尝试使用Lua脚本中的目标选择
        if skill.luaFile and skill.luaFile ~= "" then
            local skillLua = BattleSkill.LoadSkillLua(skill.skillId)
            if skillLua and skillLua.SelectTarget then
                targets = skillLua.SelectTarget(hero, skill)
            end
        end
    end

    return targets
end

local function AppendUniqueTarget(result, seen, target)
    if not target or target.isDead or not target.isAlive then
        return
    end
    if seen[target.instanceId] then
        return
    end
    seen[target.instanceId] = true
    table.insert(result, target)
end

function BattleSkill.ExpandAreaTargets(anchorTarget, options)
    if not anchorTarget then
        return {}
    end

    local BattleFormation = require("modules.battle_formation")
    local result = {}
    local seen = {}
    local includeRow = options == nil or options.includeRow ~= false
    local includeColumn = options and options.includeColumn == true

    AppendUniqueTarget(result, seen, anchorTarget)

    if includeRow then
        local row = BattleFormation.GetHeroRow(anchorTarget.wpType)
        for _, target in ipairs(BattleFormation.GetAliveHeroesByRow(anchorTarget.isLeft, row)) do
            AppendUniqueTarget(result, seen, target)
        end
    end

    if includeColumn then
        local column = BattleFormation.GetHeroColumn(anchorTarget.wpType)
        for _, target in ipairs(BattleFormation.GetAliveHeroesByColumn(anchorTarget.isLeft, column)) do
            AppendUniqueTarget(result, seen, target)
        end
    end

    return result
end

function BattleSkill.GetChainTargets(hero, firstTarget, hitCount)
    local BattleFormation = require("modules.battle_formation")
    local isMelee = BattleFormation.IsMeleeHero and BattleFormation.IsMeleeHero(hero)
    local enemies = BattleFormation.GetEnemyTeam(hero) or {}
    local result = {}
    local seen = {}

    local resolvedFirstTarget = firstTarget
    if isMelee and BattleFormation.GetSelectableEnemyHeroes then
        -- Melee chain: first target must be in front row pool if any front enemies alive.
        local frontPool = BattleFormation.GetSelectableEnemyHeroes(hero, false) or {}
        local frontSet = {}
        for _, e in ipairs(frontPool) do
            if e and e.instanceId then
                frontSet[e.instanceId] = true
            end
        end
        if resolvedFirstTarget and not frontSet[resolvedFirstTarget.instanceId] then
            resolvedFirstTarget = nil
        end
        if not resolvedFirstTarget then
            resolvedFirstTarget = frontPool[1]
        end
    end

    AppendUniqueTarget(result, seen, resolvedFirstTarget)

    local candidates = {}
    for _, enemy in ipairs(enemies) do
        if enemy and enemy.isAlive and not enemy.isDead and not seen[enemy.instanceId] then
            table.insert(candidates, enemy)
        end
    end

    local shuffled = ShuffleTargets(candidates)
    for _, enemy in ipairs(shuffled) do
        if #result >= hitCount then
            break
        end
        AppendUniqueTarget(result, seen, enemy)
    end

    return result
end

--- 选择敌方目标
---@param hero table 攻击者
---@param skill table 技能对象
---@param targetsSelections table 目标选择配置
---@return table 目标列表
function BattleSkill.SelectEnemyTargets(hero, skill, targetsSelections)
    local BattleFormation = require("modules.battle_formation")
    local ignoreFrontProtection = ShouldIgnoreFrontProtection(targetsSelections)
    local measureType = ReadMeasureType(targetsSelections)
    local requestedCount = ReadTargetCount(targetsSelections)
    local candidates = CollectAliveTargets(
        BattleFormation.GetSelectableEnemyHeroes and BattleFormation.GetSelectableEnemyHeroes(hero, ignoreFrontProtection)
            or BattleFormation.GetEnemyTeam(hero)
            or {},
        true,
        nil
    )

    if #candidates == 0 then
        return {}
    end

    local wpTypeFilter = ReadWpTypeFilter(targetsSelections)
    if wpTypeFilter then
        local filtered = {}
        for _, enemy in ipairs(candidates) do
            if enemy.wpType == wpTypeFilter then
                table.insert(filtered, enemy)
            end
        end
        candidates = filtered
    end

    local targetRow = ReadTargetRow(targetsSelections, BattleFormation)
    if measureType == E_MEASURE_TYPE.Row or targetRow then
        local row = targetRow
        if not row and wpTypeFilter and BattleFormation.GetHeroRow then
            row = BattleFormation.GetHeroRow(wpTypeFilter)
        end
        if row then
            local filtered = {}
            for _, enemy in ipairs(candidates) do
                if BattleFormation.GetHeroRow(enemy.wpType) == row then
                    table.insert(filtered, enemy)
                end
            end
            return filtered
        end
    end

    if measureType == E_MEASURE_TYPE.AOE then
        return candidates
    end

    if ShouldPreferLowestHp(targetsSelections) then
        local sorted = SortTargetsByLowestHp(candidates)
        return PickTopTargets(sorted, requestedCount)
    end

    if measureType == E_MEASURE_TYPE.Muti or requestedCount > 1 then
        local shuffled = ShuffleTargets(candidates)
        return PickTopTargets(shuffled, requestedCount)
    end

    return { candidates[math.random(1, #candidates)] }
end

--- 选择友方目标
---@param hero table 攻击者
---@param skill table 技能对象
---@param targetsSelections table 目标选择配置
---@param includeSelf boolean 是否包含自己
---@return table 目标列表
function BattleSkill.SelectAllyTargets(hero, skill, targetsSelections, includeSelf)
    local BattleFormation = require("modules.battle_formation")
    local requestedCount = ReadTargetCount(targetsSelections)
    local measureType = ReadMeasureType(targetsSelections)
    local targets = CollectAliveTargets(BattleFormation.GetFriendTeam(hero) or {}, includeSelf, hero.instanceId)

    if measureType == E_MEASURE_TYPE.AOE then
        return targets
    end

    if ShouldPreferLowestHp(targetsSelections) then
        local sorted = SortTargetsByLowestHp(targets)
        return PickTopTargets(sorted, requestedCount)
    end

    if requestedCount >= #targets then
        return targets
    end

    if measureType == E_MEASURE_TYPE.Muti or requestedCount > 1 then
        local shuffled = ShuffleTargets(targets)
        return PickTopTargets(shuffled, requestedCount)
    end

    if #targets > 0 then
        return { targets[1] }
    end
    return {}
end

--- 选择所有目标
---@param hero table 攻击者
---@param skill table 技能对象
---@param targetsSelections table 目标选择配置
---@return table 目标列表
function BattleSkill.SelectAllTargets(hero, skill, targetsSelections)
    local BattleFormation = require("modules.battle_formation")
    return CollectAliveTargets(BattleFormation.GetAllAliveHeroes and BattleFormation.GetAllAliveHeroes() or {}, true, nil)
end

--- 获取技能配置
---@param skillId number 技能ID
---@return table 技能配置
function BattleSkill.GetSkillConfig(skillId)
    if BattleSkill.skillConfigCache[skillId] then
        return BattleSkill.skillConfigCache[skillId]
    end

    -- TODO: 从配置表加载技能配置
    -- 这里需要根据实际项目结构从CSV或JSON加载配置
    local config = BattleSkill.LoadSkillConfigFromFile(skillId)

    BattleSkill.skillConfigCache[skillId] = config
    return config
end

--- 从文件加载技能配置
---@param skillId number 技能ID
---@return table 技能配置
function BattleSkill.LoadSkillConfigFromFile(skillId)
    -- TODO: 实现从配置文件加载
    -- 示例：从CSV或JSON文件加载
    return {}
end

--- 加载技能Lua脚本
---@param skillId number 技能ID
---@return table Lua脚本模块
function BattleSkill.LoadSkillLua(skillId)
    -- 确保模块已初始化
    BattleSkill.InitModule()
    
    if BattleSkill.skillLuaCache[skillId] then
        return BattleSkill.skillLuaCache[skillId]
    end

    local luaPath = SkillConfig.GetSkillLuaPath(skillId)
    if not luaPath or luaPath == "" then
        -- 技能 1001 是普通攻击，没有Lua脚本是正常的，不显示警告
        if skillId ~= 1001 then
            Logger.Log("[BattleSkill.LoadSkillLua] 技能 " .. tostring(skillId) .. " 没有配置Lua脚本，使用默认普通攻击")
        end
        return nil
    end

    -- 移除.lua后缀（如果有）
    local luaFile = string.gsub(luaPath, "%.lua$", "")
    
    Logger.Log("[BattleSkill.LoadSkillLua] 尝试加载技能Lua: " .. luaFile)

    -- 尝试加载技能Lua脚本
    local success, skillModule = pcall(require, luaFile)
    if not success then
        Logger.LogWarning("[BattleSkill.LoadSkillLua] 加载技能Lua失败: " .. luaFile .. ", 错误: " .. tostring(skillModule))
        -- 失败时返回nil，让调用者执行默认攻击
        return nil
    end

    -- 兼容仅定义全局变量、不显式 return 的技能文件
    if type(skillModule) == "boolean" then
        local loadedSkillId = string.match(luaFile, "skill_(%d+)$")
        if not loadedSkillId then
            Logger.LogWarning("[BattleSkill.LoadSkillLua] 无法从路径提取技能ID: " .. luaFile)
            return nil
        end
        local globalVarName = "skill_" .. loadedSkillId
        skillModule = _G[globalVarName]
        if not skillModule then
            Logger.LogWarning("[BattleSkill.LoadSkillLua] 无法从全局变量获取技能数据: " .. globalVarName)
            return nil
        end
    end

    Logger.Log("[BattleSkill.LoadSkillLua] 成功加载技能Lua: " .. luaFile)
    BattleSkill.skillLuaCache[skillId] = skillModule
    return skillModule
end

--- 触发技能释放事件
---@param hero table 攻击者
---@param skill table 技能对象
---@param targets table 目标列表
function BattleSkill.TriggerSkillCastEvent(hero, skill, targets)
    -- 触发技能释放事件，通知其他系统（旧版兼容）
    local target = targets and targets[1] or nil
    if target then
        BattleEvent.Publish("SkillCast", hero, target, skill.name or "未知技能")
    end
    
    -- 触发可视化技能释放开始事件
    BattleEvent.Publish(BattleVisualEvents.SKILL_CAST_STARTED, 
        BattleVisualEvents.BuildSkillCastEvent(BattleVisualEvents.SKILL_CAST_STARTED, hero, skill, targets))
end

--- 获取英雄的所有技能
---@param hero table 英雄对象
---@return table 技能列表
function BattleSkill.GetHeroSkills(hero)
    if not hero or not hero.skills then
        return {}
    end
    return hero.skills
end

--- 获取指定类型的技能
---@param hero table 英雄对象
---@param skillType number 技能类型
---@return table 技能列表
function BattleSkill.GetSkillsByType(hero, skillType)
    local skills = {}
    if not hero or not hero.skills then
        return skills
    end

    for _, skill in ipairs(hero.skills) do
        if skill.skillType == skillType then
            table.insert(skills, skill)
        end
    end

    return skills
end

--- 重置所有技能冷却
---@param hero table 英雄对象
function BattleSkill.ResetAllCoolDowns(hero)
    if not hero or not hero.skillData or not hero.skillData.coolDowns then
        return
    end

    for skillId, _ in pairs(hero.skillData.coolDowns) do
        BattleSkill.SetSkillCurCoolDown(hero, skillId, 0)
    end

    Logger.Log("[BattleSkill.ResetAllCoolDowns] Reset all cooldowns for hero: " .. tostring(hero.name))
end

--- 检查技能是否在冷却中
---@param hero table 英雄对象
---@param skillId number 技能ID
---@return boolean 是否在冷却中
function BattleSkill.IsSkillInCoolDown(hero, skillId)
    local cd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
    return cd > 0
end

--- 获取技能冷却进度（0-1）
---@param hero table 英雄对象
---@param skillId number 技能ID
---@return number 冷却进度，0表示无冷却，1表示满冷却
function BattleSkill.GetSkillCoolDownProgress(hero, skillId)
    local skill = hero.skillData and hero.skillData.skillInstances and hero.skillData.skillInstances[skillId]
    if not skill or skill.maxCoolDown <= 0 then
        return 0
    end

    local curCd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
    return curCd / skill.maxCoolDown
end

--- 清理模块
function BattleSkill.OnFinal()
    Logger.Log("[BattleSkill.OnFinal] 技能模块清理")
    BattleSkill.skillConfigCache = {}
    BattleSkill.skillLuaCache = {}
    BattleSkill.skillInstanceIdCounter = 0
end

-- ============================================================================
-- 特殊效果处理系统（支持9大流派技能）
-- ============================================================================

--- 处理连击效果（S1 连击流）
---@param hero table 攻击者
---@param targets table 目标列表
---@param skill table 技能对象
---@return number 额外攻击次数
function BattleSkill.ProcessComboEffect(hero, targets, skill)
    if not skill or not skill.skillParam then return 0 end
    
    local comboRate = skill.skillParam[2] or 0  -- 连击概率（万分比）
    if comboRate <= 0 then return 0 end

    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local comboMasterMinRate = BattlePassiveSkill.GetPassiveValue(hero, "comboMasterMinRate", 0)
    if comboMasterMinRate > 0 then
        comboRate = math.max(comboRate, comboMasterMinRate)
    end
    
    local roll = math.random(1, 10000)
    if roll <= comboRate then
        Logger.Log(string.format("[ProcessComboEffect] %s 触发连击！概率: %d%%", 
            hero.name or "Unknown", comboRate / 100))
        return 1
    end
    
    return 0
end

function BattleSkill.GetPassiveAdjustedRate(hero, baseRate, passiveKey)
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local bonusPct = BattlePassiveSkill.GetPassiveValue(hero, passiveKey, 0)
    if bonusPct <= 0 then
        return baseRate
    end
    return math.floor(baseRate * (10000 + bonusPct) / 10000)
end

function BattleSkill.GetPassiveAdjustedChance(hero, baseChance, passiveKey)
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local bonusChance = BattlePassiveSkill.GetPassiveValue(hero, passiveKey, 0)
    local finalChance = baseChance + bonusChance
    if finalChance < 0 then
        return 0
    end
    if finalChance > 10000 then
        return 10000
    end
    return finalChance
end

function BattleSkill.ApplyDamageKindBonus(attacker, defender, damageRate, damageKind)
    if type(damageKind) ~= "string" or damageKind == "" then
        return damageRate
    end

    -- Fire affinity: +15% fire damage (design: "火焰亲和 法伤+15%燃烧")
    if damageKind == "fire" then
        local BattleBuff = require("modules.battle_buff")
        if BattleBuff.GetBuffBySubType(attacker, 870002) then
            return math.floor((tonumber(damageRate) or 0) * 1.15)
        end
    end

    return damageRate
end

--- 处理追击效果（A1 追击流）
---@param hero table 攻击者
---@param target table 被击杀的目标
---@param skill table 技能对象
function BattleSkill.ProcessPursuitEffect(hero, target, skill)
    if not target or not target.isDead then return false end
    
    -- 检查是否有"追击"被动
    local hasPursuit = false
    if hero.skills then
        for _, s in ipairs(hero.skills) do
            if s.name == "追击" then
                hasPursuit = true
                break
            end
        end
    end
    
    if hasPursuit then
        local pursuitRate = 10000  -- 100%追击
        local roll = math.random(1, 10000)
        if roll <= pursuitRate then
            Logger.Log(string.format("[ProcessPursuitEffect] %s 触发追击！目标: %s", 
                hero.name or "Unknown", target.name or "Unknown"))
            
            -- 选择新目标进行追击攻击
            local newTarget = BattleSkill.SelectLowestHpEnemy(hero)
            if newTarget and not newTarget.isDead then
                BattleSkill.CastSmallSkill(hero, newTarget)
                return true
            end
        end
    end
    
    return false
end

--- 选择血量最低的敌人（用于斩杀/收割）
---@param hero table 英雄对象
---@return table|nil 目标
function BattleSkill.SelectLowestHpEnemy(hero)
    local BattleFormation = require("modules.battle_formation")
    local enemies = nil
    if BattleFormation.GetSelectableEnemyHeroes then
        enemies = BattleFormation.GetSelectableEnemyHeroes(hero, false)
    end
    if not enemies or #enemies == 0 then
        enemies = BattleFormation.GetEnemyTeam(hero)
    end
    
    if not enemies or #enemies == 0 then return nil end
    
    local lowestHpTarget = nil
    local lowestHpRatio = math.huge
    
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead and enemy.hp and enemy.maxHp and enemy.maxHp > 0 then
            local hpRatio = enemy.hp / enemy.maxHp
            if hpRatio < lowestHpRatio then
                lowestHpRatio = hpRatio
                lowestHpTarget = enemy
            end
        end
    end
    
    return lowestHpTarget
end

--- 选择随机存活敌人（用于连击风暴等）
---@param hero table 英雄对象
---@param count number 数量
---@return table 目标列表
function BattleSkill.SelectRandomAliveEnemies(hero, count)
    local BattleFormation = require("modules.battle_formation")
    local enemies = nil
    if BattleFormation.GetSelectableEnemyHeroes then
        enemies = BattleFormation.GetSelectableEnemyHeroes(hero, false)
    end
    if not enemies or #enemies == 0 then
        enemies = BattleFormation.GetEnemyTeam(hero)
    end
    
    if not enemies or #enemies == 0 then return {} end
    
    local aliveEnemies = {}
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead then
            table.insert(aliveEnemies, enemy)
        end
    end
    
    -- 随机打乱并选择指定数量
    local selected = {}
    local shuffled = ShuffleTargets(aliveEnemies)
    
    for i = 1, math.min(count, #shuffled) do
        table.insert(selected, shuffled[i])
    end
    
    return selected
end

--- 处理中毒效果（T1 毒爆流）
---@param target table 目标
---@param layers number 中毒层数
function BattleSkill.ApplyPoison(target, layers, caster)
    if not target or layers <= 0 then return end

    local BattleBuff = require("modules.battle_buff")
    local existingBuff = BattleBuff.GetBuff(target, 850001)
    if existingBuff then
        BattleBuff.ModifyBuffStack(target, 850001, layers)
        Logger.Log(string.format("[ApplyPoison] %s 中毒层数: %d (总计: %d)",
            target.name or "Unknown", layers, existingBuff.stackCount))
        return
    end

    BattleSkill.ApplyBuffFromSkill(caster or target, target, 850001, nil, {
        initialStack = layers,
    })
    local totalStacks = BattleBuff.GetBuffStackNumBySubType(target, 850001)
    Logger.Log(string.format("[ApplyPoison] %s 中毒层数: %d (总计: %d)",
        target.name or "Unknown", layers, totalStacks))
end

--- 处理感染效果（中毒自动加深）
---@param target table 目标
function BattleSkill.ProcessInfectEffect(target)
    local BattleBuff = require("modules.battle_buff")
    if not target or BattleBuff.GetBuffStackNumBySubType(target, 850001) <= 0 then return end

    BattleSkill.ApplyPoison(target, 1, target)
    Logger.Log(string.format("[ProcessInfectEffect] %s 中毒加深，当前层数: %d",
        target.name or "Unknown", BattleBuff.GetBuffStackNumBySubType(target, 850001)))
end

--- 判断是否为友方
---@param hero table 英雄
---@param target table 目标
---@return boolean 是否为友方
function BattleSkill.IsAlly(hero, target)
    if not hero or not target then return false end
    return hero.isLeft == target.isLeft
end

function BattleSkill.SelectLowestHpAlly(hero)
    local BattleFormation = require("modules.battle_formation")
    local allies = BattleFormation.GetFriendTeam(hero)
    local lowestHpTarget = nil
    local lowestHpRatio = 1.0

    for _, ally in ipairs(allies) do
        if ally and ally.isAlive and not ally.isDead and ally.maxHp and ally.maxHp > 0 and ally.hp < ally.maxHp then
            local hpRatio = ally.hp / ally.maxHp
            if hpRatio < lowestHpRatio then
                lowestHpRatio = hpRatio
                lowestHpTarget = ally
            end
        end
    end

    return lowestHpTarget
end

--- 处理多目标攻击（双连斩、毒雾、连锁闪电等）
---@param hero table 攻击者
---@param skill table 技能对象
---@return table 目标列表
function BattleSkill.SelectMultiTargets(hero, skill)
    if not skill or not skill.skillParam then 
        return {} 
    end
    
    local targetCount = skill.skillParam[2] or 1
    
    if targetCount <= 1 then
        -- 单目标，选择默认目标
        local defaultTarget = BattleSkill.SelectTarget(hero, skill)
        return defaultTarget or {}
    end
    
    -- 多目标：随机选择存活的敌人
    return BattleSkill.SelectRandomAliveEnemies(hero, targetCount)
end

--- 处理全场攻击（收割、陨石术、暴风雪、雷暴术、圣光普照等）
---@param hero table 攻击者
---@param skill table 技能对象
---@return table 所有存活敌人
function BattleSkill.SelectAllAliveTargets(hero)
    local BattleFormation = require("modules.battle_formation")
    local enemies = BattleFormation.GetEnemyTeam(hero)
    
    if not enemies then return {} end
    
    local aliveTargets = {}
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead then
            table.insert(aliveTargets, enemy)
        end
    end
    
    return aliveTargets
end

function BattleSkill.ApplyBurn(target, stacks, turns, caster)
    if not target or stacks <= 0 then
        return
    end
    local BattleBuff = require("modules.battle_buff")
    local actualTurns = turns or 2
    if caster and BattleBuff.GetBuff(caster, 870002) then
        actualTurns = actualTurns + 2
    end
    local existingBuff = BattleBuff.GetBuff(target, 870001)
    if existingBuff then
        existingBuff.duration = math.max(existingBuff.duration or 0, actualTurns)
        BattleBuff.ModifyBuffStack(target, 870001, stacks)
    else
        BattleSkill.ApplyBuffFromSkill(caster or target, target, 870001, nil, {
            initialStack = stacks,
            duration = actualTurns,
        })
    end
    Logger.Log(string.format("[ApplyBurn] %s 燃烧层数: %d (总计: %d, 回合: %d)",
        target.name or "Unknown", stacks, BattleBuff.GetBuffStackNumBySubType(target, 870001), actualTurns))
end

function BattleSkill.ApplyFreeze(target, turns, slowPct, caster)
    if not target then
        return
    end
    if slowPct and slowPct > 0 then
        BattleSkill.ApplyBuffFromSkill(caster or target, target, 880001, nil, {
            value = slowPct,
            maxValue = slowPct,
            duration = math.max(turns or 0, 2),
        })
    end
    if turns and turns > 0 then
        BattleSkill.ApplyBuffFromSkill(caster or target, target, 880002, nil, {
            duration = turns,
        })
    end
    Logger.Log(string.format("[ApplyFreeze] %s 冻结回合: %d 减速: %d",
        target.name or "Unknown", turns or 0, slowPct or 0))
end

function BattleSkill.ProcessTurnStartStatus(hero)
    if not hero or hero.isDead then
        return false
    end

    local BattleBuff = require("modules.battle_buff")
    BattleBuff.OnRoundBegin(hero)

    if BattleBuff.IsHeroUnderControl(hero) then
        Logger.Log(string.format("[ProcessTurnStartStatus] %s 因冻结跳过行动", hero.name or "Unknown"))
        return false
    end

    return hero.isAlive and not hero.isDead
end

return BattleSkill
