---
--- Skill Data Configuration
--- Test skills for MiniBattleSimulator
---

local SkillData = {
    -- ==================== 普通攻击 ====================
    [1001] = {
        skillId = 1001,
        name = "普通攻击",
        skillType = 1,  -- E_SKILL_TYPE_NORMAL
        damageRate = 1.0,  -- 100%攻击力
        cooldown = 0,  -- 无冷却
        targetType = 1,  -- E_CAST_TARGET.Enemy 敌方单体
        energyCost = 0,
        energyGain = 10,  -- 攻击获得10点能量
        description = "对单个敌人造成100%攻击力的物理伤害",
    },

    -- ==================== 狂战士·格罗姆 必杀技 ====================
    [1002] = {
        skillId = 1002,
        name = "狂暴斩击",
        skillType = 2,  -- E_SKILL_TYPE_ULTIMATE
        damageRate = 2.5,  -- 250%攻击力
        cooldown = 3,  -- 3回合冷却
        targetType = 1,  -- E_CAST_TARGET.Enemy 敌方单体
        energyCost = 100,
        energyGain = 0,
        description = "对单个敌人造成250%攻击力的物理伤害，并附加流血效果",
    },

    -- ==================== 冰霜女巫·艾琳娜 必杀技 ====================
    [1003] = {
        skillId = 1003,
        name = "暴风雪",
        skillType = 2,  -- E_SKILL_TYPE_ULTIMATE
        damageRate = 1.8,  -- 180%攻击力
        cooldown = 4,  -- 4回合冷却
        targetType = 4,  -- E_CAST_TARGET.AOE 敌方全体 (通过measureType实现)
        energyCost = 100,
        energyGain = 0,
        description = "对所有敌人造成180%攻击力的魔法伤害，并降低其速度",
    },

    -- ==================== 暗影刺客·凯尔 必杀技 ====================
    [1004] = {
        skillId = 1004,
        name = "暗影突袭",
        skillType = 2,  -- E_SKILL_TYPE_ULTIMATE
        damageRate = 3.0,  -- 300%攻击力
        cooldown = 3,  -- 3回合冷却
        targetType = 1,  -- E_CAST_TARGET.Enemy 敌方单体
        energyCost = 100,
        energyGain = 0,
        description = "对单个敌人造成300%攻击力的物理伤害，暴击率提升50%",
    },

    -- ==================== 圣盾守卫·泰坦 必杀技 ====================
    [1005] = {
        skillId = 1005,
        name = "圣盾庇护",
        skillType = 2,  -- E_SKILL_TYPE_ULTIMATE
        damageRate = 0,  -- 无伤害
        cooldown = 5,  -- 5回合冷却
        targetType = 3,  -- E_CAST_TARGET.Alias 我方全体
        energyCost = 100,
        energyGain = 0,
        description = "为全体队友添加护盾，吸收相当于泰坦防御力200%的伤害",
    },
}

-- 获取技能数据
function SkillData.GetSkill(skillId)
    return SkillData[skillId]
end

-- 根据技能类型获取技能列表
function SkillData.GetSkillsByType(skillType)
    local skills = {}
    for id, skill in pairs(SkillData) do
        if type(id) == "number" and skill.skillType == skillType then
            table.insert(skills, skill)
        end
    end
    return skills
end

-- 获取英雄的所有技能配置
function SkillData.GetHeroSkills(skillIds)
    local skills = {}
    for _, skillId in ipairs(skillIds) do
        local skill = SkillData.GetSkill(skillId)
        if skill then
            table.insert(skills, skill)
        end
    end
    return skills
end

return SkillData
