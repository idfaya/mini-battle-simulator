-- ==========================================================================
-- 队伍 EXP 阈值（转发 5e SSOT：config/roguelike/exp_5e.lua）
-- ==========================================================================
local Exp5e = require("config.roguelike.exp_5e")

---@class LevelCurveModule
---@field LEVEL_EXP_THRESHOLDS table<integer, integer>
---@field STARTER_LEVEL integer
---@field CHAPTER_LEVEL_CAP integer
---@field LEVEL_STEP_EXP number|nil
---@field GetExpThreshold fun(level: integer): integer
---@field GetExpToNextLevel fun(level: integer, cap?: integer): integer
---@field GetLevelForExp fun(exp: integer, cap?: integer): integer

local function buildThresholds(cap)
    local t = {}
    for lv = 1, cap do
        t[lv] = Exp5e.GetCharacterExpThreshold(lv)
    end
    return t
end

local CHAPTER_LEVEL_CAP = Exp5e.MAX_CHARACTER_LEVEL

---@type LevelCurveModule
local M = {
    STARTER_LEVEL = Exp5e.STARTER_LEVEL,
    CHAPTER_LEVEL_CAP = CHAPTER_LEVEL_CAP,
    LEVEL_EXP_THRESHOLDS = buildThresholds(CHAPTER_LEVEL_CAP),
}

function M.GetExpThreshold(level)
    return Exp5e.GetCharacterExpThreshold(level)
end

function M.GetExpToNextLevel(level, cap)
    return Exp5e.GetExpToNextLevel(level, cap)
end

function M.GetLevelForExp(exp, cap)
    return Exp5e.GetLevelForExp(exp, cap)
end

-- 兼容旧测试：Lv1→2 的增量（随 PARTY_EXP_SCALE 变化）。
M.LEVEL_STEP_EXP = M.GetExpToNextLevel(1, CHAPTER_LEVEL_CAP)

return M
