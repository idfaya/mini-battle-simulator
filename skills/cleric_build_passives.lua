local SkillRuntimeConfig = require("config.skill_runtime_config")
local BuildPassiveCommon = require("skills.build_passive_common")

local ClericBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local SANCTUARY_BUFF_ID = 890006
local WATCH_BISHOP_BUFF_ID = 890007
local SHELTER_PRAYER_BUFF_ID = 890011

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

local function syncTimedBuff(hero, buffId, expireRound)
    local BattleBuff = require("modules.battle_buff")
    local BattleSkill = require("modules.battle_skill")
    if not hero then
        return
    end
    local remain = math.max(0, (tonumber(expireRound) or -1) - getRound() + 1)
    local buff = BattleBuff.GetBuff(hero, buffId)
    if remain <= 0 then
        if buff then
            BattleBuff.DelBuffByBuffIdAndCaster(hero, buffId, hero, 1)
        end
        return
    end
    if not buff then
        BattleSkill.ApplyBuffFromSkill(hero, hero, buffId, nil, { duration = remain })
        buff = BattleBuff.GetBuff(hero, buffId)
    end
    if buff then
        buff.duration = remain
        buff.maxDuration = math.max(tonumber(buff.maxDuration) or 0, remain)
    end
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

local function didSpellConnect(damageResult)
    if not damageResult then
        return false
    end
    if damageResult.save then
        return damageResult.save.success ~= true
    end
    if damageResult.hit then
        return damageResult.hit.hit == true
    end
    return (tonumber(damageResult.damage) or 0) > 0
end

local function pickLowestHpAllies(hero, count)
    local BattleFormation = require("modules.battle_formation")
    local allies = {}
    for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
        if isAlive(ally) then
            allies[#allies + 1] = ally
        end
    end
    table.sort(allies, function(a, b)
        local ratioA = math.max(0, tonumber(a.hp) or 0) / math.max(1, tonumber(a.maxHp) or 1)
        local ratioB = math.max(0, tonumber(b.hp) or 0) / math.max(1, tonumber(b.maxHp) or 1)
        if ratioA == ratioB then
            return (tonumber(a.instanceId or a.id) or 0) < (tonumber(b.instanceId or b.id) or 0)
        end
        return ratioA < ratioB
    end)
    local result = {}
    for i = 1, math.min(math.max(1, tonumber(count) or 1), #allies) do
        result[#result + 1] = allies[i]
    end
    return result
end

local function applyHealAmount(hero, ally, baseDice, flatBonus, sourceSkillId, sourceSkillName)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local healAmount = BattleSkill.CalculateHealDice(hero, ally, baseDice)
    healAmount = healAmount + math.max(0, math.floor(tonumber(flatBonus) or 0))
    if hasSkill(hero, IDS.cleric_revival_prayer) then
        healAmount = healAmount + BattleSkill.CalculateHealDice(hero, ally, "1d8")
    end
    if hasSkill(hero, IDS.cleric_healing_mastery) then
        healAmount = healAmount + BattleSkill.CalculateHealDice(hero, ally, "1d8")
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if hasSkill(hero, IDS.cleric_mercy_bishop) and runtime.clericMercyHealRound ~= round then
        runtime.clericMercyHealRound = round
        local mercy = BattleSkill.CalculateHealDice(hero, ally, "1d6")
        healAmount = healAmount + mercy
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发慈恩主教：对 %s 额外回复 %d 生命",
            hero.name or "Unknown",
            ally.name or "目标",
            mercy))
    end
    BattleDmgHeal.ApplyHeal(ally, healAmount, hero)
    BuildPassiveCommon.PublishCombatLog(string.format("%s 使用%s：为 %s 回复 %d 生命",
        hero.name or "Unknown",
        sourceSkillName or "神术治疗",
        ally.name or "目标",
        healAmount))
    return healAmount
end

local function applyRadiantBonus(hero, target, diceExpr, sourceSkillId, sourceSkillName, label)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, diceExpr, {
        kind = "spell",
        damageKind = "spell",
        noWeapon = true,
        noAbilityMod = true,
        skillId = sourceSkillId,
        skillName = sourceSkillName,
    })
    if bonus > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：对 %s 追加 %d 点光耀伤害",
            hero.name or "Unknown",
            label or sourceSkillName or "神术强化",
            target.name or "目标",
            bonus))
    end
    return bonus
end

