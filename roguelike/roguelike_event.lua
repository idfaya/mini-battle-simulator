local RunEventConfig = require("config.roguelike.run_event_config")

local RoguelikeEvent = {}

local function applyTeamHeal(runState, healPct)
    for _, hero in ipairs(runState.teamRoster or {}) do
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
    for _, hero in ipairs(runState.teamRoster or {}) do
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

function RoguelikeEvent.GetEvent(eventId)
    return RunEventConfig.GetEvent(eventId)
end

function RoguelikeEvent.ResolveOption(runState, eventId, optionId)
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

    local resultType = selected.resultType
    local result = selected.result or {}

    if resultType == "grant_gold" then
        runState.gold = (runState.gold or 0) + (tonumber(result.gold) or 0)
        runState.lastActionMessage = "事件获得金币"
        return true, { kind = "done" }
    end
    if resultType == "team_heal_pct" then
        applyTeamHeal(runState, result.value)
        runState.lastActionMessage = "事件治疗"
        return true, { kind = "done" }
    end
    if resultType == "grant_recruit" then
        return true, { kind = "recruit", heroId = result.heroId }
    end
    if resultType == "grant_blessing" then
        return true, { kind = "blessing", blessingId = result.blessingId }
    end
    if resultType == "grant_relic" then
        return true, { kind = "relic", relicId = result.relicId }
    end
    if resultType == "grant_reward_group" then
        return true, { kind = "reward_group", rewardGroupId = result.rewardGroupId }
    end
    if resultType == "trigger_battle" then
        return true, { kind = "battle", encounterId = result.encounterId, rewardGroupId = result.rewardGroupId }
    end

    return false, "unsupported_result"
end

return RoguelikeEvent
