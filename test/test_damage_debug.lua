---
--- 调试伤害计算
---

package.path = package.path .. ";./?.lua;./core/?.lua;./modules/?.lua;./config/?.lua;./utils/?.lua"

print("========================================")
print("调试伤害计算")
print("========================================")

-- 先加载全局定义
require("core.battle_enum")

-- 加载必要模块
local BattleFormula = require("core.battle_formula")
local BattleAttribute = require("modules.battle_attribute")

-- 初始化公式
BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)

-- 模拟战斗中的英雄（没有attributes结构）
local enemy = {
    name = "Enemy_10321607",
    atk = 400,
    def = 200,
    critRate = 1500,
}

local hero = {
    name = "Hero_13103",
    atk = 800,
    def = 350,
    critRate = 2000,
}

print("\n[敌人属性]")
print(string.format("  enemy.atk = %d", enemy.atk))
print(string.format("  enemy.def = %d", enemy.def))
print(string.format("  enemy.critRate = %d", enemy.critRate))

print("\n[英雄属性]")
print(string.format("  hero.atk = %d", hero.atk))
print(string.format("  hero.def = %d", hero.def))
print(string.format("  hero.critRate = %d", hero.critRate))

-- 检查GetAttribute返回值
print("\n[BattleAttribute.GetAttribute 返回值]")
print(string.format("  GetAttribute(enemy, ATK) = %d (期望: 400)", 
    BattleAttribute.GetAttribute(enemy, BattleAttribute.ATTR_ID.ATK)))
print(string.format("  GetAttribute(enemy, CRIT_RATE) = %d (期望: 1500)", 
    BattleAttribute.GetAttribute(enemy, BattleAttribute.ATTR_ID.CRIT_RATE)))
print(string.format("  GetAttribute(hero, DEF) = %d (期望: 350)", 
    BattleAttribute.GetAttribute(hero, BattleAttribute.ATTR_ID.DEF)))

-- 手动构建数据（模拟CalculateDamageWithRate的做法）
local config = BattleFormula.GetConfig()
local attackerData = {
    attrs = {
        [config.attrType.ATK] = BattleAttribute.GetAttribute(enemy, BattleAttribute.ATTR_ID.ATK) or enemy.atk or 0,
        [config.attrType.CRIT] = BattleAttribute.GetAttribute(enemy, BattleAttribute.ATTR_ID.CRIT_RATE) or enemy.critRate or 0,
    },
}

local defenderData = {
    attrs = {
        [config.attrType.DEF] = BattleAttribute.GetAttribute(hero, BattleAttribute.ATTR_ID.DEF) or hero.def or 0,
    },
}

print("\n[构建的公式数据]")
print(string.format("  attackerData.attrs[ATK] = %d", attackerData.attrs[config.attrType.ATK]))
print(string.format("  attackerData.attrs[CRIT] = %d", attackerData.attrs[config.attrType.CRIT]))
print(string.format("  defenderData.attrs[DEF] = %d", defenderData.attrs[config.attrType.DEF]))

-- 计算基础伤害
local baseDamage = (attackerData.attrs[config.attrType.ATK] - defenderData.attrs[config.attrType.DEF])
print(string.format("\n  基础伤害计算: %d - %d = %d", 
    attackerData.attrs[config.attrType.ATK],
    defenderData.attrs[config.attrType.DEF],
    baseDamage))

-- 计算实际伤害
local damageResult = BattleFormula.CalcDamage(attackerData, defenderData, 10000, 1)
print(string.format("\n[最终伤害结果]"))
print(string.format("  伤害: %d", damageResult.damage))
print(string.format("  是否暴击: %s", tostring(damageResult.isCrit)))

print("\n========================================")
print("调试完成")
print("========================================")
