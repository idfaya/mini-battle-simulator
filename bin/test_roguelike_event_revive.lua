local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local RoguelikeEvent = require("roguelike.roguelike_event")
local HeroData = require("config.hero_data")

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", msg or "assert_eq", tostring(expected), tostring(actual)))
    end
end

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local EVENT_ID = 101002
local OPTION_ID = 4

do
    local alive = HeroData.CreateClassUnit(2, { level = 3, rosterId = 1 })
    local dead = HeroData.CreateClassUnit(5, { level = 3, rosterId = 2 })
    alive.teamState = "active"
    dead.teamState = "active"
    dead.isDead = true
    dead.currentHp = 0

    local runState = {
        chapterId = 101,
        gold = 200,
        partyLevel = 3,
        ownedUnits = { alive, dead },
    }

    local ok, output = RoguelikeEvent.ResolveOption(runState, EVENT_ID, OPTION_ID)
    assert_true(ok, "event revive should succeed")
    assert_eq(runState.gold, 120, "event revive should deduct gold")
    assert_true(dead.isDead == false, "dead hero should be revived")
    assert_eq(dead.currentHp, math.floor((dead.maxHp or 0) * 0.5), "revived hero at 50% max hp")
    assert_true(type(output) == "table" and output.kind == "done", "event revive should finish as done result")
end

do
    local aliveA = HeroData.CreateClassUnit(2, { level = 3, rosterId = 1 })
    local aliveB = HeroData.CreateClassUnit(5, { level = 3, rosterId = 2 })
    aliveA.teamState = "active"
    aliveB.teamState = "active"

    local runState = {
        chapterId = 101,
        gold = 200,
        partyLevel = 3,
        ownedUnits = { aliveA, aliveB },
    }

    local ok, reason = RoguelikeEvent.ResolveOption(runState, EVENT_ID, OPTION_ID)
    assert_true(not ok and reason == "no_dead_hero", "event revive should reject when no dead hero")
    assert_eq(runState.gold, 200, "event revive should not deduct gold on failed precheck")
end

print("[OK] roguelike event revive")
