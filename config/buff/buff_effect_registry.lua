local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleSkill = require("modules.battle_skill")
local Ability5e = require("modules.ability_5e")

local BuffEffectRegistry = {}

local function buildDotHandler(damageKind, dicePerStack)
    return function(buff, hero)
        if not hero or hero.isDead then
            return
        end
        local stacks = math.max(1, tonumber(buff.stackCount) or 1)
        local diceExpr = string.format("%d%s", stacks, dicePerStack)
        local dmgResult = BattleSkill.ResolveScaledDamage(buff.caster or hero, hero, {
            skipCheck = true,
            noClassScalar = true,
            kind = "spell",
            damageKind = damageKind,
            damageDice = diceExpr,
        })
        local damage = tonumber(dmgResult and dmgResult.damage) or 0
        BattleDmgHeal.ApplyDamage(hero, damage, buff.caster or hero, {
            damageKind = damageKind,
        })
    end
end

local function getFrozenAcPenalty(hero)
    local classId = tonumber(hero and (hero.class or hero.Class or hero._class)) or 0
    local dex = tonumber(hero and hero.dexMod) or 0
    local wis = tonumber(hero and hero.wisMod) or 0
    local con = tonumber(hero and hero.conMod) or 0
    local withDex = Ability5e.CalculateArmorClass(classId, {
        dex = dex,
        wis = wis,
        con = con,
    })
    local withoutDex = Ability5e.CalculateArmorClass(classId, {
        dex = 0,
        wis = wis,
        con = con,
    })
    return math.max(0, (tonumber(withDex) or 0) - (tonumber(withoutDex) or 0))
end

local function applyFrozenDexPenalty(buff, hero)
    if not hero or hero.isDead or buff.__dexPenaltyApplied then
        return
    end
    local acPenalty = getFrozenAcPenalty(hero)
    local currentSaveRef = tonumber(hero.saveRef) or 0
    local dexSaveBonus = math.max(0, tonumber(hero.dexMod) or 0)
    local savePenalty = math.max(0, math.min(currentSaveRef, dexSaveBonus))
    buff.__frozenAcPenalty = acPenalty
    buff.__frozenSavePenalty = savePenalty
    if acPenalty > 0 then
        hero.ac = math.max(0, math.floor((tonumber(hero.ac) or 0) - acPenalty))
    end
    if savePenalty > 0 then
        hero.saveRef = math.max(0, math.floor((tonumber(hero.saveRef) or 0) - savePenalty))
    end
    buff.__dexPenaltyApplied = true
end

local function removeFrozenDexPenalty(buff, hero)
    if not hero or not buff.__dexPenaltyApplied then
        return
    end
    local acPenalty = math.max(0, math.floor(tonumber(buff.__frozenAcPenalty) or 0))
    local savePenalty = math.max(0, math.floor(tonumber(buff.__frozenSavePenalty) or 0))
    if acPenalty > 0 then
        hero.ac = math.max(0, math.floor((tonumber(hero.ac) or 0) + acPenalty))
    end
    if savePenalty > 0 then
        hero.saveRef = math.max(0, math.floor((tonumber(hero.saveRef) or 0) + savePenalty))
    end
    buff.__dexPenaltyApplied = false
    buff.__frozenAcPenalty = 0
    buff.__frozenSavePenalty = 0
end

BuffEffectRegistry.poison_tick = buildDotHandler("poison", "d4")
BuffEffectRegistry.burn_tick = buildDotHandler("fire", "d6")
BuffEffectRegistry.slow_apply_penalty = applyFrozenDexPenalty
BuffEffectRegistry.slow_remove_penalty = removeFrozenDexPenalty

return BuffEffectRegistry
