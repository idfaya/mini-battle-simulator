---
--- Battle Skill Module
--- 管理英雄技能、冷却和技能释放
---

local Logger = require("utils.logger")
local SkillConfig = require("config.skill_config")

---@class BattleSkill
local BattleSkill = {}

-- 技能配置缓存
BattleSkill.skillConfigCache = {}

-- 技能Lua脚本缓存
BattleSkill.skillLuaCache = {}

-- 技能实例计数器（用于生成唯一技能实例ID）
BattleSkill.skillInstanceIdCounter = 0

-- 是否已初始化
local isInitialized = false

--- 初始化技能模块
function BattleSkill.InitModule()
    if isInitialized then
        return
    end
    SkillConfig.Init()
    isInitialized = true
    Logger.Log("[BattleSkill] 模块初始化完成")
end

--- 生成唯一技能实例ID
---@return number 技能实例ID
local function GenerateSkillInstanceId()
    BattleSkill.skillInstanceIdCounter = BattleSkill.skillInstanceIdCounter + 1
    return BattleSkill.skillInstanceIdCounter
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
            Logger.LogWarning("[BattleSkill.Init] hero.skills 也为空，无法初始化技能")
            return
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
    
    -- 从 SkillConfig 获取配置
    local skillType = SkillConfig.GetSkillType(skillId)
    local skillParam = SkillConfig.GetSkillParam(skillId)
    local skillBuffs = SkillConfig.GetSkillBuffs(skillId)
    local skillCooldown = SkillConfig.GetSkillCooldown(skillId)
    local skillCost = SkillConfig.GetSkillCost(skillId)
    local luaPath = SkillConfig.GetSkillLuaPath(skillId)
    
    -- 合并配置
    local config = BattleSkill.GetSkillConfig(skillId)
    local mergedConfig = BattleSkill.MergeSkillConfig(config, skillConfig)
    
    -- 确定技能类型
    local finalSkillType = mergedConfig.skillType or E_SKILL_TYPE_NORMAL
    if skillType then
        -- 根据 res_skill.json 的 Type 字段映射
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

    local skill = {
        -- 基础信息
        instanceId = GenerateSkillInstanceId(),
        skillId = skillId,
        skillType = finalSkillType,
        level = mergedConfig.level or 1,
        name = mergedConfig.name or ("Skill_" .. skillId),

        -- 冷却相关
        coolDown = 0,
        maxCoolDown = skillCooldown or mergedConfig.coolDown or mergedConfig.cd or 0,

        -- 配置数据
        config = mergedConfig,
        
        -- 从 res_skill.json 加载的数据
        skillParam = skillParam,
        skillBuffs = skillBuffs,
        skillCost = skillCost,

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

        -- Lua脚本路径 (从 SkillConfig 获取)
        luaFile = luaPath or mergedConfig.luaFile or mergedConfig.LuaFile or "",
        luaFuncName = mergedConfig.luaFuncName or "",

        -- 额外数据
        extraData = mergedConfig.extraData or {},
    }
    
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

