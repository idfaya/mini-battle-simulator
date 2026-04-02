-- Roguelike Spell: Fireball (火球术)
-- SpellID: 800010101

spell_800010101 = {
    Name = "Fireball",
    Title = "火球术",
    
    -- 基础配置
    IntervalTimeS = 0.5,
    IsHitExplosion = true,
    IsMoveToTarget = true,
    MotionType = 1,  -- 飞行弹道
    
    -- 特效配置
    MotionEffectPath = "Effects/Fireball",
    TargetEffect = {
        effectpath = "Effects/FireExplosion",
        duringS = 1.0,
        scale = { x = 1, y = 1, z = 1 },
    },
    
    -- 音效配置
    SoundData = {
        soundid = "SFX_Fireball",
        triggerS = 0,
    },
    
    -- 触发效果 (NewAttackDrop)
    NewAttackDrop = {
        triggerType = 1,  -- 伤害触发
        damageData = {
            damageType = 1,  -- 魔法伤害
            attackType = 1,  -- 技能攻击
            hitType = 0,     -- 普通命中
        },
        targetsSelections = {
            castTarget = 2,  -- 敌方
            tSConditions = {
                Num = 1,
            },
        },
    },
    
    -- 镜头配置
    CameraData = {
        shake = true,
        shakeIntensity = 0.3,
        shakeDuration = 0.5,
    },
}

return spell_800010101
