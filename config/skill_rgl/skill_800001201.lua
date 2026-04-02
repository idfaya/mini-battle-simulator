-- 追击基础: 击杀后50%概率追击
-- 技能ID: 800001201
-- ClassID: 8000012, Level: 1

skill_800001201 = {
    -- 技能基础信息
    meta = {
        id = 800001201,
        classId = 8000012,
        level = 1,
        name = "追击基础",
        description = "击杀后50%概率追击",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 100,
        cooldown = 0,
        cost = 0,
        icon = "skill_chase_base",
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
    skillParam = {5000, 10000, 1, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810005,
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

return skill_800001201