--- 释放指定技能
---@param hero table 攻击者
---@param target table 目标
---@param skillId number 技能ID
---@return boolean 是否释放成功
function BattleSkill.CastSkillInSeq(hero, target, skillId)
    if not hero then
        Logger.LogError("[BattleSkill.CastSkillInSeq] hero is nil")
        return false
    end

    local skill = hero.skillData and hero.skillData.skillInstances and hero.skillData.skillInstances[skillId]
    if not skill then
        Logger.LogError("[BattleSkill.CastSkillInSeq] Skill not found: " .. tostring(skillId))
        return false
    end

    -- 检查技能释放条件
    if not BattleSkill.CheckSkillCondition(hero, skill) then
        Logger.Log("[BattleSkill.CastSkillInSeq] Skill condition check failed: " .. tostring(skillId))
        return false
    end

    -- 检查冷却
    local curCd = BattleSkill.GetSkillCurCoolDown(hero, skillId)
    if curCd > 0 then
        Logger.Log("[BattleSkill.CastSkillInSeq] Skill in cooldown: " .. tostring(skillId) .. ", cd: " .. curCd)
        return false
    end

    -- 选择目标
    local targets = target and {target} or BattleSkill.SelectTarget(hero, skill)
    if not targets or #targets == 0 then
        Logger.LogWarning("[BattleSkill.CastSkillInSeq] No valid targets for skill: " .. tostring(skillId))
        return false
    end

    -- 加载并执行技能Lua脚本
    local executed = false
    
    -- 始终加载技能配置文件（skill_{ID}.lua），不管 luaFile 是否为空
    -- luaFile 不为空时，表示有额外的自定义脚本（War/ActiveSkills/{LuaFile}.lua）
    local skillLua = BattleSkill.LoadSkillLua(skillId)
    if skillLua then
        -- 检查是否有Execute函数（自定义技能脚本）
        if skillLua.Execute then
            local success = skillLua.Execute(hero, targets, skill)
            if success then
                executed = true
            else
                Logger.LogWarning("[BattleSkill.CastSkillInSeq] Skill Lua execution failed: " .. tostring(skillId))
            end
        else
            -- 原工程技能文件（数据配置），使用SkillExecutor执行 actData 中的关键帧
            local SkillExecutor = require("core.skill_executor")
            executed = SkillExecutor.ExecuteSkill(hero, targets, skillLua, skill)
            if executed then
                Logger.Log("[BattleSkill.CastSkillInSeq] 使用SkillExecutor执行技能关键帧: " .. tostring(skillId))
            end
        end
    end
    
    -- 如果没有执行技能Lua脚本，执行默认的普通攻击伤害
    if not executed then
        Logger.Log("[BattleSkill.CastSkillInSeq] 执行默认普通攻击")
        BattleSkill.ExecuteDefaultAttack(hero, targets, skill)
    end

    -- 设置冷却
    BattleSkill.SetSkillCurCoolDown(hero, skillId, skill.maxCoolDown)
    
    -- 扣除能量（大招技能）
    if skill.skillType == E_SKILL_TYPE_ULTIMATE and skill.skillCost and skill.skillCost > 0 then
        hero.curEnergy = (hero.curEnergy or 0) - skill.skillCost
        Logger.Log(string.format("[CastSkillInSeq] %s 释放大招消耗能量: %d, 剩余能量: %d", 
            hero.name or "Unknown", skill.skillCost, hero.curEnergy))
    end

    -- 触发技能释放事件
    BattleSkill.TriggerSkillCastEvent(hero, skill, targets)

    Logger.Log("[BattleSkill.CastSkillInSeq] Skill cast success: " .. tostring(skillId) .. ", hero: " .. tostring(hero.name))
    return true
end

--- 执行默认普通攻击
---@param hero table 攻击者
---@param targets table 目标列表
---@param skill table 技能对象
function BattleSkill.ExecuteDefaultAttack(hero, targets, skill)
    if not hero or not targets or #targets == 0 then
        return
    end

    local BattleAttribute = require("modules.battle_attribute")
    local SkillLoader = require("core.skill_loader")

    -- 尝试加载技能配置
    local skillId = skill and skill.skillId
    local spellConfig = nil
    if skillId then
        local config = SkillLoader.LoadSkillConfig(skillId)
        if config then
            -- 配置文件的变量名格式为 spell_xxxxxx
            local varName = "spell_" .. tostring(skillId)
            spellConfig = config[varName]
        end
    end

    -- 获取技能的伤害倍率（优先使用技能对象中的配置）
    local damageRate = 10000  -- 默认100%（万分比）
    if skill and skill.damageData and skill.damageData.damageRate then
        -- 使用技能对象中的damageData（百分比转万分比）
        damageRate = skill.damageData.damageRate * 100
        Logger.Log(string.format("[ExecuteDefaultAttack] 使用技能配置伤害倍率: %d%%", skill.damageData.damageRate))
    elseif spellConfig and spellConfig.Trigger and spellConfig.Trigger.damageData then
        -- 使用配置文件中的damageData
        damageRate = spellConfig.Trigger.damageData.damageRate or 10000
    end
    
    -- 检查是否是治疗技能
    local isHealSkill = skill and skill.healData and skill.healData.healRate
    local healRate = isHealSkill and skill.healData.healRate * 100 or 0

    -- 对每个目标执行效果
    for _, target in ipairs(targets) do
        if target and not target.isDead then
            if isHealSkill then
                -- 执行治疗
                local healAmount = BattleSkill.CalculateHeal(hero, target, healRate)
                local curHp = BattleAttribute.GetHeroCurHp(target)
                local maxHp = BattleAttribute.GetHeroMaxHp(target)
                local newHp = math.min(maxHp, curHp + healAmount)
                BattleAttribute.SetHpByVal(target, newHp)
                
                Logger.Log(string.format("[ExecuteDefaultAttack] %s 对 %s 治疗 %d 点生命 (HP: %d -> %d)",
                    hero.name or "Unknown",
                    target.name or "Unknown",
                    healAmount,
                    curHp,
                    newHp))
            else
                -- 执行伤害
                local damage = BattleSkill.CalculateDamageWithRate(hero, target, damageRate)
                
                -- 应用伤害
                local curHp = BattleAttribute.GetHeroCurHp(target)
                local newHp = math.max(0, curHp - damage)
                BattleAttribute.SetHpByVal(target, newHp)

                Logger.Log(string.format("[ExecuteDefaultAttack] %s 对 %s 造成 %d 点伤害 (HP: %d -> %d)",
                    hero.name or "Unknown",
                    target.name or "Unknown",
                    damage,
                    curHp,
                    newHp))
                
                -- 触发伤害相关Buff
                BattleSkill.TriggerDamageBuffs(hero, target, damage)
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
end

