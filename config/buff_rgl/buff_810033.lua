-- 沉默
-- BuffID: 810033
-- 类型: 控制(CC), 子类型: 810033

buff_810033 = {
    -- 基础信息
    meta = {
        id = 810033,
        name = "沉默",
        mainType = 3,  -- 1=增益, 2=减益, 3=控制
        subType = 810033,
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
    duration = 1,  -- 回合数(99表示永久)
    
    -- 属性效果
    attributeEffects = {
        { attrType = 231, value = 10000 }
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

return buff_810033
