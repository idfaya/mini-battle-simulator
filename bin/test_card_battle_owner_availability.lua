local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local CardBattle = require("roguelike.card_battle")

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", msg or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local runState = {
    cardBattle = {
        deck = { { ownerInstanceId = 1, disabled = false } },
        drawPile = { { ownerInstanceId = 1, disabled = false } },
        hand = { { ownerInstanceId = 1, disabled = false }, { ownerInstanceId = 2, disabled = false } },
        discardPile = { { ownerInstanceId = 1, disabled = false } },
        exhaustPile = { { ownerInstanceId = 1, disabled = false } },
        powers = { { ownerInstanceId = 1, disabled = false } },
    },
}

CardBattle.SyncOwnerAvailability(runState, {
    leftTeam = {
        { id = "1", hp = 0, isAlive = false },
        { id = "2", hp = 10, isAlive = true },
    },
})
assert_eq(runState.cardBattle.deck[1].disabled, true, "deck card should be disabled")
assert_eq(runState.cardBattle.drawPile[1].disabled, true, "draw card should be disabled")
assert_eq(runState.cardBattle.hand[1].disabled, true, "hand card should be disabled")
assert_eq(runState.cardBattle.hand[2].disabled, false, "other owner hand card should stay enabled")
assert_eq(runState.cardBattle.discardPile[1].disabled, true, "discard card should be disabled")
assert_eq(runState.cardBattle.exhaustPile[1].disabled, true, "exhaust card should be disabled")
assert_eq(runState.cardBattle.powers[1].disabled, true, "power card should be disabled")

CardBattle.SyncOwnerAvailability(runState, {
    leftTeam = {
        { id = "1", hp = 5, isAlive = true },
        { id = "2", hp = 10, isAlive = true },
    },
})
assert_eq(runState.cardBattle.hand[1].disabled, false, "revived owner hand card should be enabled")
assert_eq(runState.cardBattle.deck[1].disabled, false, "revived owner deck card should be enabled")

print("test_card_battle_owner_availability: ok")
