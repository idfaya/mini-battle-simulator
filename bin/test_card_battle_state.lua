local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local function findSelectableNode(snapshot, pred)
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if node.selectable and pred(node) then
            return node.id
        end
    end
    return nil
end

local function chooseAndEnter(nodeId)
    local ok, reason = Run.ChoosePath(nodeId)
    assert_true(ok, "choose path: " .. tostring(reason))
    ok, reason = Run.EnterCurrentNode()
    assert_true(ok, "enter node: " .. tostring(reason))
end

local function settleNonBattle(snapshot)
    if snapshot.phase == "reward" then
        local ok, reason = Run.ChooseReward(1)
        assert_true(ok, "choose reward: " .. tostring(reason))
    elseif snapshot.phase == "event" then
        if snapshot.eventState and snapshot.eventState.result then
            local ok, reason = Run.ContinueEvent()
            assert_true(ok, "continue event: " .. tostring(reason))
        else
            local option = snapshot.eventState and snapshot.eventState.options and snapshot.eventState.options[1]
            assert_true(option, "event option missing")
            local ok, reason = Run.ChooseEventOption(option.id)
            assert_true(ok, "choose event: " .. tostring(reason))
        end
    elseif snapshot.phase == "shop" then
        local ok, reason = Run.ShopLeave()
        assert_true(ok, "shop leave: " .. tostring(reason))
    elseif snapshot.phase == "stair" then
        local ok, reason = Run.StairLeave()
        assert_true(ok, "stair leave: " .. tostring(reason))
    elseif snapshot.phase ~= "map" then
        error("unexpected phase while seeking battle: " .. tostring(snapshot.phase))
    end
end

Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = 24680,
})

local snapshot = Run.GetSnapshot()
for _ = 1, 32 do
    local battleId = findSelectableNode(snapshot, function(node)
        return node.nodeType == "battle_normal" or node.nodeType == "battle_elite" or node.nodeType == "boss"
    end)
    if battleId then
        chooseAndEnter(battleId)
        snapshot = Run.GetSnapshot()
        break
    end

    local nextId = findSelectableNode(snapshot, function()
        return true
    end)
    assert_true(nextId, "no selectable node while seeking battle")
    chooseAndEnter(nextId)
    snapshot = Run.GetSnapshot()
    settleNonBattle(snapshot)
    snapshot = Run.GetSnapshot()
end

assert_true(snapshot.phase == "battle", "expected battle phase, got " .. tostring(snapshot.phase))
assert_true(type(snapshot.cardBattle) == "table", "cardBattle missing from full snapshot")
assert_true(snapshot.cardBattle.teamEnergy == 4, "teamEnergy should start at 4 for a four-hero team")
assert_true(snapshot.cardBattle.maxEnergy == 4, "maxEnergy should start at 4 for a four-hero team")
assert_true(#(snapshot.cardBattle.deck or {}) > 0, "deck should not be empty")
assert_true(#(snapshot.cardBattle.hand or {}) > 0, "hand should not be empty")
assert_true(snapshot.cardBattle.drawCount == 6, "drawCount should start at 6 for a four-hero team")
assert_true(#snapshot.cardBattle.hand <= 6, "opening hand should be capped by draw count")
assert_true(#(snapshot.cardBattle.enemyIntents or {}) > 0, "enemy intents should be visible")

Run.Tick(5000)
snapshot = Run.GetSnapshot()
assert_true(snapshot.phase == "battle", "card battle should not auto resolve during tick")
assert_true(#(snapshot.cardBattle.hand or {}) > 0, "hand should remain while waiting for player cards")

local lite = Run.GetSnapshot({ lite = true })
assert_true(type(lite.cardBattle) == "table", "cardBattle missing from lite snapshot")
assert_true(#(lite.cardBattle.hand or {}) == #snapshot.cardBattle.hand, "lite hand count mismatch")

local firstCard = nil
for _, card in ipairs(snapshot.cardBattle.hand or {}) do
    if card.targetSide == "enemy" then
        firstCard = card
        break
    end
end
firstCard = firstCard or snapshot.cardBattle.hand[1]
assert_true(firstCard and firstCard.uid, "first hand card missing uid")
local targetId = nil
if firstCard.targetSide == "enemy" then
    for _, enemy in ipairs(snapshot.battleSnapshot and snapshot.battleSnapshot.rightTeam or {}) do
        if enemy.isAlive then
            targetId = enemy.id
            break
        end
    end
elseif firstCard.targetSide == "ally" then
    for _, ally in ipairs(snapshot.battleSnapshot and snapshot.battleSnapshot.leftTeam or {}) do
        if ally.isAlive then
            targetId = ally.id
            break
        end
    end
else
    targetId = firstCard.ownerInstanceId
end
assert_true(targetId, "explicit target missing")
local energyBefore = snapshot.cardBattle.teamEnergy
local handBefore = #snapshot.cardBattle.hand
local discardBefore = snapshot.cardBattle.discardPileCount or 0
local exhaustBefore = snapshot.cardBattle.exhaustPileCount or 0
local powerBefore = #(snapshot.cardBattle.powers or {})
local ok, result = nil, nil
if firstCard.targetSide == "enemy" then
    local invalidTargetId = nil
    for _, ally in ipairs(snapshot.battleSnapshot and snapshot.battleSnapshot.leftTeam or {}) do
        if ally.isAlive then
            invalidTargetId = ally.id
            break
        end
    end
    assert_true(invalidTargetId, "invalid target fixture missing")
    ok, result = Run.PlayCard(firstCard.uid, invalidTargetId)
    assert_true(not ok, "enemy card should reject ally target")
    assert_true(result == "target_invalid", "unexpected invalid target reason: " .. tostring(result))
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.cardBattle.teamEnergy == energyBefore, "invalid target should not spend energy")
    assert_true(#snapshot.cardBattle.hand == handBefore, "invalid target should not remove hand card")
end
ok, result = Run.PlayCard(firstCard.uid, targetId)
assert_true(ok, "play card failed: " .. tostring(result))
assert_true(type(result.cast) == "table", "play card should invoke skill runtime")
assert_true(result.cast.skillId == firstCard.skillId, "cast skillId mismatch")
snapshot = Run.GetSnapshot()
assert_true(snapshot.cardBattle.teamEnergy == energyBefore - (firstCard.cost or 0), "teamEnergy did not decrease by card cost")
assert_true(#snapshot.cardBattle.hand == handBefore - 1, "hand count did not decrease")
local movedCount = (snapshot.cardBattle.discardPileCount or 0) - discardBefore
    + (snapshot.cardBattle.exhaustPileCount or 0) - exhaustBefore
    + #(snapshot.cardBattle.powers or {}) - powerBefore
assert_true(movedCount == 1, "played card did not move to a destination pile")

local turnBefore = snapshot.cardBattle.turn
ok, result = Run.EndTurn()
assert_true(ok, "end turn failed: " .. tostring(result))
snapshot = Run.GetSnapshot()
if snapshot.phase == "battle" then
    assert_true(snapshot.cardBattle.phase == "player", "expected next player turn")
    assert_true(snapshot.cardBattle.turn == turnBefore + 1, "turn did not advance")
    assert_true(snapshot.cardBattle.teamEnergy == snapshot.cardBattle.maxEnergy, "teamEnergy should refresh")
    assert_true(#(snapshot.cardBattle.hand or {}) > 0, "new player turn should draw hand")
    assert_true(#(snapshot.cardBattle.enemyIntents or {}) > 0, "next turn enemy intents should refresh")
end

print("test_card_battle_state: ok")