local function applyBasicSpellPostHit(hero, target)
    local total = 0
    if hasSkill(hero, IDS.cleric_radiant_prayer) then
        total = total + applyRadiantBonus(hero, target, "1d6", IDS.cleric_radiant_prayer, "裁断祷文", "裁断祷文")
    end
    if hasSkill(hero, IDS.cleric_spell_mastery) then
        total = total + applyRadiantBonus(hero, target, "1d6", IDS.cleric_spell_mastery, "神术专精", "神术专精")
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.clericBlessedRound ~= round then
        runtime.clericBlessedRound = round
        if hasSkill(hero, IDS.cleric_dawn_bishop) then
            total = total + applyRadiantBonus(hero, target, "1d8", IDS.cleric_dawn_bishop, "圣焰主教", "Blessed Strikes")
        end
        if hasSkill(hero, IDS.cleric_watch_bishop) then
            runtime.clericWatchBishopExpireRound = round + 1
            syncTimedBuff(hero, WATCH_BISHOP_BUFF_ID, runtime.clericWatchBishopExpireRound)
            BuildPassiveCommon.PublishCombatLog(string.format("%s 触发守望主教：前排友军 AC +1 持续到下回合开始",
                hero.name or "Unknown"))
        end
    end
    return total
end

function ClericBuildPassives.PerformBasicSpellAttack(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    if BattleSkill.IsAlly(hero, target) then
        return applyHealAmount(
            hero,
            target,
            "1d8",
            0,
            skill and skill.skillId or IDS.cleric_basic_spell,
            skill and skill.name or "神圣火花")
    end
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local BattleVisualEvents = require("ui.battle_visual_events")
    local BattleEvent = require("core.battle_event")
    local runtime = ensureRuntime(hero)
    local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
        meta = {
            kind = "spell",
            damageDice = "1d8",
        },
        damageKind = "spell",
        noWeapon = true,
        noAbilityMod = true,
    })
    runtime.clericBasicSpellLastConnected = didSpellConnect(damageResult)
    local damage = tonumber(damageResult and damageResult.damage) or 0
    local damageContext = {
        attacker = hero,
        target = target,
        damage = damage,
    }
    BattlePassiveSkill.RunSkillOnDefBeforeDmg(target, damageContext)
    BuildPassiveCommon.ApplyTeamProtections(target, {
        attacker = hero,
        damageContext = damageContext,
        skill = skill,
    })
    damage = math.max(0, math.floor(tonumber(damageContext.damage) or damage))
    if damage > 0 then
        if runtime.clericBasicSpellLastConnected then
            damage = damage + applyBasicSpellPostHit(hero, target)
        end
        BattleDmgHeal.ApplyDamage(target, damage, hero, {
            isCrit = damageResult and damageResult.isCrit or false,
            isDodged = damageResult and damageResult.isDodged or false,
            isBlocked = damageResult and damageResult.isBlock or false,
            skillId = skill and skill.skillId or IDS.cleric_basic_spell,
            skillName = skill and skill.name or "神圣火花",
            damageKind = "spell",
            attackRoll = damageResult and damageResult.hit or nil,
            saveRoll = damageResult and damageResult.save or nil,
            damageRoll = damageResult and damageResult.damageRoll or nil,
        })
        BuildPassiveCommon.PublishCombatLog(string.format("%s 使用神圣火花：对 %s 造成 %d 点伤害",
            hero.name or "Unknown",
            target.name or "目标",
            damage))
        BattlePassiveSkill.RunSkillOnDefAfterDmg(target, { attacker = hero, damage = damage })
        BattleSkill.TriggerDamageBuffs(hero, target, damage)
        if target.isDead or (tonumber(target.hp) or 0) <= 0 then
            BattlePassiveSkill.RunSkillOnDmgMakeKill(hero, { target = target })
        end
        return damage
    end
    if damageResult and damageResult.hit and damageResult.hit.hit == false then
        BattleEvent.Publish(BattleVisualEvents.MISS, BattleVisualEvents.BuildCombatEvent(
            BattleVisualEvents.MISS,
            hero,
            target,
            {
                skillId = skill and skill.skillId or IDS.cleric_basic_spell,
                skillName = skill and skill.name or "神圣火花",
                attackRoll = damageResult.hit,
            }))
    end
    return 0
end

function ClericBuildPassives.PerformHealingWord(hero, skill)
    if not isAlive(hero) then
        return 0, nil
    end
    local ally = BuildPassiveCommon.PickLowestHpAlly(hero, true)
    if not isAlive(ally) then
        return 0, nil
    end
    local amount = applyHealAmount(hero, ally, "1d8", tonumber(hero.level) or 1, skill and skill.skillId or IDS.cleric_healing_word, skill and skill.name or "治愈之言")
    return amount, ally
end

