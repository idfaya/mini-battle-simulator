-- 减速
-- BuffID: 810016
-- 类型: 减益(Debuff), 子类型: 810016

buff_810016 = {
    -- 基础信息
    meta = {
        id = 810016,
        name = "减速",
        mainType = 2,  -- 1=增益, 2=减益, 3=控制
        subType = 810016,
        icon = "",
        description = "",
    },
    
    -- 叠加配置
    stackConfig = {
        stackType = 1,  -- 可叠加
        maxStack = 3,
        canStack = true,
    },
    
    -- 持续时间
    duration = 2,  -- 回合数(99表示永久)
    
    -- 属性效果
    attributeEffects = {
        { attrType = 229, value = 3000 }
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

return buff_810016
