local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleSkill = require("modules.battle_skill")
local BattleFormula = require("core.battle_formula")
local BuildPassiveCommon = require("skills.build_passive_common")

local BuffEffectRegistry = {}

local function getSaveBonus(hero, saveType)
    if saveType == "fort" then
        return tonumber(hero and hero.saveFort) or 0
    end
    if saveType == "will" then
        return tonumber(hero and hero.saveWill) or 0
    end
    return tonumber(hero and hero.saveRef) or 0
end

local function getSaveLabel(saveType)
    if saveType == "fort" then
        return "强韧"
    end
    if saveType == "will" then
        return "意志"
    end
    return "反射"
end

local function handleBurnTick(buff, hero)
    if not hero or hero.isDead then
        return
    end

    local caster = buff.caster or hero
    local saveType = buff.__burnSaveType or "ref"
    local dc = tonumber(caster and caster.spellDC) or 10
    local saveBonus = getSaveBonus(hero, saveType)
        + (tonumber(BuildPassiveCommon.GetDefenderSaveBonus(hero, saveType)) or 0)
    local saveResult = BattleFormula.RollSave(hero, dc, saveBonus, {})
    local saveLabel = getSaveLabel(saveType)
    local BattleBuff = require("modules.battle_buff")

    if saveResult.success then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 的燃烧熄灭：%s豁免成功 (%d vs DC %d)",
            hero.name or "目标",
            saveLabel,
            saveResult.total or 0,
            saveResult.dc or dc))
        BattleBuff.RemoveBuffById(hero, buff.id)
        return
    end

    local stacks = math.max(1, tonumber(buff.stackCount) or 1)
    local diceExpr = string.format("%d%s", stacks, "d4")
    local dmgResult = BattleSkill.ResolveScaledDamage(caster, hero, {
        skipCheck = true,
        noClassScalar = true,
        kind = "spell",
        damageKind = "fire",
        damageDice = diceExpr,
    })
    local damage = tonumber(dmgResult and dmgResult.damage) or 0
    BattleDmgHeal.ApplyDamage(hero, damage, caster, {
        damageKind = "fire",
    })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 的燃烧持续：%s豁免失败，受到 %d 点火焰伤害",
        hero.name or "目标",
        saveLabel,
        damage))
end

local function applySlowInitiativePenalty(buff, hero)
    if not hero or hero.isDead or buff.__slowPenaltyApplied then
        return
    end
    local penalty = math.max(1, math.floor(tonumber(buff.value) or 5))
    buff.__slowPenaltyAmount = penalty
    local BattleActionOrder = require("modules.battle_action_order")
    if BattleActionOrder.AddInitiativeModifier then
        BattleActionOrder.AddInitiativeModifier(hero, -penalty)
    end
    buff.__slowPenaltyApplied = true
end

local function removeSlowInitiativePenalty(buff, hero)
    if not hero or not buff.__slowPenaltyApplied then
        return
    end
    local penalty = math.max(1, math.floor(tonumber(buff.__slowPenaltyAmount) or tonumber(buff.value) or 5))
    local BattleActionOrder = require("modules.battle_action_order")
    if BattleActionOrder.AddInitiativeModifier then
        BattleActionOrder.AddInitiativeModifier(hero, penalty)
    end
    buff.__slowPenaltyApplied = false
    buff.__slowPenaltyAmount = 0
end

local function handleBleedTick(buff, hero)
    if not hero or hero.isDead then
        return
    end

    local caster = buff.caster or hero
    local saveType = "fort"
    local dc = tonumber(caster and caster.spellDC) or 10
    local saveBonus = getSaveBonus(hero, saveType)
        + (tonumber(BuildPassiveCommon.GetDefenderSaveBonus(hero, saveType)) or 0)
    local saveResult = BattleFormula.RollSave(hero, dc, saveBonus, {})
    local saveLabel = getSaveLabel(saveType)
    local BattleBuff = require("modules.battle_buff")

    if saveResult.success then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 的流血止住：%s豁免成功 (%d vs DC %d)",
            hero.name or "目标",
            saveLabel,
            saveResult.total or 0,
            saveResult.dc or dc))
        BattleBuff.RemoveBuffById(hero, buff.id)
        return
    end

    local dmgResult = BattleSkill.ResolveScaledDamage(caster, hero, {
        skipCheck = true,
        noClassScalar = true,
        kind = "physical",
        damageKind = "slashing",
        damageDice = "1d4",
    })
    local damage = tonumber(dmgResult and dmgResult.damage) or 0
    BattleDmgHeal.ApplyDamage(hero, damage, caster, {
        damageKind = "slashing",
    })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 的流血持续：%s豁免失败，受到 %d 点物理伤害",
        hero.name or "目标",
        saveLabel,
        damage))
end

local function handlePoisonTick(buff, hero)
    if not hero or hero.isDead then
        return
    end

    local caster = buff.caster or hero
    local saveType = "fort"
    local dc = tonumber(caster and caster.spellDC) or 10
    local saveBonus = getSaveBonus(hero, saveType)
        + (tonumber(BuildPassiveCommon.GetDefenderSaveBonus(hero, saveType)) or 0)
    local saveResult = BattleFormula.RollSave(hero, dc, saveBonus, {})
    local saveLabel = getSaveLabel(saveType)
    local BattleBuff = require("modules.battle_buff")

    if saveResult.success then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 的中毒缓解：%s豁免成功 (%d vs DC %d)",
            hero.name or "目标",
            saveLabel,
            saveResult.total or 0,
            saveResult.dc or dc))
        BattleBuff.RemoveBuffById(hero, buff.id)
        return
    end

    local stacks = math.max(1, tonumber(buff.stackCount) or 1)
    local diceExpr = string.format("%d%s", stacks, "d4")
    local dmgResult = BattleSkill.ResolveScaledDamage(caster, hero, {
        skipCheck = true,
        noClassScalar = true,
        kind = "spell",
        damageKind = "poison",
        damageDice = diceExpr,
    })
    local damage = tonumber(dmgResult and dmgResult.damage) or 0
    BattleDmgHeal.ApplyDamage(hero, damage, caster, {
        damageKind = "poison",
    })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 的中毒持续：%s豁免失败，受到 %d 点毒素伤害",
        hero.name or "目标",
        saveLabel,
        damage))
end

BuffEffectRegistry.poison_tick = handlePoisonTick
BuffEffectRegistry.burn_tick = handleBurnTick
BuffEffectRegistry.bleed_tick = handleBleedTick
BuffEffectRegistry.slow_apply_penalty = applySlowInitiativePenalty
BuffEffectRegistry.slow_remove_penalty = removeSlowInitiativePenalty

return BuffEffectRegistry
