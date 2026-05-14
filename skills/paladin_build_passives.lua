local SkillRuntimeConfig = require("config.skill_runtime_config")
local BuildPassiveCommon = require("skills.build_passive_common")

local PaladinBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local POISON_BUFF_SUBTYPE = 850001
local BURN_BUFF_SUBTYPE = 870001
local GUARDIAN_AURA_BUFF_ID = 890008
local SANCTUARY_KNIGHT_BUFF_ID = 890009
local SHELTER_PRAYER_BUFF_ID = 890012
local HEAVY_ARMOR_PRAYER_BUFF_ID = 890013

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

local function isFrontRow(unit)
    local wpType = tonumber(unit and unit.wpType) or 0
    return wpType >= 1 and wpType <= 3
end

local function buildContextState(context)
    return {
        context = context,
    }
end

local function syncPermanentBuff(hero, buffId, enabled)
    local BattleBuff = require("modules.battle_buff")
    local BattleSkill = require("modules.battle_skill")
    if not hero then
        return
    end
    local buff = BattleBuff.GetBuff(hero, buffId)
    if not enabled then
        if buff then
            BattleBuff.DelBuffByBuffIdAndCaster(hero, buffId, hero, 1)
        end
        return
    end
    if not buff then
        BattleSkill.ApplyBuffFromSkill(hero, hero, buffId, nil, {
            duration = 99,
            isPermanent = true,
        })
    end
end

local function eachFriendlyPaladin(defender, callback)
    if not isAlive(defender) or type(callback) ~= "function" then
        return nil
    end
    local BattleFormation = require("modules.battle_formation")
    for _, ally in ipairs(BattleFormation.GetFriendTeam(defender) or {}) do
        if isAlive(ally)
            and (hasSkill(ally, IDS.paladin_shelter_prayer)
                or hasSkill(ally, IDS.paladin_guardian_aura)
                or hasSkill(ally, IDS.paladin_divine_smite)) then
            local result = callback(ally, ensureRuntime(ally))
            if result ~= nil then
                return result
            end
        end
    end
    return nil
end

local function clearTurnStates(hero)
    local BattleBuff = require("modules.battle_buff")
    local runtime = ensureRuntime(hero)
    runtime.guardianAuraActive = false
    runtime.sanctuaryKnightActive = false
    BattleBuff.DelBuffByBuffIdAndCaster(hero, GUARDIAN_AURA_BUFF_ID, hero, 1)
    BattleBuff.DelBuffByBuffIdAndCaster(hero, SANCTUARY_KNIGHT_BUFF_ID, hero, 1)
end

function PaladinBuildPassives.AugmentBasicAttackResolveOpts(hero, target, opts, runtime)
    if not isAlive(hero) or not isAlive(target) then
        return
    end
    if hasSkill(hero, IDS.paladin_judgement_prayer) and runtime.paladinSmiteRound ~= getRound() then
        local originalAc = tonumber(target.ac) or 0
        local adjustedAc = math.max(0, originalAc - 1)
        if adjustedAc < originalAc then
            opts.targetAC = math.min(opts.targetAC or originalAc, adjustedAc)
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发裁决祷法：%s AC %d -> %d",
                hero.name or "Unknown",
                target.name or "目标",
                originalAc,
                opts.targetAC))
        end
    end
end

function PaladinBuildPassives.ActivateGuardianAura(hero)
    local BattleSkill = require("modules.battle_skill")
    local runtime = ensureRuntime(hero)
    runtime.guardianAuraActive = true
    runtime.guardianAuraRound = getRound()
    BattleSkill.ApplyBuffFromSkill(hero, hero, GUARDIAN_AURA_BUFF_ID, nil, {
        duration = 1,
    })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 展开守护灵光：我方全体获得 AC 加成和首次受击减伤",
        hero and hero.name or "Unknown"))
end

function PaladinBuildPassives.GetAuraAcBonus(defender, attacker)
    return eachFriendlyPaladin(defender, function(ally, runtime)
        local total = 0
        if runtime.guardianAuraActive then
            total = total + 1
            if hasSkill(ally, IDS.paladin_aura_mastery) then
                total = total + 1
            end
        end
        if runtime.sanctuaryKnightActive and isFrontRow(defender) then
            total = total + 1
        end
        if total > 0 then
            return total
        end
        return nil
    end) or 0
