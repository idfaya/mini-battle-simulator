local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

local MonkBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids

local function isAlive(unit)
    return BuildPassiveCommon.IsAlive(unit)
end

local function ensureRuntime(hero)
    return BuildPassiveCommon.EnsureRuntime(hero)
end

local function getRound()
    return BuildPassiveCommon.GetRound()
end

local function isBackRow(target)
    return tonumber(target and target.wpType) and tonumber(target.wpType) > 3 or false
end

local function buildContextState(context)
    return {
        context = context,
    }
end

local STUN_BUFF_ID = 880003
local SNEAK_ATTACK_IMMUNITY_SKILL_ID = IDS.monk_basic_attack

local function hasPositiveSkillToggle(hero, skillId, key)
    if FeatModHelper.HasFlag(hero, skillId, key) then
        return true
    end
    return math.max(0, math.floor(tonumber(FeatModHelper.GetSkillMod(hero, skillId, key, 0)) or 0)) > 0
end

local function tryApplyStun(hero, target, label, duration)
    if not isAlive(hero) or not isAlive(target) then
        return false
    end
    local BattleFormula = require("core.battle_formula")
    local BattleSkill = require("modules.battle_skill")
    local dc = tonumber(hero.spellDC) or 10
    local saveBonus = tonumber(target.saveFort) or 0
    local saveResult = BattleFormula.RollSave(target, dc, saveBonus, {})
    if saveResult.success then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s 强韧豁免成功 (%d vs DC %d)",
            hero.name or "Unknown",
            label or "震慑拳",
            target.name or "目标",
            saveResult.total or 0,
            saveResult.dc or dc))
        return false
    end
    local actualDuration = math.max(1, math.floor(tonumber(duration) or 1))
    BattleSkill.ApplyBuffFromSkill(hero, target, STUN_BUFF_ID, nil, { duration = actualDuration })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s 强韧豁免失败，STUN %d 回合",
        hero.name or "Unknown",
        label or "震慑拳",
        target.name or "目标",
        actualDuration))
    return true
end

local function triggerMartialArts(hero, target, opts)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    opts = opts or {}
    local runtime = ensureRuntime(hero)
    if runtime.__inMonkCombo then
        return 0
    end
    if opts.force ~= true then
        return 0
    end
    runtime.__inMonkCombo = true
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    runtime.__inMonkCombo = false
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发连击：对 %s 追加 %d 点打击伤害",
            hero.name or "Unknown",
            target.name or "目标",
            damage))
    end
    return damage
end

function MonkBuildPassives.PerformOpenHandStrike(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 then
        tryApplyStun(hero, target, "震慑拳", 1)
    end
    return damage
end

local function clearHarmonizeDebuffs(hero)
    local BattleBuff = require("modules.battle_buff")
    local subTypes = {
        E_BUFF_SPEC_SUBTYPE and E_BUFF_SPEC_SUBTYPE.Frozen,
        E_BUFF_SPEC_SUBTYPE and E_BUFF_SPEC_SUBTYPE.STUN,
        E_BUFF_SPEC_SUBTYPE and E_BUFF_SPEC_SUBTYPE.SILENT,
    }
    local cleared = 0
    for _, subType in ipairs(subTypes) do
        if subType and BattleBuff.DelBuffBySubType then
            cleared = cleared + math.max(0, tonumber(BattleBuff.DelBuffBySubType(hero, subType)) or 0)
        end
    end
    return cleared
end

function MonkBuildPassives.PerformHarmonize(hero, skill)
    if not isAlive(hero) then
        return 0
    end
    local healDice = FeatModHelper.GetSkillMod(hero, IDS.monk_harmonize, "healDiceOverride", "2d8+3")
    if type(healDice) ~= "string" or healDice == "" then
        healDice = "2d8+3"
    end
    local bonusDice = FeatModHelper.GetSkillMod(hero, IDS.monk_harmonize, "bonusHealDice", nil)
    if type(bonusDice) == "string" and bonusDice ~= "" then
        healDice = BuildPassiveCommon.JoinDiceParts(healDice, bonusDice)
    end
    local healAmount = BuildPassiveCommon.RollDice(healDice)
    if healAmount > 0 then
        BuildPassiveCommon.ApplyHeal(hero, healAmount)
    end
    if FeatModHelper.HasFlag(hero, IDS.monk_harmonize, "clearDebuffs") then
        local cleared = clearHarmonizeDebuffs(hero)
        if cleared > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发调息熟练：解除 %d 个负面状态",
                hero.name or "Unknown", cleared))
        end
    end
    return healAmount
