-- 反击全体: 反击时攻击全体敌人
-- 技能ID: 800001105
-- ClassID: 8000011, Level: 5

skill_800001105 = {
    -- 技能基础信息
    meta = {
        id = 800001105,
        classId = 8000011,
        level = 5,
        name = "反击全体",
        description = "反击时攻击全体敌人",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 300,
        cooldown = 0,
        cost = 0,
        icon = "skill_counter_aoe",
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
    -- SkillParam[1]=触发概率, [2]=伤害比例, [3]=连击次数, [4]=无限连击概率
    skillParam = {5000, 10000, 0, 0, 5000, 1, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810003,
        probability = 10000,
        targetType = 0,
        delayRound = 99,
        stackCount = 1,
    },
    {
        buffId = 810004,
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

return skill_800001105
