local RoguelikeRoster = {}

local function isBenchUnit(unit)
    return unit and unit.teamState == "bench"
end

local function normalizeTeamState(unit, fallbackState)
    if not unit then
        return
    end
    if unit.teamState == "bench" or unit.teamState == "dead" or unit.teamState == "active" then
        return
    end
    unit.teamState = fallbackState or "active"
end

local function ensureOwnedUnits(runState)
    runState.ownedUnits = runState.ownedUnits or {}
    if #runState.ownedUnits > 0 then
        return runState.ownedUnits
    end

    local owned = {}
    local seen = {}
    for _, unit in ipairs(runState.teamRoster or {}) do
        if unit and not seen[unit] then
            normalizeTeamState(unit, "active")
            owned[#owned + 1] = unit
            seen[unit] = true
        end
    end
    for _, unit in ipairs(runState.benchRoster or {}) do
        if unit and not seen[unit] then
            unit.teamState = "bench"
            owned[#owned + 1] = unit
            seen[unit] = true
        end
    end
    runState.ownedUnits = owned
    return runState.ownedUnits
end

function RoguelikeRoster.RefreshLegacyViews(runState)
    local owned = ensureOwnedUnits(runState)
    local teamRoster = {}
    local benchRoster = {}
    for _, unit in ipairs(owned) do
        normalizeTeamState(unit, "active")
        if isBenchUnit(unit) then
            benchRoster[#benchRoster + 1] = unit
        else
            teamRoster[#teamRoster + 1] = unit
        end
    end
    runState.teamRoster = teamRoster
    runState.benchRoster = benchRoster
    return teamRoster, benchRoster
end

function RoguelikeRoster.GetOwnedUnits(runState)
    return ensureOwnedUnits(runState)
end

function RoguelikeRoster.GetTeamUnits(runState)
    return RoguelikeRoster.RefreshLegacyViews(runState)
end

function RoguelikeRoster.GetBenchUnits(runState)
    RoguelikeRoster.RefreshLegacyViews(runState)
    return runState.benchRoster
end

function RoguelikeRoster.GetTeamUnitCount(runState)
    local teamRoster = RoguelikeRoster.GetTeamUnits(runState)
    return #teamRoster
end

function RoguelikeRoster.FindOwnedUnitByRosterId(runState, rosterId)
    local targetId = tonumber(rosterId)
    if not targetId then
        return nil, nil
    end
    for index, unit in ipairs(ensureOwnedUnits(runState)) do
        if tonumber(unit.rosterId) == targetId then
            return index, unit
        end
    end
    return nil, nil
end

function RoguelikeRoster.AddOwnedUnit(runState, unit, teamState)
    if not unit then
        return nil
    end
    local owned = ensureOwnedUnits(runState)
    unit.teamState = teamState or unit.teamState or "active"
    owned[#owned + 1] = unit
    RoguelikeRoster.RefreshLegacyViews(runState)
    return unit
end

function RoguelikeRoster.PromoteBenchHero(runState, benchRosterId)
    local _, unit = RoguelikeRoster.FindOwnedUnitByRosterId(runState, benchRosterId)
    if not unit or unit.teamState ~= "bench" then
        return false, "bench_hero_not_found"
    end
    if RoguelikeRoster.GetTeamUnitCount(runState) >= (runState.maxHeroCount or 5) then
        return false, "team_full"
    end
    unit.teamState = "active"
    RoguelikeRoster.RefreshLegacyViews(runState)
    return true, unit
end

function RoguelikeRoster.SwapBenchWithTeam(runState, benchRosterId, teamRosterId)
    local owned = ensureOwnedUnits(runState)
    local benchIndex, benchHero = RoguelikeRoster.FindOwnedUnitByRosterId(runState, benchRosterId)
    local teamIndex, teamHero = RoguelikeRoster.FindOwnedUnitByRosterId(runState, teamRosterId)
    if not benchIndex or not benchHero or benchHero.teamState ~= "bench" then
        return false, "bench_hero_not_found"
    end
    if not teamIndex or not teamHero or teamHero.teamState == "bench" then
        return false, "team_hero_not_found"
    end

    owned[benchIndex], owned[teamIndex] = owned[teamIndex], owned[benchIndex]
    benchHero.teamState = "active"
    teamHero.teamState = "bench"
    RoguelikeRoster.RefreshLegacyViews(runState)
    return true, benchHero, teamHero
end

return RoguelikeRoster
