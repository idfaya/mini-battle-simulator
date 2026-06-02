local RunEventConfig = require("config.roguelike.run_event_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local EventResolver = require("roguelike.event_resolver")

local RoguelikeEvent = {}

-- 事件解析成功后给队伍的小额 EXP：按"事件 ≈ 1/4 场普通遭遇"。
-- F1 第一战 ~300 EXP，事件 ~75 EXP 让玩家明确感觉"事件房有产出"，
-- 但不至于让 event-heavy 路线节奏倒挂战斗路线。
local EVENT_BASE_EXP = 75
-- 按 partyLevel 缩放（与 5e ENEMY_LEVEL_XP_FACTOR 同样的乘法系数），保证后期事件不会太微薄。
local EVENT_LEVEL_FACTOR = 0.50

local function grantEventExp(runState, skillCheckOutcome)
    local partyLevel = math.max(1, math.floor(tonumber(runState.partyLevel) or 1))
    local levelScale = 1 + (partyLevel - 1) * EVENT_LEVEL_FACTOR
    local exp = math.max(0, math.floor(EVENT_BASE_EXP * levelScale + 0.5))
    -- 检定 critical_failure 不给 EXP；其他档位（含 failure）都给：失败也是经验来源（5e 风格）。
    if skillCheckOutcome and skillCheckOutcome.tier == "critFailure" then
        exp = 0
    end
    runState.lastEventExpReward = exp
    if exp > 0 then
        runState.partyExp = (runState.partyExp or 0) + exp
    end
    return exp
end

local function applyTeamHeal(runState, healPct)
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if not hero.isDead then
            local heal = math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0))
            hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
        end
    end
end

local function hasDeadTeamHero(runState)
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if hero.isDead then
            return true
        end
    end
    return false
end

local function reviveOne(runState, healPct)
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if hero.isDead then
            hero.isDead = false
            hero.teamState = "active"
            hero.currentHp = math.max(1, math.floor((hero.maxHp or 0) * (tonumber(healPct) or 0)))
            hero.buffs = {}
            hero.debuffs = {}
            hero.statuses = {}
            hero.riskHooks = nil
            return true
        end
    end
    return false
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

local function formatSkillCheckTierLabel(tier)
    if tier == "critSuccess" then
        return "大成功"
    end
    if tier == "success" then
        return "成功"
    end
    if tier == "failure" then
        return "失败"
    end
    if tier == "critFailure" then
        return "大失败"
    end
    return "结果未知"
end

local function buildCostDescription(option)
    if type(option) ~= "table" then
        return nil
    end
    local costType = tostring(option.costType or "")
    local costValue = tonumber(option.costValue) or 0
    if costType == "gold" and costValue > 0 then
        return string.format("支付 %d 金币", costValue)
    end
    if costType == "current_hp_pct" and costValue > 0 then
        return string.format("全队失去当前生命 %.0f%%", costValue * 100)
    end
    if costType == "hp_pct" and costValue > 0 then
        return string.format("全队失去最大生命 %.0f%%", costValue * 100)
    end
    return nil
end

local function buildSkillCheckDescription(outcome)
    if not outcome then
        return nil
    end
    local actor = outcome.heroName and (tostring(outcome.heroName) .. " 进行检定") or "检定"
    local extra = tonumber(outcome.trinketBonus)
    local extraText = extra and extra ~= 0 and string.format("，饰品 %+d", extra) or ""
    return string.format(
        "%s：%s d20(%d) %+d%s = %d vs DC%d，%s",
        actor,
        tostring(outcome.ability or "?"),
        tonumber(outcome.roll) or 0,
        tonumber(outcome.modifier) or 0,
        extraText,
        tonumber(outcome.total) or 0,
        tonumber(outcome.dc) or 0,
        formatSkillCheckTierLabel(outcome.tier)
    )
end

local function buildResultSummary(resultType, result)
    if resultType == "grant_gold" then
        return string.format("获得 %d 金币", tonumber(result and result.gold) or 0)
    end
    if resultType == "team_heal_pct" then
        return string.format("全队恢复 %.0f%% 生命", (tonumber(result and result.value) or 0) * 100)
    end
    if resultType == "grant_blessing" then
        local blessing = RunBlessingConfig.GetBlessing(tonumber(result and result.blessingId) or 0)
        return string.format("获得祝福：%s", blessing and blessing.name or ("祝福 " .. tostring(result and result.blessingId)))
    end
    if resultType == "grant_equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(tonumber(result and result.equipmentId) or 0)
        return string.format("获得装备：%s", equipment and equipment.name or ("装备 " .. tostring(result and result.equipmentId)))
    end
    if resultType == "revive_one" then
        return string.format("复活 1 名阵亡队友并恢复 %.0f%% 生命", (tonumber(result and result.healPct) or 0.5) * 100)
    end
    if resultType == "trigger_battle" then
        return "事件引发战斗"
    end
    if resultType == "unlock_hidden_floor" then
        return "发现隐藏层入口"
    end
    return "事件已结算"
end

