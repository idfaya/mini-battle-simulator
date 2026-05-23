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
--     通过 BuildReport → gap 计算 hpMul/atkMul/defMul/hitDelta/spellDCDelta/saveDelta。
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
        level = 5,
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
        level = 5,
        initialEnergy = 100,
        speed = 1.0,
        gold = { min = 24, max = 38 },
        -- combat 二战维持低编组，但把白送战回拉成会产生真实损耗的缓坡战。
        budget = { difficulty = "easy", pressureFactor = 0.10 },
    },
    [101003] = {
        id = 101003,
        kind = "normal",
        chapterId = 101,
        difficulty = 2,
        level = 5,
        initialEnergy = 60,
        speed = 1.0,
        gold = { min = 28, max = 42 },
        budget = { difficulty = "easy", pressureFactor = 0.10 },
    },

    -- Elite battles
    [101101] = {
        id = 101101,
        kind = "elite",
        chapterId = 101,
        difficulty = 3,
        level = 6,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 52, max = 68 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 1 },
        -- F3–F5 首次精英时 partyLevel≈4–5；压强低于普通战连战后的 Boss。
        budget = { difficulty = "easy", pressureFactor = 0.14 },
    },
    [101102] = {
        id = 101102,
        kind = "elite",
        chapterId = 101,
        difficulty = 4,
        level = 6,
        initialEnergy = 90,
        speed = 1.0,
        gold = { min = 62, max = 84 },
        eliteBonus = { equipmentRoll = 1, rewardRarityBonus = 2 },
        budget = { difficulty = "easy", pressureFactor = 0.16 },
    },

    -- Light route battles: used to stop low-risk routes from skipping straight to boss.
    [101103] = {
        id = 101103,
        kind = "event_battle",
        chapterId = 101,
        difficulty = 2,
        level = 8,
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
        budget = { difficulty = "easy", pressureFactor = 0.16 },
    },
}

function RunBattleProfile.GetBattleProfile(battleId)
    return RunBattleProfile.BATTLE_PROFILES[battleId]
end

return RunBattleProfile
