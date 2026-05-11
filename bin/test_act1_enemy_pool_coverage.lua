local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local RunEncounterGroup = require("config.roguelike.run_encounter_group")

local function assert_true(cond, message)
    if not cond then
        io.stderr:write("ASSERT FAIL: " .. tostring(message) .. "\n")
        os.exit(1)
    end
end

local encounterIds = { 101001, 101002, 101003, 101101, 101102, 101103, 101104, 101201 }
local usedEnemyIds = {}

for _, encounterId in ipairs(encounterIds) do
    local encounter = RunEncounterGroup.GetEncounter(encounterId)
    assert_true(encounter ~= nil, "encounter exists: " .. tostring(encounterId))
    for _, enemyId in ipairs(encounter.enemyIds or {}) do
        usedEnemyIds[tonumber(enemyId)] = true
    end
end

assert_true(usedEnemyIds[910010] == true, "Act1 should include paladin enemy 910010")
assert_true(usedEnemyIds[910011] == true, "Act1 should include barbarian enemy 910011")

print("Act1 enemy pool coverage test passed.")
