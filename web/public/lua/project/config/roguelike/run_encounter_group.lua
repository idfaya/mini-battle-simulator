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
        level = 8,
        enemyCount = 3,
        enemyIds = { 910001, 910002, 910002 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 20, max = 30 },
        playerScale = { hp = 1.00, atk = 1.05, def = 1.00, energyBonus = 12 },
        enemyScale = { hp = 0.92, atk = 0.92, def = 0.95 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 10,
        enemyCount = 3,
        enemyIds = { 910001, 910002, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 22, max = 34 },
        playerScale = { hp = 1.00, atk = 1.03, def = 1.00, energyBonus = 10 },
        enemyScale = { hp = 0.95, atk = 0.95, def = 0.98 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 11,
        enemyCount = 3,
        enemyIds = { 910002, 910003, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        playerScale = { hp = 1.00, atk = 1.00, def = 1.00, energyBonus = 8 },
        enemyScale = { hp = 1.00, atk = 1.00, def = 1.00 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 16,
        enemyCount = 3,
        enemyIds = { 910004, 910002, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 45, max = 60 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 1 },
        playerScale = { hp = 1.00, atk = 1.00, def = 1.00, energyBonus = 10 },
        enemyScale = { hp = 1.00, atk = 1.00, def = 1.00 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 19,
        enemyCount = 3,
        enemyIds = { 910005, 910004, 910003 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 55, max = 75 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 2 },
        playerScale = { hp = 1.00, atk = 1.00, def = 1.00, energyBonus = 12 },
        enemyScale = { hp = 1.05, atk = 1.03, def = 1.03 },
    },

    -- Event battles (optional branch, still useful for vertical slice)
    [101103] = {
        id = 101103,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 13,
        enemyCount = 3,
        enemyIds = { 910003, 910003, 910002 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        playerScale = { hp = 1.00, atk = 1.02, def = 1.00, energyBonus = 10 },
        enemyScale = { hp = 0.98, atk = 0.98, def = 0.98 },
    },
    [101104] = {
        id = 101104,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 4,
        level = 18,
        enemyCount = 3,
        enemyIds = { 910004, 910004, 910002 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 40, max = 58 },
        playerScale = { hp = 1.00, atk = 1.00, def = 1.00, energyBonus = 12 },
        enemyScale = { hp = 1.02, atk = 1.02, def = 1.00 },
    },

    -- Boss battle
    [101201] = {
        id = 101201,
        kind = "boss",
        chapterId = 101,
        difficulty = 6,
        level = 22,
        enemyCount = 1,
        enemyIds = { 910006 }, -- IceDemon (BOSS)
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 90, max = 110 },
        boss = { phaseGroupId = 101201 },
        playerScale = { hp = 1.00, atk = 1.02, def = 1.00, energyBonus = 16 },
        enemyScale = { hp = 0.92, atk = 0.94, def = 0.95 },
    },
}

function RunEncounterGroup.GetEncounter(encounterId)
    return RunEncounterGroup.ENCOUNTERS[encounterId]
end

return RunEncounterGroup
