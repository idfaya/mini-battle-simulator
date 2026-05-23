local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Events = require("config.tables.events")
local RunEventConfig = require("config.roguelike.run_event_config")

local function assertHasZeroRisk(event)
    for _, opt in ipairs(event.options or {}) do
        if opt.zeroRisk then
            return true
        end
    end
    return false
end

local all = Events.AllEvents()
local count = 0
for _ in pairs(all) do
    count = count + 1
end
assert(count >= 12, "events.json should define at least 12 events, got " .. tostring(count))

local legacy = Events.GetEvent(101001)
assert(legacy and legacy.title == "破损商队", "101001 title should match migrated entry")
assert(legacy.chapterId == 101, "chapterId should derive from chapterIds")
assert(#legacy.chapterIds >= 1, "chapterIds should be preserved")
assert(legacy.options[1].resultType == "grant_gold", "legacy option should keep grant_gold")

local skillEvent = Events.GetEvent(101004)
assert(skillEvent, "101004 should exist")
assert(skillEvent.options[2].skillCheck and skillEvent.options[2].skillCheck.dc == 12,
    "skillCheck metadata should load for D2-T2")
assert(assertHasZeroRisk(skillEvent), "each event should expose a zeroRisk option")

assert(RunEventConfig.GetEvent(101003).code == "sealed_armory", "run_event_config should forward to JSON SSOT")
assert(RunEventConfig.EVENTS[101002].title == "余烬圣坛", "EVENTS table should proxy AllEvents")

print(string.format("events json loader test passed (count=%d)", count))
