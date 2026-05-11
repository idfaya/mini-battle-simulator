local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyData = require("config.enemy_data")

local function log(msg)
    print(msg)
end

local function assert_true(cond, name)
    if not cond then
        io.stderr:write("ASSERT FAIL: " .. name .. "\n")
        os.exit(1)
    else
        log("ASSERT OK  : " .. name)
    end
end

local function assert_array_equals(actual, expected, name)
    assert_true(type(actual) == "table", name .. " (actual is table)")
    assert_true(#actual == #expected, name .. " (size)")
    for i = 1, #expected do
        assert_true(tonumber(actual[i]) == tonumber(expected[i]), name .. " (index " .. i .. ")")
    end
end

local expected = {
    [910001] = { classId = 3, skillIds = { 80003011 } },
    [910002] = { classId = 1, skillIds = { 80001011, 80001101 } },
    [910003] = { classId = 2, skillIds = { 80002001, 80002104 } },
    [910004] = { classId = 2, skillIds = { 80002001, 80002005, 80002105 } },
    [910005] = { classId = 7, skillIds = { 80007001, 80007003 } },
    [910006] = { classId = 8, skillIds = { 80008001, 80008003 } },
    [910007] = { classId = 9, skillIds = { 80009001, 80009003 } },
    [910008] = { classId = 5, skillIds = { 80005011 } },
    [910009] = { classId = 6, skillIds = { 80006011 } },
    [910010] = { classId = 4, skillIds = { 80004011, 80004102 } },
    [910011] = { classId = 10, skillIds = { 80010011, 80010101 } },
}

for enemyId, spec in pairs(expected) do
    local enemy = EnemyData.GetEnemy(enemyId)
    assert_true(enemy ~= nil, "Enemy exists: " .. tostring(enemyId))
    assert_true(tonumber(enemy.Class) == spec.classId, "Enemy class matches: " .. tostring(enemyId))
    assert_array_equals(enemy.SkillIDs or {}, spec.skillIds, "Enemy skills match: " .. tostring(enemyId))
end

log("Enemy skill alignment tests passed.")
