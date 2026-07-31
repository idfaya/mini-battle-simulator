local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local DungeonGenerator = require("roguelike.dungeon_generator")
local BattleResolver = require("roguelike.roguelike_battle_resolver")
local LevelCurve = require("config.roguelike.level_curve")
local Exp5e = require("config.roguelike.exp_5e")
local BattleExpReward = require("config.roguelike.battle_exp_reward")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")

local CHAPTER_BATTLE_EXP_MULTIPLIER = {
    [101] = 2.30,
    [102] = 2.00,
    [103] = 2.00,
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

local function buildBudgetRunState(chapterId, seed, partyLevel)
    local effectiveLevel = 1 + math.max(0, (tonumber(partyLevel) or 1) - 1) / 4
    local teamRoster = {}
    for i = 1, 4 do
        teamRoster[#teamRoster + 1] = {
            rosterId = i,
            level = effectiveLevel,
            currentHp = 100,
            maxHp = 100,
            teamState = "active",
        }
    end
    return {
        chapterId = chapterId,
        seed = seed,
        partyLevel = tonumber(partyLevel) or 1,
        teamRoster = teamRoster,
        benchRoster = {},
    }
end

local function collectBattleRooms(state)
    local rooms = {}
    for floorIndex, floor in ipairs(state.floors or {}) do
        for roomId, room in pairs(floor.rooms or {}) do
            if room.roomType == "battle_normal" or room.roomType == "battle_elite" or room.roomType == "boss" then
                rooms[#rooms + 1] = {
                    id = tonumber(room.id) or tonumber(roomId) or (floorIndex * 100 + #rooms + 1),
                    battlePoolId = room.payload and room.payload.battlePoolId or nil,
                }
            end
        end
    end
    table.sort(rooms, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)
    return rooms
end

local function getResolvedEncounterExp(chapterId, seed, node, partyLevel, chapterMult)
    local runState = buildBudgetRunState(chapterId, seed, partyLevel)
    local battle, _, reason = BattleResolver.ResolveNodeBattle(runState, node)
    assert(battle, "battle resolve failed: " .. tostring(reason))
    local enemyIds = flattenBattleEnemyIds(battle)
    assert(#enemyIds > 0, "resolved battle has no enemies: " .. tostring(node and node.battlePoolId))
    return BattleExpReward.ComputeVictoryExp({
        enemyIds = enemyIds,
        partySize = 4,
        partyLevel = partyLevel,
        chapterMultiplier = chapterMult,
    })
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
        local partyLevel = 1
        for _, node in ipairs(collectBattleRooms(state)) do
            runBattles = runBattles + 1
            local gain = getResolvedEncounterExp(chapterId, seed, node, partyLevel, mult)
            runExp = runExp + gain
            partyLevel = LevelCurve.GetLevelForExp(runExp, LevelCurve.CHAPTER_LEVEL_CAP)
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
    assert(avgLevel >= 9 and avgLevel <= 10,
        string.format("act1 固定章节难度 + CR 经验节奏期望 partyLevel 9-10，实际 Lv%d (%.0f exp)", avgLevel, avgExp))
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
