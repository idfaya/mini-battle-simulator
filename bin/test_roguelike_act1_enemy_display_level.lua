local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyData = require("config.enemy_data")
local RunBattleProfile = require("config.roguelike.run_battle_profile")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")
local BattleBridge = require("roguelike.roguelike_battle_bridge")
local HeroData = require("config.hero_data")

local function assertEq(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

assertEq(EnemyData.GetDisplayLevel(910002), 2, "Goblin display level from enemies.json")
assertEq(EnemyData.GetDisplayLevel(910016), 3, "Shadow Priest display level from enemies.json")
assertEq(EnemyData.ConvertToHeroData(910004).level, 2, "ConvertToHeroData uses enemies.json Level")

local function flattenGroupEnemyIds(groupId)
    local group = RunEnemyGroup.GetGroup(groupId)
    assert(group, "missing enemy group " .. tostring(groupId))
    local ids = {}
    for _, enemyId in ipairs(group.front or {}) do
        ids[#ids + 1] = enemyId
    end
    for _, enemyId in ipairs(group.back or {}) do
        ids[#ids + 1] = enemyId
    end
    return ids
end

local function buildStarterRoster()
    local roster = {}
    for index, heroId in ipairs({ 900005, 900001, 900007, 900002 }) do
        local heroInfo = HeroData.GetHeroInfo(heroId)
        local classId = tonumber(heroInfo and heroInfo.Class) or 0
        assert(classId > 0, "starter class for " .. tostring(heroId))
        local unit = HeroData.CreateClassUnit(classId, {
            rosterId = index,
            unitId = string.format("test_unit_%d", index),
            level = 1,
            teamState = "active",
            source = "starter",
            ultimateCharges = 1,
            ultimateChargesMax = 1,
            skillCooldowns = {},
        })
        assert(unit, "starter unit " .. tostring(heroId))
        unit.currentHp = unit.maxHp
        unit.isDead = false
        roster[#roster + 1] = unit
    end
    return roster
end

local function collectBattleDisplayLevels(floorDepth)
    local profile = RunBattleProfile.GetBattleProfile(101001)
    local runState = {
        chapterId = 101,
        partyLevel = 1,
        ownedUnits = buildStarterRoster(),
        dungeonState = { currentFloorDepth = floorDepth },
    }
    local battle = {
        id = 101001,
        kind = profile.kind,
        waveGroupIds = { 101001 },
    }
    local ok, reason = BattleBridge.StartBattle(runState, battle, profile)
    assert(ok, string.format("start battle failed on F%d: %s", floorDepth, tostring(reason)))
    local snapshot = BattleBridge.GetSnapshot()
    local levels = {}
    for _, enemy in ipairs((snapshot and snapshot.rightTeam) or {}) do
        levels[#levels + 1] = tonumber(enemy.level) or 0
    end
    table.sort(levels)
    return levels
end

local expectedLevels = {}
for _, enemyId in ipairs(flattenGroupEnemyIds(101001)) do
    expectedLevels[#expectedLevels + 1] = EnemyData.GetDisplayLevel(enemyId)
end
table.sort(expectedLevels)

local f1Levels = collectBattleDisplayLevels(1)
local f5Levels = collectBattleDisplayLevels(5)
assertEq(table.concat(f1Levels, ","), table.concat(expectedLevels, ","), "F1 battle display levels follow enemies.json")
assertEq(table.concat(f5Levels, ","), table.concat(expectedLevels, ","), "F5 battle display levels follow enemies.json")
assertEq(table.concat(f1Levels, ","), table.concat(f5Levels, ","), "floor depth does not change display levels")

print("[OK] roguelike enemy display levels follow enemies.json Level")
