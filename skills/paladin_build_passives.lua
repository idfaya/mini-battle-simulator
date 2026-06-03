local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

local PaladinBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local POISON_BUFF_SUBTYPE = 850001
local BURN_BUFF_SUBTYPE = 870001
local GUARDIAN_AURA_BUFF_ID = 890008
local SHELTER_PRAYER_BUFF_ID = 890012

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
                or hasSkill(ally, IDS.paladin_guardian_aura)) then
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
    BattleBuff.DelBuffByBuffIdAndCaster(hero, GUARDIAN_AURA_BUFF_ID, hero, 1)
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
        if hasSkill(ally, IDS.paladin_shelter_prayer) then
            total = total + 1
            total = total + math.max(0, FeatModHelper.GetClassMod(ally, "paladinAuraAcBonus", 0))
        end
        if runtime.guardianAuraActive then
            total = total + 1
        end
        if total > 0 then
            return total
        end
        return nil
    end) or 0
end

function PaladinBuildPassives.GetAuraSaveBonus(defender, saveType)
    return eachFriendlyPaladin(defender, function(ally, runtime)
        local total = 0
        if hasSkill(ally, IDS.paladin_shelter_prayer) then
            total = total + math.max(0, FeatModHelper.GetClassMod(ally, "paladinAuraSaveBonus", 0))
        end
        if runtime.guardianAuraActive then
            total = total + 1
        end
        if total > 0 then
            return total
        end
        return nil
    end) or 0
end

function PaladinBuildPassives.ApplyPaladinProtections(defender, extraParam)
    return
end

function PaladinBuildPassives.PerformLayOnHands(hero, target, skill)
    local ally = BuildPassiveCommon.PickLowestHpAlly(hero, true) or hero
    if not isAlive(ally) then
        return 0, nil
    end
    local BattleBuff = require("modules.battle_buff")
    local healDice = "2d8+4"
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

function PaladinBuildPassives.CreateShelterPrayerPassive(context)
    local self = buildContextState(context)

    local function syncSelf()
        local hero = self.context and self.context.src or nil
        clearTurnStates(hero)
        syncPermanentBuff(hero, SHELTER_PRAYER_BUFF_ID, hasSkill(hero, IDS.paladin_shelter_prayer))
    end

    function self:OnBattleBegin()
        syncSelf()
    end

    function self:OnSelfTurnBegin()
        syncSelf()
    end

    return self
end

return PaladinBuildPassives
