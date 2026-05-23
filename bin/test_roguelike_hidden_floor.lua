local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local DungeonGenerator = require("roguelike.dungeon_generator")
local Run = require("roguelike.roguelike_run")
local RoguelikeTestRoute = dofile(script_dir .. "roguelike_test_route.lua")
local BattleFormation = require("modules.battle_formation")
local RoguelikeTrinket = require("roguelike.trinket")

local HIDDEN_DEPTH = DungeonGenerator.HIDDEN_FLOOR_DEPTH

local function getUltimateSkillForUnit(unitId)
    local hero = BattleFormation.FindHeroByInstanceId and BattleFormation.FindHeroByInstanceId(tonumber(unitId))
    local instances = hero and hero.skillData and hero.skillData.skillInstances
    if not instances then
        return nil
    end
    for _, skill in pairs(instances) do
        if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then
            return skill
        end
    end
end

local function runBattleUntilResolved(maxSteps)
    for _ = 1, maxSteps do
        local snapshot = Run.GetSnapshot()
        if snapshot.phase ~= "battle" then
            return snapshot
        end
        for _, unit in ipairs((snapshot.battleSnapshot and snapshot.battleSnapshot.leftTeam) or {}) do
            if unit.ultimateReady and getUltimateSkillForUnit(unit.id) then
                Run.QueueBattleCommand({ type = "cast_ultimate", heroId = unit.id })
                break
            end
        end
        Run.Tick(800)
    end
    return Run.GetSnapshot()
end

local function acceptRewards()
    for _ = 1, 32 do
        local snapshot = Run.GetSnapshot()
        if snapshot.phase ~= "reward" then
            return snapshot
        end
        Run.ChooseReward(1)
    end
    return Run.GetSnapshot()
end

local function findBossNodeId(snapshot)
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if node.floor == HIDDEN_DEPTH and node.nodeType == "boss" then
            return node.id
        end
    end
    return nil
end

local function resolveNonMapPhase(routeState)
    local snapshot = Run.GetSnapshot()
    if snapshot.phase == "battle" then
        routeState.firstBattleResolved = true
        snapshot = runBattleUntilResolved(1200)
        if snapshot.phase == "reward" then
            snapshot = acceptRewards()
        end
    elseif snapshot.phase == "reward" then
        snapshot = acceptRewards()
    elseif snapshot.phase == "event" then
        RoguelikeTestRoute.resolveEvent(Run, snapshot)
    elseif snapshot.phase == "shop" then
        Run.ShopLeave()
    elseif snapshot.phase == "camp" then
        if not Run.CampChoose(1) then
            Run.CampLeave()
        end
    elseif snapshot.phase == "stair" then
        local stair = snapshot.stairState or {}
        if stair.direction == "down" then
            Run.StairUse()
        else
            Run.StairLeave()
        end
    end
end

local function pathToNode(targetId, routeState)
    for _ = 1, 250 do
        local snapshot = Run.GetSnapshot()
        if snapshot.phase == "map" and snapshot.currentNodeId == targetId then
            return true
        end
        if snapshot.phase == "stair" and snapshot.stairState and snapshot.stairState.nodeId == targetId then
            return true
        end
        if snapshot.currentNodeId == targetId
            and (snapshot.phase == "battle" or snapshot.phase == "reward" or snapshot.phase == "event") then
            return true
        end
        if snapshot.phase ~= "map" and snapshot.phase ~= "stair" then
            resolveNonMapPhase(routeState)
        else
            local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(node)
                return node.id == targetId
            end)
            local nextNode = hop
            if not nextNode then
                nextNode = RoguelikeTestRoute.chooseNextNode(snapshot, routeState)
            end
            Run.ChoosePath(nextNode.id)
            Run.EnterCurrentNode()
            routeState.recentNodeIds[2] = routeState.recentNodeIds[1]
            routeState.recentNodeIds[1] = routeState.lastNodeId
            routeState.lastNodeId = nextNode.id
        end
    end
    snapshot = Run.GetSnapshot()
    return snapshot.phase == "map" and snapshot.currentNodeId == targetId
