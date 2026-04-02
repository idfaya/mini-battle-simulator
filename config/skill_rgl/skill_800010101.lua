-- 火球术: 释放火球造成150%法术伤害
-- 技能ID: 800010101
-- ClassID: 8000101, Level: 1

skill_800010101 = {
    -- 技能基础信息
    meta = {
        id = 800010101,
        classId = 8000101,
        level = 1,
        name = "火球术",
        description = "释放火球造成150%法术伤害",
        type = 1,  -- 1=普攻, 2=主动技, 3=大招, 4=被动
        power = 150,
        cooldown = 0,
        cost = 0,
        icon = "skill_fireball",
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
    -- SkillParam[1]=法术增伤比例
    skillParam = {15000, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    
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

return skill_800010101