end

function PaladinBuildPassives.ApplyPaladinProtections(defender, extraParam)
    local attacker = extraParam and extraParam.attacker or nil
    local damageContext = extraParam and extraParam.damageContext or nil
    if not isAlive(defender) or not isAlive(attacker) or type(damageContext) ~= "table" then
        return
    end
    eachFriendlyPaladin(defender, function(ally, runtime)
        local round = getRound()
        local defenderRuntime = ensureRuntime(defender)
        if runtime.guardianAuraActive and defenderRuntime.guardianAuraReducedRound ~= round then
            defenderRuntime.guardianAuraReducedRound = round
            local reduction = BuildPassiveCommon.RollDice("1d6")
            damageContext.damage = math.max(0, (tonumber(damageContext.damage) or 0) - reduction)
            BuildPassiveCommon.PublishPassiveTriggered(ally, "守护灵光", "团队减伤", string.format("为 %s 抵消 %d 伤害", defender.name or "目标", reduction))
        end
        if hasSkill(ally, IDS.paladin_shelter_prayer) and defenderRuntime.paladinShelterRound ~= round then
            defenderRuntime.paladinShelterRound = round
            local reduction = BuildPassiveCommon.RollDice("1d6")
            damageContext.damage = math.max(0, (tonumber(damageContext.damage) or 0) - reduction)
            BuildPassiveCommon.PublishPassiveTriggered(ally, "神圣庇护", "团队减伤", string.format("为 %s 抵消 %d 伤害", defender.name or "目标", reduction))
        end
        return nil
    end)
end

function PaladinBuildPassives.PerformLayOnHands(hero, target, skill)
    local ally = BuildPassiveCommon.PickLowestHpAlly(hero, true) or hero
    if not isAlive(ally) then
        return 0, nil
    end
    local BattleBuff = require("modules.battle_buff")
    local healDice = "2d8+4"
    if hasSkill(hero, IDS.paladin_healing_mastery) then
        healDice = BuildPassiveCommon.JoinDiceParts(healDice, "1d8")
    end
    local amount = BuildPassiveCommon.RollDice(healDice)
    BuildPassiveCommon.ApplyHeal(ally, amount)
    BattleBuff.DelBuffBySubType(ally, E_BUFF_SPEC_SUBTYPE.Frozen)
    BattleBuff.DelBuffBySubType(ally, E_BUFF_SPEC_SUBTYPE.STUN)
    BattleBuff.DelBuffBySubType(ally, E_BUFF_SPEC_SUBTYPE.SILENT)
    BattleBuff.DelBuffBySubType(ally, POISON_BUFF_SUBTYPE)
    BattleBuff.DelBuffBySubType(ally, BURN_BUFF_SUBTYPE)
    BuildPassiveCommon.PublishCombatLog(string.format("%s 发动圣疗之手：为 %s 回复 %d 生命并净化负面状态",
        hero and hero.name or "Unknown",
        ally.name or "目标",
        amount))
    return amount, ally
end

function PaladinBuildPassives.PerformVengeanceSmite(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 then
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "2d8", {
            kind = "physical",
            damageKind = "direct",
            skillId = skill and skill.skillId or IDS.paladin_vengeance_smite,
            skillName = skill and skill.name or "破邪斩",
        })
        damage = damage + bonus
        local BattleBuff = require("modules.battle_buff")
        local buffs = BattleBuff.GetAllBuffs(target) or {}
        for i = #buffs, 1, -1 do
            if tonumber(buffs[i].mainType) == E_BUFF_MAIN_TYPE.GOOD then
                table.remove(buffs, i)
                BuildPassiveCommon.PublishCombatLog(string.format("%s 发动破邪斩：驱散 %s 的 1 个正面状态",
                    hero.name or "Unknown",
                    target.name or "目标"))
                break
            end
        end
        BuildPassiveCommon.PublishCombatLog(string.format("%s 发动破邪斩：对 %s 追加 %d 点光耀伤害",
            hero.name or "Unknown",
            target.name or "目标",
            bonus))
    end
    return damage