end

-- 1) 生成器：3~5 房 + Boss
local floor, reason = DungeonGenerator.GenerateHiddenFloor(101, 88001)
assert(floor, "hidden floor should generate: " .. tostring(reason))
local roomCount = 0
for _ in pairs(floor.rooms or {}) do
    roomCount = roomCount + 1
end
assert(roomCount >= 3 and roomCount <= 5, "hidden floor room count should be 3-5, got " .. tostring(roomCount))

-- 2) Run 注入 + 下楼 + 隐藏 Boss 双倍 trinket
math.randomseed(88002)
Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = 88002,
    testPartyLevel = 10,
})
assert(Run.TestInjectHiddenFloor() == true, "inject hidden floor should succeed")

local snapshot = Run.GetSnapshot()
assert(snapshot.hiddenFloorInjected == true, "snapshot.hiddenFloorInjected")
assert(snapshot.hiddenFloorStairRoomId, "should expose hidden stair room id")

local routeState = { firstBattleResolved = true, lastNodeId = nil, recentNodeIds = {} }
assert(pathToNode(snapshot.hiddenFloorStairRoomId, routeState) == true, "should reach hidden stair room")

snapshot = Run.GetSnapshot()
if snapshot.phase ~= "stair" then
    assert(Run.ChoosePath(snapshot.hiddenFloorStairRoomId) == true, "choose hidden stair")
    assert(Run.EnterCurrentNode() == true, "enter hidden stair room")
    snapshot = Run.GetSnapshot()
end
assert(snapshot.phase == "stair", "should open stair phase at hidden entrance")
assert(snapshot.stairState and snapshot.stairState.isHiddenEntrance == true, "stair should be hidden entrance")

assert(Run.StairUse() == true, "stair use into hidden floor")
snapshot = Run.GetSnapshot()
assert(snapshot.currentFloorDepth == HIDDEN_DEPTH, "should be on hidden floor depth")
assert(snapshot.hiddenFloorActive == true, "hiddenFloorActive after entering")

local trinketBefore = #(snapshot.trinkets or {})
local bossId = findBossNodeId(snapshot)
assert(bossId, "hidden floor should have boss node")

routeState = { firstBattleResolved = true, lastNodeId = nil, recentNodeIds = {} }
assert(pathToNode(bossId, routeState) == true, "should reach hidden boss")
snapshot = Run.GetSnapshot()
if snapshot.phase == "map" then
    assert(Run.ChoosePath(bossId) == true)
    assert(Run.EnterCurrentNode() == true)
end

assert(Run.TestForceCurrentBattleVictory() == true, "force hidden boss victory for bin regression")
snapshot = Run.GetSnapshot()
assert(snapshot.phase == "map", "hidden boss should return to map, got " .. tostring(snapshot.phase))
assert(snapshot.hiddenFloorCleared == true, "hidden floor should be cleared after boss")
assert(#(snapshot.trinkets or {}) >= trinketBefore + 2,
    string.format("hidden boss should grant double trinket (before=%d after=%d)", trinketBefore, #(snapshot.trinkets or {})))

-- 上楼回主线
snapshot = Run.GetSnapshot()
local upStairId = nil
for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
    if node.floor == HIDDEN_DEPTH and node.nodeType == "stair_up" and node.current then
        upStairId = node.id
        break
    end
end
if upStairId then
    assert(Run.ChoosePath(upStairId) == true)
    assert(Run.EnterCurrentNode() == true)
    assert(Run.StairUse() == true, "stair up back to main floor")
    snapshot = Run.GetSnapshot()
    assert(snapshot.currentFloorDepth ~= HIDDEN_DEPTH, "should leave hidden floor")
    assert(snapshot.hiddenFloorActive ~= true, "hiddenFloorActive should be false after leaving")
end

print(string.format("[OK] roguelike hidden floor (rooms=%d, double_trinket=true)", roomCount))