end

function MonkBuildPassives.PerformShadowCombo(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and isBackRow(target) then
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "1d8", {
            kind = "physical",
            damageKind = "direct",
            skillId = skill and skill.skillId or IDS.monk_shadow_combo,
            skillName = skill and skill.name or "影步连打",
        })
        damage = damage + bonus
        if bonus > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发影步连打：后排目标 %s 额外受到 %d 伤害",
                hero.name or "Unknown",
                target.name or "目标",
                bonus))
        end
    end
    return damage
end

function MonkBuildPassives.CreateMartialArtsPassive(context)
    local self = buildContextState(context)

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) or not isAlive(extraParam.target) then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.monk_basic_attack then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        local forceCombo = false
        if hasPositiveSkillToggle(hero, IDS.monk_martial_arts, "firstHitGuaranteedCombo")
            and runtime.monkGuaranteedComboRound ~= round then
            runtime.monkGuaranteedComboRound = round
            forceCombo = true
        end
        if (tonumber(extraParam.damageDealt) or 0) <= 0 and not forceCombo then
            return
        end
        triggerMartialArts(hero, extraParam.target, { force = forceCombo })
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        if not isAlive(hero) then
            return
        end
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local damage = math.max(0, math.floor(tonumber(extraParam.damage) or 0))
        if damage <= 0 then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        if FeatModHelper.HasFlag(hero, IDS.monk_martial_arts, "flawlessFirstHitImmune")
            and tonumber(runtime.monkFlawlessImmuneRound) ~= round then
            runtime.monkFlawlessImmuneRound = round
            extraParam.damage = 0
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发无懈可击：本回合首次伤害免疫",
                hero.name or "Unknown"))
            return
        end
        local blockFlat = math.max(0, math.floor(tonumber(FeatModHelper.GetSkillMod(hero, IDS.monk_martial_arts, "deflectAttackFlat", 0)) or 0))
        if blockFlat > 0 and (extraParam.damageKind == "physical" or extraParam.damageKind == nil) then
            local reduced = math.min(damage, blockFlat)
            damage = damage - reduced
            extraParam.damage = damage
            if reduced > 0 then
                BuildPassiveCommon.PublishCombatLog(string.format("%s 触发拨挡攻击：伤害 -%d",
                    hero.name or "Unknown", reduced))
            end
        end
        local spellFlat = math.max(0, math.floor(tonumber(FeatModHelper.GetSkillMod(hero, IDS.monk_martial_arts, "deflectSpellFlat", 0)) or 0))
        if spellFlat > 0 and damage > 0 and extraParam.damageKind ~= "physical" then
            local reduced = math.min(damage, spellFlat)
            if reduced > 0 then
                damage = damage - reduced
                extraParam.damage = damage
                BuildPassiveCommon.PublishCombatLog(string.format("%s 触发拨挡能量：法术伤害 -%d",
                    hero.name or "Unknown", reduced))
            end
        end
    end

    return self
end

function MonkBuildPassives.HasSneakAttackImmunity(defender)
    if not isAlive(defender) or not FeatModHelper.HasFlag(defender, SNEAK_ATTACK_IMMUNITY_SKILL_ID, "sneakAttackImmune") then
        return false
    end
    local BattleBuff = require("modules.battle_buff")
    return not BattleBuff.HasControlBuff(defender)
end

return MonkBuildPassives
