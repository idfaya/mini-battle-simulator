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
        enemyCount = 5,
        enemyIds = { 910004, 910004, 910002, 910002, 910002 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 20, max = 30 },
        budget = { difficulty = "deadly", pressureFactor = 1.60 },
        playerScale = { hp = 1.00, atk = 1.08, def = 1.00, energyBonus = 0 },
        enemyScale = { hp = 0.62, atk = 2.50, def = 0.84, hitDelta = 5, spellDCDelta = 0 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 3,
        enemyCount = 6,
        enemyIds = { 910004, 910003, 910003, 910003, 910002, 910002 },
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        budget = { difficulty = "deadly", pressureFactor = 1.70 },
        playerScale = { hp = 0.98, atk = 1.06, def = 0.98, energyBonus = 0 },
        enemyScale = { hp = 0.68, atk = 2.85, def = 0.86, hitDelta = 6, spellDCDelta = 1 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 6,
        enemyCount = 6,
        enemyIds = { 910005, 910005, 910004, 910003, 910002, 910002 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        budget = { difficulty = "deadly", pressureFactor = 1.90 },
        playerScale = { hp = 0.96, atk = 1.04, def = 0.98, energyBonus = 0 },
        enemyScale = { hp = 0.74, atk = 3.10, def = 0.90, hitDelta = 6, spellDCDelta = 3 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 5,
        enemyCount = 6,
        enemyIds = { 910005, 910005, 910004, 910003, 910002, 910002 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 1 },
        budget = { difficulty = "deadly", pressureFactor = 2.00 },
        playerScale = { hp = 0.96, atk = 1.04, def = 0.98, energyBonus = 0 },
        enemyScale = { hp = 0.76, atk = 3.20, def = 0.92, hitDelta = 6, spellDCDelta = 3 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 8,
        enemyCount = 6,
        enemyIds = { 910005, 910005, 910005, 910005, 910004, 910003 },
        initialEnergy = 120,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { relicRoll = 1, rewardRarityBonus = 2 },
        budget = { difficulty = "deadly", pressureFactor = 2.20 },
        playerScale = { hp = 0.94, atk = 1.02, def = 0.96, energyBonus = 4 },
        enemyScale = { hp = 0.56, atk = 4.20, def = 0.84, hitDelta = 8, spellDCDelta = 6 },
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
        playerScale = { hp = 0.98, atk = 1.06, def = 0.98, energyBonus = 10 },
        enemyScale = { hp = 0.86, atk = 2.60, def = 0.96, hitDelta = 4, spellDCDelta = 2 },
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
        playerScale = { hp = 0.95, atk = 1.03, def = 0.97, energyBonus = 5 },
        enemyScale = { hp = 0.96, atk = 3.10, def = 1.04, hitDelta = 5, spellDCDelta = 3 },
    },

    -- Boss battle
    [101201] = {
        id = 101201,
        kind = "boss",
        chapterId = 101,
        difficulty = 6,
        level = 10,
        enemyCount = 6,
        enemyIds = { 910007, 910006, 910006, 910005, 910005, 910005 },
        initialEnergy = 150,
        speed = 1.0,
        gold = { min = 96, max = 118 },
        boss = { phaseGroupId = 101201 },
        budget = { difficulty = "deadly", pressureFactor = 2.60 },
        playerScale = { hp = 0.95, atk = 1.04, def = 0.98, energyBonus = 0 },
        enemyScale = { hp = 0.42, atk = 5.60, def = 0.76, hitDelta = 10, spellDCDelta = 8, saveDelta = 0 },
    },
}

function RunEncounterGroup.GetEncounter(encounterId)
    return RunEncounterGroup.ENCOUNTERS[encounterId]
end

return RunEncounterGroup
