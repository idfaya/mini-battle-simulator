-- 无视防御: 攻击无视目标30%防御
-- 技能ID: 800005004
-- ClassID: 8000050, Level: 4

skill_800005004 = {
    -- 技能基础信息
    meta = {
        id = 800005004,
        classId = 8000050,
        level = 4,
        name = "无视防御",
        description = "攻击无视目标30%防御",
        type = 4,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 250,
        cooldown = 0,
        cost = 0,
        icon = "skill_ignore_def",
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
        buffId = 810031,
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

return skill_800005004
