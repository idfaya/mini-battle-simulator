-- 闪电术: 释放闪电造成130%伤害，暴击率+20%
-- 技能ID: 800012101
-- ClassID: 8000121, Level: 1

skill_800012101 = {
    -- 技能基础信息
    meta = {
        id = 800012101,
        classId = 8000121,
        level = 1,
        name = "闪电术",
        description = "释放闪电造成130%伤害，暴击率+20%",
        type = 1,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 130,
        cooldown = 0,
        cost = 0,
        icon = "skill_thunder_bolt",
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
    -- SkillParam 参数
    skillParam = {13000, 2000, 0, 0, 0, 0, 0, 0, 0, 0},
    
    -- Buff触发配置
    buffTriggers = {

    },
    
    -- 动作时间轴数据（根据技能类型生成）
    actData = {},
    
    -- 被动技能特有配置
    passiveConfig = {
        isPassive = false,
        triggerTiming = 0,  -- 触发时机（需要根据实际情况配置）
    },
}

return skill_800012101
