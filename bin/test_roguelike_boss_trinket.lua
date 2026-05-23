local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local RoguelikeTrinket = require("roguelike.trinket")
local RunTrinketConfig = require("config.roguelike.run_trinket_config")

local runState = { seed = 42, trinketIds = {} }
local id = RunTrinketConfig.RollChapterTrinket(101, runState.seed)
assert(id, "chapter 101 should have trinket pool")
assert(RoguelikeTrinket.Grant(runState, id) == true, "grant trinket")
assert(#runState.trinketIds == 1, "should have one trinket")
assert(RoguelikeTrinket.GrantChapterBoss(runState, 102, false) == true, "boss grant")
assert(#runState.trinketIds == 2, "boss grant should add second trinket")

print("[OK] roguelike boss trinket")
