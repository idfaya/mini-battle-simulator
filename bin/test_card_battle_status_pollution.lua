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

local function makeState()
    return {
        cardLibrary = {
            version = 1,
            nextSequence = 1,
            cards = {},
        },
        cardBattle = {
            version = 1,
            turn = 1,
            phase = "player",
            seed = 1,
            shuffleCount = 0,
            baseEnergy = 3,
            maxEnergy = 3,
            teamEnergy = 3,
            energyHardCap = 6,
            handLimit = 10,
            drawCount = 0,
            guard = 0,
            enemyIntents = {
                { enemyInstanceId = 101, enemyName = "测试敌人", skillId = 1, targetIds = { 1 }, targetNames = { "英雄" } },
            },
            nextStatusSequence = 1,
            statusCreatedCount = 0,
            deck = {},
            drawPile = {},
            hand = {
                {
                    uid = "test_card_001",
                    cardId = 1,
                    name = "测试卡",
                    cost = 1,
                    type = "attack",
                    disabled = false,
                },
            },
            discardPile = {},
            exhaustPile = {},
            powers = {},
        },
    }
end

local state = makeState()
local ok, result = CardBattle.EndTurn(state, {
    executeEnemyIntent = function(_intent)
        return true, { totalDamage = 3 }
    end,
    buildEnemyIntents = function()
        return {}
    end,
    isBattleEnded = function()
        return false
    end,
})
assert_true(ok, "EndTurn should succeed: " .. tostring(result))
assert_true(state.cardBattle.statusCreatedCount == 1, "damaging enemy intent should create one status card")

local wound = nil
for _, card in ipairs(state.cardBattle.discardPile or {}) do
    if card.type == "status" and card.statusSubtype == "wound" then
        wound = card
        break
    end
end
assert_true(wound ~= nil, "wound should be added to discard pile")
assert_true(wound.transient == true, "wound should be battle-transient")
assert_true(#(state.cardLibrary.cards or {}) == 0, "wound should not enter permanent card library")

state.cardBattle.hand = { wound }
state.cardBattle.discardPile = {}
ok, result = CardBattle.PlayCard(state, wound.uid, {
    castCard = function()
        error("status card must not invoke castCard")
    end,
})
assert_true(ok == false and result == "card_unplayable", "wound should be unplayable")

local cleanState = makeState()
ok, result = CardBattle.EndTurn(cleanState, {
    executeEnemyIntent = function(_intent)
        return true, { totalDamage = 0 }
    end,
    buildEnemyIntents = function()
        return {}
    end,
    isBattleEnded = function()
        return false
    end,
})
assert_true(ok, "clean EndTurn should succeed: " .. tostring(result))
assert_true(cleanState.cardBattle.statusCreatedCount == 0, "non-damaging intent should not create wound")

print("test_card_battle_status_pollution: ok")
