local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local RunBattleConfig = require("config.roguelike.run_battle_config")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")

local function assert_true(cond, message)
    if not cond then
        io.stderr:write("ASSERT FAIL: " .. tostring(message) .. "\n")
        os.exit(1)
    end
end

local battleIds = { 101001, 101002, 101003, 101101, 101102, 101103, 101104, 101201 }
local usedEnemyIds = {}

local function markEnemy(enemyId)
    local id = tonumber(enemyId)
    if id then
        usedEnemyIds[id] = true
    end
end

for _, battleId in ipairs(battleIds) do
    local battle = RunBattleConfig.GetBattle(battleId)
    assert_true(battle ~= nil, "battle exists: " .. tostring(battleId))
    for _, groupId in ipairs(battle.waveGroupIds or {}) do
        local group = RunEnemyGroup.GetGroup(groupId)
        assert_true(group ~= nil, "enemy group exists: " .. tostring(groupId))
        for _, enemyId in ipairs(group.front or {}) do
            markEnemy(enemyId)
        end
        for _, enemyId in ipairs(group.back or {}) do
            markEnemy(enemyId)
        end
        for _, enemyId in ipairs(group.elite or {}) do
            markEnemy(enemyId)
        end
        markEnemy(group.boss)
        for _, enemyId in ipairs(group.guards or {}) do
            markEnemy(enemyId)
        end
    end
    markEnemy(battle.bossId)
end

local distinctCount = 0
for _ in pairs(usedEnemyIds) do
    distinctCount = distinctCount + 1
end

assert_true(distinctCount >= 6, "Act1 fixed battles should cover at least 6 distinct enemy ids")
assert_true(usedEnemyIds[910004] == true, "Act1 fixed battles should include caster enemy 910004")
assert_true(usedEnemyIds[910007] == true, "Act1 fixed battles should include boss enemy 910007")

print("Act1 enemy pool coverage test passed.")
