local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local CardBattle = require("roguelike.card_battle")
local RoguelikeReward = require("roguelike.roguelike_reward")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local runState = {
    seed = 1,
    currentNodeId = 1,
    currentBattleId = 101001,
    teamRoster = {
        {
            rosterId = 1,
            heroId = 1001,
            unitId = "hero_1",
            name = "测试英雄",
            classId = 2,
            teamState = "active",
            currentHp = 20,
            isDead = false,
            feats = {},
        },
    },
    cardLibrary = {
        version = 1,
        nextSequence = 2,
        cards = {
            {
                uid = "runlib_card_0001",
                cardId = 1,
                sourceKey = "manual:1",
                name = "测试打击",
                description = "测试用可复制 Card。",
                ownerRosterId = 1,
                ownerInstanceId = "hero_1",
                ownerHeroId = 1001,
                ownerName = "测试英雄",
                ownerClassId = 2,
                cost = 1,
                type = "attack",
                targetSide = "enemy",
                targetMode = "",
                targetCount = 0,
                disabled = false,
                removed = false,
                upgraded = false,
                upgradeLevel = 0,
            },
        },
    },
}

local rewardState = RoguelikeReward.GenerateCardRewardState(runState, { source = "test" })
assert_true(rewardState ~= nil, "card reward state should be generated")
assert_true(rewardState.kind == "card_reward", "reward kind mismatch")
assert_true(#rewardState.options >= 3, "card reward should include copy/greed/skip options")

local copyOptionIndex = nil
local greedOptionIndex = nil
for index, option in ipairs(rewardState.options or {}) do
    if option.rewardType == "copy_card" then
        copyOptionIndex = index
    elseif option.rewardType == "copy_card_curse" then
        greedOptionIndex = index
    end
end
assert_true(copyOptionIndex ~= nil, "copy_card option missing")
assert_true(greedOptionIndex ~= nil, "copy_card_curse option missing")

local ok, result = RoguelikeReward.ApplyReward(runState, rewardState, copyOptionIndex)
assert_true(ok, "copy card reward failed: " .. tostring(result))
local copied = nil
for _, card in ipairs(runState.cardLibrary.cards or {}) do
    if card.sourceKey and tostring(card.sourceKey):find(":copy:", 1, true) then
        copied = card
        break
    end
end
assert_true(copied ~= nil, "copy reward should add one permanent card copy")
assert_true(copied.type ~= "status" and copied.type ~= "curse", "copy should preserve a playable card type")
assert_true(copied.uid ~= "runlib_card_0001", "copy should allocate new uid")

rewardState = RoguelikeReward.GenerateCardRewardState(runState, { source = "test" })
greedOptionIndex = nil
for index, option in ipairs(rewardState.options or {}) do
    if option.rewardType == "copy_card_curse" then
        greedOptionIndex = index
        break
    end
end
ok, result = RoguelikeReward.ApplyReward(runState, rewardState, greedOptionIndex)
assert_true(ok, "greed card reward failed: " .. tostring(result))

local curse = nil
for _, card in ipairs(runState.cardLibrary.cards or {}) do
    if card.type == "curse" then
        curse = card
        break
    end
end
assert_true(curse ~= nil, "greed reward should add a permanent curse")
assert_true(curse.transient ~= true, "curse should not be transient")

local battleSnapshot = {
    leftTeam = {
        { id = "hero_1", name = "测试英雄", isAlive = true, hp = 20 },
    },
}
CardBattle.StartBattle(runState, battleSnapshot)
local foundCurse = nil
for _, card in ipairs(runState.cardBattle.deck or {}) do
    if card.type == "curse" then
        foundCurse = card
        break
    end
end
assert_true(foundCurse ~= nil, "permanent curse should enter battle deck")

runState.cardBattle.hand = { foundCurse }
runState.cardBattle.phase = "player"
runState.cardBattle.teamEnergy = 3
ok, result = CardBattle.PlayCard(runState, foundCurse.uid, {
    castCard = function()
        error("curse must not invoke castCard")
    end,
})
assert_true(ok == false and result == "card_unplayable", "curse should be unplayable")

print("test_card_reward_curse: ok")
