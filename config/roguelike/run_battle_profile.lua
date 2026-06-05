---@alias RunBattleProfileBudgetDifficulty
---| "easy"
---| "medium"
---| "hard"
---| "deadly"

---@class RunBattleProfileGoldRange
---@field min integer
---@field max integer

---@class RunBattleProfileBudget
---@field difficulty RunBattleProfileBudgetDifficulty
---@field pressureFactor number

---@class RunBattleProfileEliteBonus
---@field equipmentRoll integer
---@field rewardRarityBonus integer

---@class RunBattleProfileBoss
---@field phaseGroupId integer

---@class RunBattleProfileEntry
---@field id integer
---@field kind string
---@field chapterId integer
---@field difficulty integer
---@field level integer
---@field initialEnergy integer
---@field speed number
---@field gold RunBattleProfileGoldRange
---@field budget RunBattleProfileBudget
---@field eliteBonus RunBattleProfileEliteBonus|nil
---@field boss RunBattleProfileBoss|nil

---@class RunBattleProfileModule
---@field BATTLE_PROFILES table<integer, RunBattleProfileEntry>
---@field GetBattleProfile fun(battleId: integer): RunBattleProfileEntry|nil

---@type RunBattleProfileModule
local RunBattleProfile = {}

-- Battle profile = one battle meta/setup entry for a roguelike node.
-- Enemy composition comes from battle wave groups/templates, not static battle enemy ids.
--
-- 难度模型（2026-05-11 收敛）：
--   * 压强由 `budget.difficulty` + `budget.pressureFactor` 主导（见 run_encounter_budget.lua），
--     在 enemy generator 阶段按固定 profile budget 挑选最接近目标预算的编组；
--     不跟随当前血线/减员/实时等级波动做自适应热修。
--   * battle profile 不再使用 `playerScale / enemyScale`。
--   * battle profile 也不再配置 `enemyCount / enemyIds`，这些由 battle template → wave group 生成链决定。
--   * 如果战斗过强，优先调整 CR 组合、怪物数量、battle profile 等级或 budget，不再靠额外 scale 修正。
---@type table<integer, RunBattleProfileEntry>
RunBattleProfile.BATTLE_PROFILES = {
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
        budget = { difficulty = "easy", pressureFactor = 0.10 },
    },
    [101002] = {
        id = 101002,
        kind = "normal",
        chapterId = 101,
        difficulty = 1,
        level = 1,
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        -- combat 二战维持低编组，但把白送战回拉成会产生真实损耗的缓坡战。
        budget = { difficulty = "easy", pressureFactor = 0.00 },
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
        budget = { difficulty = "easy", pressureFactor = 0.00 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 2,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 1 },
        -- F3–F5 首次精英时 partyLevel≈4–5；压强低于普通战连战后的 Boss。
        budget = { difficulty = "easy", pressureFactor = 0.02 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 2,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 2 },
        budget = { difficulty = "easy", pressureFactor = 0.04 },
    },

    -- Light route battles: used to stop low-risk routes from skipping straight to boss.
    [101103] = {
        id = 101103,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 1,
        initialEnergy = 50,
        speed = 1.0,
        gold = { min = 30, max = 46 },
        budget = { difficulty = "easy", pressureFactor = 0.04 },
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
        budget = { difficulty = "easy", pressureFactor = -0.05 },
    },

    -- Boss battle
    [101201] = {
        id = 101201,
        kind = "boss",
        chapterId = 101,
        difficulty = 6,
        level = 1,
        initialEnergy = 20,
        speed = 1.0,
        gold = { min = 96, max = 118 },
        boss = { phaseGroupId = 101201 },
        -- 阶段 1 收尾平衡（2026-05-21 v3）：
        --   * partyLevel 改语义为"累计三选一次数+1"；feats 仅配到 Lv5，
        --     4 人队最终 lvSum 上限 = 20（4×Lv5）。boss 必须按此基线平衡。
        --   * level=1 + easy/0.25 + waveCount=2（template）：
        --     维持 boss 仍有压强，但避免 4×Lv5 必 wipe（test_roguelike_act1 验证）。
        budget = { difficulty = "easy", pressureFactor = -0.10 },
    },
    [102001] = {
        id = 102001,
        kind = "normal",
        chapterId = 102,
        difficulty = 2,
        level = 7,
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 34, max = 48 },
        budget = { difficulty = "easy", pressureFactor = 0.18 },
    },
    [102002] = {
        id = 102002,
        kind = "normal",
        chapterId = 102,
        difficulty = 3,
        level = 8,
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 40, max = 54 },
        budget = { difficulty = "easy", pressureFactor = 0.20 },
    },
    [102003] = {
        id = 102003,
        kind = "normal",
        chapterId = 102,
        difficulty = 4,
        level = 9,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 46, max = 62 },
        budget = { difficulty = "easy", pressureFactor = 0.22 },
    },
    [102101] = {
        id = 102101,
        kind = "elite",
        chapterId = 102,
        difficulty = 5,
        level = 10,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 72, max = 94 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 2 },
        budget = { difficulty = "easy", pressureFactor = 0.24 },
    },
    [102102] = {
        id = 102102,
        kind = "elite",
        chapterId = 102,
        difficulty = 6,
        level = 11,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 84, max = 108 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 3 },
        budget = { difficulty = "easy", pressureFactor = 0.27 },
    },
    [102201] = {
        id = 102201,
        kind = "boss",
        chapterId = 102,
        difficulty = 8,
        level = 12,
        initialEnergy = 30,
        speed = 1.0,
        gold = { min = 126, max = 154 },
        boss = { phaseGroupId = 101201 },
        budget = { difficulty = "easy", pressureFactor = 0.30 },
    },
    [103001] = {
        id = 103001,
        kind = "normal",
        chapterId = 103,
        difficulty = 4,
        level = 12,
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        budget = { difficulty = "easy", pressureFactor = 0.28 },
    },
    [103002] = {
        id = 103002,
        kind = "normal",
        chapterId = 103,
        difficulty = 5,
        level = 13,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 58, max = 76 },
        budget = { difficulty = "easy", pressureFactor = 0.30 },
    },
    [103003] = {
        id = 103003,
        kind = "normal",
        chapterId = 103,
        difficulty = 6,
        level = 14,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 66, max = 84 },
        budget = { difficulty = "easy", pressureFactor = 0.32 },
    },
    [103101] = {
        id = 103101,
        kind = "elite",
        chapterId = 103,
        difficulty = 7,
        level = 15,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 102, max = 128 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 3 },
        budget = { difficulty = "easy", pressureFactor = 0.35 },
    },
    [103102] = {
        id = 103102,
        kind = "elite",
        chapterId = 103,
        difficulty = 8,
        level = 16,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 118, max = 146 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 4 },
        budget = { difficulty = "easy", pressureFactor = 0.38 },
    },
    [103201] = {
        id = 103201,
        kind = "boss",
        chapterId = 103,
        difficulty = 10,
        level = 18,
        initialEnergy = 40,
        speed = 1.0,
        gold = { min = 168, max = 204 },
        boss = { phaseGroupId = 101201 },
        budget = { difficulty = "easy", pressureFactor = 0.42 },
    },
}

function RunBattleProfile.GetBattleProfile(battleId)
    return RunBattleProfile.BATTLE_PROFILES[battleId]
end

return RunBattleProfile
