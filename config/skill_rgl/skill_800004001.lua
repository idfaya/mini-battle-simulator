-- 开局加攻: 全体友方开局攻击+20%
-- 技能ID: 800004001
-- ClassID: 8000040, Level: 1

skill_800004001 = {
    -- 技能基础信息
    meta = {
        id = 800004001,
        classId = 8000040,
        level = 1,
        name = "开局加攻",
        description = "全体友方开局攻击+20%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 100,
        cooldown = 0,
        cost = 0,
        icon = "skill_team_attack",
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
        buffId = 810021,
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

return skill_800004001
