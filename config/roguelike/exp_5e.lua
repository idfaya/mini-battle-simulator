-- ==========================================================================
-- D&D 5e 经验表（SSOT）
-- 角色升级：PHB 角色成长表（累计 XP）
-- 怪物掉落：DMG 按 CR 的 XP + 遭遇数量倍率（见 run_encounter_budget.lua）
--
-- 队伍 EXP 池：整场遭遇的调整后 XP 进入 partyExp（不按 5e 规则在队员间平分）。
-- PARTY_EXP_SCALE：Run 内缩放（1 = 原版 5e 数值；<1 可放慢三章总成长）。
-- ==========================================================================

---@class Exp5eModule
---@field PARTY_EXP_SCALE number
---@field MAX_CHARACTER_LEVEL integer
---@field CHARACTER_LEVEL_EXP table<integer, integer>
---@field MONSTER_XP_BY_CR table<string, integer>
---@field GetCharacterExpThreshold fun(level: integer): integer
---@field GetExpToNextLevel fun(level: integer, cap?: integer): integer
---@field GetLevelForExp fun(totalExp: integer, cap?: integer): integer
---@field GetMonsterXpByCr fun(cr: string|number): integer
---@field GetDisplayLevelByCr fun(cr: string|number): integer
---@field NormalizeCrKey fun(cr: string|number|nil): string

local M = {}

-- PHB 角色等级累计经验（Lv1 = 0）。
M.CHARACTER_LEVEL_EXP = {
    [1] = 0,
    [2] = 300,
    [3] = 900,
    [4] = 2700,
    [5] = 6500,
    [6] = 14000,
    [7] = 23000,
    [8] = 34000,
    [9] = 48000,
    [10] = 64000,
    [11] = 85000,
    [12] = 100000,
    [13] = 120000,
    [14] = 140000,
    [15] = 165000,
    [16] = 195000,
    [17] = 225000,
    [18] = 265000,
    [19] = 305000,
    [20] = 355000,
}

-- DMG 怪物 XP（按挑战等级 CR）。
M.MONSTER_XP_BY_CR = {
    ["0"] = 10,
    ["1/8"] = 25,
    ["1/4"] = 50,
    ["1/2"] = 100,
    ["1"] = 200,
    ["2"] = 450,
    ["3"] = 700,
    ["4"] = 1100,
    ["5"] = 1800,
    ["6"] = 2300,
    ["7"] = 2900,
    ["8"] = 3900,
    ["9"] = 5000,
    ["10"] = 5900,
    ["11"] = 7200,
    ["12"] = 8400,
    ["13"] = 10000,
    ["14"] = 11500,
    ["15"] = 13000,
    ["16"] = 15000,
    ["17"] = 18000,
    ["18"] = 20000,
    ["19"] = 22000,
    ["20"] = 25000,
    ["21"] = 33000,
    ["22"] = 41000,
    ["23"] = 50000,
    ["24"] = 62000,
    ["25"] = 75000,
    ["26"] = 90000,
    ["27"] = 105000,
    ["28"] = 120000,
    ["29"] = 135000,
    ["30"] = 155000,
}

-- DMG 编遭遇表：4 人队对单怪「中等难度」时，CR 与队伍等级的对照（展示用，不影响模板强度）。
-- 与 MONSTER_XP_BY_CR 并列，为 enemies.json Level 的配置口径 SSOT。
M.MONSTER_DISPLAY_LEVEL_BY_CR = {
    ["0"] = 1,
    ["1/8"] = 1,
    ["1/4"] = 2,
    ["1/2"] = 3,
    ["1"] = 5,
    ["2"] = 7,
    ["3"] = 9,
    ["4"] = 11,
    ["5"] = 13,
    ["6"] = 15,
    ["7"] = 16,
    ["8"] = 17,
    ["9"] = 18,
    ["10"] = 19,
    ["11"] = 20,
    ["12"] = 21,
    ["13"] = 22,
    ["14"] = 23,
    ["15"] = 24,
    ["16"] = 25,
    ["17"] = 26,
    ["18"] = 27,
    ["19"] = 28,
    ["20"] = 29,
    ["21"] = 30,
    ["22"] = 31,
    ["23"] = 32,
    ["24"] = 33,
    ["25"] = 34,
    ["26"] = 35,
    ["27"] = 36,
    ["28"] = 37,
    ["29"] = 38,
    ["30"] = 39,
}

