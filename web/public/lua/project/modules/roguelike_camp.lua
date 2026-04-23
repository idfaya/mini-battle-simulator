local RunCampConfig = require("config.roguelike.run_camp_config")

local RoguelikeCamp = {}

local function applyTeamHeal(runState, healPct)
    for _, hero in ipairs(runState.teamRoster or {}) do
        if not hero.isDead then
            local heal = math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0))
            hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
        end
    end
end

local function restoreUltimateCharges(runState)
    for _, hero in ipairs(runState.teamRoster or {}) do
        hero.ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1
        hero.ultimateCharges = hero.ultimateChargesMax
    end
    for _, hero in ipairs(runState.benchRoster or {}) do
        hero.ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1
        hero.ultimateCharges = hero.ultimateChargesMax
    end
end

local function reviveOne(runState, healPct)
    for _, hero in ipairs(runState.teamRoster or {}) do
        if hero.isDead then
            hero.isDead = false
            hero.currentHp = math.max(1, math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0)))
            return true
        end
    end
    return false
end

function RoguelikeCamp.GetCamp(campId)
    return RunCampConfig.GetCamp(campId)
end

function RoguelikeCamp.BuildCampState(campId, runState)
    local camp = RoguelikeCamp.GetCamp(campId)
    if not camp then
        return nil
    end

    local actions = {}
    for _, action in ipairs(camp.actions or {}) do
        local available = true
        if (action.requirements or {}).hasDeadHero then
            available = false
            for _, hero in ipairs(runState.teamRoster or {}) do
                if hero.isDead then
                    available = true
                    break
                end
            end
        end

        actions[#actions + 1] = {
            id = action.id,
            label = action.label,
            available = available,
        }
    end

    return {
        campId = campId,
        name = camp.name or "Camp",
        actions = actions,
    }
end

function RoguelikeCamp.ApplyAction(runState, campId, actionId)
    local camp = RoguelikeCamp.GetCamp(campId)
    if not camp then
        return false, "camp_not_found"
    end

    local selected = nil
    for _, action in ipairs(camp.actions or {}) do
        if action.id == actionId then
            selected = action
            break
        end
    end
    if not selected then
        return false, "action_not_found"
    end

    if selected.effectType == "team_heal_pct" then
        applyTeamHeal(runState, (selected.params or {}).value)
        restoreUltimateCharges(runState)
        runState.lastActionMessage = "营地休息，大招次数恢复"
        return true
    end
    if selected.effectType == "grant_blessing" then
        runState.blessingIds = runState.blessingIds or {}
        runState.blessingIds[#runState.blessingIds + 1] = (selected.params or {}).blessingId
        runState.lastActionMessage = "营地强化"
        return true
    end
    if selected.effectType == "revive_one" then
        local revived = reviveOne(runState, (selected.params or {}).healPct or 0.5)
        if not revived then
            return false, "no_dead_hero"
        end
        runState.lastActionMessage = "营地复活"
        return true
    end

    return false, "unsupported_action"
end

return RoguelikeCamp
