local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

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
    if runtime.__inMonkCombo and opts.force ~= true then
        -- §6 comboReentryOnce：默认连击不可在自身回合内重入；feat 解锁后允许每回合 1 次额外重入。
        local reentryOnce = FeatModHelper.HasFlag(hero, IDS.monk_martial_arts, "comboReentryOnce")
            or (hero.buildState and hero.buildState.classMods and hero.buildState.classMods.comboReentryOnce == true)
        if reentryOnce then
            local round = getRound()
            if runtime.monkComboReentryRound ~= round then
                runtime.monkComboReentryRound = round
                -- 允许本回合一次重入：不直接 return；继续执行追加攻击逻辑。
            else
                return 0
            end
        else
            return 0
        end
    end
    if opts.force ~= true and math.random(10000) > 5000 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 连击未触发",
            hero.name or "Unknown"))
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

    -- §C 调息大师：HP < threshold% 时自动触发一次明镜止水（治疗+净化），并获得临时生命；每场限次。
    -- 配置来源：feats.lua c_monk_breath_master → modify_skill 80003015：
    --   autoTriggerHpThresholdPct / autoTriggerCharges / autoTriggerTempHpFlat
    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        if not isAlive(hero) then
            return
        end
        local thresholdPct = math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.monk_harmonize, "autoTriggerHpThresholdPct", 0)))
        if thresholdPct <= 0 then
            return
        end
        local maxCharges = math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.monk_harmonize, "autoTriggerCharges", 0)))
        if maxCharges <= 0 then
            return
        end
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local incomingDamage = math.max(0, math.floor(tonumber(extraParam.damage) or 0))
        local maxHp = tonumber(hero.maxHp) or 0
        if maxHp <= 0 then
            return
        end
        local hpAfter = math.max(0, (tonumber(hero.hp) or 0) - incomingDamage)
        if hpAfter <= 0 then
            return -- 已致命交给「不屈之风」类被动；调息大师不抢救致死。
        end
        if hpAfter * 100 >= maxHp * thresholdPct then
            return
        end
        local runtime = ensureRuntime(hero)
        local used = math.max(0, math.floor(tonumber(runtime.monkBreathMasterUsed) or 0))
        if used >= maxCharges then
            return
        end
        runtime.monkBreathMasterUsed = used + 1

        -- 复用明镜止水的治疗效果与净化（与 skill_80003003 高阶口径一致：2d8+6）。
        local healDice = "2d8+6"
        local bonusDice = FeatModHelper.GetSkillMod(hero, IDS.monk_harmonize, "bonusHealDice", nil)
        if type(bonusDice) == "string" and bonusDice ~= "" then
            healDice = BuildPassiveCommon.JoinDiceParts(healDice, bonusDice)
        end
        local healAmount = BuildPassiveCommon.RollDice(healDice)
        if healAmount > 0 then
            local before = tonumber(hero.hp) or 0
            hero.hp = math.min(maxHp, before + healAmount)
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发调息大师：明镜止水回复 %d 生命",
                hero.name or "Unknown", math.max(0, hero.hp - before)))
        end

        -- 净化关键控制：与明镜止水一致的 Frozen / STUN / SILENT 三类。
        local BattleBuff = require("modules.battle_buff")
        local subTypes = {
            E_BUFF_SPEC_SUBTYPE and E_BUFF_SPEC_SUBTYPE.Frozen,
            E_BUFF_SPEC_SUBTYPE and E_BUFF_SPEC_SUBTYPE.STUN,
            E_BUFF_SPEC_SUBTYPE and E_BUFF_SPEC_SUBTYPE.SILENT,
        }
        for _, subType in ipairs(subTypes) do
            if subType and BattleBuff.DelBuffBySubType then
                BattleBuff.DelBuffBySubType(hero, subType)
            end
        end

        -- 临时生命。
        local tempHpFlat = math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.monk_harmonize, "autoTriggerTempHpFlat", 0)))
        if tempHpFlat > 0 then
            hero.tempHp = math.max(math.floor(tonumber(hero.tempHp) or 0), tempHpFlat)
            BuildPassiveCommon.PublishCombatLog(string.format("%s 调息大师：获得 %d 点临时生命",
                hero.name or "Unknown", tempHpFlat))
        end

        BuildPassiveCommon.PublishPassiveTriggered(hero, "调息大师", "低血自动调息",
            string.format("HP %d/%d 触发", hpAfter, maxHp))
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

    function self:OnSelfTurnBegin()
        local hero = self.context and self.context.src or nil
        if not isAlive(hero) then
            return
        end
        BuildPassiveCommon.AppendPendingBasicAttackHitBonus(hero, 1, "疾风技")
        BuildPassiveCommon.AppendPendingBasicAttackBonusDice(hero, "1d4")
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
    })
end

return MonkBuildPassives

