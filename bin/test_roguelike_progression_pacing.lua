local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local DungeonGenerator = require("roguelike.dungeon_generator")
local LevelCurve = require("config.roguelike.level_curve")
local Exp5e = require("config.roguelike.exp_5e")
local BattleExpReward = require("config.roguelike.battle_exp_reward")
local RunBattlePool = require("config.roguelike.run_battle_pool")
local RunBattleTemplate = require("config.roguelike.run_battle_template")
local RunBattleConfig = require("config.roguelike.run_battle_config")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")

local CHAPTER_BATTLE_EXP_MULTIPLIER = {
    [101] = 1.00,
    [102] = 0.50,
    [103] = 0.35,
}

local function assertEq(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local function assertLevelCurve5e()
    assertEq(LevelCurve.CHAPTER_LEVEL_CAP, 20, "chapter level cap")
    -- partyExp 阈值同时被 PARTY_EXP_SCALE（Run 内总缩放）与 PARTY_EXP_THRESHOLD_SCALE
    -- （4 人队 → 单角色升级补偿）等比缩放。
    local thresholdScale = (Exp5e.PARTY_EXP_SCALE or 1.0) * (Exp5e.PARTY_EXP_THRESHOLD_SCALE or 1.0)
    assertEq(Exp5e.GetCharacterExpThreshold(2), math.floor(300 * thresholdScale + 0.5), "lv2 threshold")
    assertEq(Exp5e.GetExpToNextLevel(1), math.floor(300 * thresholdScale + 0.5), "lv1 step")
    assertEq(Exp5e.GetExpToNextLevel(2), math.floor(600 * thresholdScale + 0.5), "lv2 step")
    assertEq(Exp5e.GetExpToNextLevel(11), math.floor(15000 * thresholdScale + 0.5), "lv11 step")
    assertEq(LevelCurve.GetLevelForExp(0), 1, "level at 0 exp")
    assertEq(LevelCurve.GetLevelForExp(Exp5e.GetCharacterExpThreshold(12)), 12, "level at lv12 threshold")
end

local function appendEnemyGroupIds(target, groupId)
    local group = RunEnemyGroup.GetGroup(tonumber(groupId))
    if not group then
        return
    end
    local function push(id)
        local n = tonumber(id)
        if n then
            target[#target + 1] = n
        end
    end
    for _, enemyId in ipairs(group.front or {}) do
        push(enemyId)
    end
    for _, enemyId in ipairs(group.back or {}) do
        push(enemyId)
    end
    for _, enemyId in ipairs(group.elite or {}) do
        push(enemyId)
    end
    push(group.boss)
    for _, enemyId in ipairs(group.guards or {}) do
        push(enemyId)
    end
end

local function flattenBattleEnemyIds(battle)
    local enemyIds = {}
    if not battle then
        return enemyIds
    end
    for _, groupId in ipairs(battle.waveGroupIds or {}) do
        appendEnemyGroupIds(enemyIds, groupId)
    end
    return enemyIds
end

local function enemyIdsForTemplate(template)
    local enemyIds = {}
    for _, entry in ipairs(template.battleEntries or {}) do
        local battle = RunBattleConfig.GetBattle(entry.battleId)
        if battle then
            for _, id in ipairs(flattenBattleEnemyIds(battle)) do
                enemyIds[#enemyIds + 1] = id
            end
        end
    end
    if template.bossEnemyId then
        enemyIds[#enemyIds + 1] = template.bossEnemyId
    end
    return enemyIds
end

local function getPoolAverageEncounterExp(poolId, partyLevel, chapterMult)
    local pool = RunBattlePool.GetPool(poolId)
    assert(pool, "missing battle pool " .. tostring(poolId))
    local totalWeight = 0
    local weightedExp = 0
    for _, entry in ipairs(pool.entries or {}) do
        local template = RunBattleTemplate.GetTemplate(entry.battleTemplateId)
        assert(template, "missing battle template " .. tostring(entry.battleTemplateId))
        local weight = math.max(0, tonumber(entry.weight) or 0)
        local enemyIds = enemyIdsForTemplate(template)
        assert(#enemyIds > 0, "template has no enemies: " .. tostring(entry.battleTemplateId))
        local exp = BattleExpReward.ComputeVictoryExp({
            enemyIds = enemyIds,
            partySize = 4,
            partyLevel = partyLevel,
            chapterMultiplier = chapterMult,
        })
        totalWeight = totalWeight + weight
        weightedExp = weightedExp + weight * exp
    end
    assert(totalWeight > 0, "empty battle pool " .. tostring(poolId))
    return weightedExp / totalWeight
end

local function estimateChapterExp(chapterId, seedFrom, seedTo)
    local mult = CHAPTER_BATTLE_EXP_MULTIPLIER[chapterId] or 1.0
    local totalExp = 0
    local totalBattles = 0
    local runs = seedTo - seedFrom + 1
    local partyLevel = 1
    for seed = seedFrom, seedTo do
        local state, reason = DungeonGenerator.Generate(seed, chapterId, { id = chapterId * 1000 + 1 })
        assert(state, "dungeon generation failed: " .. tostring(reason))
        local runExp = 0
        local runBattles = 0
        for floorIndex, floor in ipairs(state.floors or {}) do
            for _, room in pairs(floor.rooms or {}) do
                if room.roomType == "battle_normal" or room.roomType == "battle_elite" or room.roomType == "boss" then
                    runBattles = runBattles + 1
                    local gain = getPoolAverageEncounterExp(room.payload.battlePoolId, partyLevel, mult)
                    runExp = runExp + gain
                    partyLevel = LevelCurve.GetLevelForExp(runExp, LevelCurve.CHAPTER_LEVEL_CAP)
                end
            end
        end
        totalExp = totalExp + runExp
        totalBattles = totalBattles + runBattles
    end
    return totalExp / runs, totalBattles / runs
end

local function assertAct1Pacing5e()
    local avgExp, avgBattles = estimateChapterExp(101, 10001, 10200)
    local avgLevel = LevelCurve.GetLevelForExp(math.floor(avgExp + 0.5), LevelCurve.CHAPTER_LEVEL_CAP)
    assert(avgBattles >= 6 and avgBattles <= 20,
        string.format("act1 battle count out of range: %.2f", avgBattles))
    -- 改为 CR 主导后，战斗 EXP 不再吃 enemyLevel 膨胀；Act1 终局平均等级应明显低于旧口径，
    -- 但仍要保证具备稳定成长感与进入中段 build 的空间。
    assert(avgLevel >= 7 and avgLevel <= 10,
        string.format("act1 CR 主导节奏下期望 partyLevel 7-10，实际 Lv%d (%.0f exp)", avgLevel, avgExp))
    print(string.format("[OK] act1 5e avgExp=%.0f avgBattles=%.2f avgFinalLevel=Lv%d", avgExp, avgBattles, avgLevel))
end

local function assertEscalatingSteps()
    local step1 = Exp5e.GetExpToNextLevel(1)
    local step5 = Exp5e.GetExpToNextLevel(5)
    local step10 = Exp5e.GetExpToNextLevel(10)
    assert(step5 > step1, "mid levels need more exp per level")
    assert(step10 > step5, "high levels need more exp per level")
end

local function assertSingleBattleUsesCrOnly()
    local partyLevel = 1
    local highGain = BattleExpReward.ComputeVictoryExp({
        enemyIds = { 910006, 910007, 910006, 910007 },
        partySize = 4,
        partyLevel = partyLevel,
        chapterMultiplier = 1,
    })
    local lowGain = BattleExpReward.ComputeVictoryExp({
        enemyIds = { 910006, 910007, 910006, 910007 },
        partySize = 4,
        partyLevel = partyLevel,
        chapterMultiplier = 1,
    })
    local goblinGain = BattleExpReward.ComputeVictoryExp({
        enemyIds = { 910002, 910002, 910002, 910002 },
        partySize = 4,
        partyLevel = partyLevel,
        chapterMultiplier = 1,
    })
    assert(highGain == lowGain, "same encounter without enemyLevel scaling should keep same exp")
    assert(highGain > goblinGain,
        string.format("higher CR encounters should grant more exp: goblin=%d boss=%d", goblinGain, highGain))
end

assertLevelCurve5e()
assertEscalatingSteps()
assertSingleBattleUsesCrOnly()
assertAct1Pacing5e()
print("[OK] roguelike progression pacing (5e)")
