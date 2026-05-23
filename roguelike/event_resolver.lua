---@alias RunEventSkillTier
---| "critSuccess"
---| "success"
---| "failure"
---| "critFailure"

local Dice = require("core.dice")
local Ability5e = require("modules.ability_5e")

local EventResolver = {}

--- 5e 技能名 → 属性键（用于事件房检定）。
---@type table<string, string>
local SKILL_ABILITY_KEY = {
    athletics = "str",
    acrobatics = "dex",
    stealth = "dex",
    investigation = "int",
    arcana = "int",
    history = "int",
    nature = "int",
    religion = "wis",
    insight = "wis",
    medicine = "wis",
    perception = "wis",
    survival = "wis",
    deception = "cha",
    intimidation = "cha",
    performance = "cha",
    persuasion = "cha",
}

local function normalizeAbilityName(ability)
    return string.lower(tostring(ability or "investigation"))
end

local function getHeroAbilityMods(hero)
    return {
        str = Ability5e.GetAbilityMod(hero and hero.str or 10),
        dex = Ability5e.GetAbilityMod(hero and hero.dex or 10),
        con = Ability5e.GetAbilityMod(hero and hero.con or 10),
        int = Ability5e.GetAbilityMod(hero and hero.int or 10),
        wis = Ability5e.GetAbilityMod(hero and hero.wis or 10),
        cha = Ability5e.GetAbilityMod(hero and hero.cha or 10),
    }
end

function EventResolver.GetAbilityKeyForSkill(skillName)
    local key = SKILL_ABILITY_KEY[normalizeAbilityName(skillName)]
    return key or "int"
end

function EventResolver.GetSkillModifier(hero, skillName)
    if not hero then
        return 0, 0, 0
    end
    local abilityKey = EventResolver.GetAbilityKeyForSkill(skillName)
    local mods = getHeroAbilityMods(hero)
    local abilityMod = mods[abilityKey] or 0
    local proficiency = Ability5e.GetProficiencyBonus(hero.level or 1)
    return abilityMod + proficiency, abilityMod, proficiency
end

---@param roll integer
---@param total integer
---@param dc integer
---@return RunEventSkillTier
function EventResolver.ClassifyTier(roll, total, dc)
    local r = tonumber(roll) or 0
    local t = tonumber(total) or 0
    local target = tonumber(dc) or 10
    if r >= 20 then
        return "critSuccess"
    end
    if r <= 1 then
        return "critFailure"
    end
    if t >= target then
        return "success"
    end
    return "failure"
end

---@param hero table
---@param skillCheck table
---@param extraModifier integer|nil  Run 层加值（如 trinket 事件检定 +1）
---@return table|nil, string|nil
function EventResolver.ResolveSkillCheck(hero, skillCheck, extraModifier)
    if type(skillCheck) ~= "table" then
        return nil, "invalid_skill_check"
    end
    if not hero then
        return nil, "no_hero"
    end

    local skillName = normalizeAbilityName(skillCheck.ability)
    local dc = math.max(1, math.floor(tonumber(skillCheck.dc) or 10))
    local modifier, abilityMod, proficiency = EventResolver.GetSkillModifier(hero, skillName)
    local roll, meta = Dice.RollD20("normal")
    local extra = tonumber(extraModifier) or 0
    local total = roll + modifier + extra
    local tier = EventResolver.ClassifyTier(roll, total, dc)

    local results = skillCheck.results or {}
    local outcome = results[tier] or results.success or results.failure
    if type(outcome) ~= "table" then
        return nil, "missing_skill_check_result"
    end

    return {
        ability = skillName,
        abilityKey = EventResolver.GetAbilityKeyForSkill(skillName),
        dc = dc,
        roll = roll,
        abilityMod = abilityMod,
        proficiencyBonus = proficiency,
        modifier = modifier,
        trinketBonus = extra ~= 0 and extra or nil,
        total = total,
        tier = tier,
        nat20 = meta and meta.nat20 == true,
        nat1 = meta and meta.nat1 == true,
        resultType = outcome.resultType,
        result = outcome.result or {},
        heroRosterId = hero.rosterId,
        heroName = hero.name,
    }, nil
end

---@param runState table
---@param skillName string
---@return table|nil
function EventResolver.PickBestHeroForSkill(runState, skillName)
    local RoguelikeRoster = require("roguelike.roguelike_roster")
    local bestHero, bestMod
    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if not hero.isDead and (hero.currentHp or 0) > 0 then
            local mod = EventResolver.GetSkillModifier(hero, skillName)
            if not bestHero or mod > bestMod then
                bestHero = hero
                bestMod = mod
            end
        end
    end
    return bestHero
end

---@param runState table
---@param hero table|nil
---@param option table
---@return string|nil resultType
---@return table|nil result
---@return table|nil skillCheckOutcome
---@return string|nil errorReason
function EventResolver.ResolveOptionOutcome(runState, hero, option)
    if type(option) ~= "table" then
        return nil, nil, nil, "invalid_option"
    end

    if option.zeroRisk == true then
        return option.resultType, option.result or {}, nil, nil
    end

    if type(option.skillCheck) == "table" then
        local actor = hero or EventResolver.PickBestHeroForSkill(runState, option.skillCheck.ability)
        if not actor then
            return nil, nil, nil, "no_alive_hero"
        end
        local TrinketEffects = require("roguelike.trinket_effects")
        local trinketBonus = TrinketEffects.GetEventSkillCheckBonus(runState)
        local outcome, reason = EventResolver.ResolveSkillCheck(actor, option.skillCheck, trinketBonus)
        if not outcome then
            return nil, nil, nil, reason or "skill_check_failed"
        end
        return outcome.resultType, outcome.result, outcome, nil
    end

    return option.resultType, option.result or {}, nil, nil
end

return EventResolver
