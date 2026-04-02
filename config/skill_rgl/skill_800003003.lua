-- 开局控制: 首回合控制抗性+50%
-- 技能ID: 800003003
-- ClassID: 8000030, Level: 3

skill_800003003 = {
    -- 技能基础信息
    meta = {
        id = 800003003,
        classId = 8000030,
        level = 3,
        name = "开局控制",
        description = "首回合控制抗性+50%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 200,
        cooldown = 0,
        cost = 0,
        icon = "skill_start_control",
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
    -- SkillParam[1]=加成比例, [2]=持续回合
    skillParam = {5000, 1, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810012,
        probability = 10000,
        targetType = 0,
        delayRound = 1,
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

return skill_800003003
