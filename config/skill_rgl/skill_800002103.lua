-- 闪避后加速: 闪避后速度+30%
-- 技能ID: 800002103
-- ClassID: 8000021, Level: 3

skill_800002103 = {
    -- 技能基础信息
    meta = {
        id = 800002103,
        classId = 8000021,
        level = 3,
        name = "闪避后加速",
        description = "闪避后速度+30%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 200,
        cooldown = 0,
        cost = 0,
        icon = "skill_dodge_speed",
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
    -- SkillParam[1]=格挡率, [2]=额外减伤
    skillParam = {3000, 3000, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810008,
        probability = 10000,
        targetType = 0,
        delayRound = 99,
        stackCount = 1,
    },
    {
        buffId = 810009,
        probability = 10000,
        targetType = 0,
        delayRound = 2,
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

return skill_800002103
