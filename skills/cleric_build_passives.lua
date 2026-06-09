local SkillRuntimeConfig = require("config.tables.skill_runtime")
local Skill5eMeta = require("config.tables.skill_meta")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

local ClericBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local SANCTUARY_BUFF_ID = 890006
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

local function sameUnit(a, b)
    return BuildPassiveCommon.SameUnit(a, b)
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
        return (tonumber(damageResult.damage) or 0) > 0
    end
    if damageResult.hit then
        return damageResult.hit.hit == true
    end
    return (tonumber(damageResult.damage) or 0) > 0
end

local function getBasicSpellStageDice(skill)
    return Skill5eMeta.ResolveStageDamageDice(IDS.cleric_basic_spell, skill and skill.level)
end

local function getClericSpellAbilityMod(hero)
    return math.max(0, math.floor(tonumber(hero and hero.wisMod) or 0))
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
    BattleDmgHeal.ApplyHeal(ally, healAmount, hero)
    BuildPassiveCommon.PublishCombatLog(string.format("%s 使用%s：为 %s 回复 %d 生命",
        hero.name or "Unknown",
        sourceSkillName or "神术治疗",
        ally.name or "目标",
        healAmount))
    return healAmount
end

local function getLowestHpAllies(hero, includeSelf, count)
    local BattleFormation = require("modules.battle_formation")
    local picked = {}
    for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
        if isAlive(ally) and (includeSelf or not sameUnit(ally, hero)) then
            picked[#picked + 1] = ally
        end
    end
    table.sort(picked, function(a, b)
        local aMaxHp = math.max(1, tonumber(a.maxHp) or 1)
        local bMaxHp = math.max(1, tonumber(b.maxHp) or 1)
        local aRatio = math.max(0, tonumber(a.hp) or 0) / aMaxHp
        local bRatio = math.max(0, tonumber(b.hp) or 0) / bMaxHp
        if aRatio ~= bRatio then
            return aRatio < bRatio
        end
        return (tonumber(a.instanceId or a.id) or 0) < (tonumber(b.instanceId or b.id) or 0)
    end)
    local maxCount = math.max(1, math.floor(tonumber(count) or 1))
    while #picked > maxCount do
        picked[#picked] = nil
    end
    return picked
end

local function getRowOfUnit(unit)
    local BattleFormation = require("modules.battle_formation")
    if not unit then
        return nil
    end
    return tonumber(BattleFormation.GetHeroRow and BattleFormation.GetHeroRow(unit)) or ({
        [1] = 1, [2] = 1, [3] = 2, [4] = 2
    })[tonumber(unit.wpType) or 0]
end

local function collectAliveAlliesInRow(hero, row)
    local BattleFormation = require("modules.battle_formation")
    local result = {}
    if not hero or not row then
        return result
    end
    for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
        if isAlive(ally) and getRowOfUnit(ally) == row then
            result[#result + 1] = ally
        end
    end
    return result
end

local function resolveAliveUnit(unit)
    if not unit then
        return nil
    end
    local BattleFormation = require("modules.battle_formation")
    local resolved = BattleFormation.FindHeroByInstanceId(unit.instanceId or unit.id) or unit
    if not isAlive(resolved) then
        return nil
    end
    return resolved
end

local function clearOneDebuff(target)
    local BattleBuff = require("modules.battle_buff")
    for i = #(BattleBuff.GetAllBuffs(target) or {}), 1, -1 do
        local buff = BattleBuff.GetAllBuffs(target)[i]
        if buff and (buff.mainType == E_BUFF_MAIN_TYPE.BAD or buff.mainType == E_BUFF_MAIN_TYPE.CONTROL) then
            return BattleBuff.DelBuffBySubType(target, buff.subType, 1)
        end
    end
    return 0
end

local function grantShelterDebuffGuard(target, delta)
    local value = math.floor(tonumber(delta) or 0)
    if not isAlive(target) or value == 0 then
        return
    end
    local runtime = ensureRuntime(target)
    runtime.clericShelterDebuffDurationDelta = value
    runtime.clericShelterDebuffCharges = 1
end

local function grantTempHp(target, amount, sourceName)
    local value = math.max(0, math.floor(tonumber(amount) or 0))
    if not isAlive(target) or value <= 0 then
        return 0
    end
    target.tempHp = math.max(math.floor(tonumber(target.tempHp) or 0), value)
    BuildPassiveCommon.PublishCombatLog(string.format("%s 获得 %d 点临时生命",
        target.name or sourceName or "目标",
        value))
    return value
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
    return total
end

function ClericBuildPassives.PerformBasicSpellAttack(hero, target, skill)
    hero = resolveAliveUnit(hero)
    target = resolveAliveUnit(target)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local sparkDice = getBasicSpellStageDice(skill)
    local spellAbilityMod = getClericSpellAbilityMod(hero)
    if BattleSkill.IsAlly(hero, target) then
        return 0
    end
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local BattleVisualEvents = require("ui.battle_visual_events")
    local BattleEvent = require("core.battle_event")
    local runtime = ensureRuntime(hero)
    local meta = Skill5eMeta.Get(IDS.cleric_basic_spell)
    local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
        meta = meta,
        damageKind = "spell",
        damageDice = sparkDice,
        noWeapon = true,
        noAbilityMod = true,
    })
    runtime.clericBasicSpellLastConnected = didSpellConnect(damageResult)
    local damage = math.max(0, math.floor(tonumber(damageResult and damageResult.damage) or 0))
    if damage > 0 and spellAbilityMod > 0 then
        if damageResult and damageResult.save and damageResult.save.success == true then
            damage = damage + math.floor(spellAbilityMod / 2)
        else
            damage = damage + spellAbilityMod
        end
    end
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
        local rollParams = BuildPassiveCommon.BuildDamageEventRollParams(damageResult, meta)
        BattleDmgHeal.ApplyDamage(target, damage, hero, {
            isCrit = damageResult and damageResult.isCrit or false,
            isDodged = damageResult and damageResult.isDodged or false,
            isBlocked = damageResult and damageResult.isBlock or false,
            skillId = skill and skill.skillId or IDS.cleric_basic_spell,
            skillName = skill and skill.name or "圣火术",
            damageKind = "spell",
            attackRoll = rollParams.attackRoll,
            saveRoll = rollParams.saveRoll,
            damageRoll = rollParams.damageRoll,
            saveType = rollParams.saveType or "dex",
            onSaveSuccess = rollParams.onSaveSuccess or "none",
        })
        local rollSuffix = BuildPassiveCommon.FormatRollSuffixForLog(rollParams, true)
        BuildPassiveCommon.PublishCombatLog(string.format("%s 使用圣火术：对 %s 造成 %d 点伤害%s",
            hero.name or "Unknown",
            target.name or "目标",
            damage,
            rollSuffix))
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
                skillName = skill and skill.name or "圣火术",
                attackRoll = damageResult.hit,
            }))
    end
    return 0
