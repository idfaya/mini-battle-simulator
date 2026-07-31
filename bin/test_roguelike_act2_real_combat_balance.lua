--- Act2 真战统计：从 Act1 开始真实推进，统计 Act2 入口/通关失败分布。
local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RoguelikeTestRoute = dofile(script_dir .. "roguelike_test_route.lua")
local Driver = dofile(script_dir .. "roguelike_run_driver.lua")

local SEED_START = 1
local SEED_COUNT = 30

local function teamHpRatio(snapshot)
    local team = snapshot.team or {}
    if #team == 0 then return 1.0 end
    local hp, max = 0, 0
    for _, hero in ipairs(team) do
        hp = hp + math.max(tonumber(hero.hp) or 0, 0)
        max = max + (tonumber(hero.maxHp) or 0)
    end
    if max <= 0 then return 0 end
    return hp / max
end

-- Act2 诊断先使用 Act1 rush 前置，避免普通探索路线在少数地图上陷入已访问节点环，
-- 把寻路问题混入战斗平衡统计。
local USE_ACT1_RUSH_ROUTE = true

local ch101Cleared, ch102Cleared, wiped, otherEnd = 0, 0, 0, 0
local floorWipeCount = {}  -- "chapter:floor" -> count
local battleWipeCount = {} -- battleId -> count
local floorEnterHpSum, floorEnterHpN = {}, {}
local results = {}

local function floorKey(chapterId, depth)
    return string.format("%d:%d", tonumber(chapterId) or 0, tonumber(depth) or 0)
end

local function recordFloorEnter(snapshot)
    local key = floorKey(snapshot.chapterId, snapshot.currentFloorDepth)
    floorEnterHpSum[key] = (floorEnterHpSum[key] or 0) + teamHpRatio(snapshot)
    floorEnterHpN[key] = (floorEnterHpN[key] or 0) + 1
end

local function recordWipe(snapshot, depth, battleId)
    local key = floorKey(snapshot.chapterId, depth)
    floorWipeCount[key] = (floorWipeCount[key] or 0) + 1
    local bid = tonumber(battleId) or 0
    if bid > 0 then
        battleWipeCount[bid] = (battleWipeCount[bid] or 0) + 1
    end
    wiped = wiped + 1
end

local function isSelectable(snapshot, node)
    if not node then
        return false
    end
    for _, candidate in ipairs(RoguelikeTestRoute.findSelectableNodes(snapshot)) do
        if tonumber(candidate.id) == tonumber(node.id) and candidate.current ~= true then
            return true
        end
    end
    return false
end

