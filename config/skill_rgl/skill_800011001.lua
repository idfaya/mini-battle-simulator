-- 冰元素亲和: 冰属性伤害+20%，减速效果+10%
-- 技能ID: 800011001
-- ClassID: 8000110, Level: 1

skill_800011001 = {
    -- 技能基础信息
    meta = {
        id = 800011001,
        classId = 8000110,
        level = 1,
        name = "冰元素亲和",
        description = "冰属性伤害+20%，减速效果+10%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 100,
        cooldown = 0,
        cost = 0,
        icon = "skill_ice_affinity",
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
    skillParam = {2000, 1000, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810026,
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

return skill_800011001
