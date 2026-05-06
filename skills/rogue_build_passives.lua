local ClassRoleConfig = require("config.class_role_config")
local SkillRuntimeConfig = require("config.skill_runtime_config")
local BuildPassiveCommon = require("skills.build_passive_common")

local RogueBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local BREACH_BUFF_ID = 880004

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

local function buildContextState(context)
    return {
        context = context,
    }
end

local function isFrontRow(unit)
    local wpType = tonumber(unit and unit.wpType) or 0
    return wpType > 0 and wpType <= 3
end

local function isBackRow(unit)
    local wpType = tonumber(unit and unit.wpType) or 0
    return wpType >= 4
end

local function countAliveFrontAllies(hero)
    local BattleFormation = require("modules.battle_formation")
    local count = 0
    for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
        if isAlive(ally) and isFrontRow(ally) then
            count = count + 1
        end
    end
    return count
end

local function evaluateSneakCondition(hero, target)
    local BattleBuff = require("modules.battle_buff")
    local runtime = ensureRuntime(hero)
    local forcedCharges = tonumber(runtime.rogueForcedSneakCharges) or 0
    if forcedCharges > 0 then
        return {
            qualified = true,
            viaForced = true,
            label = runtime.rogueForcedSneakLabel or "强制偷袭",
        }
    end
    if BattleBuff.HasControlBuff(target) then
        return {
            qualified = true,
            viaControl = true,
            label = "目标被控制",
        }
    end
    if isFrontRow(target) and countAliveFrontAllies(hero) >= 2 then
        return {
            qualified = true,
            viaFlank = true,
            label = "夹击成立",
        }
    end
    return {
        qualified = false,
    }
end

local function consumeForcedSneak(runtime)
    local charges = tonumber(runtime.rogueForcedSneakCharges) or 0
    if charges <= 0 then
        return
    end
    charges = charges - 1
    runtime.rogueForcedSneakCharges = charges
    if charges <= 0 then
        runtime.rogueForcedSneakLabel = nil
    end
end

local function applySneakAttack(hero, target, condition)
    if not isAlive(hero) or not isAlive(target) or not condition or not condition.qualified then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.rogueSneakAttackRound == round then
        return 0
    end
    local diceExpr = hasSkill(hero, IDS.rogue_sneak_attack_mastery) and "2d6" or "1d6"
    if hasSkill(hero, IDS.rogue_executioner) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
    end
    if condition.viaFlank and hasSkill(hero, IDS.rogue_flanking_expert) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    if runtime.rogueShadowDancePending == true and hasSkill(hero, IDS.rogue_shadow_dancer) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "2d6")
        runtime.rogueShadowDancePending = false
    end
    runtime.rogueSneakAttackRound = round
    local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, diceExpr, {
        kind = "physical",
        damageKind = "direct",
        skillId = IDS.rogue_sneak_attack,
        skillName = "偷袭",
    })
    if bonus > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发偷袭：对 %s 追加 %d 点伤害（%s）",
            hero.name or "Unknown",
            target.name or "目标",
            bonus,
            condition.label or "满足条件"))
    end
    return bonus
end

local function applyFirstMeleeReduction(hero)
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.rogueFirstMeleeReduceRound == round then
        return 0
    end
    runtime.rogueFirstMeleeReduceRound = round
    local diceExpr = "1d6"
    if hasSkill(hero, IDS.rogue_lightfoot_mastery) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    local reduction = BuildPassiveCommon.RollDice(diceExpr)
    if reduction > 0 then
        BuildPassiveCommon.PublishPassiveTriggered(hero, "翻滚脱离", "首次近战受击减伤", string.format("减免 %d 伤害", reduction))
    end
    return reduction
end

local function applySubclassMasteryDamage(hero, target)
    if not hasSkill(hero, IDS.rogue_subclass_mastery) then
        return 0
    end
    local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "1d6", {
        kind = "physical",
        damageKind = "direct",
        skillId = IDS.rogue_subclass_mastery,
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

function RogueBuildPassives.ShouldIgnoreFrontProtection(hero, skill)
    if not isAlive(hero) or not hasSkill(hero, IDS.rogue_shadow_step) then
        return false
    end
    local skillId = tonumber(skill and (skill.skillId or skill.id)) or 0
    if skillId ~= IDS.rogue_basic_attack then
        return false
    end
    local runtime = ensureRuntime(hero)
    return runtime.rogueShadowStepAvailable == true
end

function RogueBuildPassives.PerformExecuteStrike(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local isExecutionWindow = (tonumber(target.hp) or 0) <= math.max(1, math.floor((tonumber(target.maxHp) or 1) * 0.5))
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and isExecutionWindow then
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "2d6", {
            kind = "physical",
            damageKind = "direct",
            skillId = skill and skill.skillId or IDS.rogue_execute_strike,
            skillName = skill and skill.name or "处决打击",
        })
        damage = damage + bonus
        if bonus > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 发动处决打击：对半血目标 %s 追加 %d 点伤害",
                hero.name or "Unknown",
                target.name or "目标",
                bonus))
        end
    end
    return damage + applySubclassMasteryDamage(hero, target)
