-- 治疗强化
-- BuffID: 810039
-- 类型: 增益(Buff), 子类型: 810039

buff_810039 = {
    -- 基础信息
    meta = {
        id = 810039,
        name = "治疗强化",
        mainType = 1,  -- 1=增益, 2=减益, 3=控制
        subType = 810039,
        icon = "",
        description = "",
    },
    
    -- 叠加配置
    stackConfig = {
        stackType = 0,  -- 不可叠加
        maxStack = 1,
        canStack = false,
    },
    
    -- 持续时间
    duration = 99,  -- 回合数(99表示永久)
    
    -- 属性效果
    attributeEffects = {
        { attrType = 237, value = 3000 }
    },
    
    -- 特效配置
    vfxConfig = {
        startEffect = "",
        loopEffect = "",
        endEffect = "",
    },
    
    -- 触发时机配置（可选）
    triggerConfig = {
        -- 触发时机: 1=回合开始, 2=回合结束, 3=受到伤害, 4=造成伤害, etc.
        timing = 0,
        -- 触发概率(万分比)
        probability = 10000,
        -- 触发效果
        effect = nil,
    },
}

return buff_810039
