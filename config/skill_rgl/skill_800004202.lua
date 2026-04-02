-- 能量回复+: 每次行动额外回复15点能量
-- 技能ID: 800004202
-- ClassID: 8000042, Level: 2

skill_800004202 = {
    -- 技能基础信息
    meta = {
        id = 800004202,
        classId = 8000042,
        level = 2,
        name = "能量回复+",
        description = "每次行动额外回复15点能量",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 150,
        cooldown = 0,
        cost = 0,
        icon = "skill_mana_regen",
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
    -- SkillParam[1]=团队加成比例
    skillParam = {15, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810026,
        probability = 10000,
        targetType = 0,
        delayRound = 99,
        stackCount = 1,
    },
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

return skill_800004202