end

function ClericBuildPassives.PerformHealingWord(hero, skill, lockedTargets)
    if not isAlive(hero) then
        return 0, nil
    end
    local mods = hero and hero.buildState and hero.buildState.skillMods
        and hero.buildState.skillMods[IDS.cleric_healing_word]
        or {}
    local healLowestCount = math.max(1, math.floor(tonumber(mods and mods.healLowestCount) or 1))
    local targets = {}
    if type(lockedTargets) == "table" then
        for _, ally in ipairs(lockedTargets) do
            local resolvedAlly = resolveAliveUnit(ally)
            if resolvedAlly then
                targets[#targets + 1] = resolvedAlly
            end
            if #targets >= healLowestCount then
                break
            end
        end
    end
    if #targets == 0 then
        targets = getLowestHpAllies(hero, true, healLowestCount)
    end
    local primaryTarget = targets[1]
    if not isAlive(primaryTarget) then
        return 0, nil
    end
    local total = 0
    local dispelOnlyPrimary = mods and mods.dispelOnlyPrimary == true
    local shieldValue = math.max(0, math.floor(tonumber(mods and mods.postHealShield) or 0))
    if shieldValue <= 0 and hasSkill(hero, IDS.cleric_shelter_prayer) then
        shieldValue = 4
    end
    for index, ally in ipairs(targets) do
        total = total + applyHealAmount(hero, ally, "1d8", tonumber(hero.level) or 1,
            skill and skill.skillId or IDS.cleric_healing_word,
            skill and skill.name or "治愈真言")
        if shieldValue > 0 then
            grantTempHp(ally, shieldValue, skill and skill.name or "治愈真言")
        end
        if index == 1 or not dispelOnlyPrimary then
            clearOneDebuff(ally)
        end
    end
    return total, primaryTarget, targets
end

function ClericBuildPassives.ActivateSanctuary(hero, skill, lockedTargets)
    if not isAlive(hero) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local blessMods = hero and hero.buildState and hero.buildState.skillMods
        and hero.buildState.skillMods[IDS.cleric_sanctuary_prayer]
        or {}
    local blessAttackBonus = math.max(1, math.floor(tonumber(blessMods and blessMods.blessAttackBonus) or 1))
    local blessSaveBonus = math.max(1, math.floor(tonumber(blessMods and blessMods.blessSaveBonus) or 1))
    local blessTempHpFlat = math.max(0, math.floor(tonumber(blessMods and blessMods.blessTempHpFlat) or 0))
    local blessAcBonus = math.max(0, math.floor(tonumber(blessMods and blessMods.blessAcBonus) or 0))
    local targetRow = nil
    if type(lockedTargets) == "table" and #lockedTargets > 0 then
        targetRow = getRowOfUnit(resolveAliveUnit(lockedTargets[1]))
    end
    if not targetRow then
        local frontAllies = collectAliveAlliesInRow(hero, 1)
        local backAllies = collectAliveAlliesInRow(hero, 2)
        local frontInjured = 0
        local backInjured = 0
        for _, ally in ipairs(frontAllies) do
            if (tonumber(ally.hp) or 0) < (tonumber(ally.maxHp) or 0) then
                frontInjured = frontInjured + 1
            end
        end
        for _, ally in ipairs(backAllies) do
            if (tonumber(ally.hp) or 0) < (tonumber(ally.maxHp) or 0) then
                backInjured = backInjured + 1
            end
        end
        targetRow = (backInjured > frontInjured) and 2 or 1
    end
    runtime.clericSanctuaryExpireRound = getRound() + 2
    runtime.clericSanctuaryTargetRow = targetRow
    runtime.clericSanctuaryAttackBonus = blessAttackBonus
    runtime.clericSanctuarySaveBonus = blessSaveBonus
    runtime.clericSanctuaryTempHpFlat = blessTempHpFlat
    runtime.clericSanctuaryAcBonus = blessAcBonus
    syncTimedBuff(hero, SANCTUARY_BUFF_ID, runtime.clericSanctuaryExpireRound)
    local affectedTargets = collectAliveAlliesInRow(hero, targetRow)
    for _, ally in ipairs(affectedTargets) do
        if blessTempHpFlat > 0 then
            grantTempHp(ally, blessTempHpFlat, skill and skill.name or "祝福术")
        end
    end
    local rowLabel = targetRow == 1 and "前排" or "后排"
    BuildPassiveCommon.PublishCombatLog(string.format("%s 使用%s：%s获得祝福护持（攻击检定 +%d，豁免检定 +%d%s%s）",
        hero.name or "Unknown",
        skill and skill.name or "祝福术",
        rowLabel,
        blessAttackBonus,
        blessSaveBonus,
        blessTempHpFlat > 0 and ("，临时生命 +" .. tostring(blessTempHpFlat)) or "",
        blessAcBonus > 0 and ("，AC +" .. tostring(blessAcBonus)) or ""))
    return 1, affectedTargets
end

local function getBlessBonuses(source)
    local runtime = ensureRuntime(source)
    if (tonumber(runtime.clericSanctuaryExpireRound) or -1) < getRound() then
        return 0, 0, 0, nil
    end
    return math.max(0, tonumber(runtime.clericSanctuaryAttackBonus) or 0),
        math.max(0, tonumber(runtime.clericSanctuarySaveBonus) or 0),
        math.max(0, tonumber(runtime.clericSanctuaryAcBonus) or 0),
        tonumber(runtime.clericSanctuaryTargetRow)
end

function ClericBuildPassives.GetAuraAcBonus(defender, attacker)
    local BattleFormation = require("modules.battle_formation")
    if not isAlive(defender) then
        return 0
    end
    local defenderRow = getRowOfUnit(defender)
    local total = 0
    for _, ally in ipairs(BattleFormation.GetFriendTeam(defender) or {}) do
        if isAlive(ally) then
            local _, _, acBonus, targetRow = getBlessBonuses(ally)
            if targetRow and targetRow == defenderRow then
                total = total + acBonus
            end
        end
    end
    return total
end

function ClericBuildPassives.GetAuraSaveBonus(defender, saveType)
    local BattleFormation = require("modules.battle_formation")
    if not isAlive(defender) then
        return 0
    end
    local total = 0
    local defenderRow = getRowOfUnit(defender)
    for _, ally in ipairs(BattleFormation.GetFriendTeam(defender) or {}) do
        if isAlive(ally) then
            local _, saveBonus, _, targetRow = getBlessBonuses(ally)
            if targetRow and targetRow == defenderRow then
                total = total + saveBonus
            end
        end
    end
    return total
end

function ClericBuildPassives.GetAuraAttackBonus(attacker, defender)
    local BattleFormation = require("modules.battle_formation")
    if not isAlive(attacker) then
        return 0
    end
    local attackerRow = getRowOfUnit(attacker)
    local total = 0
    for _, ally in ipairs(BattleFormation.GetFriendTeam(attacker) or {}) do
        if isAlive(ally) then
            local attackBonus, _, _, targetRow = getBlessBonuses(ally)
            if targetRow and targetRow == attackerRow then
                total = total + attackBonus
            end
        end
    end
    return total
end

function ClericBuildPassives.ApplyClericProtections(defender, extraParam)
    return
end

function ClericBuildPassives.PerformTurnUndead(hero, skill, lockedTargets)
    if not isAlive(hero) then
        return 0, {}
    end
    local BattleFormation = require("modules.battle_formation")
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local total = 0
    local affectedTargets = {}
    local bonusDice = hero and hero.buildState and hero.buildState.skillMods
        and hero.buildState.skillMods[IDS.cleric_turn_undead]
        and hero.buildState.skillMods[IDS.cleric_turn_undead].bonusDamageDice
        or nil
    local executeThresholdPct = hero and hero.buildState and hero.buildState.skillMods
        and hero.buildState.skillMods[IDS.cleric_turn_undead]
        and tonumber(hero.buildState.skillMods[IDS.cleric_turn_undead].executeThresholdPct)
        or 0
    local targetPool = lockedTargets
    if type(targetPool) ~= "table" or #targetPool == 0 then
        targetPool = BattleFormation.GetEnemyTeam(hero) or {}
    end
    for _, target in ipairs(targetPool) do
        target = resolveAliveUnit(target)
        if isAlive(target) then
            local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
                skill = skill,
                meta = { attackMode = "spell_save", saveType = "wis", kind = "spell", damageDice = "1d8" },
                damageKind = "spell",
                damageDice = "1d8",
            })
            local damage = math.max(0, math.floor(tonumber(damageResult and damageResult.damage) or 0))
            if type(bonusDice) == "string" and bonusDice ~= "" and damage > 0 then
                damage = damage + math.max(0, BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, bonusDice, {
                    kind = "spell",
                    damageKind = "spell",
                    noWeapon = true,
                    noAbilityMod = true,
                    skillId = skill and skill.skillId or IDS.cleric_turn_undead,
                    skillName = skill and skill.name or "驱散亡灵",
                }))
            end
            if damage > 0 then
                local turnMeta = { attackMode = "spell_save", saveType = "wis", kind = "spell", onSaveSuccess = "half" }
                local rollParams = BuildPassiveCommon.BuildDamageEventRollParams(damageResult, turnMeta)
                BattleDmgHeal.ApplyDamage(target, damage, hero, {
                    skillId = skill and skill.skillId or IDS.cleric_turn_undead,
                    skillName = skill and skill.name or "驱散亡灵",
                    damageKind = "spell",
                    saveRoll = rollParams.saveRoll,
                    damageRoll = rollParams.damageRoll,
                    saveType = rollParams.saveType or "wis",
                    onSaveSuccess = rollParams.onSaveSuccess or "half",
                })
                total = total + damage
                affectedTargets[#affectedTargets + 1] = target
            end
            if damageResult and damageResult.save and damageResult.save.success ~= true then
                BattleSkill.ApplyBuffFromSkill(hero, target, 880001, nil, { duration = 1 })
            end
            if executeThresholdPct > 0 and isAlive(target) then
                local hpRatio = math.max(0, tonumber(target.hp) or 0) / math.max(1, tonumber(target.maxHp) or 1)
                if hpRatio <= (executeThresholdPct / 100) then
                    target.hp = 0
                    target.isAlive = false
                    target.isDead = true
                end
            end
        end
    end
    return total, affectedTargets
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
