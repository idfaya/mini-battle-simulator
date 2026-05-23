-- D2-T4：营地房一键结算（全队回满 + 清状态 + 复活 1）
local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RoguelikeCamp = require("roguelike.roguelike_camp")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local HeroData = require("config.hero_data")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local function findSelectableCamp(snapshot)
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if node.selectable and node.nodeType == "camp" then
            return node.id
        end
    end
    return nil
end

-- 单元：ApplyReviveFullRest
do
    local alive = HeroData.CreateClassUnit(2, { level = 3, rosterId = 1 })
    local dead = HeroData.CreateClassUnit(5, { level = 3, rosterId = 2 })
    alive.teamState = "active"
    dead.teamState = "active"
    alive.currentHp = math.floor((alive.maxHp or 1) * 0.4)
    alive.debuffs = { { id = 1 } }
    alive.statuses = { downed = true }
    dead.isDead = true
    dead.currentHp = 0

    local runState = {
        blessingIds = {},
        ownedUnits = { alive, dead },
    }
    for blessingId in pairs(RunBlessingConfig.BLESSINGS or {}) do
        local entry = RunBlessingConfig.GetBlessing(blessingId)
        local tags = entry and entry.tags or {}
        local isCurse = false
        for _, tag in ipairs(tags) do
            if tag == "curse" then
                isCurse = true
                break
            end
        end
        if isCurse then
            runState.blessingIds[#runState.blessingIds + 1] = blessingId
        end
    end
    local keptBlessing = (runState.blessingIds or {})[1]

    assert_true(RoguelikeCamp.ApplyReviveFullRest(runState) == true, "apply full rest")
    assert_true(alive.currentHp == alive.maxHp, "alive hero should be at full hp")
    assert_true(#(alive.debuffs or {}) == 0 and #(alive.statuses or {}) == 0, "alive hero statuses cleared")
    assert_true(dead.isDead == false and dead.currentHp == dead.maxHp, "one dead hero revived at full hp")
    if keptBlessing then
        assert_true(#runState.blessingIds == 0, "curse-tagged blessings should be removed")
    end
end

local function pickSelectable(snapshot, preferCamp)
    local fallback
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if node.selectable then
            if preferCamp and node.nodeType == "camp" then
                return node.id
            end
            fallback = fallback or node.id
        end
    end
    return fallback
end

local function advanceRun(maxSteps)
    for _ = 1, maxSteps do
        local snapshot = Run.GetSnapshot()
        if snapshot.phase == "map" then
            local nextId = pickSelectable(snapshot, true)
            if not nextId then
                return snapshot
            end
            Run.ChoosePath(nextId)
            Run.EnterCurrentNode()
        elseif snapshot.phase == "battle" then
            for _ = 1, 200 do
                Run.Tick(800)
                if Run.GetSnapshot().phase ~= "battle" then
                    break
                end
            end
        elseif snapshot.phase == "reward" then
            Run.ChooseReward(1)
        elseif snapshot.phase == "event" then
            local opts = snapshot.eventState and snapshot.eventState.options or {}
            if opts[1] then
                Run.ChooseEventOption(opts[1].id)
            end
        elseif snapshot.phase == "shop" then
            Run.ShopLeave()
        elseif snapshot.phase == "stair" then
            Run.StairLeave()
        end
    end
    return Run.GetSnapshot()
end

-- 集成：探索至营地 → 自动回 map；cleared 后仅作通路
do
    Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = 1,
    })
    local campId
    for _ = 1, 40 do
        local snapshot = Run.GetSnapshot()
        campId = findSelectableCamp(snapshot)
        if campId then
            break
        end
        advanceRun(1)
    end
    assert_true(campId, "should discover a selectable camp within exploration budget")

    local ok, reason = Run.ChoosePath(campId)
    assert_true(ok, "choose camp path: " .. tostring(reason))
    ok, reason = Run.EnterCurrentNode()
    assert_true(ok, "enter camp: " .. tostring(reason))
    local snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "map", "camp should auto-settle to map")
    assert_true(
        string.find(snapshot.lastActionMessage or "", "营地安息", 1, true) ~= nil,
        "camp message should mention rest"
    )

    for _, hero in ipairs(snapshot.team or {}) do
        if not hero.isDead then
            assert_true((hero.hp or 0) >= (hero.maxHp or 1), "team should be healed after camp")
        end
    end

    Run.ChoosePath(campId)
    Run.EnterCurrentNode()
    snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "map", "cleared camp re-enter should pass through")
    assert_true(snapshot.campState == nil, "cleared camp should not reopen camp UI state")
end

print("[OK] roguelike camp full rest")
