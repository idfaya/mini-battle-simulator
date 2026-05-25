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
local floorEnterHpSum, floorEnterHpN = {}, {}

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
            floorWipeCount[depth] = (floorWipeCount[depth] or 0) + 1
            wiped = wiped + 1
            break
        end
        if snap.phase == "chapter_result" or (tonumber(snap.chapterId) or 101) > 101 then
            outcome = "boss_clear"
            bossCleared = bossCleared + 1
            break
        end

        if snap.phase == "map" then
            local nextNode = RoguelikeTestRoute.chooseNextNode(snap, routeState)
            if not nextNode then break end
            Run.ChoosePath(nextNode.id)
            Run.EnterCurrentNode()
            routeState.recentNodeIds[2] = routeState.recentNodeIds[1]
            routeState.recentNodeIds[1] = routeState.lastNodeId
            routeState.lastNodeId = nextNode.id
            if nextNode.nodeType == "battle_normal" or nextNode.nodeType == "battle_elite" or nextNode.nodeType == "boss" then
                routeState.firstBattleResolved = true
            end
        elseif snap.phase == "battle" then
            snap = Driver.runBattleUntilResolved(Run, 900, 800)
            if snap.phase == "failed" then
                outcome = "wipe"
                floorWipeCount[depth] = (floorWipeCount[depth] or 0) + 1
                wiped = wiped + 1
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
        elseif snap.phase == "camp" then
            if Run.CampChoose(2) ~= true then Run.CampLeave() end
        elseif snap.phase == "stair" then
            local stair = snap.stairState or {}
            if stair.direction == "down" then
                Run.StairUse()
            else
                Run.StairLeave()
            end
        end
    end
    if outcome == "unknown" then otherEnd = otherEnd + 1 end
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
