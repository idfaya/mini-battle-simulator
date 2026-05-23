local RunTrinketConfig = require("config.roguelike.run_trinket_config")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local RoguelikeMap = require("roguelike.roguelike_map")

---@alias RunTrinketEffectType
---| "team_save_delta"
---| "team_damage_resistance"
---| "elite_victory_bonus_gold"
---| "event_skill_check_bonus"
---| "boss_victory_full_heal"
---| "hidden_boss_extra_trinket_roll"

local TrinketEffects = {}

local function forEachTrinket(runState, visitor)
    if type(runState) ~= "table" or type(visitor) ~= "function" then
        return
    end
    for _, trinketId in ipairs(runState.trinketIds or {}) do
        local entry = RunTrinketConfig.GetTrinket(trinketId)
        if entry then
            visitor(entry)
        end
    end
end

local function applyClassFlat(modMap, classIds, value)
    for _, classId in ipairs(classIds or {}) do
        modMap[classId] = (modMap[classId] or 0) + (tonumber(value) or 0)
    end
end

--- 战前修正：与 blessing / 装备一并写入 buildBattleModifiers。
---@param runState table
---@param modifiers table
function TrinketEffects.ApplyBattleModifiers(runState, modifiers)
    if type(runState) ~= "table" or type(modifiers) ~= "table" then
        return
    end
    forEachTrinket(runState, function(trinket)
        local params = trinket.params or {}
        if trinket.effectType == "team_save_delta" then
            local delta = tonumber(params.saveDelta) or 1
            for _, unit in ipairs(RoguelikeRoster.GetTeamUnits(runState) or {}) do
                applyClassFlat(modifiers.saveDeltaByClass, { unit.classId }, delta)
            end
        elseif trinket.effectType == "team_damage_resistance" then
            local kind = tostring(params.damageKind or "fire")
            modifiers.teamResistances = modifiers.teamResistances or {}
            modifiers.teamResistances[kind] = true
        end
    end)
end

--- 事件房 5e 检定加值（void_lantern 等）。
function TrinketEffects.GetEventSkillCheckBonus(runState)
    local bonus = 0
    forEachTrinket(runState, function(trinket)
        if trinket.effectType == "event_skill_check_bonus" then
            bonus = bonus + (tonumber(trinket.params and trinket.params.bonus) or 0)
        end
    end)
    return bonus
end

function TrinketEffects.HasHiddenBossExtraTrinketRoll(runState)
    local found = false
    forEachTrinket(runState, function(trinket)
        if trinket.effectType == "hidden_boss_extra_trinket_roll" then
            found = true
        end
    end)
    return found
end

---@param runState table
---@return string|nil
function TrinketEffects.GetCurrentBattleNodeType(runState)
    if not runState or not runState.dungeonState or not runState.currentNodeId then
        return nil
    end
    local node = RoguelikeMap.GetNode(runState.currentNodeId, runState.dungeonState)
    return node and node.nodeType or nil
end

--- 战斗胜利后：精英加金、Boss 回满等（在 ResolveBattle 发基础金币之后调用）。
---@param runState table
---@param context table|nil { won?: boolean, nodeType?: string }
function TrinketEffects.ApplyBattleVictory(runState, context)
    if type(runState) ~= "table" or not context or context.won ~= true then
        return
    end
    local nodeType = context.nodeType or TrinketEffects.GetCurrentBattleNodeType(runState)
    forEachTrinket(runState, function(trinket)
        local params = trinket.params or {}
        if trinket.effectType == "elite_victory_bonus_gold" and nodeType == "battle_elite" then
            local extra = math.max(0, math.floor(tonumber(params.gold) or 0))
            if extra > 0 then
                runState.gold = (runState.gold or 0) + extra
            end
        elseif trinket.effectType == "boss_victory_full_heal" and nodeType == "boss" then
            for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState) or {}) do
                if not hero.isDead then
                    hero.currentHp = hero.maxHp or hero.currentHp
                end
            end
        end
    end)
end

return TrinketEffects
