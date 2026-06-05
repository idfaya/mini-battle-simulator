local Exp5e = require("config.roguelike.exp_5e")

local RunEncounterBudget = {}

-- 与 exp_5e.MONSTER_XP_BY_CR 同源（DMG）。
RunEncounterBudget.CR_XP = Exp5e.MONSTER_XP_BY_CR
-- MiniBattle 的 4 人队 + 技能协同强于原生 5e 纸面阈值；这里统一做预算锚点校准。
RunEncounterBudget.ENGINE_PARTY_THRESHOLD_SCALE = 2.0

RunEncounterBudget.THRESHOLDS_BY_LEVEL = {
    [1] = { easy = 25,  medium = 50,   hard = 75,   deadly = 100 },
    [2] = { easy = 50,  medium = 100,  hard = 150,  deadly = 200 },
    [3] = { easy = 75,  medium = 150,  hard = 225,  deadly = 400 },
    [4] = { easy = 125, medium = 250,  hard = 375,  deadly = 500 },
    [5] = { easy = 250, medium = 500,  hard = 750,  deadly = 1100 },
    [6] = { easy = 300, medium = 600,  hard = 900,  deadly = 1400 },
    [7] = { easy = 350, medium = 750,  hard = 1100, deadly = 1700 },
    [8] = { easy = 450, medium = 900,  hard = 1400, deadly = 2100 },
    [9] = { easy = 550, medium = 1100, hard = 1600, deadly = 2400 },
    [10] = { easy = 600, medium = 1200, hard = 1900, deadly = 2800 },
    [11] = { easy = 800, medium = 1600, hard = 2400, deadly = 3600 },
    [12] = { easy = 1000, medium = 2000, hard = 3000, deadly = 4500 },
    [13] = { easy = 1100, medium = 2200, hard = 3400, deadly = 5100 },
    [14] = { easy = 1250, medium = 2500, hard = 3800, deadly = 5700 },
    [15] = { easy = 1400, medium = 2800, hard = 4300, deadly = 6400 },
    [16] = { easy = 1600, medium = 3200, hard = 4800, deadly = 7200 },
    [17] = { easy = 2000, medium = 3900, hard = 5900, deadly = 8800 },
    [18] = { easy = 2100, medium = 4200, hard = 6300, deadly = 9500 },
    [19] = { easy = 2400, medium = 4900, hard = 7300, deadly = 10900 },
    [20] = { easy = 2800, medium = 5700, hard = 8500, deadly = 12700 },
}

local function clampLevel(level)
    local numeric = tonumber(level) or 1
    if numeric < 1 then
        return 1
    end
    if numeric > 20 then
        return 20
    end
    return numeric
end

local function normalizePressureFactor(pressureFactor)
    local value = tonumber(pressureFactor)
    if value == nil then
        return 1.0
    end
    -- 旧配置把 pressureFactor 当作“增量”录入（0.10 = +10%）。
    if value > -0.95 and value < 0.95 then
        return math.max(0.05, 1.0 + value)
    end
    return math.max(0.05, value)
end

function RunEncounterBudget.GetCrXp(cr)
    return Exp5e.GetMonsterXpByCr(cr)
end

function RunEncounterBudget.GetCountMultiplier(monsterCount, partySize)
    local count = math.max(1, tonumber(monsterCount) or 1)
    local party = math.max(1, tonumber(partySize) or 3)
    local mult = 1
    if count == 1 then mult = 1
    elseif count == 2 then mult = 1.5
    elseif count <= 6 then mult = 2
    elseif count <= 10 then mult = 2.5
    elseif count <= 14 then mult = 3
    else mult = 4 end

    -- 5e DMG style adjustment for unusually small/large parties.
    if party < 3 then
        if mult == 1 then mult = 1.5
        elseif mult == 1.5 then mult = 2
        elseif mult == 2 then mult = 2.5
        elseif mult == 2.5 then mult = 3
        else mult = 4 end
    elseif party >= 6 then
        if mult == 4 then mult = 3
        elseif mult == 3 then mult = 2.5
        elseif mult == 2.5 then mult = 2
        elseif mult == 2 then mult = 1.5
        else mult = 1 end
    end
    return mult
end

function RunEncounterBudget.GetPartyThreshold(level, partySize, difficulty)
    local lv = clampLevel(level)
    local size = math.max(1, tonumber(partySize) or 3)
    local key = tostring(difficulty or "medium")
    local low = math.floor(lv)
    local high = math.min(20, math.ceil(lv))
    local lowRow = RunEncounterBudget.THRESHOLDS_BY_LEVEL[low] or RunEncounterBudget.THRESHOLDS_BY_LEVEL[1]
    local highRow = RunEncounterBudget.THRESHOLDS_BY_LEVEL[high] or lowRow
    local lowVal = tonumber(lowRow[key] or lowRow.medium or 0) or 0
    local highVal = tonumber(highRow[key] or highRow.medium or lowVal) or lowVal
    local t = lv - low
    local perHero = lowVal + (highVal - lowVal) * t
    return math.floor(perHero * size * RunEncounterBudget.ENGINE_PARTY_THRESHOLD_SCALE + 0.5)
end

function RunEncounterBudget.BuildReport(level, partySize, enemyMetas, difficulty, pressureFactor)
    local count = 0
    local baseXp = 0
    for _, meta in ipairs(enemyMetas or {}) do
        count = count + 1
        baseXp = baseXp + (tonumber(meta and meta.xp) or 0)
    end
    local mult = RunEncounterBudget.GetCountMultiplier(count, partySize)
    local adjustedXp = math.floor(baseXp * mult)
    local baseThreshold = RunEncounterBudget.GetPartyThreshold(level, partySize, difficulty)
    local pressureScalar = normalizePressureFactor(pressureFactor)
    local targetAdjustedXp = math.floor(baseThreshold * pressureScalar + 0.5)
    local ratio = targetAdjustedXp > 0 and (adjustedXp / targetAdjustedXp) or 1.0
    return {
        monsterCount = count,
        baseXp = baseXp,
        multiplier = mult,
        adjustedXp = adjustedXp,
        effectiveLevel = clampLevel(level),
        baseThreshold = baseThreshold,
        targetDifficulty = difficulty or "medium",
        targetAdjustedXp = targetAdjustedXp,
        pressureFactor = tonumber(pressureFactor) or 1.0,
        pressureScalar = pressureScalar,
        ratio = ratio,
    }
end

return RunEncounterBudget
