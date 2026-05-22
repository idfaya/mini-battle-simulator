-- ==========================================================================
-- 队伍 EXP 阈值
-- 唯一权威来源（SSOT）：所有运行时模块统一从本文件读取等级曲线，禁止散写。
--
-- D1.5 迷宫节奏重调（2026-05-22）：完整 3 章约 38~39 场战斗，
-- 10 级上限只需要 9 次队伍等级提升。固定 20 EXP/级，配合单战
-- expReward <= 8，确保单场战斗最多只跨 1 个 partyLevel。
local LEVEL_STEP_EXP = 20

local function buildThresholds(cap)
    local t = { [1] = 0 }
    for lv = 2, cap do
        t[lv] = (lv - 1) * LEVEL_STEP_EXP
    end
    return t
end

local CHAPTER_LEVEL_CAP = 10

local M = {
    LEVEL_EXP_THRESHOLDS = buildThresholds(CHAPTER_LEVEL_CAP),
    STARTER_LEVEL = 1,
    CHAPTER_LEVEL_CAP = CHAPTER_LEVEL_CAP,
}

-- 累计经验阈值：超出 cap 时回退到 cap 阈值。
function M.GetExpThreshold(level)
    local lv = math.max(M.STARTER_LEVEL, tonumber(level) or M.STARTER_LEVEL)
    return M.LEVEL_EXP_THRESHOLDS[lv] or M.LEVEL_EXP_THRESHOLDS[M.CHAPTER_LEVEL_CAP] or 0
end

-- 当前等级跨入下一级所需的增量经验；已达 cap 时返回 0。
function M.GetExpToNextLevel(level, cap)
    local lv = math.max(M.STARTER_LEVEL, tonumber(level) or M.STARTER_LEVEL)
    local levelCap = math.max(M.STARTER_LEVEL, tonumber(cap) or M.CHAPTER_LEVEL_CAP)
    if lv >= levelCap then
        return 0
    end
    return math.max(1, M.GetExpThreshold(lv + 1) - M.GetExpThreshold(lv))
end

-- 根据累计经验推导对应的等级（≤ cap）。
function M.GetLevelForExp(exp, cap)
    local levelCap = math.max(M.STARTER_LEVEL, tonumber(cap) or M.CHAPTER_LEVEL_CAP)
    local totalExp = math.max(0, math.floor(tonumber(exp) or 0))
    local current = M.STARTER_LEVEL
    for lv = M.STARTER_LEVEL + 1, levelCap do
        if totalExp >= M.GetExpThreshold(lv) then
            current = lv
        else
            break
        end
    end
    return current
end

return M
