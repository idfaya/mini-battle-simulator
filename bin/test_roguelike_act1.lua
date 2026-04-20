package.path = package.path
    .. ";./?.lua"
    .. ";./core/?.lua"
    .. ";./modules/?.lua"
    .. ";./config/?.lua"
    .. ";./utils/?.lua"
    .. ";./ui/?.lua"
    .. ";../?.lua"
    .. ";../core/?.lua"
    .. ";../modules/?.lua"
    .. ";../config/?.lua"
    .. ";../utils/?.lua"
    .. ";../ui/?.lua"

require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")
require("modules.BattleDefaultTypesOpt")

local Run = require("modules.roguelike_run")

local function findReadyHero(snapshot)
    local battleSnapshot = snapshot and snapshot.battleSnapshot or nil
    if not battleSnapshot then
        return nil
    end
    for _, unit in ipairs(battleSnapshot.leftTeam or {}) do
        if unit.isAlive and unit.ultimateReady then
            return unit.id
        end
    end
    return nil
end

local function runBattleUntilResolved(maxSteps)
    local snapshot = Run.GetSnapshot()
    for _ = 1, maxSteps do
        local readyHeroId = findReadyHero(snapshot)
        if readyHeroId and snapshot.battleSnapshot and snapshot.battleSnapshot.pendingCommands == 0 then
            Run.QueueBattleCommand({
                type = "cast_ultimate",
                heroId = readyHeroId,
            })
        end
        Run.Tick(800)
        snapshot = Run.GetSnapshot()
        if snapshot.phase ~= "battle" then
            return snapshot
        end
    end
    error("battle did not resolve in time")
end

local function choosePathAndEnter(nodeId)
    local ok, reason = Run.ChoosePath(nodeId)
    assert(ok, "choose path failed: " .. tostring(reason))
    ok, reason = Run.EnterCurrentNode()
    assert(ok, "enter node failed: " .. tostring(reason))
end

local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900007, 900002 },
})

assert(snapshot.phase == "map", "run should start on map")
assert(#(snapshot.debug.availableNextNodeIds or {}) == 1, "start map should expose one node")

choosePathAndEnter(101001)
assert(Run.GetSnapshot().phase == "battle", "first node should be battle")
snapshot = runBattleUntilResolved(600)
assert(snapshot.phase == "reward", "first battle should open reward")
assert(Run.ChooseReward(1) == true, "reward selection should succeed")

choosePathAndEnter(101002)
assert(Run.GetSnapshot().phase == "event", "second path should open event")
assert(Run.ChooseEventOption(1) == true, "event option should resolve")
assert(Run.GetSnapshot().phase == "map", "event should return to map")

choosePathAndEnter(101004)
assert(Run.GetSnapshot().phase == "shop", "shop node should open shop")
local shopSnapshot = Run.GetSnapshot()
local originalFrontRosterId = shopSnapshot.team[1].rosterId
assert(Run.ShopBuy(101004) == true, "shop recruit should succeed")
shopSnapshot = Run.GetSnapshot()
assert(#(shopSnapshot.bench or {}) >= 1, "recruit should enter bench")
local benchRosterId = shopSnapshot.bench[1].rosterId
assert(Run.SwapBenchWithTeam(benchRosterId, originalFrontRosterId) == true, "bench swap should succeed")
shopSnapshot = Run.GetSnapshot()
assert(shopSnapshot.team[1].rosterId == benchRosterId, "bench recruit should replace target team member")
assert(#(shopSnapshot.bench or {}) >= 1, "replaced member should move to bench")
assert(Run.ShopLeave() == true, "should be able to leave shop")

choosePathAndEnter(101006)
assert(Run.GetSnapshot().phase == "camp", "camp node should open camp")
assert(Run.CampChoose(1) == true, "camp rest should work")

choosePathAndEnter(101008)
assert(Run.GetSnapshot().phase == "event", "ember shrine should open event")
assert(Run.ChooseEventOption(1) == true, "healing event option should resolve")

choosePathAndEnter(101010)
assert(Run.GetSnapshot().phase == "shop", "last stop should open shop")
assert(Run.ShopLeave() == true, "should leave final shop")

choosePathAndEnter(101011)
assert(Run.GetSnapshot().phase == "battle", "boss node should be battle")
snapshot = runBattleUntilResolved(900)
assert(snapshot.phase == "reward" or snapshot.phase == "chapter_result", "boss should resolve to reward or chapter result")
if snapshot.phase == "reward" then
    assert(Run.ChooseReward(1) == true, "boss reward selection should succeed")
    snapshot = Run.GetSnapshot()
end

assert(snapshot.phase == "chapter_result", "run should end at chapter result")
assert(snapshot.chapterResult and snapshot.chapterResult.success == true, "chapter should clear successfully")
print("roguelike act1 test passed")
