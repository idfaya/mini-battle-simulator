-- dungeon §4.2：战斗房 / 事件房 cleared 后重入仅作通路，不再触发战斗或事件。
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

-- 战斗房：打完一次后重入不再开战
do
    Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = 20260520,
    })
    local snapshot = Run.GetSnapshot()
    local battleId = findSelectableNode(snapshot, function(node)
        return node.nodeType == "battle_normal" or node.nodeType == "battle_elite"
    end)
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
        seed = 88001,
    })
    local snapshot = Run.GetSnapshot()
    local eventId = findSelectableNode(snapshot, function(node)
        return node.nodeType == "event"
    end)
    assert_true(eventId, "need a selectable event node")

    chooseAndEnter(eventId)
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "event", "first event enter should open event")
    Run.ChooseEventOption(1)
    snapshot = drainRewards()
    if snapshot.phase == "reward" then
        snapshot = drainRewards()
    end
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
    end

    chooseAndEnter(eventId)
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "map", "re-enter cleared event room should stay on map")
    assert_true(snapshot.eventState == nil, "should not reopen event")
end

print("[OK] roguelike room one-shot (battle/event)")
