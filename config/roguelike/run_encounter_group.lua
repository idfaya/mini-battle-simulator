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
        playerScale = { hp = 1.30, atk = 1.50, def = 1.20, energyBonus = 40 },
        enemyScale = { hp = 0.60, atk = 0.65, def = 0.80 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 2,
        enemyCount = 3,
        enemyIds = { 910001, 910002, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        playerScale = { hp = 1.08, atk = 1.24, def = 1.06, energyBonus = 26 },
        enemyScale = { hp = 0.72, atk = 0.74, def = 0.78 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 3,
        enemyCount = 3,
        enemyIds = { 910002, 910003, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        playerScale = { hp = 1.08, atk = 1.18, def = 1.06, energyBonus = 22 },
        enemyScale = { hp = 0.80, atk = 0.82, def = 0.86 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 5,
        enemyCount = 3,
        enemyIds = { 910004, 910002, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 1 },
        playerScale = { hp = 1.08, atk = 1.26, def = 1.10, energyBonus = 30 },
        enemyScale = { hp = 0.60, atk = 0.72, def = 0.76 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 7,
        enemyCount = 3,
        enemyIds = { 910005, 910004, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 2 },
        playerScale = { hp = 1.10, atk = 1.28, def = 1.12, energyBonus = 32 },
        enemyScale = { hp = 0.64, atk = 0.74, def = 0.80 },
    },

    -- Event battles (optional branch, still useful for vertical slice)
    [101103] = {
        id = 101103,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 5,
        enemyCount = 3,
        enemyIds = { 910003, 910003, 910002 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 30, max = 46 },
        playerScale = { hp = 1.06, atk = 1.18, def = 1.04, energyBonus = 22 },
        enemyScale = { hp = 0.78, atk = 0.80, def = 0.86 },
    },
    [101104] = {
        id = 101104,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 4,
        level = 8,
        enemyCount = 3,
        enemyIds = { 910004, 910004, 910002 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 46, max = 64 },
        playerScale = { hp = 1.08, atk = 1.22, def = 1.06, energyBonus = 24 },
        enemyScale = { hp = 0.76, atk = 0.80, def = 0.84 },
    },

    -- Boss battle
    [101201] = {
        id = 101201,
        kind = "boss",
        chapterId = 101,
        difficulty = 6,
        level = 12,
        enemyCount = 1,
        enemyIds = { 910006 }, -- IceDemon (BOSS)
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 96, max = 118 },
        boss = { phaseGroupId = 101201 },
        playerScale = { hp = 1.10, atk = 1.26, def = 1.10, energyBonus = 34 },
        enemyScale = { hp = 0.62, atk = 0.78, def = 0.84 },
    },
}

function RunEncounterGroup.GetEncounter(encounterId)
    return RunEncounterGroup.ENCOUNTERS[encounterId]
end

return RunEncounterGroup