local function buildResultDetails(option, resultType, result, skillCheckOutcome, expReward)
    local details = {}

    local costText = buildCostDescription(option)
    if costText then
        details[#details + 1] = costText
    end

    local checkText = buildSkillCheckDescription(skillCheckOutcome)
    if checkText then
        details[#details + 1] = checkText
    end

    if resultType == "grant_blessing" then
        local blessing = RunBlessingConfig.GetBlessing(tonumber(result and result.blessingId) or 0)
        if blessing and blessing.description and blessing.description ~= "" then
            details[#details + 1] = blessing.description
        end
    elseif resultType == "grant_equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(tonumber(result and result.equipmentId) or 0)
        if equipment and equipment.slot then
            details[#details + 1] = string.format("类型：%s", tostring(equipment.slot))
        end
    elseif resultType == "trigger_battle" then
        details[#details + 1] = "准备进入战斗结算。"
    elseif resultType == "revive_one" then
        details[#details + 1] = string.format("目标以 %.0f%% 最大生命复苏。", (tonumber(result and result.healPct) or 0.5) * 100)
    elseif resultType == "unlock_hidden_floor" then
        details[#details + 1] = "返回地图后可前往相邻的隐藏层入口房间。"
    end

    if (tonumber(expReward) or 0) > 0 then
        details[#details + 1] = string.format("队伍获得 %d 经验", tonumber(expReward) or 0)
    end

    return details
end

local function buildEventResult(option, resultType, result, skillCheckOutcome, expReward)
    local actionLabel = "继续前进"
    if resultType == "trigger_battle" then
        actionLabel = "进入战斗"
    end
    return {
        title = skillCheckOutcome and ("检定" .. formatSkillCheckTierLabel(skillCheckOutcome.tier)) or "事件结果",
        optionLabel = tostring(option and option.label or ""),
        summary = buildResultSummary(resultType, result),
        details = buildResultDetails(option, resultType, result, skillCheckOutcome, expReward),
        actionLabel = actionLabel,
    }
end

local function applyResult(runState, resultType, result, skillCheckOutcome)
    result = result or {}

    if resultType == "grant_gold" then
        runState.gold = (runState.gold or 0) + (tonumber(result.gold) or 0)
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        if not skillCheckOutcome then
            runState.lastActionMessage = "事件获得金币"
        end
        local expReward = grantEventExp(runState, skillCheckOutcome)
        return true, {
            kind = "done",
            eventResult = buildEventResult(nil, resultType, result, skillCheckOutcome, expReward),
        }
    end
    if resultType == "team_heal_pct" then
        applyTeamHeal(runState, result.value)
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        if not skillCheckOutcome then
            runState.lastActionMessage = "事件治疗"
        end
        local expReward = grantEventExp(runState, skillCheckOutcome)
        return true, {
            kind = "done",
            eventResult = buildEventResult(nil, resultType, result, skillCheckOutcome, expReward),
        }
    end
    if resultType == "grant_blessing" then
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        local expReward = grantEventExp(runState, skillCheckOutcome)
        return true, {
            kind = "blessing",
            blessingId = result.blessingId,
            eventResult = buildEventResult(nil, resultType, result, skillCheckOutcome, expReward),
        }
    end
    if resultType == "grant_equipment" then
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        local expReward = grantEventExp(runState, skillCheckOutcome)
        return true, {
            kind = "equipment",
            equipmentId = result.equipmentId,
            eventResult = buildEventResult(nil, resultType, result, skillCheckOutcome, expReward),
        }
    end
    if resultType == "revive_one" then
        local revived = reviveOne(runState, result.healPct or 0.5)
        if not revived then
            return false, "no_dead_hero"
        end
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        if not skillCheckOutcome then
            runState.lastActionMessage = "事件复活队友"
        end
        local expReward = grantEventExp(runState, skillCheckOutcome)
        return true, {
            kind = "done",
            eventResult = buildEventResult(nil, resultType, result, skillCheckOutcome, expReward),
        }
    end
    if resultType == "trigger_battle" then
        -- 触发战斗自身会通过 BattleExpReward 发放 EXP，事件不再额外给。
        runState.lastActionMessage = formatSkillCheckMessage(skillCheckOutcome)
        return true, {
            kind = "battle",
            battleId = result.battleId,
            rewardGroupId = result.rewardGroupId,
            eventResult = buildEventResult(nil, resultType, result, skillCheckOutcome, 0),
        }
    end
    if resultType == "unlock_hidden_floor" then
        runState.lastActionMessage = "发现隐藏层入口"
        local expReward = grantEventExp(runState, skillCheckOutcome)
        return true, {
            kind = "unlock_hidden_floor",
            eventResult = buildEventResult(nil, resultType, result, skillCheckOutcome, expReward),
        }
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
    runState.lastEventExpReward = 0

    if selected.resultType == "revive_one" and not hasDeadTeamHero(runState) then
        return false, "no_dead_hero"
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

    local ok, output = applyResult(runState, resultType, result, skillCheckOutcome)
    if ok and type(output) == "table" and output.eventResult then
        output.eventResult = buildEventResult(selected, resultType, result, skillCheckOutcome, runState.lastEventExpReward or 0)
    end
    return ok, output
end

return RoguelikeEvent
