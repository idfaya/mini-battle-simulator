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
        enemyCount = 5,
        enemyIds = { 910002, 910001, 910001, 910001, 910001 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 20, max = 30 },
        -- 教学战：4 怪起步，配合初始 4 人队形成完整前后排战斗。
        budget = { difficulty = "easy", pressureFactor = 0.28 },
        playerScale = { hp = 1.32, atk = 1.12, def = 1.12, energyBonus = 18 },
        -- enemyScale 保持近乎中性，不再把 hp 打到 0.45 造成与 budget 的双重打折。
        enemyScale = { hp = 0.90, atk = 0.90, def = 0.90, hitDelta = -1, spellDCDelta = -1 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 2,
        enemyCount = 5,
        enemyIds = { 910002, 910001, 910001, 910001, 910002 },
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        -- combat 二战维持低编组，但把白送战回拉成会产生真实损耗的缓坡战。
        budget = { difficulty = "easy", pressureFactor = 0.34 },
        playerScale = { hp = 1.30, atk = 1.12, def = 1.16, energyBonus = 18 },
        enemyScale = { hp = 0.90, atk = 0.92, def = 0.90, hitDelta = -1, spellDCDelta = -1, saveDelta = -1 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 3,
        enemyCount = 5,
        enemyIds = { 910002, 910001, 910001, 910001, 910001 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        budget = { difficulty = "easy", pressureFactor = 0.56 },
        playerScale = { hp = 1.20, atk = 1.10, def = 1.12, energyBonus = 12 },
        enemyScale = { hp = 0.92, atk = 0.94, def = 0.92, hitDelta = -1, spellDCDelta = -1 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 4,
        enemyCount = 6,
        enemyIds = { 910003, 910002, 910002, 910001, 910001, 910003 },
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 1 },
        -- 首个精英恢复一定压强，确保 combat 路线在中段前已有资源压力。
        budget = { difficulty = "medium", pressureFactor = 1.00 },
        playerScale = { hp = 1.02, atk = 1.02, def = 1.04, energyBonus = 6 },
        enemyScale = { hp = 1.00, atk = 1.06, def = 1.00, hitDelta = 0, spellDCDelta = 0 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 4,
        enemyCount = 6,
        enemyIds = { 910005, 910004, 910003, 910004, 910003, 910005 },
        initialEnergy = 120,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 2 },
        budget = { difficulty = "hard", pressureFactor = 1.18 },
        playerScale = { hp = 0.98, atk = 0.98, def = 1.00, energyBonus = 4 },
        enemyScale = { hp = 1.06, atk = 1.10, def = 1.04, hitDelta = 1, spellDCDelta = 1 },
    },

    -- Light route battles: used to stop low-risk routes from skipping straight to boss.
    [101103] = {
        id = 101103,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 4,
        enemyCount = 5,
        enemyIds = { 910003, 910002, 910001, 910001, 910002 },
        initialEnergy = 50,
        speed = 1.0,
        gold = { min = 30, max = 46 },
        budget = { difficulty = "easy", pressureFactor = 0.58 },
        playerScale = { hp = 1.16, atk = 1.08, def = 1.12, energyBonus = 14 },
        enemyScale = { hp = 0.98, atk = 0.98, def = 0.96, hitDelta = 0, spellDCDelta = 0 },
    },
    [101104] = {
        id = 101104,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 1,
        enemyCount = 5,
        enemyIds = { 910002, 910001, 910001, 910001, 910001 },
        initialEnergy = 10,
        speed = 1.0,
        gold = { min = 46, max = 64 },
        budget = { difficulty = "easy", pressureFactor = 0.45 },
        playerScale = { hp = 1.28, atk = 1.12, def = 1.16, energyBonus = 18 },
        enemyScale = { hp = 0.90, atk = 0.90, def = 0.90, hitDelta = -1, spellDCDelta = -1, saveDelta = -1 },
    },

    -- Boss battle
    [101201] = {
        id = 101201,
        kind = "boss",
        chapterId = 101,
        difficulty = 6,
        level = 3,
        enemyCount = 5,
        enemyIds = { 910002, 910001, 910001, 910001, 910007 },
        initialEnergy = 20,
        speed = 1.0,
        gold = { min = 96, max = 118 },
        boss = { phaseGroupId = 101201 },
        budget = { difficulty = "easy", pressureFactor = 0.72 },
        playerScale = { hp = 1.20, atk = 1.10, def = 1.14, energyBonus = 20 },
        -- Frozen Gate 需要保留“会完整释放吟唱大招”的机制真实性，但压强应回到可通关区间。
        enemyScale = { hp = 0.90, atk = 0.90, def = 0.90, hitDelta = -1, spellDCDelta = 0, saveDelta = -1 },
    },
}

function RunEncounterGroup.GetEncounter(encounterId)
    return RunEncounterGroup.ENCOUNTERS[encounterId]
end

return RunEncounterGroup
