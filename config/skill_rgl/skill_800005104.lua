-- 眩晕: 攻击5%概率眩晕目标1回合
-- 技能ID: 800005104
-- ClassID: 8000051, Level: 4

skill_800005104 = {
    -- 技能基础信息
    meta = {
        id = 800005104,
        classId = 8000051,
        level = 4,
        name = "眩晕",
        description = "攻击5%概率眩晕目标1回合",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 250,
        cooldown = 0,
        cost = 0,
        icon = "skill_stun",
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
    skillParam = {500, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810034,
        probability = 500,
        targetType = 2,
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

return skill_800005104
