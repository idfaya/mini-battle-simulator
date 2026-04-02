-- 无限连击: 连击后25%概率继续连击
-- 技能ID: 800001004
-- ClassID: 8000010, Level: 4

skill_800001004 = {
    -- 技能基础信息
    meta = {
        id = 800001004,
        classId = 8000010,
        level = 4,
        name = "无限连击",
        description = "连击后25%概率继续连击",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 250,
        cooldown = 0,
        cost = 0,
        icon = "skill_combo_infinite",
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
    skillParam = {3500, 10000, 2, 2500, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810001,
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

return skill_800001004
