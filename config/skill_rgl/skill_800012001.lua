-- 雷元素亲和: 雷属性伤害+20%，暴击率+15%
-- 技能ID: 800012001
-- ClassID: 8000120, Level: 1

skill_800012001 = {
    -- 技能基础信息
    meta = {
        id = 800012001,
        classId = 8000120,
        level = 1,
        name = "雷元素亲和",
        description = "雷属性伤害+20%，暴击率+15%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 100,
        cooldown = 0,
        cost = 0,
        icon = "skill_thunder_affinity",
    },
    
    -- 目标选择配置
    targetsSelections = {
        castTarget = 2,  -- 2=敌方
        tSConditions = {
            Num = 1,
            wpType = nil,
        }
    },
    
    -- 技能参数
    -- SkillParam 参数
    skillParam = {2000, 1500, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810027,
        probability = 10000,
        targetType = 0,
        delayRound = 99,
        stackCount = 1,
    },
    },
    
    -- 动作时间轴数据（根据技能类型生成）
    actData = {},
    
    -- 被动技能特有配置
    passiveConfig = {
        isPassive = true,
        triggerTiming = 0,  -- 触发时机（需要根据实际情况配置）
    },
}

return skill_800012001
