local RunCampConfig = require("config.roguelike.run_camp_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local CardBattle = require("roguelike.card_battle")

local RoguelikeCamp = {}

local NEGATIVE_BLESSING_TAGS = {
    curse = true,
    negative = true,
    debuff = true,
}

local function clearAllStatuses(hero)
    if not hero then
        return
    end
    hero.buffs = {}
    hero.debuffs = {}
    hero.statuses = {}
    hero.riskHooks = nil
end

local function isNegativeBlessing(blessingId)
    local entry = RunBlessingConfig.GetBlessing(tonumber(blessingId) or -1)
    if not entry then
        return false
    end
    for _, tag in ipairs(entry.tags or {}) do
        if NEGATIVE_BLESSING_TAGS[tag] then
            return true
        end
    end
    return false
end

local function removeNegativeBlessings(runState)
    local kept = {}
    for _, blessingId in ipairs(runState.blessingIds or {}) do
        if not isNegativeBlessing(blessingId) then
            kept[#kept + 1] = blessingId
        end
    end
    runState.blessingIds = kept
end

local function healOwnedToFull(runState)
    for _, hero in ipairs(RoguelikeRoster.GetOwnedUnits(runState)) do
        if not hero.isDead then
            hero.currentHp = tonumber(hero.maxHp) or tonumber(hero.currentHp) or 0
        end
    end
end

local function refreshOwnedResources(runState)
    for _, hero in ipairs(RoguelikeRoster.GetOwnedUnits(runState)) do
        clearAllStatuses(hero)
        hero.skillCooldowns = {}
        hero.ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1
        hero.ultimateCharges = hero.ultimateChargesMax
    end
end

local function reviveOneAtFull(runState)
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if hero.isDead then
            hero.isDead = false
            hero.currentHp = tonumber(hero.maxHp) or 1
            clearAllStatuses(hero)
            hero.skillCooldowns = {}
            hero.ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1
            hero.ultimateCharges = hero.ultimateChargesMax
            return true
        end
    end
    return false
end

--- dungeon §4.5：全队回满 + 清全队负面状态/负面祝福 + 复活 1 名（满血）。
function RoguelikeCamp.ApplyReviveFullRest(runState)
    if type(runState) ~= "table" then
        return false, "invalid_run_state"
    end

    healOwnedToFull(runState)
    refreshOwnedResources(runState)
    removeNegativeBlessings(runState)
    local revived = reviveOneAtFull(runState)

    if revived then
        runState.lastActionMessage = "营地安息：全队回满并清状态，复活一名队友"
    else
        runState.lastActionMessage = "营地安息：全队回满并清状态"
    end
    return true
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
        local reason = nil
        if action.effectType == "purify_one_curse" and #CardBattle.GetCurseCards(runState) <= 0 then
            available = false
            reason = "没有可净化的诅咒"
        end
        actions[#actions + 1] = {
            id = action.id,
            label = action.label,
            available = available,
            reason = reason,
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
    if selected.effectType == "revive_full_rest" then
        return RoguelikeCamp.ApplyReviveFullRest(runState)
    end
    if selected.effectType == "purify_one_curse" then
        local ok, result = CardBattle.PurifyOneCurse(runState)
        if not ok then
            return false, result
        end
        runState.lastActionMessage = "营地净化：" .. tostring(result.cardName or "诅咒")
        return true
    end

    return false, "unsupported_action"
end

return RoguelikeCamp
