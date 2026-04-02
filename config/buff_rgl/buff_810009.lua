-- 闪避加速
-- BuffID: 810009
-- 类型: 增益(Buff), 子类型: 810009

buff_810009 = {
    -- 基础信息
    meta = {
        id = 810009,
        name = "闪避加速",
        mainType = 1,  -- 1=增益, 2=减益, 3=控制
        subType = 810009,
        icon = "",
        description = "",
    },
    
    -- 叠加配置
    stackConfig = {
        stackType = 1,  -- 可叠加
        maxStack = 1,
        canStack = true,
    },
    
    -- 持续时间
    duration = 2,  -- 回合数(99表示永久)
    
    -- 属性效果
    attributeEffects = {
        { attrType = 209, value = 3000 }
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

return buff_810009
