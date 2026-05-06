local SkillRuntimeConfig = require("config.skill_runtime_config")
local BuildPassiveCommon = require("skills.build_passive_common")

local MonkBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids

local function isAlive(unit)
    return BuildPassiveCommon.IsAlive(unit)
end

local function hasSkill(hero, skillId)
    return BuildPassiveCommon.HasSkill(hero, skillId)
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

local function tryApplyStun(hero, target, label)
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
            label or "截脉",
            target.name or "目标",
            saveResult.total or 0,
            saveResult.dc or dc))
        return false
    end
    BattleSkill.ApplyBuffFromSkill(hero, target, STUN_BUFF_ID, nil, { duration = 1 })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s 强韧豁免失败，STUN 1 回合",
        hero.name or "Unknown",
        label or "截脉",
        target.name or "目标"))
    return true
end

local function triggerMartialArts(hero, target, opts)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    opts = opts or {}
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.monkMartialArtsRound == round and opts.force ~= true then
        return 0
    end
    if opts.force ~= true then
        runtime.monkMartialArtsRound = round
    end
    local diceExpr = "1d4"
    if hasSkill(hero, IDS.monk_flurry_training) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    if hasSkill(hero, IDS.monk_combo_mastery) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    local damage = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, diceExpr, {
        kind = "physical",
        damageKind = "direct",
        skillId = IDS.monk_martial_arts,
        skillName = "武艺",
    })
    if damage > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发武艺：对 %s 追加 %d 点打击伤害",
            hero.name or "Unknown",
            target.name or "目标",
            damage))
        if hasSkill(hero, IDS.monk_purity_mastery) then
            local heal = BuildPassiveCommon.RollDice("1d6")
            BuildPassiveCommon.ApplyHeal(hero, heal)
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发无垢宗师：回复 %d 生命",
                hero.name or "Unknown",
                heal))
        end
    end
    return damage
end

local function applyFirstHitReduction(hero, label)
    if not isAlive(hero) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.monkFirstHitReduceRound == round then
        return 0
    end
    local diceExpr = ""
    if hasSkill(hero, IDS.monk_iron_mind) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    if hasSkill(hero, IDS.monk_body_guard) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    if diceExpr == "" then
        return 0
    end
    runtime.monkFirstHitReduceRound = round
    local reduction = BuildPassiveCommon.RollDice(diceExpr)
    if reduction > 0 then
        BuildPassiveCommon.PublishPassiveTriggered(hero, label or "守心技", "首次受击减伤", string.format("减免 %d 伤害", reduction))
    end
    return reduction
end

function MonkBuildPassives.PerformOpenHandStrike(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 then
        tryApplyStun(hero, target, "震劲掌")
    end
    return damage
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
        if (tonumber(extraParam.damageDealt) or 0) <= 0 then
            return
        end
        triggerMartialArts(hero, extraParam.target)
    end

    return self
end

function MonkBuildPassives.CreateIronMindPassive(context)
    local self = buildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local reduction = applyFirstHitReduction(hero, "守心技")
        if reduction > 0 then
            extraParam.damage = math.max(0, (tonumber(extraParam.damage) or 0) - reduction)
        end
    end

    return self
end

function MonkBuildPassives.CreateSwiftStepPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        ensureRuntime(self.context and self.context.src).ignoreFrontProtection = true
    end

    return self
end

function MonkBuildPassives.CreateBodyMasteryPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        local runtime = ensureRuntime(self.context and self.context.src)
        runtime.basicAttackBonusDice = BuildPassiveCommon.JoinDiceParts(runtime.basicAttackBonusDice, "1d4")
    end

    return self
end

function MonkBuildPassives.CreateBodyGuardPassive(context)
    local self = buildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local reduction = applyFirstHitReduction(hero, "护体专精")
        if reduction > 0 then
            extraParam.damage = math.max(0, (tonumber(extraParam.damage) or 0) - reduction)
        end
    end

    return self
end

function MonkBuildPassives.CreateExtraAttackPassive(context)
    return BuildPassiveCommon.CreateExtraAttackPassive(context, {
        basicAttackSkillId = IDS.monk_basic_attack,
        tokenKey = "monkExtraAttackToken",
        onPrimaryHit = function(hero, target)
            if hasSkill(hero, IDS.monk_combo_mastery_capstone) then
                local bonus = triggerMartialArts(hero, target, { force = true })
                if bonus > 0 then
                    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发连拳宗师：对 %s 追加 1 次武艺打击",
                        hero.name or "Unknown",
                        target.name or "目标"))
                end
            end
            if hasSkill(hero, IDS.monk_disruption_mastery) then
                tryApplyStun(hero, target, "截脉宗师")
            end
        end,
    })
end

return MonkBuildPassives
