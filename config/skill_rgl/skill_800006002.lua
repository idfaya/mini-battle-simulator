-- 治疗暴击: 治疗可以触发暴击
-- 技能ID: 800006002
-- ClassID: 8000060, Level: 2

skill_800006002 = {
    -- 技能基础信息
    meta = {
        id = 800006002,
        classId = 8000060,
        level = 2,
        name = "治疗暴击",
        description = "治疗可以触发暴击",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 150,
        cooldown = 0,
        cost = 0,
        icon = "skill_heal_crit",
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
    },
    
    -- 动作时间轴数据（根据技能类型生成）
    actData = {},
    
    -- 被动技能特有配置
    passiveConfig = {
        isPassive = true,
        triggerTiming = 0,  -- 触发时机（需要根据实际情况配置）
    },
}

return skill_800006002
