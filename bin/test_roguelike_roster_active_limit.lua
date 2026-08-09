local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local RoguelikeRoster = require("roguelike.roguelike_roster")

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected=%s actual=%s", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local state = {
    maxHeroCount = 4,
    ownedUnits = {},
}

for index = 1, 5 do
    state.ownedUnits[#state.ownedUnits + 1] = {
        rosterId = index,
        name = "Hero" .. tostring(index),
        teamState = "active",
    }
end

local team, bench = RoguelikeRoster.RefreshLegacyViews(state)
assert_eq(#team, 4, "active team should be capped at four")
assert_eq(#bench, 1, "overflow active unit should move to bench")
assert_eq(bench[1].rosterId, 5, "overflow unit should preserve roster order")
assert_eq(bench[1].teamState, "bench", "overflow unit should become bench")

local ok, reason = RoguelikeRoster.PromoteBenchHero(state, 5)
assert_eq(ok, false, "promote should fail when active team is full")
assert_eq(reason, "team_full", "promote failure should be team_full")

local swapped = RoguelikeRoster.SwapBenchWithTeam(state, 5, 1)
assert_eq(swapped, true, "bench unit should be able to replace active unit")
assert_eq(#RoguelikeRoster.GetTeamUnits(state), 4, "swap should keep active team capped at four")

print("test_roguelike_roster_active_limit: ok")
