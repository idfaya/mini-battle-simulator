-- 减速: 攻击降低目标速度30%
-- 技能ID: 800005101
-- ClassID: 8000051, Level: 1

skill_800005101 = {
    -- 技能基础信息
    meta = {
        id = 800005101,
        classId = 8000051,
        level = 1,
        name = "减速",
        description = "攻击降低目标速度30%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 100,
        cooldown = 0,
        cost = 0,
        icon = "skill_slow",
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
    -- SkillParam[1]=吸血比例
    skillParam = {3000, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    
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
        isPassive = true,
        triggerTiming = 0,  -- 触发时机（需要根据实际情况配置）
    },
}

return skill_800005101
