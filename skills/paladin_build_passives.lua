local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

local PaladinBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local POISON_BUFF_SUBTYPE = 850001
local BURN_BUFF_SUBTYPE = 870001
local GUARDIAN_AURA_BUFF_ID = 890008
local SHELTER_PRAYER_BUFF_ID = 890012

local function joinDiceParts(a, b)
    a = tostring(a or ""):gsub("^%s+", ""):gsub("%s+$", "")
    b = tostring(b or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if a == "" then
        return b
    end
    if b == "" then
        return a
    end
    return a .. ";" .. b
end

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

local function sameUnit(a, b)
    return BuildPassiveCommon.SameUnit(a, b)
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
    local best = nil
    for _, ally in ipairs(BattleFormation.GetFriendTeam(defender) or {}) do
        if isAlive(ally)
            and (hasSkill(ally, IDS.paladin_shelter_prayer)
                or hasSkill(ally, IDS.paladin_guardian_aura)) then
            local result = callback(ally, ensureRuntime(ally))
            if type(result) == "number" then
                best = math.max(tonumber(best) or 0, result)
            elseif result ~= nil and best == nil then
                best = result
            end
        end
    end
    return best
end

local function getAuraDistance(a, b)
    local BattleFormation = require("modules.battle_formation")
    local aWpType = tonumber(a and a.wpType)
    local bWpType = tonumber(b and b.wpType)
    if not aWpType or not bWpType then
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

local function getAuraMaxDistance(paladin)
    if BuildPassiveCommon.HasSkillOrClassFlag(paladin, IDS.paladin_shelter_prayer, "paladinAuraGlobal") then
        return math.huge
    end
    local delta = math.max(0, math.floor(tonumber(FeatModHelper.GetClassMod(paladin, "paladinAuraRangeDelta", 0)) or 0))
    return 1 + delta
end

local function isUnitInAuraRange(paladin, unit)
    if not isAlive(paladin) or not isAlive(unit) or sameUnit(paladin, unit) then
        return false
    end
    local distance = getAuraDistance(paladin, unit)
    if distance == nil then
        return true
    end
    return distance <= getAuraMaxDistance(paladin)
end

local function clearTurnStates(hero)
    local BattleBuff = require("modules.battle_buff")
    local runtime = ensureRuntime(hero)
    runtime.guardianAuraActive = false
    BattleBuff.DelBuffByBuffIdAndCaster(hero, GUARDIAN_AURA_BUFF_ID, hero, 1)
end

local function getHolyMarkState(target)
    local runtime = ensureRuntime(target)
    runtime.paladinHolyMarks = runtime.paladinHolyMarks or {}
    return runtime.paladinHolyMarks
end

local function applyHolyMark(hero, target, amount, duration)
    if not isAlive(hero) or not isAlive(target) or amount <= 0 then
        return
    end
    local sourceId = tonumber(hero.instanceId or hero.id) or 0
    local marks = getHolyMarkState(target)
    marks[sourceId] = {
        expireRound = getRound() + math.max(1, math.floor(tonumber(duration) or 1)),
        amount = math.max(1, math.floor(tonumber(amount) or 1)),
    }
end

local function getHolyMarkAmount(attacker, defender)
    if not isAlive(attacker) or not isAlive(defender) then
        return 0
    end
    local sourceId = tonumber(attacker.instanceId or attacker.id) or 0
    local mark = getHolyMarkState(defender)[sourceId]
    if not mark then
        return 0
    end
    if (tonumber(mark.expireRound) or 0) < getRound() then
        return 0
    end
    return math.max(0, math.floor(tonumber(mark.amount) or 0))
end

local function collectAdjacentEnemies(hero, target, totalTargets)
    local BattleFormation = require("modules.battle_formation")
    local picked = {}
    local extraCount = math.max(0, math.floor(tonumber(totalTargets) or 1) - 1)
    if extraCount <= 0 then
        return picked
    end
    local targetRow = isFrontRow(target) and "front" or "back"
    local targetId = tonumber(target and (target.instanceId or target.id)) or 0
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        local enemyId = tonumber(enemy and (enemy.instanceId or enemy.id)) or 0
        local sameRow = (targetRow == "front" and isFrontRow(enemy)) or (targetRow == "back" and not isFrontRow(enemy))
        if isAlive(enemy) and enemyId ~= targetId and sameRow then
            picked[#picked + 1] = enemy
            if #picked >= extraCount then
                return picked
            end
        end
    end
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        local enemyId = tonumber(enemy and (enemy.instanceId or enemy.id)) or 0
        if isAlive(enemy) and enemyId ~= targetId then
            local seen = false
            for _, existed in ipairs(picked) do
                if tonumber(existed.instanceId or existed.id) == enemyId then
                    seen = true
                    break
                end
            end
            if not seen then
                picked[#picked + 1] = enemy
                if #picked >= extraCount then
                    break
                end
            end
        end
    end
    return picked
end

function PaladinBuildPassives.ActivateGuardianAura(hero)
    local BattleSkill = require("modules.battle_skill")
    local runtime = ensureRuntime(hero)
    runtime.guardianAuraActive = true
    runtime.guardianAuraRound = getRound()
    BattleSkill.ApplyBuffFromSkill(hero, hero, GUARDIAN_AURA_BUFF_ID, nil, {
        duration = 1,
    })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 展开守护灵光：灵光范围内友军获得 AC 加成",
        hero and hero.name or "Unknown"))
end

function PaladinBuildPassives.GetAuraAcBonus(defender, attacker)
    return eachFriendlyPaladin(defender, function(ally, runtime)
        if not isUnitInAuraRange(ally, defender) then
            return nil
        end
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
        if not isUnitInAuraRange(ally, defender) then
            return nil
        end
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
    local damageContext = extraParam and extraParam.damageContext or nil
    local attacker = damageContext and damageContext.attacker or nil
    if not damageContext or not isAlive(defender) or not isAlive(attacker) then
        return
    end
    local bonus = getHolyMarkAmount(attacker, defender)
    if bonus <= 0 then
        return
    end
    damageContext.damage = math.max(0, math.floor(tonumber(damageContext.damage) or 0)) + bonus
    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发惩戒印记：%s 额外承受 %d 点伤害",
        attacker.name or "Unknown",
        defender.name or "目标",
        bonus))
