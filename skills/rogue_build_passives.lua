local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

local RogueBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local POISON_BUFF_ID = 850001
local STUN_BUFF_ID = 880003
local BLIND_BUFF_ID = 880006
local BLEED_BUFF_ID = 880007
local RANGER_MARK_BUFF_ID = 890005
local WARLOCK_MARK_BUFF_ID = 890001

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

local function getGridDistance(a, b)
    local BattleFormation = require("modules.battle_formation")
    local aWpType = tonumber(a and a.wpType) or 0
    local bWpType = tonumber(b and b.wpType) or 0
    if aWpType <= 0 or bWpType <= 0 then
        return nil
    end
    local aRow = BattleFormation.GetHeroRow(aWpType)
    local bRow = BattleFormation.GetHeroRow(bWpType)
    local aColumn = BattleFormation.GetHeroColumn(aWpType)
    local bColumn = BattleFormation.GetHeroColumn(bWpType)
    if not aRow or not bRow or not aColumn or not bColumn then
        return nil
    end
    return math.abs(aRow - bRow) + math.abs(aColumn - bColumn)
end

local function hasAdjacentAllyToTarget(hero, target)
    local BattleFormation = require("modules.battle_formation")
    for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
        if isAlive(ally) and not BuildPassiveCommon.SameUnit(ally, hero) then
            local distance = getGridDistance(ally, target)
            if distance ~= nil and distance <= 1 then
                return true
            end
        end
    end
    return false
end

local function evaluateSneakCondition(hero, target)
    local BattleBuff = require("modules.battle_buff")
    local okMonk, MonkBuildPassives = pcall(require, "skills.monk_build_passives")
    if okMonk and MonkBuildPassives and MonkBuildPassives.HasSneakAttackImmunity
        and MonkBuildPassives.HasSneakAttackImmunity(target) then
        return {
            qualified = false,
            blocked = true,
            label = "疾风步",
        }
    end
    local runtime = ensureRuntime(hero)
    local targetRuntime = ensureRuntime(target)
    local forcedCharges = tonumber(runtime.rogueForcedSneakCharges) or 0
    if forcedCharges > 0 then
        return {
            qualified = true,
            viaForced = true,
            label = runtime.rogueForcedSneakLabel or "强制偷袭",
        }
    end
    local heroId = tonumber(hero and (hero.instanceId or hero.id)) or 0
    local targetFocusId = tonumber(targetRuntime.lastAttackVictimId) or 0
    local targetAttackRound = tonumber(targetRuntime.lastAttackRound) or 0
    if targetFocusId > 0
        and targetFocusId ~= heroId
        and targetAttackRound > 0
        and targetAttackRound == getRound() then
        return {
            qualified = true,
            viaDistracted = true,
            label = "目标被牵制",
        }
    end
    if BattleBuff.HasControlBuff(target) then
        return {
            qualified = true,
            viaControl = true,
            label = "目标被控制",
        }
    end
    if FeatModHelper.HasFlag(hero, IDS.rogue_sneak_attack, "relaxedSneakStatus") then
        if BattleBuff.GetBuffStackNumBySubType(target, POISON_BUFF_ID) > 0
            or BattleBuff.GetBuffStackNumBySubType(target, BLEED_BUFF_ID) > 0
            or BattleBuff.GetBuffStackNumBySubType(target, RANGER_MARK_BUFF_ID) > 0
            or BattleBuff.GetBuffStackNumBySubType(target, WARLOCK_MARK_BUFF_ID) > 0 then
            return {
                qualified = true,
                viaMarked = true,
                label = "目标带负面标记",
            }
        end
    end
    if FeatModHelper.HasFlag(hero, IDS.rogue_sneak_attack, "unconditional") then
        return {
            qualified = true,
            viaMastery = true,
            label = "致命偷袭",
        }
    end
    if hasAdjacentAllyToTarget(hero, target) then
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
    local diceCount = 1 + math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.rogue_sneak_attack, "sneakDiceCountDelta", 0)))
    local diceExpr = string.format("%dd6", diceCount)
    local runtime = ensureRuntime(hero)
    if runtime.lastBasicAttackCrit == true and FeatModHelper.HasFlag(hero, IDS.rogue_sneak_attack, "sneakDiceDoubleOnCrit") then
        diceExpr = string.format("%dd6", diceCount * 2)
    end
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

local function getSaveBonus(target, saveType)
    if saveType == "con" then
        return tonumber(target and target.saveCon) or 0
    end
    if saveType == "wis" then
        return tonumber(target and target.saveWis) or 0
    end
    return tonumber(target and target.saveDex) or 0
end

local function getSaveLabel(saveType)
    if saveType == "con" then
        return "体质"
    end
    if saveType == "wis" then
        return "感知"
    end
    return "敏捷"
end

