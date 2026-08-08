local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local HeroData = require("config.hero_data")
local LevelCurve = require("config.roguelike.level_curve")
local CardBattle = require("roguelike.card_battle")
local FeatPicker = require("roguelike.feat_picker")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local function findOption(session, rewardAction)
    for index, option in ipairs(session and session.options or {}) do
        if option.rewardAction == rewardAction then
            return index, option
        end
    end
    return nil, nil
end

local heroA = HeroData.CreateClassUnit(1, {
    rosterId = 101,
    unitId = "test_a",
    level = 1,
    teamState = "active",
    source = "test",
})
local heroB = HeroData.CreateClassUnit(2, {
    rosterId = 102,
    unitId = "test_b",
    level = 1,
    teamState = "active",
    source = "test",
})
heroA.feats = {}
heroB.feats = {}
if heroA.buildState then heroA.buildState.featIds = {} end
if heroB.buildState then heroB.buildState.featIds = {} end

local state = {
    ownedUnits = { heroA, heroB },
    teamRoster = { heroA, heroB },
    benchRoster = {},
    partyLevel = 1,
    partyExp = LevelCurve.GetExpThreshold(2),
    levelCap = LevelCurve.CHAPTER_LEVEL_CAP,
}

local library = CardBattle.SyncLibrary(state)
assert_true(library and #(library.cards or {}) > 0, "card library should initialize from feat projection")
local originalCount = #library.cards

local session = FeatPicker.BeginSession(state)
local upgradeIndex, upgradeOption = findOption(session, "upgrade_card")
assert_true(upgradeIndex ~= nil, "levelup session should include upgrade_card option")
local cardToUpgrade = upgradeOption.cardUid
local oldLevelSum = (tonumber(heroA.level) or 0) + (tonumber(heroB.level) or 0)
local ok, result = FeatPicker.Pick(state, upgradeIndex)
assert_true(ok, "upgrade_card pick should succeed: " .. tostring(result))
assert_true((tonumber(heroA.level) or 0) + (tonumber(heroB.level) or 0) == oldLevelSum,
    "upgrade_card should not level a hero")

local upgraded = nil
for _, card in ipairs(state.cardLibrary.cards or {}) do
    if card.uid == cardToUpgrade then
        upgraded = card
        break
    end
end
assert_true(upgraded and upgraded.upgraded == true, "selected card should be upgraded")

state.partyExp = LevelCurve.GetExpThreshold(3)
session = FeatPicker.BeginSession(state)
local removeIndex, removeOption = findOption(session, "remove_card")
assert_true(removeIndex ~= nil, "next levelup session should include remove_card option")
local cardToRemove = removeOption.cardUid
ok, result = FeatPicker.Pick(state, removeIndex)
assert_true(ok, "remove_card pick should succeed: " .. tostring(result))

local removed = nil
for _, card in ipairs(state.cardLibrary.cards or {}) do
    if card.uid == cardToRemove then
        removed = card
        break
    end
end
assert_true(removed and removed.removed == true, "selected card should be marked removed")
assert_true(#state.cardLibrary.cards == originalCount, "remove should preserve library history instead of deleting table row")

CardBattle.StartBattle(state, {
    leftTeam = {
        { id = 1, name = heroA.name, hp = 10, isAlive = true },
        { id = 2, name = heroB.name, hp = 10, isAlive = true },
    },
})
for _, card in ipairs(state.cardBattle.deck or {}) do
    assert_true(card.uid ~= cardToRemove, "removed card should not enter battle deck")
end

print("test_card_library_rewards: ok")
