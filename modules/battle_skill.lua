---
--- Battle Skill Module
--- 管理英雄技能、冷却和技能释放
---

local Logger = require("utils.logger")

---@class BattleSkill
local BattleSkill = {}

-- 技能配置缓存
BattleSkill.skillConfigCache = {}

-- 技能Lua脚本缓存
BattleSkill.skillLuaCache = {}

-- 技能实例计数器（用于生成唯一技能实例ID）
BattleSkill.skillInstanceIdCounter = 0

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

    if not skillsConfig or #skillsConfig == 0 then
        Logger.LogWarning("[BattleSkill.Init] skillsConfig is empty for hero: " .. tostring(hero.name))
        return
    end

    for _, skillConfig in ipairs(skillsConfig) do
        local skillId = skillConfig.skillId or skillConfig.id
        if skillId then
            local skill = BattleSkill.CreateSkillInstance(skillId, skillConfig)
            table.insert(hero.skills, skill)
            hero.skillData.skillInstances[skillId] = skill
            hero.skillData.coolDowns[skillId] = 0
        end
    end

    Logger.Log("[BattleSkill.Init] Initialized " .. #hero.skills .. " skills for hero: " .. tostring(hero.name))
end

--- 创建技能实例
---@param skillId number 技能ID
---@param skillConfig table 技能配置
---@return table 技能实例
function BattleSkill.CreateSkillInstance(skillId, skillConfig)
    local config = BattleSkill.GetSkillConfig(skillId)
    local mergedConfig = BattleSkill.MergeSkillConfig(config, skillConfig)

    local skill = {
        -- 基础信息
        instanceId = GenerateSkillInstanceId(),
        skillId = skillId,
        skillType = mergedConfig.skillType or E_SKILL_TYPE_NORMAL,
        level = mergedConfig.level or 1,
        name = mergedConfig.name or "Unknown Skill",

        -- 冷却相关
        coolDown = 0,
        maxCoolDown = mergedConfig.coolDown or mergedConfig.cd or 0,

        -- 配置数据
        config = mergedConfig,

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

        -- Lua脚本
        luaFile = mergedConfig.luaFile or mergedConfig.LuaFile or "",
        luaFuncName = mergedConfig.luaFuncName or "",

        -- 额外数据
        extraData = mergedConfig.extraData or {},
    }

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
    if skill.luaFile and skill.luaFile ~= "" then
        local skillLua = BattleSkill.LoadSkillLua(skillId)
        if skillLua and skillLua.Execute then
            local success = skillLua.Execute(hero, targets, skill)
            if not success then
                Logger.LogWarning("[BattleSkill.CastSkillInSeq] Skill Lua execution failed: " .. tostring(skillId))
                return false
            end
        end
    end

    -- 设置冷却
    BattleSkill.SetSkillCurCoolDown(hero, skillId, skill.maxCoolDown)

    -- 触发技能释放事件
    BattleSkill.TriggerSkillCastEvent(hero, skill, targets)

    Logger.Log("[BattleSkill.CastSkillInSeq] Skill cast success: " .. tostring(skillId) .. ", hero: " .. tostring(hero.name))
    return true
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
        -- TODO: 获取当前回合数进行判断
        return true

    elseif conditionType == E_SKILL_CONDITION.EnemyRowCount then
        -- 敌方行数条件
        local count = condition.count or condition.value or 0
        -- TODO: 获取敌方行数进行判断
        return true

    elseif conditionType == E_SKILL_CONDITION.FriendDiedNumLargerThan then
        -- 友方死亡数量条件
        local num = condition.num or condition.value or 0
        -- TODO: 获取友方死亡数量进行判断
        return true

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
    if BattleSkill.skillLuaCache[skillId] then
        return BattleSkill.skillLuaCache[skillId]
    end

    local config = BattleSkill.GetSkillConfig(skillId)
    if not config or not config.luaFile or config.luaFile == "" then
        return nil
    end

    local luaFile = config.luaFile
    -- 移除.lua后缀（如果有）
    luaFile = string.gsub(luaFile, "%.lua$", "")

    local success, skillModule = pcall(require, luaFile)
    if not success then
        Logger.LogError("[BattleSkill.LoadSkillLua] Failed to load skill lua: " .. luaFile .. ", error: " .. tostring(skillModule))
        return nil
    end

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