end

function PaladinBuildPassives.CreateDivineSmitePassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        local hero = self.context and self.context.src or nil
        clearTurnStates(hero)
        syncPermanentBuff(hero, SHELTER_PRAYER_BUFF_ID, hasSkill(hero, IDS.paladin_shelter_prayer))
    end

    function self:OnSelfTurnBegin()
        local hero = self.context and self.context.src or nil
        clearTurnStates(hero)
        syncPermanentBuff(hero, SHELTER_PRAYER_BUFF_ID, hasSkill(hero, IDS.paladin_shelter_prayer))
    end

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not isAlive(hero) or not isAlive(target) then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.paladin_basic_attack then
            return
        end
        if (tonumber(extraParam.damageDealt) or 0) <= 0 then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        if runtime.paladinSmiteRound == round then
            return
        end
        runtime.paladinSmiteRound = round
        local diceExpr = "1d6"
        if hasSkill(hero, IDS.paladin_smite_mastery) then
            diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
        end
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, diceExpr, {
            kind = "physical",
            damageKind = "direct",
            skillId = IDS.paladin_divine_smite,
            skillName = "神圣惩击",
        })
        if bonus > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发神圣惩击：对 %s 追加 %d 点光耀伤害",
                hero.name or "Unknown",
                target.name or "目标",
                bonus))
        end
    end

    return self
end

function PaladinBuildPassives.CreateHeavyArmorPrayerPassive(context)
    local self = buildContextState(context)

    local function syncSelf()
        local hero = self.context and self.context.src or nil
        syncPermanentBuff(hero, HEAVY_ARMOR_PRAYER_BUFF_ID, hasSkill(hero, IDS.paladin_heavy_armor_prayer))
    end

    function self:OnBattleBegin()
        syncSelf()
    end

    function self:OnSelfTurnBegin()
        syncSelf()
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        if runtime.paladinHeavyArmorRound == round then
            return
        end
        runtime.paladinHeavyArmorRound = round
        local reduction = BuildPassiveCommon.RollDice("1d6")
        extraParam.damage = math.max(0, (tonumber(extraParam.damage) or 0) - reduction)
        BuildPassiveCommon.PublishPassiveTriggered(hero, "重甲祷法", "首次受击减伤", string.format("减免 %d 伤害", reduction))
    end

    return self
end

function PaladinBuildPassives.CreateExtraAttackPassive(context)
    return BuildPassiveCommon.CreateExtraAttackPassive(context, {
        basicAttackSkillId = IDS.paladin_basic_attack,
        tokenKey = "paladinExtraAttackToken",
        onPrimaryHit = function(hero, target, runtime)
            if hasSkill(hero, IDS.paladin_execution_knight) then
                runtime.pendingBasicAttackBonusDice = BuildPassiveCommon.JoinDiceParts(runtime.pendingBasicAttackBonusDice, "1d8")
            end
            if hasSkill(hero, IDS.paladin_merciful_knight) then
                local ally = BuildPassiveCommon.PickLowestHpAlly(hero, true) or hero
                local heal = BuildPassiveCommon.RollDice("1d6")
                BuildPassiveCommon.ApplyHeal(ally, heal)
                BuildPassiveCommon.PublishCombatLog(string.format("%s 触发慈光圣骑：为 %s 回复 %d 生命",
                    hero.name or "Unknown",
                    ally and ally.name or "目标",
                    heal))
            end
            if hasSkill(hero, IDS.paladin_sanctuary_knight) then
                local BattleSkill = require("modules.battle_skill")
                runtime.sanctuaryKnightActive = true
                BattleSkill.ApplyBuffFromSkill(hero, hero, SANCTUARY_KNIGHT_BUFF_ID, nil, {
                    duration = 1,
                })
                BuildPassiveCommon.PublishCombatLog(string.format("%s 触发圣域圣骑：我方前排直到下回合开始 AC +1",
                    hero.name or "Unknown"))
            end
        end,
    })
end

return PaladinBuildPassives
