local RunEncounterBudget = {}

RunEncounterBudget.CR_XP = {
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
}

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
}

local function normalizeCrKey(cr)
    if cr == nil then
        return "0"
    end
    if type(cr) == "number" then
        if math.abs(cr - 0.125) < 0.0001 then return "1/8" end
        if math.abs(cr - 0.25) < 0.0001 then return "1/4" end
        if math.abs(cr - 0.5) < 0.0001 then return "1/2" end
        return tostring(math.floor(cr))
    end
    local s = tostring(cr)
    if s == "" then
        return "0"
    end
    return s
end

function RunEncounterBudget.GetCrXp(cr)
    return RunEncounterBudget.CR_XP[normalizeCrKey(cr)] or 0
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
    local lv = math.max(1, math.min(10, tonumber(level) or 1))
    local size = math.max(1, tonumber(partySize) or 3)
    local key = tostring(difficulty or "medium")
    local row = RunEncounterBudget.THRESHOLDS_BY_LEVEL[lv] or RunEncounterBudget.THRESHOLDS_BY_LEVEL[1]
    return (row[key] or row.medium or 0) * size
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
    local targetAdjustedXp = math.floor(baseThreshold * (tonumber(pressureFactor) or 1.0))
    local ratio = targetAdjustedXp > 0 and (adjustedXp / targetAdjustedXp) or 1.0
    return {
        monsterCount = count,
        baseXp = baseXp,
        multiplier = mult,
        adjustedXp = adjustedXp,
        targetDifficulty = difficulty or "medium",
        targetAdjustedXp = targetAdjustedXp,
        pressureFactor = tonumber(pressureFactor) or 1.0,
        ratio = ratio,
    }
end

return RunEncounterBudget
