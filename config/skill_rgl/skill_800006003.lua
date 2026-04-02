-- 过量转护盾: 过量治疗转化为护盾
-- 技能ID: 800006003
-- ClassID: 8000060, Level: 3

skill_800006003 = {
    -- 技能基础信息
    meta = {
        id = 800006003,
        classId = 8000060,
        level = 3,
        name = "过量转护盾",
        description = "过量治疗转化为护盾",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 200,
        cooldown = 0,
        cost = 0,
        icon = "skill_overheal_shield",
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
    -- SkillParam[1]=眩晕概率, [2]=眩晕回合
    skillParam = {1, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810039,
        probability = 10000,
        targetType = 0,
        delayRound = 99,
        stackCount = 1,
    },
    {
        buffId = 810040,
        probability = 10000,
        targetType = 0,
        delayRound = 99,
        stackCount = 1,
    },
    {
        buffId = 810041,
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

return skill_800006003
