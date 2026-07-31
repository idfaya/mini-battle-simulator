--- 真战推图统计：用 driver 但 autoWinBattles=false，跑真战，统计 Boss 击破率 / 团灭层 / 血线。
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

local results = {}
local bossCleared, wiped, otherEnd = 0, 0, 0
local floorWipeCount = {}  -- floorDepth -> count
local battleWipeCount = {} -- battleId -> count
local floorEnterHpSum, floorEnterHpN = {}, {}

local function recordWipe(depth, battleId)
    floorWipeCount[depth] = (floorWipeCount[depth] or 0) + 1
    local bid = tonumber(battleId) or 0
    if bid > 0 then
        battleWipeCount[bid] = (battleWipeCount[bid] or 0) + 1
    end
    wiped = wiped + 1
end

for offset = 0, SEED_COUNT - 1 do
    local seed = SEED_START + offset
    -- 自定义版 simulate：复用 driver 内部逻辑但 autoWinBattles=false
    Run.StartRun({ chapterId = 101, starterHeroIds = { 900005, 900001, 900007, 900002 }, seed = seed })
    local routeState = { recentNodeIds = {}, lastNodeId = nil, firstBattleResolved = false, progressionMode = "ch101_reach" }
    local hpTrack = {}
    local maxFloor, finalFloor = 1, 1
    local outcome = "unknown"
    local rushBoss = true
    local lastFloorObserved = 0

    for guard = 1, 4000 do
        local snap = Run.GetSnapshot()
        local depth = tonumber(snap.currentFloorDepth) or 1
        if depth > maxFloor then maxFloor = depth end
        finalFloor = depth
        if depth ~= lastFloorObserved then
            -- 进入新层
            local hpRatio = teamHpRatio(snap)
            floorEnterHpSum[depth] = (floorEnterHpSum[depth] or 0) + hpRatio
            floorEnterHpN[depth] = (floorEnterHpN[depth] or 0) + 1
            lastFloorObserved = depth
        end
        if snap.phase == "failed" then
            outcome = "wipe"
            recordWipe(depth, snap.currentBattleId or (snap.lastBattleSummary and snap.lastBattleSummary.battleId))
            break
        end
        if snap.phase == "chapter_result" or (tonumber(snap.chapterId) or 101) > 101 then
            outcome = "boss_clear"
            bossCleared = bossCleared + 1
            break
        end

        if snap.phase == "map" then
            local nextNode = RoguelikeTestRoute.chooseNextNode(snap, routeState)
            if not nextNode then
                -- #region debug-point E:no-next-node
                Driver.ReportDebugEvent("E", "test_roguelike_real_combat_balance.lua:no_next_node", "route ended without next node", {
                    seed = seed,
                    phase = tostring(snap.phase),
                    floor = depth,
                    partyLevel = tonumber(snap.partyLevel) or 0,
                    maxFloor = maxFloor,
                })
                -- #endregion
                break
            end
            Run.ChoosePath(nextNode.id)
            Run.EnterCurrentNode()
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
                recordWipe(depth, battleId or snap.currentBattleId or (snap.lastBattleSummary and snap.lastBattleSummary.battleId))
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
    if outcome == "unknown" then
        -- #region debug-point E:unknown-outcome
        Driver.ReportDebugEvent("E", "test_roguelike_real_combat_balance.lua:unknown_outcome", "real combat balance ended as unknown", {
            seed = seed,
            phase = tostring(Run.GetSnapshot().phase),
            floor = finalFloor,
            maxFloor = maxFloor,
            partyLevel = tonumber(Run.GetSnapshot().partyLevel) or 0,
        })
        -- #endregion
        otherEnd = otherEnd + 1
    end
    results[#results + 1] = { seed = seed, outcome = outcome, finalFloor = finalFloor, maxFloor = maxFloor }
end

print(string.format("[ch101 real-combat] seeds=%d..%d", SEED_START, SEED_START + SEED_COUNT - 1))
print(string.format("  bossClear=%d/%d (%.1f%%)  wiped=%d  other=%d",
    bossCleared, SEED_COUNT, bossCleared * 100 / SEED_COUNT, wiped, otherEnd))

print("  Wipe distribution by floor:")
for d = 1, 5 do
    if (floorWipeCount[d] or 0) > 0 then
        print(string.format("    floor %d: %d wipes", d, floorWipeCount[d]))
    end
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

print("  Avg HP ratio entering each floor:")
for d = 1, 5 do
    if (floorEnterHpN[d] or 0) > 0 then
        print(string.format("    floor %d: %.1f%% (n=%d)", d,
            floorEnterHpSum[d] / floorEnterHpN[d] * 100, floorEnterHpN[d]))
    end
end

print("  Per-seed outcomes:")
for _, r in ipairs(results) do
    print(string.format("    seed=%d outcome=%s finalFloor=%d maxFloor=%d",
        r.seed, r.outcome, r.finalFloor, r.maxFloor))
end
