local SkillRuntimeConfig = require("config.skill_runtime_config")
local BuildPassiveCommon = require("skills.build_passive_common")

local RangerBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local RESTRAINED_PROXY_BUFF_ID = 880002

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

local function isBackRow(unit)
    local wpType = tonumber(unit and unit.wpType) or 0
    return wpType > 3
end

local function getMarkTable(target)
    local runtime = ensureRuntime(target)
    runtime.rangerMarks = runtime.rangerMarks or {}
    return runtime.rangerMarks
end

local function buildContextState(context)
    return {
        context = context,
    }
end

local function applyMarkedBonusDamage(hero, target)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.rangerMarkedDamageRound == round then
        return 0
    end
    runtime.rangerMarkedDamageRound = round
    local diceExpr = "1d4"
    if hasSkill(hero, IDS.ranger_tracking_skill) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
    end
    if hasSkill(hero, IDS.ranger_mark_mastery) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
    end
    local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, diceExpr, {
        kind = "physical",
        damageKind = "direct",
        skillId = IDS.ranger_hunter_mark,
        skillName = "猎人印记",
    })
    if bonus > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发猎人印记：对 %s 追加 %d 点追猎伤害",
            hero.name or "Unknown",
            target.name or "目标",
            bonus))
    end
    return bonus
end

function RangerBuildPassives.IsTargetMarkedBy(hero, target)
    if not isAlive(hero) or not isAlive(target) then
        return false
    end
    local marks = getMarkTable(target)
    local sourceId = tonumber(hero.instanceId or hero.id) or 0
    local mark = marks[sourceId]
    if not mark then
        return false
    end
    return (tonumber(mark.expireRound) or 0) >= getRound()
end

function RangerBuildPassives.ApplyHunterMark(hero, target)
    if not isAlive(hero) or not isAlive(target) then
        return
    end
    local BattleFormation = require("modules.battle_formation")
    local sourceId = tonumber(hero.instanceId or hero.id) or 0
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        local marks = getMarkTable(enemy)
        marks[sourceId] = nil
    end
    local marks = getMarkTable(target)
    marks[sourceId] = {
        expireRound = getRound() + 1,
    }
    BuildPassiveCommon.PublishCombatLog(string.format("%s 对 %s 施加猎人印记",
        hero.name or "Unknown",
        target.name or "目标"))
end

function RangerBuildPassives.AugmentBasicAttackResolveOpts(hero, target, opts, runtime)
    if not isAlive(hero) or not isAlive(target) then
        return
    end
    if hasSkill(hero, IDS.ranger_precise_shot) and RangerBuildPassives.IsTargetMarkedBy(hero, target) then
        opts.attackBonus = (tonumber(opts.attackBonus) or 0) + 1
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发精准射击：对 %s 命中 +1",
            hero.name or "Unknown",
            target.name or "目标"))
    end
end

local function tryApplySnare(hero, target, label)
    if not isAlive(hero) or not isAlive(target) then
        return false
    end
    local BattleFormula = require("core.battle_formula")
    local BattleSkill = require("modules.battle_skill")
    local dc = tonumber(hero.spellDC) or 10
    local saveBonus = tonumber(target.saveRef) or 0
    local saveResult = BattleFormula.RollSave(target, dc, saveBonus, {})
    if saveResult.success then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s 反射豁免成功 (%d vs DC %d)",
            hero.name or "Unknown",
            label or "缠绕",
            target.name or "目标",
            saveResult.total or 0,
            saveResult.dc or dc))
        return false
    end
    BattleSkill.ApplyBuffFromSkill(hero, target, RESTRAINED_PROXY_BUFF_ID, nil, { duration = 1 })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s 反射豁免失败，冻结 1 回合（近似 Restrained）",
        hero.name or "Unknown",
        label or "缠绕",
        target.name or "目标"))
    return true
end

local function applyFirstHitReduction(hero, label)
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.rangerReduceRound == round then
        return 0
    end
    local diceExpr = ""
    if hasSkill(hero, IDS.ranger_wild_endurance) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
    end
    if hasSkill(hero, IDS.ranger_survival_mastery) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    if diceExpr == "" then
        return 0
    end
    runtime.rangerReduceRound = round
    local reduction = BuildPassiveCommon.RollDice(diceExpr)
    if reduction > 0 then
        BuildPassiveCommon.PublishPassiveTriggered(hero, label or "野外坚忍", "首次受击减伤", string.format("减免 %d 伤害", reduction))
    end
    return reduction