--- 计算伤害
---@param attacker table 攻击者
---@param defender table 防御者
---@param spellConfig table 技能配置
---@return number 伤害值
function BattleSkill.CalculateDamage(attacker, defender, spellConfig)
    local BattleAttribute = require("modules.battle_attribute")
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
            [config.attrType.CRIT] = BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.CRIT_RATE) or attacker.critRate or 0,
        },
        damageBonus = attacker.damageIncrease or 0,
    }
    
    local defenderData = {
        attrs = {
            [config.attrType.DEF] = BattleAttribute.GetAttribute(defender, BattleAttribute.ATTR_ID.DEF) or defender.def or 0,
            [config.attrType.BLOCK] = defender.blockRate or 0,
        },
        damageReduction = defender.damageReduce or 0,
    }
    
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
    
    return damageResult.damage
end

--- 使用指定倍率计算伤害
---@param attacker table 攻击者
---@param defender table 防御者
---@param damageRate number 伤害倍率（万分比）
---@return number 伤害值
function BattleSkill.CalculateDamageWithRate(attacker, defender, damageRate)
    local BattleAttribute = require("modules.battle_attribute")
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
            [config.attrType.CRIT] = BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.CRIT_RATE) or attacker.critRate or 0,
        },
        damageBonus = attacker.damageIncrease or 0,
    }
    
    local defenderData = {
        attrs = {
            [config.attrType.DEF] = BattleAttribute.GetAttribute(defender, BattleAttribute.ATTR_ID.DEF) or defender.def or 0,
            [config.attrType.BLOCK] = defender.blockRate or 0,
        },
        damageReduction = defender.damageReduce or 0,
    }
    
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
    
    return damageResult.damage
end

--- 计算治疗量
---@param healer table 治疗者
---@param target table 目标
---@param healRate number 治疗倍率（万分比）
---@return number 治疗量
function BattleSkill.CalculateHeal(healer, target, healRate)
    local BattleAttribute = require("modules.battle_attribute")
    
    -- 基础治疗量 = 治疗者攻击力 * 治疗倍率
    local atk = BattleAttribute.GetAttribute(healer, BattleAttribute.ATTR_ID.ATK) or healer.atk or 0
    local healAmount = math.floor(atk * healRate / 10000)
    
    -- 添加随机波动 (90% - 110%)
    local randomFactor = math.random(9000, 11000) / 10000
    healAmount = math.floor(healAmount * randomFactor)
    
    Logger.Log(string.format("[CalculateHeal] %s 治疗 %s: 基础治疗=%d, 倍率=%.2f%%, 最终=%d",
        healer.name or "Unknown",
        target.name or "Unknown",
        atk,
        healRate / 100,
        healAmount))
    
    return math.max(1, healAmount)  -- 最小治疗1点
end