local function applyBuffOnFailedSave(hero, target, buffId, saveType, duration, label)
    if not isAlive(hero) or not isAlive(target) then
        return false
    end
    local BattleFormula = require("core.battle_formula")
    local BattleSkill = require("modules.battle_skill")
    local dc = tonumber(hero.spellDC) or 10
    local saveBonus = getSaveBonus(target, saveType) + (tonumber(BuildPassiveCommon.GetDefenderSaveBonus(target, saveType)) or 0)
    local saveResult = BattleFormula.RollSave(target, dc, saveBonus, {})
    local saveLabel = getSaveLabel(saveType)
    if saveResult.success then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s %s豁免成功 (%d vs DC %d)",
            hero.name or "Unknown",
            label or "诡诈打击",
            target.name or "目标",
            saveLabel,
            saveResult.total or 0,
            saveResult.dc or dc))
        return false
    end
    BattleSkill.ApplyBuffFromSkill(hero, target, buffId, nil, {
        duration = duration,
        isPermanent = false,
    })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s %s豁免失败，附加状态 %d 回合",
        hero.name or "Unknown",
        label or "诡诈打击",
        target.name or "目标",
        saveLabel,
        duration))
    return true
end

function RogueBuildPassives.PerformCunningStrike(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleBuff = require("modules.battle_buff")
    local runtime = ensureRuntime(hero)
    runtime.rogueForcedSneakCharges = (tonumber(runtime.rogueForcedSneakCharges) or 0) + 1
    runtime.rogueForcedSneakLabel = "诡诈打击"
    if FeatModHelper.HasFlag(hero, IDS.rogue_cunning_strike_build, "autoCritOnIncapacitated")
        and BattleBuff.HasControlBuff(target) then
        runtime.pendingBasicAttackForceCrit = true
        runtime.pendingBasicAttackForceCritLabel = "诡诈大师"
    end
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if (tonumber(runtime.rogueForcedSneakCharges) or 0) > 0 then
        consumeForcedSneak(runtime)
    end
    local duration = 1 + math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.rogue_cunning_strike_build, "cunningDurationDelta", 0)))
    if damage > 0 and isAlive(target) then
        applyBuffOnFailedSave(hero, target, POISON_BUFF_ID, "con", duration, "诡诈打击·涂毒")
        applyBuffOnFailedSave(hero, target, BLEED_BUFF_ID, "con", duration, "诡诈打击·流血")
        if FeatModHelper.HasFlag(hero, IDS.rogue_cunning_strike_build, "addBlind") then
            applyBuffOnFailedSave(hero, target, BLIND_BUFF_ID, "con", duration, "诡诈打击·盲目")
        end
        if FeatModHelper.HasFlag(hero, IDS.rogue_cunning_strike_build, "addDaze") then
            applyBuffOnFailedSave(hero, target, STUN_BUFF_ID, "wis", duration, "诡诈打击·眩晕")
        end
    end
    return damage
end

function RogueBuildPassives.CreateSneakAttackPassive(context)
    local self = buildContextState(context)

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not isAlive(hero) or not target then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.rogue_basic_attack then
            return
        end
        local runtime = ensureRuntime(hero)
        local damageDealt = tonumber(extraParam.damageDealt) or 0
        local condition = isAlive(target) and evaluateSneakCondition(hero, target) or { qualified = false }
        if isAlive(target) and damageDealt > 0 and condition.qualified then
            applySneakAttack(hero, target, condition)
        end
        if condition.viaForced then
            consumeForcedSneak(runtime)
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
        local isReflexOrAoe = extraParam.isAoe == true
            or extraParam.damageKind == "aoe"
            or extraParam.saveType == "dex"
        if isReflexOrAoe and FeatModHelper.HasFlag(hero, IDS.rogue_uncanny_dodge, "evasion") then
            local saveSuccess = extraParam.saveSuccess
            if saveSuccess == nil and type(extraParam.save) == "table" then
                saveSuccess = extraParam.save.success == true
            end
            if saveSuccess == true then
                extraParam.damage = 0
                BuildPassiveCommon.PublishPassiveTriggered(hero, "反射闪避", "敏捷豁免成功免伤",
                    string.format("%d -> %d", damage, extraParam.damage))
            else
                extraParam.damage = math.max(0, math.floor(damage * 0.5))
                BuildPassiveCommon.PublishPassiveTriggered(hero, "反射闪避", "敏捷豁免失败半伤",
                    string.format("%d -> %d", damage, extraParam.damage))
            end
            return
        end
        if runtime.rogueUncannyRound == round then
            return
        end
        runtime.rogueUncannyRound = round
        extraParam.damage = math.max(0, math.floor(damage * 0.5))
        BuildPassiveCommon.PublishPassiveTriggered(hero, "直觉闪避", "首次受击减半", string.format("%d -> %d", damage, extraParam.damage))
    end

    return self
end

return RogueBuildPassives