M.MAX_CHARACTER_LEVEL = 20
M.PARTY_EXP_SCALE = 1.0
-- 5e 原版每次升级是全队一起升；本工程改为「每次三选一只升 1 个英雄」，
-- 因此 partyExp → partyLevel 的阈值需要按 4 人队规模等比缩小，
-- 否则 4 名英雄共享一个 5e 单角色阈值，会让 3/4 队员长期落后于 floorBaseline。
-- 0.50 = 4 人队 / 单角色升级 + "一战最多跨 1 阈值"的折中：
--   原 0.25 让 Lv3 阈值仅 225，单战 ~300 EXP 一次性跨 Lv2/Lv3，节奏过快；
--   0.50 → Lv2=150, Lv3=450，单战正好 +1 级。
M.PARTY_EXP_THRESHOLD_SCALE = 0.50
M.STARTER_LEVEL = 1

local function normalizeCrKey(cr)
    if cr == nil then
        return "0"
    end
    if type(cr) == "number" then
        if math.abs(cr - 0.125) < 0.0001 then
            return "1/8"
        end
        if math.abs(cr - 0.25) < 0.0001 then
            return "1/4"
        end
        if math.abs(cr - 0.5) < 0.0001 then
            return "1/2"
        end
        return tostring(math.floor(cr))
    end
    local s = tostring(cr)
    if s == "" then
        return "0"
    end
    return s
end

M.NormalizeCrKey = normalizeCrKey

function M.GetMonsterXpByCr(cr)
    return M.MONSTER_XP_BY_CR[normalizeCrKey(cr)] or 0
end

function M.GetDisplayLevelByCr(cr)
    return M.MONSTER_DISPLAY_LEVEL_BY_CR[normalizeCrKey(cr)] or 1
end

function M.GetCharacterExpThreshold(level)
    local lv = math.max(M.STARTER_LEVEL, math.floor(tonumber(level) or M.STARTER_LEVEL))
    local raw = M.CHARACTER_LEVEL_EXP[lv] or M.CHARACTER_LEVEL_EXP[M.MAX_CHARACTER_LEVEL] or 0
    -- PARTY_EXP_SCALE：Run 内统一缩放（旧字段，默认 1.0）。
    -- PARTY_EXP_THRESHOLD_SCALE：补偿"每次三选一只升 1 人"导致的 partyExp 池稀释。
    return math.max(0, math.floor(raw * M.PARTY_EXP_SCALE * M.PARTY_EXP_THRESHOLD_SCALE + 0.5))
end

function M.GetExpToNextLevel(level, cap)
    local lv = math.max(M.STARTER_LEVEL, math.floor(tonumber(level) or M.STARTER_LEVEL))
    local levelCap = math.max(M.STARTER_LEVEL, math.floor(tonumber(cap) or M.MAX_CHARACTER_LEVEL))
    if lv >= levelCap then
        return 0
    end
    local nextThreshold = M.GetCharacterExpThreshold(lv + 1)
    local currentThreshold = M.GetCharacterExpThreshold(lv)
    return math.max(1, nextThreshold - currentThreshold)
end

function M.GetLevelForExp(totalExp, cap)
    local levelCap = math.max(M.STARTER_LEVEL, math.floor(tonumber(cap) or M.MAX_CHARACTER_LEVEL))
    local exp = math.max(0, math.floor(tonumber(totalExp) or 0))
    local current = M.STARTER_LEVEL
    for lv = M.STARTER_LEVEL + 1, levelCap do
        if exp >= M.GetCharacterExpThreshold(lv) then
            current = lv
        else
            break
        end
    end
    return current
end

return M
