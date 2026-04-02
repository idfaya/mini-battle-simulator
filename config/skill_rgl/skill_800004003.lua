-- 开局护盾: 全体友方开局获得20%生命护盾
-- 技能ID: 800004003
-- ClassID: 8000040, Level: 3

skill_800004003 = {
    -- 技能基础信息
    meta = {
        id = 800004003,
        classId = 8000040,
        level = 3,
        name = "开局护盾",
        description = "全体友方开局获得20%生命护盾",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 200,
        cooldown = 0,
        cost = 0,
        icon = "skill_team_shield",
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
    skillParam = {2000, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810023,
        probability = 10000,
        targetType = 3,
        delayRound = 3,
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

return skill_800004003
