-- 战斗胜利队伍 EXP：5e 遭遇 XP（CR 表 + 数量倍率）+ 敌方等级缩放。
local Exp5e = require("config.roguelike.exp_5e")
local RunEncounterBudget = require("config.roguelike.run_encounter_budget")
local EnemyData = require("config.enemy_data")

---@class BattleExpRewardOptions
---@field enemyIds integer[]
---@field partySize integer
---@field partyLevel integer
---@field levelCap integer|nil
---@field enemyLevel integer|nil
---@field chapterMultiplier number|nil

---@class BattleExpRewardModule
---@field ENEMY_LEVEL_XP_FACTOR number
---@field ComputeVictoryExp fun(opts: BattleExpRewardOptions): integer, table

---@type BattleExpRewardModule
local M = {}

-- 遭遇内怪物「生成等级」高于 1 时，在 5e CR 经验上按级递增（非 RAW，用于 Run 内成长同步）。
-- 怪物等级对遭遇 XP 的加成；第一章普通怪固定 Lv1–5 时靠此系数维持升级节奏。
M.ENEMY_LEVEL_XP_FACTOR = 0.70

---@param opts BattleExpRewardOptions
---@return integer expReward
---@return table report RunEncounterBudget report
function M.ComputeVictoryExp(opts)
    opts = opts or {}
    local enemyIds = opts.enemyIds or {}
    local partySize = math.max(1, math.floor(tonumber(opts.partySize) or 4))
    local partyLevel = math.max(1, math.floor(tonumber(opts.partyLevel) or 1))
    local levelCap = tonumber(opts.levelCap) or Exp5e.MAX_CHARACTER_LEVEL
    local enemyLevel = math.max(1, math.floor(tonumber(opts.enemyLevel) or 1))
    local chapterMult = tonumber(opts.chapterMultiplier) or 1.0

    local metas = {}
    for _, enemyId in ipairs(enemyIds) do
        metas[#metas + 1] = EnemyData.GetChallengeMeta(enemyId)
    end

    local report = RunEncounterBudget.BuildReport(partyLevel, partySize, metas, "medium", 1.0)
    local levelScale = 1 + (enemyLevel - 1) * M.ENEMY_LEVEL_XP_FACTOR
    local scaled = math.floor(report.adjustedXp * Exp5e.PARTY_EXP_SCALE * levelScale * chapterMult + 0.5)

    -- 遭遇怪物等级高于队伍时，单场 EXP 上限随怪物等级放宽（仍不超过 partyLevel+4 档的步长）。
    -- 注意：阈值表已被 PARTY_EXP_THRESHOLD_SCALE 缩放（4 人队 / 单角色升级），但单场战斗的物理量
    -- 应保持 5e 原版水平（一场 medium ≈ 5e 单角色 1 级），所以 cap 反向缩放回去。
    local capLevel = math.max(partyLevel, math.min(enemyLevel, partyLevel + 4))
    local maxSingleScaled = Exp5e.GetExpToNextLevel(capLevel, levelCap)
    local thresholdScale = (Exp5e.PARTY_EXP_THRESHOLD_SCALE or 1.0)
    local maxSingle = thresholdScale > 0 and (maxSingleScaled / thresholdScale) or maxSingleScaled
    if maxSingle > 0 then
        scaled = math.min(scaled, math.floor(maxSingle + 0.5))
    end

    return math.max(0, scaled), report
end

return M
