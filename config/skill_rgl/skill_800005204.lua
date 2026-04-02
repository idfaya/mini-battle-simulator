-- 灼烧爆炸: 灼烧叠加5层时爆炸造成200%伤害
-- 技能ID: 800005204
-- ClassID: 8000052, Level: 4

skill_800005204 = {
    -- 技能基础信息
    meta = {
        id = 800005204,
        classId = 8000052,
        level = 4,
        name = "灼烧爆炸",
        description = "灼烧叠加5层时爆炸造成200%伤害",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 250,
        cooldown = 0,
        cost = 0,
        icon = "skill_burn_explode",
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
    skillParam = {5000, 5, 20000, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810037,
        probability = 500,
        targetType = 2,
        delayRound = 3,
        stackCount = 1,
    },
    {
        buffId = 810038,
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

return skill_800005204
