local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local ChapterClearPrep = require("roguelike.chapter_clear_prep")

local function assert_eq(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local runState = {
    teamRoster = {
        { rosterId = 1, name = "Fighter", teamState = "active", maxHp = 40, currentHp = 12, isDead = false },
        { rosterId = 2, name = "Cleric", teamState = "active", maxHp = 30, currentHp = 0, isDead = true },
        { rosterId = 3, name = "Wizard", teamState = "active", maxHp = 20, currentHp = 0, isDead = true },
    },
    benchRoster = {
        { rosterId = 4, name = "Bench", teamState = "bench", maxHp = 25, currentHp = 1, isDead = true },
    },
}

local changed = ChapterClearPrep.Apply(runState, {
    healPct = 1.00,
    reviveCount = 1,
    revivePct = 0.50,
})

assert_eq(changed, true, "chapter clear prep should change state")
assert_eq(runState.teamRoster[1].currentHp, 40, "living hero should heal to full")
assert_eq(runState.teamRoster[2].isDead, false, "one dead team member should revive")
assert_eq(runState.teamRoster[2].currentHp, 15, "revived hero should return at 50% max HP")
assert_eq(runState.teamRoster[3].isDead, true, "only one dead team member should revive")
assert_eq(runState.benchRoster[1].isDead, true, "bench unit should not be affected")

print("[OK] roguelike chapter clear prep")
