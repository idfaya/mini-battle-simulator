local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local HeroData = require("config.hero_data")
local CardBattle = require("roguelike.card_battle")
local RoguelikeReward = require("roguelike.roguelike_reward")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local cleric = HeroData.CreateClassUnit(6, {
    rosterId = 1,
    unitId = "cleric_1",
    level = 5,
    teamState = "active",
    source = "test",
})
assert_true(cleric ~= nil, "cleric should be created")

local runState = {
    seed = 1,
    currentNodeId = 1,
    currentBattleId = 101001,
    teamRoster = { cleric },
    cardLibrary = {
        version = 1,
        nextSequence = 1,
        cards = {},
    },
}

local rewardState = RoguelikeReward.GenerateCardRewardState(runState, { source = "test" })
assert_true(rewardState ~= nil, "card reward state should be generated")
assert_true(rewardState.kind == "card_reward", "reward kind mismatch")

local gainOptionIndex = nil
local gainOption = nil
for index, option in ipairs(rewardState.options or {}) do
    if option.rewardType == "gain_card" then
        gainOptionIndex = index
        gainOption = option
        break
    end
end
assert_true(gainOptionIndex ~= nil, "gain_card option should be generated from reward pool")
assert_true(tonumber(gainOption.rewardCardId) ~= nil, "gain_card should carry rewardCardId")

local ok, result = RoguelikeReward.ApplyReward(runState, rewardState, gainOptionIndex)
assert_true(ok, "gain_card apply failed: " .. tostring(result))

local gained = nil
for _, card in ipairs(runState.cardLibrary.cards or {}) do
    if tostring(card.sourceKey or ""):find("reward_pool:", 1, true) then
        gained = card
        break
    end
end
assert_true(gained ~= nil, "gain_card should add a reward pool card to permanent library")
assert_true(tostring(gained.uid or ""):find("reward_card_", 1, true) == 1, "reward card should allocate reward uid")
assert_true(gained.type ~= "status" and gained.type ~= "curse", "reward card should be playable card type")
assert_true(tonumber(gained.ownerRosterId) == tonumber(cleric.rosterId), "reward card owner should be active cleric")
assert_true(tonumber(gained.skillId) == tonumber(gainOption.skillId), "reward card should keep selected skillId")

CardBattle.StartBattle(runState, {
    leftTeam = {
        { id = 11, name = cleric.name, hp = cleric.currentHp, isAlive = true },
    },
})

local foundInDeck = nil
for _, card in ipairs(runState.cardBattle.deck or {}) do
    if card.uid == gained.uid then
        foundInDeck = card
        break
    end
end
assert_true(foundInDeck ~= nil, "reward card should enter the next battle deck")
assert_true(tonumber(foundInDeck.ownerInstanceId) == 11, "reward card should bind battle instance id")

print("test_card_reward_pool: ok")
