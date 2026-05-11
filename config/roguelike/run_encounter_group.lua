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
---@field initialEnergy integer
---@field speed number
---@field gold RunEncounterGoldRange
---@field budget RunEncounterBudget
---@field eliteBonus RunEncounterEliteBonus|nil
---@field boss RunEncounterBoss|nil

---@class RunEncounterGroupModule
---@field ENCOUNTERS table<integer, RunEncounterEntry>
---@field GetEncounter fun(encounterId: integer): RunEncounterEntry|nil

---@type RunEncounterGroupModule
local RunEncounterGroup = {}

-- Encounter = one battle setup for roguelike node.
-- Enemy composition comes from battle wave groups/templates, not static encounter enemyIds.
--
-- 难度模型（2026-05-11 收敛）：
--   * 压强由 `budget.difficulty` + `budget.pressureFactor` 主导（见 run_encounter_budget.lua），
--     通过 BuildReport → gap 计算 hpMul/atkMul/defMul/hitDelta/spellDCDelta/saveDelta。
--   * 遭遇表不再使用 `playerScale / enemyScale`。
--   * 遭遇表也不再配置 `enemyCount / enemyIds`，这些由 battle template → wave group 生成链决定。
--   * 如果遭遇过强，优先调整 CR 组合、怪物数量、遭遇等级或 budget，不再靠额外 scale 修正。
---@type table<integer, RunEncounterEntry>
RunEncounterGroup.ENCOUNTERS = {
    -- Normal battles (chapter 1 baseline)
    [101001] = {
        id = 101001,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 1,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 20, max = 30 },
        -- 教学战：4 怪起步，配合初始 4 人队形成完整前后排战斗。
        budget = { difficulty = "easy", pressureFactor = 0.20 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 2,
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        -- combat 二战维持低编组，但把白送战回拉成会产生真实损耗的缓坡战。
        budget = { difficulty = "easy", pressureFactor = 0.22 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 1,
        initialEnergy = 60,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        budget = { difficulty = "easy", pressureFactor = 0.24 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 3,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 1 },
        -- 首个精英恢复一定压强，确保 combat 路线在中段前已有资源压力。
        budget = { difficulty = "medium", pressureFactor = 0.56 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 4,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 2 },
        budget = { difficulty = "medium", pressureFactor = 0.68 },
    },

    -- Light route battles: used to stop low-risk routes from skipping straight to boss.
    [101103] = {
        id = 101103,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 3,
        initialEnergy = 50,
        speed = 1.0,
        gold = { min = 30, max = 46 },
        budget = { difficulty = "easy", pressureFactor = 0.34 },
    },
    [101104] = {
        id = 101104,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 1,
        initialEnergy = 10,
        speed = 1.0,
        gold = { min = 46, max = 64 },
        budget = { difficulty = "easy", pressureFactor = 0.28 },
    },

    -- Boss battle
    [101201] = {
        id = 101201,
        kind = "boss",
        chapterId = 101,
        difficulty = 6,
        level = 3,
        initialEnergy = 20,
        speed = 1.0,
        gold = { min = 96, max = 118 },
        boss = { phaseGroupId = 101201 },
        budget = { difficulty = "easy", pressureFactor = 0.52 },
        -- Frozen Gate 需要保留“会完整释放吟唱大招”的机制真实性，但压强应回到可通关区间。
    },
}

function RunEncounterGroup.GetEncounter(encounterId)
    return RunEncounterGroup.ENCOUNTERS[encounterId]
end

return RunEncounterGroup
