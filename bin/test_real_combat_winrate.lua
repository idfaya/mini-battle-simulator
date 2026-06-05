local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RoguelikeTestRoute = dofile(script_dir .. "roguelike_test_route.lua")
local Driver = dofile(script_dir .. "roguelike_run_driver.lua")

local SEED_COUNT = 10
local cleared = 0
local failed = 0
local wiped = 0

for seed = 1, SEED_COUNT do
    local report = Driver.simulate(Run, RoguelikeTestRoute, {
        seed = seed,
        maxGuard = 2500,
        progressionMode = "ch101_reach",
        autoWinBattles = false,  -- REAL COMBAT!
        verbose = true,
    })
    local finalSnapshot = Run.GetSnapshot()
    local lastBattle = finalSnapshot.lastBattleSummary or {}
    local reason = finalSnapshot.chapterResult and finalSnapshot.chapterResult.reason or "unknown"
    if report.ch101BossCleared == true then
        cleared = cleared + 1
    elseif finalSnapshot.phase == "failed" and reason == "team_wipe" then
        wiped = wiped + 1
    else
        failed = failed + 1
    end
    print(string.format(
        "Seed %d: phase=%s reason=%s ch101BossCleared=%s battleId=%s rounds=%s",
        seed,
        finalSnapshot.phase,
        reason,
        tostring(report.ch101BossCleared == true),
        tostring(lastBattle.battleId),
        tostring(lastBattle.roundsSpent)
    ))
end

print(string.format("\nREAL COMBAT TEST: %d runs", SEED_COUNT))
print(string.format("Cleared: %d (%.1f%%)", cleared, (cleared/SEED_COUNT)*100))
print(string.format("Wiped: %d (%.1f%%)", wiped, (wiped/SEED_COUNT)*100))
print(string.format("Other Fail: %d (%.1f%%)", failed, (failed/SEED_COUNT)*100))
