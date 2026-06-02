-- dungeon §4.2：战斗房 / 事件房 cleared 后重入仅作通路，不再触发战斗或事件。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RoguelikeTestRoute = dofile(script_dir .. "roguelike_test_route.lua")

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

local function drainRewards()
    for _ = 1, 16 do
        local snapshot = Run.GetSnapshot()
        if snapshot.phase ~= "reward" then
            return snapshot
        end
        Run.ChooseReward(1)
    end
    error("reward chain did not finish")
end

local function runBattleUntilMap(maxSteps)
    for _ = 1, maxSteps do
        Run.Tick(800)
        local snapshot = Run.GetSnapshot()
        if snapshot.phase == "reward" then
            return drainRewards()
        elseif snapshot.phase ~= "battle" then
            return snapshot
        end
    end
    error("battle did not finish")
end

local function settleUntilMap(maxSteps)
    for _ = 1, maxSteps do
        local snapshot = Run.GetSnapshot()
        if snapshot.phase == "map" then
            return snapshot
        end
        if snapshot.phase == "battle" then
            snapshot = runBattleUntilMap(800)
        elseif snapshot.phase == "reward" then
            snapshot = drainRewards()
        elseif snapshot.phase == "event" then
            if snapshot.eventState and snapshot.eventState.result then
                local ok, reason = Run.ContinueEvent()
                assert_true(ok, "continue event: " .. tostring(reason))
            else
                local ok, reason = Run.ChooseEventOption(1)
                assert_true(ok, "choose event option: " .. tostring(reason))
            end
        elseif snapshot.phase == "shop" then
            Run.ShopLeave()
        elseif snapshot.phase == "camp" then
            Run.CampLeave()
        else
            error("unexpected phase while settling to map: " .. tostring(snapshot.phase))
        end
    end
    error("did not settle back to map")
end

-- 战斗房：打完一次后重入不再开战
do
    Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = 12345,
    })
    local snapshot = Run.GetSnapshot()
    local battleId = nil
    for _ = 1, 24 do
        battleId = findSelectableNode(snapshot, function(node)
            return node.nodeType == "battle_normal" or node.nodeType == "battle_elite"
        end)
        if battleId then
            break
        end
        local nextNodeId = findSelectableNode(snapshot, function(node)
            return true
        end)
        assert_true(nextNodeId, "need a selectable node while routing to battle")
        chooseAndEnter(nextNodeId)
        snapshot = settleUntilMap(800)
    end
    assert_true(battleId, "need a selectable battle node")

    chooseAndEnter(battleId)
    snapshot = runBattleUntilMap(800)
    assert_true(snapshot.phase == "map", "after battle should return to map")

    local viaId = findSelectableNode(snapshot, function(node)
        return node.id ~= battleId
    end)
    assert_true(viaId, "need a neighbor to route through")
    chooseAndEnter(viaId)
    snapshot = Run.GetSnapshot()
    if snapshot.phase == "event" then
        Run.ChooseEventOption(1)
        snapshot = drainRewards()
    elseif snapshot.phase == "shop" then
        Run.ShopLeave()
        snapshot = Run.GetSnapshot()
    elseif snapshot.phase == "reward" then
        -- 宝箱房等 via 邻居进入后会直接进 reward 阶段。
        snapshot = drainRewards()
    elseif snapshot.phase == "battle" then
        -- 减少空房后，via 邻居更可能是 battle；打完同样回到 map。
        snapshot = runBattleUntilMap(800)
    end

    assert_true(findSelectableNode(snapshot, function(node)
        return node.id == battleId
    end), "cleared battle room should be reachable again")

    chooseAndEnter(battleId)
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "map", "re-enter cleared battle room should stay on map")
    assert_true(not snapshot.battleSnapshot, "should not start battle again")
end

-- 事件房：选过一次后重入不再弹事件
do
    Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = 1,
    })
    local snapshot = Run.GetSnapshot()
    local eventId = nil
    for _ = 1, 64 do
        eventId = findSelectableNode(snapshot, function(node)
            return node.nodeType == "event"
        end)
        if eventId then
            break
        end
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(node)
            return node.nodeType == "event" and not node.visited
        end)
        local nextNodeId = (hop and hop.id) or findSelectableNode(snapshot, function(node)
            return true
        end)
        assert_true(nextNodeId, "need a selectable node while routing to event")
        chooseAndEnter(nextNodeId)
        snapshot = settleUntilMap(800)
    end
    assert_true(eventId, "need a selectable event node")

    chooseAndEnter(eventId)
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "event", "first event enter should open event")
    local ok, reason = Run.ChooseEventOption(1)
    assert_true(ok, "choose event option: " .. tostring(reason))
    snapshot = settleUntilMap(800)
    assert_true(snapshot.phase == "map", "event should return to map")

    local viaId = findSelectableNode(snapshot, function(node)
        return node.id ~= eventId
    end)
    assert_true(viaId, "need a neighbor to route through")
    chooseAndEnter(viaId)
    snapshot = Run.GetSnapshot()
    if snapshot.phase == "battle" then
        snapshot = runBattleUntilMap(400)
    elseif snapshot.phase == "shop" then
        Run.ShopLeave()
        snapshot = Run.GetSnapshot()
    elseif snapshot.phase == "reward" then
        snapshot = drainRewards()
    end

    chooseAndEnter(eventId)
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "map", "re-enter cleared event room should stay on map")
    assert_true(snapshot.eventState == nil, "should not reopen event")
end

print("[OK] roguelike room one-shot (battle/event)")

-- 楼梯房：下楼再上楼后，落点仍应弹出 stair phase（可再次下楼）
do
    Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = 1,
    })
    local routeState = { recentNodeIds = { 0, 0 }, lastNodeId = 0, firstBattleResolved = false }
    local snapshot = Run.GetSnapshot()
    for _ = 1, 240 do
        if snapshot.phase == "stair" and snapshot.stairState and snapshot.stairState.direction == "down" then
            break
        end
        if snapshot.phase ~= "map" and snapshot.phase ~= "stair" then
            snapshot = settleUntilMap(800)
        else
            local nextNode = RoguelikeTestRoute.chooseNextNode(snapshot, routeState)
            assert_true(nextNode, "need path to stair_down")
            Run.ChoosePath(nextNode.id)
            Run.EnterCurrentNode()
        end
        snapshot = Run.GetSnapshot()
    end
    assert_true(snapshot.phase == "stair", "should reach stair_down in stair phase")
    assert_true(snapshot.stairState and snapshot.stairState.direction == "down", "should offer down stair")

    assert_true(Run.StairUse() == true, "stair down should succeed")
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.currentFloorDepth == 2, "should be on floor 2 after down")
    assert_true(snapshot.phase == "stair", "floor 2 up-stair landing should open stair phase")
    assert_true(snapshot.stairState and snapshot.stairState.direction == "up", "should offer up stair")

    assert_true(Run.StairUse() == true, "stair up should succeed")
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.currentFloorDepth == 1, "should be back on floor 1")
    assert_true(snapshot.phase == "stair", "down stair landing after going up should reopen stair phase")
    assert_true(snapshot.stairState and snapshot.stairState.direction == "down", "should offer down stair again")
end

print("[OK] roguelike stair round-trip")
