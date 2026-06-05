package.path = package.path .. ";./?.lua"

local Bootstrap = dofile("core/lua_bootstrap.lua")
Bootstrap.SetupFromSource("@bin/test_roguelike_act23_battle_pools.lua", { includeParent = true })

local FloorsTable = require("config.tables.floors")
local RunBattlePool = require("config.roguelike.run_battle_pool")
local RunBattleTemplate = require("config.roguelike.run_battle_template")
local RunWaveGroupPool = require("config.roguelike.run_wave_group_pool")
local RunEnemyPickPool = require("config.roguelike.run_enemy_pick_pool")
local EnemyData = require("config.enemy_data")

local function assertTrue(value, message)
    if not value then
        error(message or "assertTrue failed")
    end
end

local function getFloor(floorId)
    local floor = FloorsTable.GetTemplate(floorId)
    assertTrue(floor ~= nil, "floor not found: " .. tostring(floorId))
    return floor
end

local function getPool(poolId)
    local pool = RunBattlePool.GetPool(poolId)
    assertTrue(pool ~= nil, "battle pool not found: " .. tostring(poolId))
    return pool
end

local function getTemplate(templateId)
    local template = RunBattleTemplate.GetTemplate(templateId)
    assertTrue(template ~= nil, "battle template not found: " .. tostring(templateId))
    return template
end

local function getWaveTemplate(templateId)
    local template = RunWaveGroupPool.GetTemplate(templateId)
    assertTrue(template ~= nil, "wave template not found: " .. tostring(templateId))
    return template
end

local function getEnemyPool(poolId)
    local pool = RunEnemyPickPool.GetPool(poolId)
    assertTrue(pool ~= nil, "enemy pool not found: " .. tostring(poolId))
    return pool
end

local function assertEnemyPoolLevelRange(poolId, minLevel, maxLevel, label)
    local pool = getEnemyPool(poolId)
    for _, entry in ipairs(pool.entries or {}) do
        local level = EnemyData.GetDisplayLevel(entry.enemyId)
        assertTrue(level ~= nil, ("enemy level missing for %d in %s"):format(entry.enemyId, label))
        assertTrue(level >= minLevel and level <= maxLevel,
            ("%s contains enemy %d with level %d outside [%d,%d]"):format(label, entry.enemyId, level, minLevel, maxLevel))
    end
end

local function assertChapterBattleFlow(floorId, expectedNormalPoolId, expectedElitePoolId, expectedBossPoolId)
    local floor = getFloor(floorId)
    local battlePoolIds = floor.battlePoolIds or {}
    if expectedBossPoolId then
        assertTrue(battlePoolIds.boss == expectedBossPoolId, ("floor %d boss pool mismatch"):format(floorId))
        return
    end

    assertTrue(battlePoolIds.battle_normal == expectedNormalPoolId, ("floor %d normal pool mismatch"):format(floorId))
    assertTrue(battlePoolIds.battle_elite == expectedElitePoolId, ("floor %d elite pool mismatch"):format(floorId))

    local normalPool = getPool(expectedNormalPoolId)
    local elitePool = getPool(expectedElitePoolId)
    assertTrue((normalPool.chapterId == 102 or normalPool.chapterId == 103), "normal pool chapter mismatch")
    assertTrue((elitePool.chapterId == 102 or elitePool.chapterId == 103), "elite pool chapter mismatch")

    local normalTemplate = getTemplate(normalPool.entries[1].battleTemplateId)
    local eliteTemplate = getTemplate(elitePool.entries[1].battleTemplateId)
    local normalWaveGroup = RunWaveGroupPool.GetPool(normalTemplate.waveGroupPoolId)
    local eliteWaveGroup = RunWaveGroupPool.GetPool(eliteTemplate.waveGroupPoolId)
    assertTrue(normalWaveGroup ~= nil and eliteWaveGroup ~= nil, "wave group pool missing")

    local normalWaveTemplate = getWaveTemplate(normalWaveGroup.entries[1].templateId)
    local eliteWaveTemplate = getWaveTemplate(eliteWaveGroup.entries[1].templateId)
    assertTrue(getEnemyPool(normalWaveTemplate.frontPoolId) ~= nil, "normal front pool missing")
    assertTrue(getEnemyPool(normalWaveTemplate.backPoolId) ~= nil, "normal back pool missing")
    assertTrue(getEnemyPool(eliteWaveTemplate.frontPoolId) ~= nil, "elite front pool missing")
    assertTrue(getEnemyPool(eliteWaveTemplate.backPoolId) ~= nil, "elite back pool missing")
end

assertChapterBattleFlow(10201, 102001, 102101)
assertChapterBattleFlow(10202, 102002, 102101)
assertChapterBattleFlow(10204, 102003, 102102)
assertChapterBattleFlow(10205, nil, nil, 102201)

assertChapterBattleFlow(10301, 103001, 103101)
assertChapterBattleFlow(10302, 103002, 103101)
assertChapterBattleFlow(10304, 103003, 103102)
assertChapterBattleFlow(10305, nil, nil, 103201)

assertTrue((getFloor(10101).constraints or {}).maxElite == 0, "act1 f1 should not allow elite")
assertTrue((getFloor(10201).constraints or {}).maxElite == 0, "act2 f1 should not allow elite")
assertTrue((getFloor(10301).constraints or {}).maxElite == 0, "act3 f1 should not allow elite")

assertEnemyPoolLevelRange(701001, 1, 2, "act1_f1_front")
assertEnemyPoolLevelRange(701002, 1, 2, "act1_f1_back")
assertEnemyPoolLevelRange(701003, 1, 2, "act1_f23_front")
assertEnemyPoolLevelRange(701005, 1, 2, "act1_f23_back")
assertEnemyPoolLevelRange(701004, 2, 3, "act1_f4_front")
assertEnemyPoolLevelRange(701011, 2, 3, "act1_f4_back")
assertEnemyPoolLevelRange(701202, 2, 3, "act1_boss_guard")
assertEnemyPoolLevelRange(701204, 3, 5, "act1_boss_back")

assertEnemyPoolLevelRange(702001, 2, 5, "act2_f1_front")
assertEnemyPoolLevelRange(702002, 1, 5, "act2_f1_back")
assertEnemyPoolLevelRange(702003, 3, 5, "act2_f23_front")
assertEnemyPoolLevelRange(702004, 1, 5, "act2_f23_back")
assertEnemyPoolLevelRange(702202, 3, 5, "act2_boss_guard")
assertEnemyPoolLevelRange(702203, 1, 5, "act2_boss_back")

assertEnemyPoolLevelRange(703001, 2, 5, "act3_f1_front")
assertEnemyPoolLevelRange(703002, 3, 5, "act3_f1_back")
assertEnemyPoolLevelRange(703003, 3, 5, "act3_f23_front")
assertEnemyPoolLevelRange(703004, 3, 5, "act3_f23_back")
assertEnemyPoolLevelRange(703202, 3, 5, "act3_boss_guard")
assertEnemyPoolLevelRange(703203, 1, 5, "act3_boss_back")

print("OK: act2/act3 battle pools are isolated from act1")