end

function RogueBuildPassives.PerformTricksterBlade(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and isBackRow(target) then
        BattleSkill.ApplyBuffFromSkill(hero, target, BREACH_BUFF_ID, nil, { duration = 1 })
        BuildPassiveCommon.PublishCombatLog(string.format("%s 发动扰乱飞刃：%s AC -1 直到下回合开始前",
            hero.name or "Unknown",
            target.name or "目标"))
    end
    return damage + applySubclassMasteryDamage(hero, target)
end

function RogueBuildPassives.PerformSwashbucklerThrust(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local runtime = ensureRuntime(hero)
    runtime.rogueForcedSneakCharges = (tonumber(runtime.rogueForcedSneakCharges) or 0) + 1
    runtime.rogueForcedSneakLabel = "穿行突刺"
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if (tonumber(runtime.rogueForcedSneakCharges) or 0) > 0 then
        consumeForcedSneak(runtime)
    end
    return damage + applySubclassMasteryDamage(hero, target)
end

function RogueBuildPassives.CreateSneakAttackPassive(context)
    local self = buildContextState(context)

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not isAlive(hero) or not isAlive(target) then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.rogue_basic_attack then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        local condition = evaluateSneakCondition(hero, target)
        local didSneak = false
        if (tonumber(extraParam.damageDealt) or 0) > 0 and condition.qualified then
            didSneak = applySneakAttack(hero, target, condition) > 0
        end
        if condition.viaForced then
            consumeForcedSneak(runtime)
        end
        if runtime.rogueFirstBasicAttackRound ~= round then
            runtime.rogueFirstBasicAttackRound = round
            if hasSkill(hero, IDS.rogue_shadow_dancer) then
                runtime.rogueShadowDancePending = not didSneak
                if runtime.rogueShadowDancePending then
                    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发影舞者：本回合下一次满足条件的偷袭额外造成 2d6 伤害",
                        hero.name or "Unknown"))
                end
            end
        elseif didSneak then
            runtime.rogueShadowDancePending = false
        end
    end

    return self
end

function RogueBuildPassives.CreateShadowStepPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        ensureRuntime(self.context and self.context.src).rogueShadowStepAvailable = true
    end

    function self:OnSelfTurnBegin()
        ensureRuntime(self.context and self.context.src).rogueShadowStepAvailable = true
    end

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if tonumber(extraParam.skillId) ~= IDS.rogue_basic_attack then
            return
        end
        ensureRuntime(hero).rogueShadowStepAvailable = false
    end

    return self
end

function RogueBuildPassives.CreateEvasiveTumblePassive(context)
    local self = buildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local attacker = extraParam.attacker
        if not isAlive(hero) or not isAlive(attacker) then
            return
        end
        local attackerClass = tonumber(attacker.class or attacker.Class) or 0
        if not ClassRoleConfig.IsMelee(attackerClass) then
            return
        end
        local reduction = applyFirstMeleeReduction(hero)
        if reduction > 0 then
            extraParam.damage = math.max(0, (tonumber(extraParam.damage) or 0) - reduction)
        end
    end

    return self
end

function RogueBuildPassives.CreateUncannyDodgePassive(context)
    local self = buildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) then
            return
        end
        local damage = math.max(0, math.floor(tonumber(extraParam.damage) or 0))
        if damage <= 0 then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        if runtime.rogueUncannyRound == round then
            return
        end
        runtime.rogueUncannyRound = round
        extraParam.damage = math.max(0, math.floor(damage * 0.5))
        BuildPassiveCommon.PublishPassiveTriggered(hero, "Uncanny Dodge", "首次受击减半", string.format("%d -> %d", damage, extraParam.damage))
        if hasSkill(hero, IDS.rogue_survivor) then
            runtime.rogueForcedSneakCharges = (tonumber(runtime.rogueForcedSneakCharges) or 0) + 1
            runtime.rogueForcedSneakLabel = "生还者"
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发生还者：下一次基础武器攻击视为满足偷袭条件",
                hero.name or "Unknown"))
        end
    end

    return self
end

return RogueBuildPassives
