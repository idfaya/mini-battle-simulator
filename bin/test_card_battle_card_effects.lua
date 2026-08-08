local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local CardBattle = require("roguelike.card_battle")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local runState = {
    cardBattle = {
        phase = "player",
        teamEnergy = 2,
        maxEnergy = 3,
        energyHardCap = 6,
        guard = 0,
        handLimit = 10,
        drawPile = {
            {
                uid = "draw_card_1",
                name = "后续手牌",
                type = "skill",
                cost = 1,
                targetSide = "enemy",
            },
        },
        hand = {
            {
                uid = "effect_card_1",
                name = "节奏测试牌",
                type = "skill",
                cost = 1,
                targetSide = "enemy",
                guardValue = 3,
                drawCards = 1,
                energyGain = 1,
                exhaust = true,
            },
        },
        discardPile = {},
        exhaustPile = {},
        powers = {},
    },
}

local ok, result = CardBattle.PlayCard(runState, "effect_card_1")
assert_true(ok, "effect card should play: " .. tostring(result))
assert_true(runState.cardBattle.teamEnergy == 2, "energy should spend 1 then gain 1")
assert_true(runState.cardBattle.guard == 3, "guard effect should apply")
assert_true(#runState.cardBattle.hand == 1, "draw effect should add one card to hand")
assert_true(runState.cardBattle.hand[1].uid == "draw_card_1", "drawn card should be from draw pile")
assert_true(#runState.cardBattle.drawPile == 0, "draw pile should be consumed")
assert_true(#runState.cardBattle.exhaustPile == 1, "exhaust card should enter exhaust pile")
assert_true(#runState.cardBattle.discardPile == 0, "exhaust card should not enter discard pile")
assert_true(result.drawCards == 1, "result should report drawn cards")
assert_true(result.energyGain == 1, "result should report gained energy")

print("test_card_battle_card_effects: ok")
