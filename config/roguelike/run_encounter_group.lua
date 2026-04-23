local RunEncounterGroup = {}

-- Encounter = one battle setup for roguelike node.
-- Enemies are real IDs from config/res_enemy.json.
-- MonsterType: 0 Normal, 1 Elite, 2 BOSS (see EnemyData).
RunEncounterGroup.ENCOUNTERS = {
    -- Normal battles (chapter 1 baseline)
    [101001] = {
        id = 101001,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 1,
        enemyCount = 3,
        enemyIds = { 910001, 910002, 910002 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 20, max = 30 },
        playerScale = { hp = 1.18, atk = 1.32, def = 1.08, energyBonus = 35 },
        enemyScale = { hp = 0.72, atk = 0.84, def = 0.88 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 3,
        enemyCount = 4,
        enemyIds = { 910001, 910002, 910003, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        playerScale = { hp = 1.08, atk = 1.22, def = 1.06, energyBonus = 26 },
        enemyScale = { hp = 0.82, atk = 0.92, def = 0.92 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 6,
        enemyCount = 5,
        enemyIds = { 910004, 910003, 910003, 910002, 910002 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        playerScale = { hp = 1.06, atk = 1.18, def = 1.04, energyBonus = 22 },
        enemyScale = { hp = 0.90, atk = 1.00, def = 0.96 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 5,
        enemyCount = 5,
        enemyIds = { 910004, 910004, 910003, 910002, 910001 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 1 },
        playerScale = { hp = 1.04, atk = 1.16, def = 1.04, energyBonus = 20 },
        enemyScale = { hp = 0.92, atk = 1.02, def = 0.98 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 8,
        enemyCount = 6,
        enemyIds = { 910005, 910004, 910004, 910003, 910002, 910001 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 2 },
        playerScale = { hp = 1.02, atk = 1.14, def = 1.02, energyBonus = 18 },
        enemyScale = { hp = 0.96, atk = 1.06, def = 1.00 },
    },

    -- Event battles (optional branch, still useful for vertical slice)
    [101103] = {
        id = 101103,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 4,
        enemyCount = 4,
        enemyIds = { 910003, 910003, 910002, 910001 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 30, max = 46 },
        playerScale = { hp = 1.06, atk = 1.18, def = 1.04, energyBonus = 22 },
        enemyScale = { hp = 0.84, atk = 0.94, def = 0.92 },
    },
    [101104] = {
        id = 101104,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 4,
        level = 7,
        enemyCount = 5,
        enemyIds = { 910004, 910004, 910003, 910002, 910001 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 46, max = 64 },
        playerScale = { hp = 1.04, atk = 1.16, def = 1.04, energyBonus = 20 },
        enemyScale = { hp = 0.90, atk = 1.00, def = 0.96 },
    },

    -- Boss battle
    [101201] = {
        id = 101201,
        kind = "boss",
        chapterId = 101,
        difficulty = 6,
        level = 10,
        enemyCount = 6,
        enemyIds = { 910006, 910005, 910004, 910003, 910002, 910001 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 96, max = 118 },
        boss = { phaseGroupId = 101201 },
        playerScale = { hp = 1.06, atk = 1.18, def = 1.06, energyBonus = 24 },
        enemyScale = { hp = 1.00, atk = 1.12, def = 1.02 },
    },
}

function RunEncounterGroup.GetEncounter(encounterId)
    return RunEncounterGroup.ENCOUNTERS[encounterId]
end

return RunEncounterGroup
