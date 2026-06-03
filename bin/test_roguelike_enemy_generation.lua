local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:match("^@?(.*[\\/])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyGroup = require("config.roguelike.run_enemy_group")
local EnemyData = require("config.enemy_data")
local EnemyGenerator = require("roguelike.roguelike_enemy_generator")

local function flattenGroup(groupId)
    local group = EnemyGroup.GetGroup(groupId)
    assert(group, "missing group " .. tostring(groupId))
    local ids = {}
    for _, enemyId in ipairs(group.front or {}) do
        ids[#ids + 1] = enemyId
    end
    for _, enemyId in ipairs(group.back or {}) do
        ids[#ids + 1] = enemyId
    end
    for _, enemyId in ipairs(group.guards or {}) do
        ids[#ids + 1] = enemyId
    end
    if tonumber(group.boss) then
        ids[#ids + 1] = tonumber(group.boss)
    end
    return ids
end

local function collectPoolEnemyIds(templatePoolId, waveCount, seedStart, seedEnd)
    local seen = {}
    for seed = seedStart, seedEnd do
        local generated, reason = EnemyGenerator.Generate(templatePoolId, waveCount, seed)
        assert(generated, "enemy generation failed: " .. tostring(reason))
        for _, groupId in ipairs(generated.waveGroupIds or {}) do
            for _, enemyId in ipairs(flattenGroup(groupId)) do
                seen[enemyId] = true
                assert(EnemyData.GetEnemy(enemyId) ~= nil, "generated unknown enemy " .. tostring(enemyId))
            end
        end
    end
    return seen
end

local function assertSeen(seen, enemyId, label)
    assert(seen[enemyId] == true, string.format("expected to see %s (%d)", label, enemyId))
end

local normalSeen = collectPoolEnemyIds(401002, 2, 1001, 1120)
assertSeen(normalSeen, 910012, "Goblin Thrower in normal pool")
assertSeen(normalSeen, 910013, "Skeleton Archer in normal pool")
assertSeen(normalSeen, 910014, "Orc Fighter in normal pool")

local eliteSeen = collectPoolEnemyIds(401101, 1, 2001, 2120)
assertSeen(eliteSeen, 910015, "Skeleton Captain in elite pool")
assertSeen(eliteSeen, 910016, "Shadow Priest in elite pool")

local bossSeen = collectPoolEnemyIds(401201, 2, 3001, 3120)
assertSeen(bossSeen, 910006, "Ice Demon in boss pool")
assertSeen(bossSeen, 910007, "Thunder Lord in boss pool")
assertSeen(bossSeen, 910015, "Skeleton Captain as boss guard")
assertSeen(bossSeen, 910016, "Shadow Priest as boss backline")

print("[OK] roguelike enemy generation pools include new enemies and bosses")
