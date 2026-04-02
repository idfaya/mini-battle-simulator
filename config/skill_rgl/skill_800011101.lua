-- 冰箭术: 释放冰箭造成120%伤害并降低目标30%速度
-- 技能ID: 800011101
-- ClassID: 8000111, Level: 1

skill_800011101 = {
    -- 技能基础信息
    meta = {
        id = 800011101,
        classId = 8000111,
        level = 1,
        name = "冰箭术",
        description = "释放冰箭造成120%伤害并降低目标30%速度",
        type = 1,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 120,
        cooldown = 0,
        cost = 0,
        icon = "skill_ice_arrow",
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
    skillParam = {12000, 3000, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810016,
        probability = 10000,
        targetType = 2,
        delayRound = 2,
        stackCount = 1,
    },
    },
    
    -- 动作时间轴数据（根据技能类型生成）
    actData = {},
    
    -- 被动技能特有配置
    passiveConfig = {
        isPassive = false,
        triggerTiming = 0,  -- 触发时机（需要根据实际情况配置）
    },
}

return skill_800011101
