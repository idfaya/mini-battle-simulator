local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:match("^@?(.*[\\/])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyGroup = require("config.roguelike.run_enemy_group")
local EnemyData = require("config.enemy_data")
local FloorsTable = require("config.tables.floors")
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

local function averageAdjustedXp(templatePoolId, waveCount, seedStart, seedEnd, opts)
    local totalAdjustedXp = 0
    local count = 0
    for seed = seedStart, seedEnd do
        local generated, reason = EnemyGenerator.Generate(templatePoolId, waveCount, seed, opts)
        assert(generated, "enemy generation failed: " .. tostring(reason))
        local report = generated.budgetReport
        assert(report and report.adjustedXp, "budgeted generation should expose adjustedXp report")
        totalAdjustedXp = totalAdjustedXp + (tonumber(report.adjustedXp) or 0)
        count = count + 1
    end
    assert(count > 0, "averageAdjustedXp requires at least one sample")
    return totalAdjustedXp / count
end

local function assertSeen(seen, enemyId, label)
    assert(seen[enemyId] == true, string.format("expected to see %s (%d)", label, enemyId))
end

local function assertNotSeen(seen, enemyId, label)
    assert(seen[enemyId] ~= true, string.format("did not expect to see %s (%d)", label, enemyId))
end

local f1 = FloorsTable.GetTemplate(10101)
assert(f1 ~= nil, "missing act1 floor1 template")
assert((f1.typeWeights or {}).battle_elite == 0, "act1 f1 should not generate elite rooms")
assert((f1.constraints or {}).maxElite == 0, "act1 f1 maxElite should be 0")

local earlySeen = collectPoolEnemyIds(401001, 1, 901, 980)
assertNotSeen(earlySeen, 910004, "Skeleton Soldier in act1 early pool")
assertNotSeen(earlySeen, 910014, "Orc Fighter in act1 early pool")
assertSeen(earlySeen, 910001, "Slime in act1 early pool")
assertSeen(earlySeen, 910002, "Goblin in act1 early pool")

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

local lowPressureAvg = averageAdjustedXp(401101, 1, 4001, 4060, {
    budget = { difficulty = "easy", pressureFactor = 0.10 },
    partyLevel = 2,
    partySize = 4,
    sampleCount = 10,
})
local highPressureAvg = averageAdjustedXp(401101, 1, 4001, 4060, {
    budget = { difficulty = "medium", pressureFactor = 0.35 },
    partyLevel = 2,
    partySize = 4,
    sampleCount = 10,
})
assert(highPressureAvg > lowPressureAvg,
    string.format("higher pressure should pick heavier encounters: low=%.1f high=%.1f", lowPressureAvg, highPressureAvg))

print("[OK] roguelike enemy generation pools include new enemies and bosses")
