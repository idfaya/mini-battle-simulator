local RunEventConfig = require("config.roguelike.run_event_config")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local EventResolver = require("roguelike.event_resolver")

local RoguelikeEvent = {}

local function applyTeamHeal(runState, healPct)
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if not hero.isDead then
            local heal = math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0))
            hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
        end
    end
end

local function applyHpCost(runState, costType, costValue)
    local pct = tonumber(costValue) or 0
    if pct <= 0 then
        return true
    end
    local anyAlive = false
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if not hero.isDead then
            anyAlive = true
            local base = hero.maxHp or 0
            if costType == "current_hp_pct" then
                base = hero.currentHp or 0
            end
            local loss = math.floor(base * pct)
            hero.currentHp = math.max(1, (hero.currentHp or 0) - loss)
        end
    end
    return anyAlive
end

local function hasEnoughGold(runState, amount)
    return (runState.gold or 0) >= (tonumber(amount) or 0)
end

local function consumeGold(runState, amount)
    local cost = tonumber(amount) or 0
    runState.gold = math.max(0, (runState.gold or 0) - cost)
end

local function findHeroByRosterId(runState, rosterHeroId)
    local target = tonumber(rosterHeroId)
    if not target then
        return nil
    end
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if tonumber(hero.rosterId) == target then
            return hero
        end
    end
    return nil
end

local function formatSkillCheckMessage(outcome)
    if not outcome then
        return "事件已结算"
    end
    return string.format(
        "检定 %s d20(%d)+%d=%d vs DC%d → %s",
        tostring(outcome.ability or "?"),
        tonumber(outcome.roll) or 0,
        tonumber(outcome.modifier) or 0,
        tonumber(outcome.total) or 0,
        tonumber(outcome.dc) or 0,
        tostring(outcome.tier or "?")
    )
end

local function applyResult(runState, resultType, result, skillCheckOutcome)
    result = result or {}

    if resultType == "grant_gold" then
        runState.gold = (runState.gold or 0) + (tonumber(result.gold) or 0)
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        if not skillCheckOutcome then
            runState.lastActionMessage = "事件获得金币"
        end
        return true, { kind = "done" }
    end
    if resultType == "team_heal_pct" then
        applyTeamHeal(runState, result.value)
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        if not skillCheckOutcome then
            runState.lastActionMessage = "事件治疗"
        end
        return true, { kind = "done" }
    end
    if resultType == "grant_blessing" then
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        return true, { kind = "blessing", blessingId = result.blessingId }
    end
    if resultType == "grant_equipment" then
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        return true, { kind = "equipment", equipmentId = result.equipmentId }
    end
    if resultType == "trigger_battle" then
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        return true, { kind = "battle", battleId = result.battleId, rewardGroupId = result.rewardGroupId }
    end
    if resultType == "unlock_hidden_floor" then
        runState.lastActionMessage = "发现隐藏层入口"
        return true, { kind = "unlock_hidden_floor" }
    end

    return false, "unsupported_result"
end

function RoguelikeEvent.GetEvent(eventId)
    return RunEventConfig.GetEvent(eventId)
end

---@param runState table
---@param eventId integer
---@param optionId integer
---@param rosterHeroId integer|nil 可选：指定出面英雄；检定选项未指定时自动选修正最高者
function RoguelikeEvent.ResolveOption(runState, eventId, optionId, rosterHeroId)
    local event = RoguelikeEvent.GetEvent(eventId)
    if not event then
        return false, "event_not_found"
    end

    local selected = nil
    for _, opt in ipairs(event.options or {}) do
        if opt.id == optionId then
            selected = opt
            break
        end
    end
    if not selected then
        return false, "option_not_found"
    end

    if selected.costType == "gold" then
        if not hasEnoughGold(runState, selected.costValue) then
            return false, "not_enough_gold"
        end
        consumeGold(runState, selected.costValue)
    elseif selected.costType == "current_hp_pct" or selected.costType == "hp_pct" then
        local ok = applyHpCost(runState, selected.costType, selected.costValue)
        if not ok then
            return false, "no_alive_heroes"
        end
    end

    local actor = findHeroByRosterId(runState, rosterHeroId)
    local resultType, result, skillCheckOutcome, resolveReason = EventResolver.ResolveOptionOutcome(
        runState,
        actor,
        selected
    )
    if not resultType then
        return false, resolveReason or "resolve_failed"
    end

    if skillCheckOutcome and runState.eventState then
        runState.eventState.lastSkillCheck = skillCheckOutcome
    end

    return applyResult(runState, resultType, result, skillCheckOutcome)
end

return RoguelikeEvent
