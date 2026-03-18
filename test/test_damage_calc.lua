---
--- 测试伤害计算
---

package.path = package.path .. ";./?.lua;./core/?.lua;./modules/?.lua;./config/?.lua;./utils/?.lua"

print("========================================")
print("测试伤害计算")
print("========================================")

-- 先加载全局定义
require("core.battle_enum")

-- 加载必要模块
local BattleFormula = require("core.battle_formula")
local BattleAttribute = require("modules.battle_attribute")

-- 初始化公式
BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)

-- 测试1: 使用直接属性的英雄
print("\n[测试1] 使用直接属性的英雄")
local hero1 = {
    name = "英雄1",
    atk = 400,
    def = 200,
    critRate = 1500,
}

local hero2 = {
    name = "英雄2", 
    atk = 350,
    def = 180,
    critRate = 1000,
}

-- 手动构建数据（模拟CalculateDamageWithRate的做法）
local config = BattleFormula.GetConfig()
local attackerData1 = {
    attrs = {
        [config.attrType.ATK] = BattleAttribute.GetAttribute(hero1, BattleAttribute.ATTR_ID.ATK) or hero1.atk or 0,
        [config.attrType.CRIT] = BattleAttribute.GetAttribute(hero1, BattleAttribute.ATTR_ID.CRIT_RATE) or hero1.critRate or 0,
    },
}

local defenderData1 = {
    attrs = {
        [config.attrType.DEF] = BattleAttribute.GetAttribute(hero2, BattleAttribute.ATTR_ID.DEF) or hero2.def or 0,
    },
}

print(string.format("  攻击者ATK: %d (期望: 400)", attackerData1.attrs[config.attrType.ATK]))
print(string.format("  防御者DEF: %d (期望: 180)", defenderData1.attrs[config.attrType.DEF]))

local damage1 = BattleFormula.CalcDamage(attackerData1, defenderData1, 10000, 1)
print(string.format("  基础伤害: %d (期望: 400-180=220)", damage1.damage))

-- 测试2: 使用attributes的英雄
print("\n[测试2] 使用attributes结构的英雄")
local hero3 = {
    name = "英雄3",
    attributes = {
        base = {
            [2] = 500,  -- ATK
            [3] = 250,  -- DEF
            [5] = 2000, -- CRIT_RATE
        },
        final = {
            [2] = 550,
            [3] = 280,
            [5] = 2200,
        }
    },
    atk = 500,  -- 备用值
    def = 250,
}

local hero4 = {
    name = "英雄4",
    attributes = {
        base = {
            [3] = 200,  -- DEF
        },
        final = {
            [3] = 220,
        }
    },
    def = 200,
}

local attackerData2 = {
    attrs = {
        [config.attrType.ATK] = BattleAttribute.GetAttribute(hero3, BattleAttribute.ATTR_ID.ATK) or hero3.atk or 0,
        [config.attrType.CRIT] = BattleAttribute.GetAttribute(hero3, BattleAttribute.ATTR_ID.CRIT_RATE) or hero3.critRate or 0,
    },
}

local defenderData2 = {
    attrs = {
        [config.attrType.DEF] = BattleAttribute.GetAttribute(hero4, BattleAttribute.ATTR_ID.DEF) or hero4.def or 0,
    },
}

print(string.format("  攻击者ATK: %d (期望: 550)", attackerData2.attrs[config.attrType.ATK]))
print(string.format("  防御者DEF: %d (期望: 220)", defenderData2.attrs[config.attrType.DEF]))

local damage2 = BattleFormula.CalcDamage(attackerData2, defenderData2, 10000, 1)
print(string.format("  基础伤害: %d (期望: 550-220=330)", damage2.damage))

-- 测试3: 高伤害倍率
print("\n[测试3] 高伤害倍率测试")
local damage3 = BattleFormula.CalcDamage(attackerData2, defenderData2, 20000, 1)  -- 200%倍率
print(string.format("  200%%倍率伤害: %d (期望: 330*2=660)", damage3.damage))

local damage4 = BattleFormula.CalcDamage(attackerData2, defenderData2, 50000, 1)  -- 500%倍率
print(string.format("  500%%倍率伤害: %d (期望: 330*5=1650)", damage4.damage))

-- 测试4: 暴击伤害
print("\n[测试4] 暴击伤害测试")
local damage5 = BattleFormula.CalcDamage(attackerData2, defenderData2, 10000, 1, true)  -- 强制暴击
print(string.format("  暴击伤害: %d (期望: 330*1.5=495)", damage5.damage))
print(string.format("  是否暴击: %s", tostring(damage5.isCrit)))

print("\n========================================")
print("伤害计算测试完成")
print("========================================")