local function chooseSelectableFallback(snapshot)
    local selectable = {}
    for _, node in ipairs(RoguelikeTestRoute.findSelectableNodes(snapshot)) do
        if node.current ~= true then
            selectable[#selectable + 1] = node
        end
    end
    local priority = {
        stair_down = 1,
        boss = 2,
        battle_normal = 3,
        battle_elite = 4,
        event = 5,
        equip = 6,
        camp = 7,
        shop = 8,
        empty = 9,
        stair_up = 10,
        entrance = 11,
    }
    table.sort(selectable, function(a, b)
        local av = a.visited and 100 or 0
        local bv = b.visited and 100 or 0
        local ap = priority[a.nodeType] or 50
        local bp = priority[b.nodeType] or 50
        if av + ap ~= bv + bp then
            return av + ap < bv + bp
        end
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)
    return selectable[1]
end

for offset = 0, SEED_COUNT - 1 do
    local seed = SEED_START + offset
    Run.StartRun({ chapterId = 101, starterHeroIds = { 900005, 900001, 900007, 900002 }, seed = seed })
    local routeState = {
        recentNodeIds = {},
        lastNodeId = nil,
        firstBattleResolved = false,
        progressionMode = USE_ACT1_RUSH_ROUTE and "ch101_reach" or nil,
    }
    local outcome = "unknown"
    local sawCh101Clear = false
    local sawCh102Clear = false
    local maxChapter, finalChapter = 101, 101
    local maxFloor, finalFloor = 1, 1
    local finalPhase, finalReason = "map", ""
    local outcomeReason = ""
    local lastChapter = 101
    local lastFloorKey = ""

    for _ = 1, 12000 do
        local snap = Run.GetSnapshot()
        local chapterId = tonumber(snap.chapterId) or 101
        local depth = tonumber(snap.currentFloorDepth) or 1
        finalPhase = tostring(snap.phase or "")
        finalReason = tostring((snap.chapterResult and snap.chapterResult.reason) or "")
        if chapterId > maxChapter then maxChapter = chapterId end
        if depth > maxFloor then maxFloor = depth end
        finalChapter, finalFloor = chapterId, depth
        if chapterId ~= lastChapter then
            routeState = { recentNodeIds = {}, lastNodeId = nil, firstBattleResolved = false }
            lastChapter = chapterId
        end

        if chapterId > 101 and not sawCh101Clear then
            sawCh101Clear = true
            ch101Cleared = ch101Cleared + 1
        end
        if chapterId > 102 and not sawCh102Clear then
            sawCh102Clear = true
            ch102Cleared = ch102Cleared + 1
            outcome = "ch102_clear"
            break
        end

        local key = floorKey(chapterId, depth)
        if key ~= lastFloorKey then
            recordFloorEnter(snap)
            lastFloorKey = key
        end

        if snap.phase == "failed" then
            outcome = "wipe"
            recordWipe(snap, depth, snap.currentBattleId or (snap.lastBattleSummary and snap.lastBattleSummary.battleId))
            break
        end
        if snap.phase == "chapter_result" then
            outcome = "chapter_result"
            break
        end

        if snap.phase == "map" then
            local nextNode = RoguelikeTestRoute.chooseNextNode(snap, routeState)
            if not isSelectable(snap, nextNode) then
                nextNode = chooseSelectableFallback(snap)
            end
            if not nextNode then
                outcome = "no_next_node"
                break
            end
            local pathOk = Run.ChoosePath(nextNode.id)
            if pathOk ~= true then
                outcome = "choose_path_failed"
                outcomeReason = tostring(select(2, Run.ChoosePath(nextNode.id)) or "")
                break
            end
            local enterOk, enterReason = Run.EnterCurrentNode()
            if enterOk ~= true then
                outcome = "enter_node_failed"
                outcomeReason = tostring(enterReason or "")
                break
            end
            routeState.recentNodeIds[2] = routeState.recentNodeIds[1]
            routeState.recentNodeIds[1] = routeState.lastNodeId
            routeState.lastNodeId = nextNode.id
            if nextNode.nodeType == "battle_normal" or nextNode.nodeType == "battle_elite" or nextNode.nodeType == "boss" then
                routeState.firstBattleResolved = true
            end
        elseif snap.phase == "battle" then
            local battleId = snap.currentBattleId
            snap = Driver.runBattleUntilResolved(Run, 900, 800)
            if snap.phase == "failed" then
                outcome = "wipe"
                recordWipe(snap, depth, battleId or snap.currentBattleId or (snap.lastBattleSummary and snap.lastBattleSummary.battleId))
                break
            end
            if snap.phase == "reward" then
                Driver.acceptRewardIfPresent(Run)
            end
        elseif snap.phase == "reward" then
            Driver.acceptRewardIfPresent(Run)
        elseif snap.phase == "shop" then
            Run.ShopLeave()
        elseif snap.phase == "event" then
            RoguelikeTestRoute.resolveEvent(Run, snap)
            local nextSnap = Run.GetSnapshot()
            if nextSnap.phase == "event" and nextSnap.eventState and nextSnap.eventState.result then
                Run.ContinueEvent()
            end
        elseif snap.phase == "camp" then
            local acted = false
            for _, action in ipairs((snap.campState and snap.campState.actions) or {}) do
                if action.available ~= false and Run.CampChoose(tonumber(action.id) or 1) == true then
                    acted = true
                    break
                end
            end
            if not acted then
                Run.CampLeave()
            end
        elseif snap.phase == "stair" then
            local stair = snap.stairState or {}
            local clearedHiddenEntrance = snap.hiddenFloorCleared == true
                and tonumber(snap.currentNodeId) == tonumber(snap.hiddenFloorStairRoomId)
            local onClearedHiddenFloor = snap.hiddenFloorCleared == true
                and (tonumber(snap.currentFloorDepth) or 0) == 9
            if stair.direction == "down" then
                if clearedHiddenEntrance then
                    Run.StairLeave()
                else
                    Run.StairUse()
                end
            elseif onClearedHiddenFloor then
                Run.StairUse()
            else
                Run.StairLeave()
            end
        end
    end

    if outcome ~= "wipe" and outcome ~= "ch102_clear" then
        otherEnd = otherEnd + 1
    end
    results[#results + 1] = {
        seed = seed,
        outcome = outcome,
        finalChapter = finalChapter,
        finalFloor = finalFloor,
        maxChapter = maxChapter,
        maxFloor = maxFloor,
        finalPhase = finalPhase,
        finalReason = finalReason,
        outcomeReason = outcomeReason,
    }
end

print(string.format("[ch102 real-combat] seeds=%d..%d", SEED_START, SEED_START + SEED_COUNT - 1))
print(string.format("  ch101Clear=%d/%d (%.1f%%)  ch102Clear=%d/%d (%.1f%%)  wiped=%d  other=%d",
    ch101Cleared, SEED_COUNT, ch101Cleared * 100 / SEED_COUNT,
    ch102Cleared, SEED_COUNT, ch102Cleared * 100 / SEED_COUNT,
    wiped, otherEnd))

print("  Wipe distribution by chapter:floor:")
local floorKeys = {}
for key, _ in pairs(floorWipeCount) do
    floorKeys[#floorKeys + 1] = key
end
table.sort(floorKeys)
for _, key in ipairs(floorKeys) do
    print(string.format("    %s: %d wipes", key, floorWipeCount[key]))
end

print("  Wipe distribution by battleId:")
local battleIds = {}
for battleId, _ in pairs(battleWipeCount) do
    battleIds[#battleIds + 1] = battleId
end
table.sort(battleIds)
for _, battleId in ipairs(battleIds) do
    print(string.format("    battle %d: %d wipes", battleId, battleWipeCount[battleId]))
end

print("  Avg HP ratio entering chapter floors:")
local hpKeys = {}
for key, _ in pairs(floorEnterHpN) do
    hpKeys[#hpKeys + 1] = key
end
table.sort(hpKeys)
for _, key in ipairs(hpKeys) do
    print(string.format("    %s: %.1f%% (n=%d)", key,
        floorEnterHpSum[key] / floorEnterHpN[key] * 100, floorEnterHpN[key]))
end

print("  Per-seed outcomes:")
for _, r in ipairs(results) do
    print(string.format("    seed=%d outcome=%s final=%d:%d max=%d:%d phase=%s reason=%s detail=%s",
        r.seed, r.outcome, r.finalChapter, r.finalFloor, r.maxChapter, r.maxFloor, r.finalPhase, r.finalReason, r.outcomeReason or ""))
end
