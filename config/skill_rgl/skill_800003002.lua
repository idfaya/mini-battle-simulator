-- 开局加攻: 前3回合攻击+30%
-- 技能ID: 800003002
-- ClassID: 8000030, Level: 2

skill_800003002 = {
    -- 技能基础信息
    meta = {
        id = 800003002,
        classId = 8000030,
        level = 2,
        name = "开局加攻",
        description = "前3回合攻击+30%",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 150,
        cooldown = 0,
        cost = 0,
        icon = "skill_start_attack",
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
    skillParam = {3000, 3, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810011,
        probability = 10000,
        targetType = 0,
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

return skill_800003002