end

function PaladinBuildPassives.PerformLayOnHands(hero, target, skill)
    local ally = nil
    if target then
        local BattleFormation = require("modules.battle_formation")
        ally = BattleFormation.FindHeroByInstanceId(target.instanceId or target.id) or target
        if not isAlive(ally) then
            ally = nil
        end
    end
    if not ally then
        local heroMaxHp = math.max(1, tonumber(hero and hero.maxHp) or tonumber(hero and hero.hp) or 1)
        local heroHp = math.max(0, tonumber(hero and hero.hp) or heroMaxHp)
        local shouldHealSelf = (heroHp / heroMaxHp) <= 0.5
        ally = shouldHealSelf and hero or (BuildPassiveCommon.PickLowestHpAlly(hero, true) or hero)
    end
    if not isAlive(ally) then
        return 0, nil
    end
    local BattleBuff = require("modules.battle_buff")
    local amount = BuildPassiveCommon.RollDice("2d8+4")
    BuildPassiveCommon.ApplyHeal(ally, amount)
    local cleanseDebuffs = FeatModHelper.HasFlag(hero, IDS.paladin_lay_on_hands, "cleanseDebuffs")
    if cleanseDebuffs then
        BattleBuff.DelBuffBySubType(ally, E_BUFF_SPEC_SUBTYPE.Frozen)
        BattleBuff.DelBuffBySubType(ally, E_BUFF_SPEC_SUBTYPE.STUN)
        BattleBuff.DelBuffBySubType(ally, E_BUFF_SPEC_SUBTYPE.SILENT)
        BattleBuff.DelBuffBySubType(ally, POISON_BUFF_SUBTYPE)
        BattleBuff.DelBuffBySubType(ally, BURN_BUFF_SUBTYPE)
    end
    local detail = cleanseDebuffs and "并净化负面状态" or ""
    BuildPassiveCommon.PublishCombatLog(string.format("%s 发动圣疗：为 %s 回复 %d 生命%s",
        hero and hero.name or "Unknown",
        ally.name or "目标",
        amount,
        detail))
    return amount, ally
end

function PaladinBuildPassives.PerformVengeanceSmite(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleBuff = require("modules.battle_buff")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 then
        local bonusDice = "2d8"
        local extraDice = FeatModHelper.GetSkillMod(hero, IDS.paladin_vengeance_smite, "bonusDamageDice", nil)
        if type(extraDice) == "string" and extraDice ~= "" then
            bonusDice = joinDiceParts(bonusDice, extraDice)
        end
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, bonusDice, {
            kind = "physical",
            damageKind = "direct",
            skillId = skill and skill.skillId or IDS.paladin_vengeance_smite,
            skillName = skill and skill.name or "破邪斩",
        })
        damage = damage + bonus
        local holyMarkDelta = math.max(0, math.floor(tonumber(FeatModHelper.GetSkillMod(hero, IDS.paladin_vengeance_smite, "onHitVulnerableDelta", 0)) or 0))
        local holyMarkDuration = math.max(1, math.floor(tonumber(FeatModHelper.GetSkillMod(hero, IDS.paladin_vengeance_smite, "onHitVulnerableDuration", 1)) or 1))
        if holyMarkDelta > 0 then
            applyHolyMark(hero, target, holyMarkDelta, holyMarkDuration)
        end
        local splitTargets = math.max(0, math.floor(tonumber(FeatModHelper.GetSkillMod(hero, IDS.paladin_vengeance_smite, "splitAdjacentTargets", 0)) or 0))
        local splitBonusDice = FeatModHelper.GetSkillMod(hero, IDS.paladin_vengeance_smite, "splitBonusDice", nil)
        for _, splashTarget in ipairs(collectAdjacentEnemies(hero, target, splitTargets)) do
            local splashOk, splashResult = BattleSkill.CastSmallSkillWithResult(hero, splashTarget)
            local splashDamage = splashOk and math.max(0, math.floor(tonumber(splashResult and splashResult.totalDamage) or 0)) or 0
            if splashDamage > 0 and type(splitBonusDice) == "string" and splitBonusDice ~= "" then
                splashDamage = splashDamage + BuildPassiveCommon.ApplyDirectBonusDamage(hero, splashTarget, splitBonusDice, {
                    kind = "physical",
                    damageKind = "direct",
                    skillId = skill and skill.skillId or IDS.paladin_vengeance_smite,
                    skillName = "惩戒大师",
                })
            end
            damage = damage + splashDamage
        end
        BuildPassiveCommon.PublishCombatLog(string.format("%s 发动破邪斩：对 %s 追加 %d 点光耀伤害",
            hero.name or "Unknown",
            target.name or "目标",
            bonus))
    end
    return damage
end

function PaladinBuildPassives.CreateExtraAttackPassive(context)
    return BuildPassiveCommon.CreateExtraAttackPassive(context, {
        basicAttackSkillId = IDS.paladin_basic_attack,
        tokenKey = "paladinExtraAttackActionToken",
        inProgressKey = "__inPaladinExtraAttack",
    })
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
