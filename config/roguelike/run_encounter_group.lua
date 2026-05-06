---@alias RunEncounterBudgetDifficulty
---| "easy"
---| "medium"
---| "hard"
---| "deadly"

---@class RunEncounterGoldRange
---@field min integer
---@field max integer

---@class RunEncounterBudget
---@field difficulty RunEncounterBudgetDifficulty
---@field pressureFactor number

---@class RunEncounterPlayerScale
---@field hp number
---@field atk number
---@field def number
---@field energyBonus integer

---@class RunEncounterEnemyScale
---@field hp number
---@field atk number
---@field def number
---@field hitDelta integer
---@field spellDCDelta integer
---@field saveDelta integer|nil

---@class RunEncounterEliteBonus
---@field equipmentRoll integer
---@field rewardRarityBonus integer

---@class RunEncounterBoss
---@field phaseGroupId integer

---@class RunEncounterEntry
---@field id integer
---@field kind string
---@field chapterId integer
---@field difficulty integer
---@field level integer
---@field enemyCount integer
---@field enemyIds integer[]
---@field initialEnergy integer
---@field speed number
---@field gold RunEncounterGoldRange
---@field budget RunEncounterBudget
---@field playerScale RunEncounterPlayerScale
---@field enemyScale RunEncounterEnemyScale
---@field eliteBonus RunEncounterEliteBonus|nil
---@field boss RunEncounterBoss|nil

---@class RunEncounterGroupModule
---@field ENCOUNTERS table<integer, RunEncounterEntry>
---@field GetEncounter fun(encounterId: integer): RunEncounterEntry|nil

---@type RunEncounterGroupModule
local RunEncounterGroup = {}

-- Encounter = one battle setup for roguelike node.
-- Enemies are real IDs from config/res_enemy.json.
-- MonsterType: 0 Normal, 1 Elite, 2 BOSS (see EnemyData).
--
-- 难度模型（2026-04-27 收敛）：
--   * 压强由 `budget.difficulty` + `budget.pressureFactor` 主导（见 run_encounter_budget.lua），
--     通过 BuildReport → gap 计算 hpMul/atkMul/defMul/hitDelta/spellDCDelta/saveDelta。
--   * `enemyScale` 仅保留「语义化的轻微修正」（±10% 以内 / hitDelta ±1），
--     不再用倍率堆砌压强（避免和 budget 双乘）。
--     如果遭遇过强，优先调整 CR 组合、怪物数量、budget 或 playerScale，不直接大幅削怪物本体。
--   * `playerScale` 维持原结构，保留给职业/队伍容错的微调。
---@type table<integer, RunEncounterEntry>
RunEncounterGroup.ENCOUNTERS = {
    -- Normal battles (chapter 1 baseline)
    [101001] = {
        id = 101001,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 1,
        enemyCount = 4,
        enemyIds = { 910004, 910002, 910002, 910001 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 20, max = 30 },
        -- 教学战：4 怪起步，配合初始 4 人队形成完整前后排战斗。
        budget = { difficulty = "easy", pressureFactor = 0.80 },
        playerScale = { hp = 1.00, atk = 1.04, def = 1.00, energyBonus = 0 },
        -- enemyScale 保持近乎中性，不再把 hp 打到 0.45 造成与 budget 的双重打折。
        enemyScale = { hp = 0.95, atk = 1.00, def = 0.95, hitDelta = 0, spellDCDelta = 0 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 2,
        enemyCount = 3,
        enemyIds = { 910003, 910002, 910001 },
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        -- 去掉战后 loot 后，纯战斗路线第二战改成 2 怪缓坡，保证能进入中盘。
        budget = { difficulty = "easy", pressureFactor = 0.55 },
        playerScale = { hp = 1.36, atk = 1.18, def = 1.24, energyBonus = 20 },
        enemyScale = { hp = 0.78, atk = 0.78, def = 0.82, hitDelta = -4, spellDCDelta = -1 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 3,
        enemyCount = 4,
        enemyIds = { 910004, 910003, 910002, 910001 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        budget = { difficulty = "easy", pressureFactor = 0.76 },
        playerScale = { hp = 1.24, atk = 1.12, def = 1.18, energyBonus = 15 },
        enemyScale = { hp = 0.88, atk = 0.84, def = 0.88, hitDelta = -2, spellDCDelta = -1 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 4,
        enemyCount = 2,
        enemyIds = { 910002, 910001 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 1 },
        -- 单人升级改版后，第二战后队伍强度爬坡更慢；首个精英收缩到 4 怪。
        budget = { difficulty = "easy", pressureFactor = 0.55 },
        playerScale = { hp = 1.36, atk = 1.18, def = 1.24, energyBonus = 20 },
        -- 精英微调：先移除命中/DC 额外压制，后续再通过 budget 精确回收难度。
        enemyScale = { hp = 0.76, atk = 0.76, def = 0.80, hitDelta = -4, spellDCDelta = -2 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 4,
        enemyCount = 1,
        enemyIds = { 910003 },
        initialEnergy = 120,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 2 },
        budget = { difficulty = "easy", pressureFactor = 0.40 },
        playerScale = { hp = 1.46, atk = 1.24, def = 1.32, energyBonus = 60 },
        enemyScale = { hp = 0.70, atk = 0.72, def = 0.78, hitDelta = -5, spellDCDelta = -3 },
    },

    -- Light route battles: used to stop low-risk routes from skipping straight to boss.
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
        budget = { difficulty = "easy", pressureFactor = 0.90 },
        playerScale = { hp = 1.16, atk = 1.10, def = 1.12, energyBonus = 15 },
        enemyScale = { hp = 0.88, atk = 0.86, def = 0.88, hitDelta = -2, spellDCDelta = -1 },
    },
    [101104] = {
        id = 101104,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 3,
        level = 5,
        enemyCount = 5,
        enemyIds = { 910004, 910003, 910002, 910002, 910001 },
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 46, max = 64 },
        budget = { difficulty = "easy", pressureFactor = 0.75 },
        playerScale = { hp = 1.24, atk = 1.12, def = 1.18, energyBonus = 15 },
        enemyScale = { hp = 0.84, atk = 0.84, def = 0.86, hitDelta = -2, spellDCDelta = -2 },
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
        budget = { difficulty = "hard", pressureFactor = 1.00 },
        playerScale = { hp = 1.24, atk = 1.12, def = 1.18, energyBonus = 10 },
        -- BOSS 保留体量感，但不再额外拉高命中/DC，避免连续点杀前排。
        enemyScale = { hp = 0.82, atk = 0.84, def = 0.86, hitDelta = -2, spellDCDelta = -2, saveDelta = -1 },
    },
}

function RunEncounterGroup.GetEncounter(encounterId)
    return RunEncounterGroup.ENCOUNTERS[encounterId]
end

return RunEncounterGroup
