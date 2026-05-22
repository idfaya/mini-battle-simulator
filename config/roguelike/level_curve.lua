-- ==========================================================================
-- 队伍 EXP 阈值
-- 唯一权威来源（SSOT）：所有运行时模块统一从本文件读取等级曲线，禁止散写。
--
-- 阶段 1 收尾打磨（2026-05-21 v3）：partyLevel 语义改为"已发生的三选一次数 + 1"。
--   设计 §3：每次三选一只升 1 个英雄；4 人队全员 Lv1→Lv8 = 28 次升级，
--   故 CHAPTER_LEVEL_CAP = 32（留 4 次余量给死亡复活补抽）。
--   阈值采用线性 +4 EXP/级步长（6→4 缩短，避免 expReward 累积不足以解锁全部 picks）。
--   配合 run_battle_template.lua 的 expReward，battle-heavy 路径 boss 时累计升级 ≈ 28 次（4 人≈Lv8）。
--
-- 注意：runtime 中 partyLevel 不再代表"角色平均等级"；hero.level 由 FeatPicker.Pick 单独 +1。
-- ==========================================================================

local LEVEL_STEP_EXP = 4

local function buildThresholds(cap)
    local t = { [1] = 0 }
    for lv = 2, cap do
        t[lv] = (lv - 1) * LEVEL_STEP_EXP
    end
    return t
end

local CHAPTER_LEVEL_CAP = 32

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
