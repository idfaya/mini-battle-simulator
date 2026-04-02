-- 灼烧: 攻击附加灼烧，每回合损失50%攻击力
-- 技能ID: 800005203
-- ClassID: 8000052, Level: 3

skill_800005203 = {
    -- 技能基础信息
    meta = {
        id = 800005203,
        classId = 8000052,
        level = 3,
        name = "灼烧",
        description = "攻击附加灼烧，每回合损失50%攻击力",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 200,
        cooldown = 0,
        cost = 0,
        icon = "skill_burn",
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
    skillParam = {5000, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {
    {
        buffId = 810037,
        probability = 500,
        targetType = 2,
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

return skill_800005203
