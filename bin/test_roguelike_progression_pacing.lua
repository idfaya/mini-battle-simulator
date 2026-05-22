local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local DungeonGenerator = require("roguelike.dungeon_generator")
local LevelCurve = require("config.roguelike.level_curve")
local RunBattleConfig = require("config.roguelike.run_battle_config")
local RunBattlePool = require("config.roguelike.run_battle_pool")
local RunBattleTemplate = require("config.roguelike.run_battle_template")

local EXPECTED_TEMPLATE_EXP = {
    [201001] = 4,
    [201002] = 4,
    [201003] = 5,
    [201101] = 6,
    [201102] = 7,
    [201201] = 8,
    [201301] = 3,
    [201302] = 4,
}

local EXPECTED_BATTLE_EXP = {
    [101001] = 4,
    [101002] = 4,
    [101003] = 5,
    [101101] = 6,
    [101102] = 7,
    [101103] = 3,
    [101104] = 4,
    [101201] = 8,
}

local function assertEq(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local function assertLevelCurve()
    assertEq(LevelCurve.CHAPTER_LEVEL_CAP, 10, "chapter level cap")
    for level = 1, 9 do
        assertEq(LevelCurve.GetExpToNextLevel(level), 20, "level step " .. tostring(level))
    end
    assertEq(LevelCurve.GetExpToNextLevel(10), 0, "cap next level exp")
    assertEq(LevelCurve.GetLevelForExp(0), 1, "level at 0 exp")
    assertEq(LevelCurve.GetLevelForExp(179), 9, "level at 179 exp")
    assertEq(LevelCurve.GetLevelForExp(180), 10, "level at 180 exp")
end

local function assertBattleRewards()
    local step = LevelCurve.GetExpToNextLevel(1)
    for templateId, expectedExp in pairs(EXPECTED_TEMPLATE_EXP) do
        local template = RunBattleTemplate.GetTemplate(templateId)
        assert(template, "missing battle template " .. tostring(templateId))
        assertEq(template.expReward, expectedExp, "template expReward " .. tostring(templateId))
        assert(template.expReward <= step, "template expReward must not exceed one level step: " .. tostring(templateId))
    end
    for battleId, expectedExp in pairs(EXPECTED_BATTLE_EXP) do
        local battle = RunBattleConfig.GetBattle(battleId)
        assert(battle, "missing direct battle config " .. tostring(battleId))
        assertEq(battle.expReward, expectedExp, "direct battle expReward " .. tostring(battleId))
        assert(battle.expReward <= step, "direct battle expReward must not exceed one level step: " .. tostring(battleId))
    end
end

local function getPoolAverageExp(poolId)
    local pool = RunBattlePool.GetPool(poolId)
    assert(pool, "missing battle pool " .. tostring(poolId))
    local totalWeight = 0
    local weightedExp = 0
    for _, entry in ipairs(pool.entries or {}) do
        local template = RunBattleTemplate.GetTemplate(entry.battleTemplateId)
        assert(template, "missing battle template " .. tostring(entry.battleTemplateId))
        local weight = math.max(0, tonumber(entry.weight) or 0)
        totalWeight = totalWeight + weight
        weightedExp = weightedExp + weight * (tonumber(template.expReward) or 0)
    end
    assert(totalWeight > 0, "empty battle pool " .. tostring(poolId))
    return weightedExp / totalWeight
end

local function estimateRunExp(seed)
    local totalExp = 0
    local totalBattles = 0
    for _, chapterId in ipairs({ 101, 102, 103 }) do
        local state, reason = DungeonGenerator.Generate(seed, chapterId, { id = chapterId * 1000 + 1 })
        assert(state, "dungeon generation failed: " .. tostring(reason))
        for _, floor in pairs(state.floors or {}) do
            for _, room in pairs(floor.rooms or {}) do
                if room.roomType == "battle_normal" or room.roomType == "battle_elite" or room.roomType == "boss" then
                    totalBattles = totalBattles + 1
                    totalExp = totalExp + getPoolAverageExp(room.payload and room.payload.battlePoolId)
                end
            end
        end
    end
    return totalExp, totalBattles
end

local function assertDungeonPacing()
    local totalExp = 0
    local totalBattles = 0
    local runs = 200
    for seed = 10001, 10000 + runs do
        local runExp, runBattles = estimateRunExp(seed)
        totalExp = totalExp + runExp
        totalBattles = totalBattles + runBattles
    end
    local avgExp = totalExp / runs
    local avgBattles = totalBattles / runs
    local avgFinalLevel = LevelCurve.GetLevelForExp(math.floor(avgExp + 0.5), LevelCurve.CHAPTER_LEVEL_CAP)
    assert(avgFinalLevel >= 9 and avgFinalLevel <= 10,
        string.format("average final level should be Lv9-Lv10, got Lv%d at %.1f exp", avgFinalLevel, avgExp))
    assert(avgBattles >= 35 and avgBattles <= 42,
        string.format("average 3-chapter battle count should stay near current maze baseline, got %.2f", avgBattles))
    print(string.format("[OK] pacing avgExp=%.1f avgBattles=%.2f avgFinalLevel=Lv%d", avgExp, avgBattles, avgFinalLevel))
end

assertLevelCurve()
assertBattleRewards()
assertDungeonPacing()
print("[OK] roguelike progression pacing")