--- 触发伤害相关Buff
---@param attacker table 攻击者
---@param defender table 防御者
---@param damage number 伤害值
function BattleSkill.TriggerDamageBuffs(attacker, defender, damage)
    local BattleBuff = require("modules.battle_buff")
    
    -- 获取双方的Buff并触发效果
    local attackerBuffs = BattleBuff.GetAllBuffs(attacker)
    local defenderBuffs = BattleBuff.GetAllBuffs(defender)
    
    -- 触发攻击者攻击时Buff效果
    if attackerBuffs then
        for _, buff in ipairs(attackerBuffs) do
            if buff.effects then
                for _, effect in ipairs(buff.effects) do
                    if effect.timing == E_BUFF_TIMING.ON_ATTACK then
                        BattleBuff.ProcessBuffEffect(buff, attacker, E_BUFF_TIMING.ON_ATTACK)
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
                    if effect.timing == E_BUFF_TIMING.ON_RECEIVE_DAMAGE then
                        BattleBuff.ProcessBuffEffect(buff, defender, E_BUFF_TIMING.ON_RECEIVE_DAMAGE)
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
function BattleSkill.ApplyBuffFromSkill(caster, target, buffId, skill)
    -- 加载Buff配置
    local buffConfig = BattleSkill.LoadBuffConfig(buffId)
    if not buffConfig then
        Logger.LogWarning(string.format("[ApplyBuffFromSkill] 无法加载Buff配置: %d", buffId))
        return
    end
    
    -- 使用BattleBuff.Add添加Buff
    BattleBuff.Add(caster, target, buffConfig)
    
    Logger.Log(string.format("[ApplyBuffFromSkill] %s 对 %s 施加Buff [%s]",
        caster.name or "Unknown",
        target.name or "Unknown",
        buffConfig.Name or "Unknown"))
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
    
    if success and result and type(result) == "table" then
        local varName = "buff_" .. tostring(buffId)
        local buffConfig = result[varName]
        
        -- 缓存配置
        BattleSkill.buffConfigCache = BattleSkill.buffConfigCache or {}
        BattleSkill.buffConfigCache[cacheKey] = buffConfig
        
        return buffConfig
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

    -- 根据目标类型选择目标
    if castTarget == E_CAST_TARGET.Self then
        -- 选择自己
        table.insert(targets, hero)

    elseif castTarget == E_CAST_TARGET.Enemy then
        -- 选择敌方
        targets = BattleSkill.SelectEnemyTargets(hero, skill, targetsSelections)

    elseif castTarget == E_CAST_TARGET.Alias then
        -- 选择友方（不含自己）
        targets = BattleSkill.SelectAllyTargets(hero, skill, targetsSelections, false)

    elseif castTarget == E_CAST_TARGET.AlliesExcludeSelf then
        -- 选择友方（不含自己）
        targets = BattleSkill.SelectAllyTargets(hero, skill, targetsSelections, false)

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

--- 选择敌方目标
---@param hero table 攻击者
---@param skill table 技能对象
---@param targetsSelections table 目标选择配置
---@return table 目标列表
function BattleSkill.SelectEnemyTargets(hero, skill, targetsSelections)
    local targets = {}
    -- TODO: 从BattleFormation获取敌方英雄
    -- 这里需要根据实际项目结构调用相应的模块
    return targets
end

--- 选择友方目标
---@param hero table 攻击者
---@param skill table 技能对象
---@param targetsSelections table 目标选择配置
---@param includeSelf boolean 是否包含自己
---@return table 目标列表
function BattleSkill.SelectEnemyTargets(hero, skill, targetsSelections, includeSelf)
    local targets = {}
    -- TODO: 从BattleFormation获取友方英雄
    -- 这里需要根据实际项目结构调用相应的模块
    return targets
end

--- 选择所有目标
---@param hero table 攻击者
---@param skill table 技能对象
---@param targetsSelections table 目标选择配置
---@return table 目标列表
function BattleSkill.SelectAllTargets(hero, skill, targetsSelections)
    local targets = {}
    -- TODO: 从BattleFormation获取所有英雄
    -- 这里需要根据实际项目结构调用相应的模块
    return targets
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

    -- 从 SkillConfig 获取Lua路径
    local luaPath = SkillConfig.GetSkillLuaPath(skillId)
    if not luaPath or luaPath == "" then
        Logger.LogWarning("[BattleSkill.LoadSkillLua] 技能 " .. tostring(skillId) .. " 没有配置Lua脚本")
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

    -- 如果模块返回的是布尔值（原工程技能文件只定义全局变量，不返回）
    -- 从全局变量中获取技能数据
    if type(skillModule) == "boolean" then
        -- 从luaFile中提取技能ID（如 config.skill.skill_131010101 -> 131010101）
        local loadedSkillId = string.match(luaFile, "skill_(%d+)$")
        if not loadedSkillId then
            Logger.LogWarning("[BattleSkill.LoadSkillLua] 无法从路径提取技能ID: " .. luaFile)
            return nil
        end
        
        -- 构建全局变量名（如 skill_131010101）
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
    -- TODO: 触发技能释放事件，通知其他系统
    -- 例如：触发被动技能、记录战斗日志等
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

return BattleSkill