function ClericBuildPassives.PerformLifePrayer(hero, skill)
    if not isAlive(hero) then
        return 0, {}
    end
    local total = 0
    local healedTargets = {}
    for _, ally in ipairs(pickLowestHpAllies(hero, 2)) do
        total = total + applyHealAmount(hero, ally, "1d8", 4, skill and skill.skillId or IDS.cleric_life_prayer, skill and skill.name or "群愈祷言")
        healedTargets[#healedTargets + 1] = ally
    end
    return total, healedTargets
end

function ClericBuildPassives.PerformHolyVerdict(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local runtime = ensureRuntime(hero)
    runtime.clericBasicSpellLastConnected = false
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and runtime.clericBasicSpellLastConnected == true then
        damage = damage + applyRadiantBonus(hero, target, "2d6", skill and skill.skillId or IDS.cleric_holy_verdict, skill and skill.name or "圣焰裁决", "光明领域")
    end
    return damage
end

function ClericBuildPassives.ActivateSanctuary(hero, skill)
    if not isAlive(hero) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    runtime.clericSanctuaryExpireRound = getRound() + 2
    runtime.clericSanctuaryProtectedTargets = {}
    syncTimedBuff(hero, SANCTUARY_BUFF_ID, runtime.clericSanctuaryExpireRound)
    BuildPassiveCommon.PublishCombatLog(string.format("%s 使用%s：我方全体获得圣域护持",
        hero.name or "Unknown",
        skill and skill.name or "圣域祷言"))
    return 1
end

local function getSanctuaryAcBonus(source)
    local runtime = ensureRuntime(source)
    if (tonumber(runtime.clericSanctuaryExpireRound) or -1) < getRound() then
        return 0
    end
    local bonus = 1
    if hasSkill(source, IDS.cleric_sanctuary_mastery) then
        bonus = bonus + 1
    end
    return bonus
end

function ClericBuildPassives.GetAuraAcBonus(defender, attacker)
    local BattleFormation = require("modules.battle_formation")
    if not isAlive(defender) then
        return 0
    end
    local total = 0
    for _, ally in ipairs(BattleFormation.GetFriendTeam(defender) or {}) do
        if isAlive(ally) then
            total = total + getSanctuaryAcBonus(ally)
            local runtime = ensureRuntime(ally)
            if hasSkill(ally, IDS.cleric_watch_bishop)
                and (tonumber(runtime.clericWatchBishopExpireRound) or 0) >= getRound()
                and tonumber(defender.wpType or 0) > 0 and tonumber(defender.wpType or 0) <= 3 then
                total = total + 1
            end
        end
    end
    return total
end

function ClericBuildPassives.ApplyClericProtections(defender, extraParam)
    local BattleFormation = require("modules.battle_formation")
    if not isAlive(defender) then
        return
    end
    local damageContext = extraParam and extraParam.damageContext or nil
    if not damageContext then
        return
    end
    for _, ally in ipairs(BattleFormation.GetFriendTeam(defender) or {}) do
        if isAlive(ally) then
            local runtime = ensureRuntime(ally)
            local round = getRound()
            local bestReduction = 0
            local bestLabel = nil
            local defenderId = tonumber(defender.instanceId or defender.id) or 0
            if hasSkill(ally, IDS.cleric_shelter_prayer) and runtime.clericShelterProtectedRound ~= round then
                runtime.clericShelterProtectedRound = round
                bestReduction = BuildPassiveCommon.RollDice("1d6")
                bestLabel = "神恩庇护"
            end
            if getSanctuaryAcBonus(ally) > 0 then
                runtime.clericSanctuaryProtectedTargets = runtime.clericSanctuaryProtectedTargets or {}
                if runtime.clericSanctuaryProtectedTargets[defenderId] ~= round then
                    runtime.clericSanctuaryProtectedTargets[defenderId] = round
                    local reduction = BuildPassiveCommon.RollDice("1d6")
                    if reduction > bestReduction then
                        bestReduction = reduction
                        bestLabel = "圣域祷言"
                    end
                end
            end
            if bestReduction > 0 then
                damageContext.damage = math.max(0, (tonumber(damageContext.damage) or 0) - bestReduction)
                BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：为 %s 减免 %d 伤害",
                    ally.name or "Unknown",
                    bestLabel or "神术庇护",
                    defender.name or "目标",
                    bestReduction))
            end
        end
    end
end

function ClericBuildPassives.CreateShelterPrayerPassive(context)
    local self = {
        context = context,
    }

    local function syncSelf()
        local hero = self.context and self.context.src or nil
        syncPermanentBuff(hero, SHELTER_PRAYER_BUFF_ID, hasSkill(hero, IDS.cleric_shelter_prayer))
    end

    function self:OnBattleBegin()
        syncSelf()
    end

    function self:OnSelfTurnBegin()
        syncSelf()
    end

    return self
end

return ClericBuildPassives
