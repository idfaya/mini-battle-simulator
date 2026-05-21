-- ==========================================================================
-- 队伍 EXP 阈值（章节级 cap=10）
-- 唯一权威来源（SSOT）：所有运行时模块统一从本文件读取等级曲线，禁止散写。
--
-- 阶段 1 收尾打磨（2026-05-21）：阈值对齐 5e 累计经验语义（缩放：约 1/300）。
-- 配合 run_battle_template.lua 的 expReward，最优 battle-heavy 路径 boss 时
-- 达 Lv8~Lv9，economy-heavy 路径达 Lv6~Lv7，避免 boss profile level=3 倒挂。
--   预期 EXP 节奏（章节末累计 EXP / partyLevel）：
--     - economy-heavy（3 战+boss）   ≈ 145 EXP → Lv7
--     - mixed（4 战+boss）           ≈ 195 EXP → Lv8
--     - battle-heavy（5 战+boss）    ≈ 218 EXP → Lv9
-- ==========================================================================

local M = {
    LEVEL_EXP_THRESHOLDS = {
        [1] = 0,
        [2] = 8,
        [3] = 20,
        [4] = 36,
        [5] = 58,
        [6] = 86,
        [7] = 120,
        [8] = 160,
        [9] = 208,
        [10] = 264,
    },
    STARTER_LEVEL = 1,
    CHAPTER_LEVEL_CAP = 10,
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
