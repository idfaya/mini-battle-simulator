-- 战斗胜利队伍 EXP：5e 遭遇 XP（CR 表 + 数量倍率）× 章节系数。
local Exp5e = require("config.roguelike.exp_5e")
local RunEncounterBudget = require("config.roguelike.run_encounter_budget")
local EnemyData = require("config.enemy_data")

---@class BattleExpRewardOptions
---@field enemyIds integer[]
---@field partySize integer
---@field partyLevel integer
---@field chapterMultiplier number|nil

---@class BattleExpRewardModule
---@field ComputeVictoryExp fun(opts: BattleExpRewardOptions): integer, table

---@type BattleExpRewardModule
local M = {}

---@param opts BattleExpRewardOptions
---@return integer expReward
---@return table report RunEncounterBudget report
function M.ComputeVictoryExp(opts)
    opts = opts or {}
    local enemyIds = opts.enemyIds or {}
    local partySize = math.max(1, math.floor(tonumber(opts.partySize) or 4))
    local partyLevel = math.max(1, math.floor(tonumber(opts.partyLevel) or 1))
    local chapterMult = tonumber(opts.chapterMultiplier) or 1.0

    local metas = {}
    for _, enemyId in ipairs(enemyIds) do
        metas[#metas + 1] = EnemyData.GetChallengeMeta(enemyId)
    end

    local report = RunEncounterBudget.BuildReport(partyLevel, partySize, metas, "medium", 1.0)
    local scaled = math.floor(report.adjustedXp * Exp5e.PARTY_EXP_SCALE * chapterMult + 0.5)

    -- 不再 cap：单战 EXP = baseXp × countMult × chapterMult。
    return math.max(0, scaled), report
end

return M
