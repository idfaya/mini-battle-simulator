local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Act1BossPrep = require("roguelike.act1_boss_prep")

local function assert_eq(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local runState = {
    chapterId = 101,
    teamRoster = {
        { rosterId = 1, name = "Fighter", teamState = "active", maxHp = 40, currentHp = 10, isDead = false, skillCooldowns = { [1] = 2 }, ultimateCharges = 0 },
        { rosterId = 2, name = "Cleric", teamState = "active", maxHp = 30, currentHp = 0, isDead = true, skillCooldowns = { [2] = 3 }, ultimateCharges = 0 },
        { rosterId = 3, name = "Wizard", teamState = "active", maxHp = 20, currentHp = 18, isDead = false, skillCooldowns = { [3] = 4 }, ultimateCharges = 0 },
    },
    benchRoster = {
        { rosterId = 4, name = "Bench", teamState = "bench", maxHp = 25, currentHp = 1, isDead = true },
    },
}

assert_eq(Act1BossPrep.Apply(runState), true, "first prep should change state")
assert_eq(runState.act1BossPrepUsed, true, "prep should mark used")
assert_eq(runState.teamRoster[1].currentHp, 24, "living hero should heal 35% max HP")
assert_eq(runState.teamRoster[1].skillCooldowns[1], 2, "prep should not clear cooldown")
assert_eq(runState.teamRoster[1].ultimateCharges, 0, "prep should not restore ultimate charges")
assert_eq(runState.teamRoster[2].isDead, false, "prep should revive one dead team member")
assert_eq(runState.teamRoster[2].currentHp, 15, "revived hero should return at 50% max HP")
assert_eq(runState.teamRoster[3].currentHp, 20, "living hero heal should cap at max HP")
assert_eq(runState.benchRoster[1].isDead, true, "prep should not affect bench units")

runState.teamRoster[1].currentHp = 1
runState.teamRoster[2].isDead = true
runState.teamRoster[2].currentHp = 0
assert_eq(Act1BossPrep.Apply(runState), false, "second prep should be ignored")
assert_eq(runState.teamRoster[1].currentHp, 1, "second prep should not heal")
assert_eq(runState.teamRoster[2].isDead, true, "second prep should not revive")

print("[OK] roguelike act1 boss prep")