end

local function applySubclassMasteryDamage(hero, target, skill)
    if not hasSkill(hero, IDS.ranger_subclass_mastery) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.rangerSubclassMasteryRound == round then
        return 0
    end
    runtime.rangerSubclassMasteryRound = round
    local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "1d6", {
        kind = "physical",
        damageKind = "direct",
        skillId = IDS.ranger_subclass_mastery,
        skillName = "子职专精",
    })
    if bonus > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发子职专精：对 %s 追加 %d 点伤害",
            hero.name or "Unknown",
            target.name or "目标",
            bonus))
    end
    return bonus
end

function RangerBuildPassives.PerformHunterShot(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and RangerBuildPassives.IsTargetMarkedBy(hero, target) then
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "2d6", {
            kind = "physical",
            damageKind = "direct",
            skillId = skill and skill.skillId or IDS.ranger_hunter_shot,
            skillName = skill and skill.name or "狩猎指引",
        })
        damage = damage + bonus
        if bonus > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 发动狩猎指引：对印记目标 %s 追加 %d 点伤害",
                hero.name or "Unknown",
                target.name or "目标",
                bonus))
        end
    end
    return damage + applySubclassMasteryDamage(hero, target, skill)
end

function RangerBuildPassives.PerformShadowShot(hero, target, skill)
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
            skillId = skill and skill.skillId or IDS.ranger_shadow_shot,
            skillName = skill and skill.name or "暮影射击",
        })
        damage = damage + bonus
        if bonus > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 发动暮影射击：后排目标 %s 额外受到 %d 伤害",
                hero.name or "Unknown",
                target.name or "目标",
                bonus))
        end
    end
    return damage + applySubclassMasteryDamage(hero, target, skill)
end

function RangerBuildPassives.PerformSnareShot(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 then
        tryApplySnare(hero, target, "缠绕箭")
    end
    return damage + applySubclassMasteryDamage(hero, target, skill)
end

function RangerBuildPassives.CreateHunterMarkPassive(context)
    local self = buildContextState(context)

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not isAlive(hero) or not isAlive(target) then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.ranger_basic_attack then
            return
        end
        if (tonumber(extraParam.damageDealt) or 0) <= 0 then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        if runtime.rangerMarkApplyRound ~= round then
            runtime.rangerMarkApplyRound = round
            RangerBuildPassives.ApplyHunterMark(hero, target)
        end
        if RangerBuildPassives.IsTargetMarkedBy(hero, target) then
            applyMarkedBonusDamage(hero, target)
        end
    end

    return self
end

function RangerBuildPassives.CreateWildEndurancePassive(context)
    local self = buildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) then
            return
        end
        local reduction = applyFirstHitReduction(hero, "野外坚忍")
        if reduction > 0 then
            extraParam.damage = math.max(0, (tonumber(extraParam.damage) or 0) - reduction)
        end
    end

    return self
end

function RangerBuildPassives.CreateExtraAttackPassive(context)
    return BuildPassiveCommon.CreateExtraAttackPassive(context, {
        basicAttackSkillId = IDS.ranger_basic_attack,
        tokenKey = "rangerExtraAttackToken",
        onPrimaryHit = function(hero, target, runtime)
            local marked = RangerBuildPassives.IsTargetMarkedBy(hero, target)
            if hasSkill(hero, IDS.ranger_hunter_mastery) and marked then
                local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "1d6", {
                    kind = "physical",
                    damageKind = "direct",
                    skillId = IDS.ranger_hunter_mastery,
                    skillName = "逐猎宗师",
                })
                if bonus > 0 then
                    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发逐猎宗师：对 %s 追加 %d 点追猎伤害",
                        hero.name or "Unknown",
                        target.name or "目标",
                        bonus))
                end
            end
            if hasSkill(hero, IDS.ranger_shadow_mastery) and isBackRow(target) then
                runtime.pendingBasicAttackBonusDice = BuildPassiveCommon.JoinDiceParts(runtime.pendingBasicAttackBonusDice, "1d6")
            end
            if hasSkill(hero, IDS.ranger_snare_mastery) and marked then
                tryApplySnare(hero, target, "缚林宗师")
            end
        end,
    })
end

return RangerBuildPassives
