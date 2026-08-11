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
local starterCountByOwner = {}
local guardStarterCount = 0
local zeroCostStarterCount = 0
local drawStarterCount = 0
local energyStarterCount = 0
local costReductionStarterCount = 0
local retainedStarterCount = 0
local exhaustedStarterCount = 0
local momentumGainStarterCount = 0
local momentumSpendStarterCount = 0
for _, card in ipairs(library.cards or {}) do
    if card.starter == true then
        local ownerKey = tostring(card.ownerRosterId)
        starterCountByOwner[ownerKey] = (starterCountByOwner[ownerKey] or 0) + 1
        if card.skillId == nil and card.guardValue and card.guardValue > 0 then
            guardStarterCount = guardStarterCount + 1
        end
        if (tonumber(card.cost) or 0) == 0 then
            zeroCostStarterCount = zeroCostStarterCount + 1
        end
        if (tonumber(card.drawCards) or 0) > 0 then
            drawStarterCount = drawStarterCount + 1
        end
        if (tonumber(card.energyGain) or 0) > 0 then
            energyStarterCount = energyStarterCount + 1
        end
        if (tonumber(card.momentumCostReduction) or 0) > 0 then
            costReductionStarterCount = costReductionStarterCount + 1
        end
        if card.retain == true then
            retainedStarterCount = retainedStarterCount + 1
        end
        if card.exhaust == true then
            exhaustedStarterCount = exhaustedStarterCount + 1
        end
        if (tonumber(card.momentumGain) or 0) > 0 then
            momentumGainStarterCount = momentumGainStarterCount + 1
        end
        if (tonumber(card.momentumSpend) or 0) > 0 then
            momentumSpendStarterCount = momentumSpendStarterCount + 1
        end
    end
end
assert_true(starterCountByOwner[tostring(heroA.rosterId)] == 4, "hero A should contribute 4 starter cards")
assert_true(starterCountByOwner[tostring(heroB.rosterId)] == 4, "hero B should contribute 4 starter cards")
assert_true(guardStarterCount == 2, "each starter hero should contribute one pure guard card")
assert_true(zeroCostStarterCount >= 2, "starter package should include setup cards")
assert_true(drawStarterCount >= 2, "starter package should include draw decisions")
assert_true(energyStarterCount >= 1 or costReductionStarterCount >= 1,
    "starter package should include energy or cost-reduction combo decisions")
assert_true(retainedStarterCount >= 1, "starter package should include retained timing decisions")
assert_true(exhaustedStarterCount >= 1, "starter package should include burst/exhaust tradeoffs")
assert_true(momentumGainStarterCount >= 2, "starter package should include setup momentum")
assert_true(momentumSpendStarterCount >= 2, "starter package should include payoff momentum")

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

local setupToUpgrade = nil
local payoffToUpgrade = nil
for _, card in ipairs(state.cardLibrary.cards or {}) do
    if card.removed ~= true and card.upgraded ~= true and (tonumber(card.momentumGain) or 0) > 0 then
        setupToUpgrade = setupToUpgrade or card
    end
    if card.removed ~= true and card.upgraded ~= true and (tonumber(card.momentumSpend) or 0) > 0 then
        payoffToUpgrade = payoffToUpgrade or card
    end
end
assert_true(setupToUpgrade ~= nil, "setup card should be available for direct upgrade")
assert_true(payoffToUpgrade ~= nil, "payoff card should be available for direct upgrade")

local setupMomentumBefore = tonumber(setupToUpgrade.momentumGain) or 0
ok, result = CardBattle.UpgradeLibraryCard(state, setupToUpgrade.uid)
assert_true(ok, "setup upgrade should succeed: " .. tostring(result))
assert_true((tonumber(setupToUpgrade.momentumGain) or 0) > setupMomentumBefore,
    "setup upgrade should increase momentum gain")

local payoffEnergyBefore = tonumber(payoffToUpgrade.momentumEnergyGain) or 0
local payoffDrawBefore = tonumber(payoffToUpgrade.momentumDrawCards) or 0
local payoffGuardBefore = tonumber(payoffToUpgrade.momentumGuardValue) or 0
local payoffDiscountBefore = tonumber(payoffToUpgrade.momentumCostReduction) or 0
ok, result = CardBattle.UpgradeLibraryCard(state, payoffToUpgrade.uid)
assert_true(ok, "payoff upgrade should succeed: " .. tostring(result))
assert_true(
    (tonumber(payoffToUpgrade.momentumEnergyGain) or 0) > payoffEnergyBefore
        or (tonumber(payoffToUpgrade.momentumDrawCards) or 0) > payoffDrawBefore
        or (tonumber(payoffToUpgrade.momentumGuardValue) or 0) > payoffGuardBefore
        or (tonumber(payoffToUpgrade.momentumCostReduction) or 0) > payoffDiscountBefore,
    "payoff upgrade should improve a momentum payoff"
)

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

local setupCard = nil
local payoffCard = nil
for _, card in ipairs(state.cardLibrary.cards or {}) do
    if card.removed ~= true and card.starter == true and (tonumber(card.momentumGain) or 0) > 0 then
        setupCard = setupCard or card
    end
    if card.removed ~= true and card.starter == true and (tonumber(card.momentumSpend) or 0) > 0 and card.skillId ~= nil then
        payoffCard = payoffCard or card
    end
end
assert_true(setupCard and payoffCard, "setup/payoff starter cards should exist")

state.cardBattle.hand = { setupCard, payoffCard }
state.cardBattle.drawPile = {}
state.cardBattle.discardPile = {}
state.cardBattle.exhaustPile = {}
state.cardBattle.teamEnergy = 1
state.cardBattle.momentum = 0

ok, result = CardBattle.PlayCard(state, setupCard.uid)
assert_true(ok, "setup card should play: " .. tostring(result))
assert_true((tonumber(state.cardBattle.momentum) or 0) >= 1, "setup card should gain momentum")

local energyBeforePayoff = state.cardBattle.teamEnergy
ok, result = CardBattle.PlayCard(state, payoffCard.uid, {
    castCard = function()
        return true, { skillId = payoffCard.skillId, totalDamage = 0 }
    end,
})
assert_true(ok, "payoff card should play: " .. tostring(result))
assert_true((tonumber(result.momentumSpend) or 0) > 0, "payoff card should spend momentum")
assert_true((tonumber(result.effectiveCost) or 0) <= math.max(0, (tonumber(payoffCard.cost) or 0) - 1),
    "payoff should receive momentum cost reduction")
assert_true((tonumber(state.cardBattle.teamEnergy) or 0) >= energyBeforePayoff - (tonumber(result.effectiveCost) or 0),
    "payoff momentum bonuses should not overspend energy")

print("test_card_library_rewards: ok")
