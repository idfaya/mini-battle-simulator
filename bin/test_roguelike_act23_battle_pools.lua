package.path = package.path .. ";./?.lua"

local Bootstrap = dofile("core/lua_bootstrap.lua")
Bootstrap.SetupFromSource("@bin/test_roguelike_act23_battle_pools.lua", { includeParent = true })

local FloorsTable = require("config.tables.floors")
local RunBattlePool = require("config.roguelike.run_battle_pool")
local RunBattleTemplate = require("config.roguelike.run_battle_template")
local RunWaveGroupPool = require("config.roguelike.run_wave_group_pool")
local RunEnemyPickPool = require("config.roguelike.run_enemy_pick_pool")

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

print("OK: act2/act3 battle pools are isolated from act1")
