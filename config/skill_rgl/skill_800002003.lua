-- 格挡减伤+: 格挡时额外减伤20%
-- 技能ID: 800002003
-- ClassID: 8000020, Level: 3

skill_800002003 = {
    -- 技能基础信息
    meta = {
        id = 800002003,
        classId = 8000020,
        level = 3,
        name = "格挡减伤+",
        description = "格挡时额外减伤20%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 200,
        cooldown = 0,
        cost = 0,
        icon = "skill_block_reduce",
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
    skillParam = {3500, 2000, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810006,
        probability = 10000,
        targetType = 0,
        delayRound = 99,
        stackCount = 1,
    },
    {
        buffId = 810007,
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

return skill_800002003
