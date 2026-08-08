local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local BattleAttribute = require("modules.battle_attribute")
local BattleDmgHeal = require("modules.battle_dmg_heal")

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", msg or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local attacker = {
    name = "Enemy",
    isLeft = false,
    isAlive = true,
    isDead = false,
    hp = 20,
    maxHp = 20,
}
local target = {
    name = "Hero",
    isLeft = true,
    isAlive = true,
    isDead = false,
    hp = 20,
    maxHp = 20,
    tempHp = 10,
    damageReduce = 0,
}
BattleAttribute.Init(attacker, { [BattleAttribute.ATTR_ID.HP] = 20 })
BattleAttribute.Init(target, { [BattleAttribute.ATTR_ID.HP] = 20 })
target.tempHp = 10

local cardBattle = {
    phase = "enemy",
    guard = 5,
}
BattleDmgHeal.BindCardBattleGuardState(cardBattle)

BattleDmgHeal.ApplyDamage(target, 8, attacker, { damageKind = "direct" })
assert_eq(cardBattle.guard, 0, "guard should absorb first")
assert_eq(target.tempHp, 7, "tempHp should absorb damage after guard")
assert_eq(target.hp, 20, "hp should be untouched while tempHp remains")

cardBattle.guard = 4
cardBattle.phase = "player"
BattleDmgHeal.ApplyDamage(target, 4, attacker, { damageKind = "direct" })
assert_eq(cardBattle.guard, 4, "player-phase guard should not absorb incoming damage")
assert_eq(target.tempHp, 3, "tempHp should absorb when guard is inactive")
assert_eq(target.hp, 20, "hp should still be protected by tempHp")

cardBattle.phase = "enemy"
BattleDmgHeal.ApplyDamage(target, 6, attacker, { damageKind = "direct" })
assert_eq(cardBattle.guard, 0, "enemy-phase guard should consume remaining guard")
assert_eq(target.tempHp, 1, "remaining damage should spill into tempHp")
assert_eq(target.hp, 20, "hp should still be intact")

BattleDmgHeal.ApplyDamage(target, 4, attacker, { damageKind = "direct" })
assert_eq(target.tempHp, 0, "tempHp should be depleted")
assert_eq(target.hp, 17, "hp should lose damage after guard and tempHp")

BattleDmgHeal.ClearCardBattleGuardState(cardBattle)

print("test_card_battle_guard_absorb: ok")
