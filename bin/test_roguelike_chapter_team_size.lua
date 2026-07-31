local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")

local function assert_eq(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local chapterTeamSize = {
    [101] = 4,
    [102] = 5,
    [103] = 6,
}

for chapterId, teamSize in pairs(chapterTeamSize) do
    local snapshot = Run.StartRun({ chapterId = chapterId, seed = chapterId })
    assert_eq(#(snapshot.team or {}), teamSize, "chapter should start with configured team size")
    assert_eq(snapshot.maxHeroCount, teamSize, "chapter max hero count should match configured team size")
end

print("[OK] roguelike chapter team size")
