local SkillRuntimeConfig = require("config.tables.skill_runtime")
local ClassWeaponConfig = require("config.tables.classes")
local BattleEvent = require("core.battle_event")
local FeatModHelper = require("skills.feat_mod_helper")

local FighterBuildPassives = {}
local IDS = SkillRuntimeConfig.Ids

local GUARD_STANCE_BUFF_ID = 890004

local function ensureRuntime(hero)
    if not hero then
        return {}
    end
    hero.passiveRuntime = hero.passiveRuntime or {}
    return hero.passiveRuntime
end

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

local function getRound()
    local BattleLogic = require("modules.battle_logic")
    return tonumber(BattleLogic.GetCurRound and BattleLogic.GetCurRound()) or 0
end

local function hasSkill(hero, skillId)
    if not hero or not skillId then
        return false
    end
    local instances = hero.skillData and hero.skillData.skillInstances or nil
    if instances and instances[skillId] then
        return true
    end
    for _, skill in ipairs(hero.skills or {}) do
        if tonumber(skill.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

local function sameUnit(a, b)
    if not a or not b then
        return false
    end
    return tonumber(a.instanceId or a.id) == tonumber(b.instanceId or b.id)
end

local function getUnitRow(unit)
    local BattleFormation = require("modules.battle_formation")
    local wpType = tonumber(unit and (unit.wpType or unit.position)) or 0
    local row = BattleFormation.GetHeroRow and BattleFormation.GetHeroRow(wpType) or nil
    if row ~= nil then
        return row
    end
    if wpType >= 1 and wpType <= 3 then
        return 1
    end
    if wpType >= 4 and wpType <= 6 then
        return 2
    end
    return nil
end

local function canGuardTarget(guard, defender)
    if not guard or not defender or sameUnit(guard, defender) then
        return false
    end
    if guard.isDead or defender.isDead then
        return false
    end
    if (tonumber(guard.hp) or 0) <= 0 or (tonumber(defender.hp) or 0) <= 0 then
        return false
    end
    if guard.isAlive == false or defender.isAlive == false then
        return false
    end
    local guardRow = getUnitRow(guard)
    local defenderRow = getUnitRow(defender)
    if guardRow == nil or defenderRow == nil then
        return true
    end
    return defenderRow >= guardRow
end

-- #region debug-point A:counter-guard-events
local function publishCounterDebug(stage, data)
    BattleEvent.Publish("DebugCounterTiming", {
        stage = stage,
        source = "skills.fighter_build_passives",
        data = data or {},
    })
end
-- #endregion

local function isAlive(unit)
    return unit and not unit.isDead and (unit.isAlive ~= false) and (tonumber(unit.hp) or 0) > 0
end

local function isMeleeUnit(unit)
    local ClassRoleConfig = require("config.tables.classes")
    local classId = tonumber(unit and (unit.class or unit.Class)) or 0
    return ClassRoleConfig.IsMelee(classId)
end

local function rollDice(expr)
    local Dice = require("core.dice")
    local total = Dice.Roll(expr, { crit = false })
    return math.max(0, math.floor(tonumber(total) or 0))
end

local function getProficiencyBonus(unit)
    return math.max(1, tonumber(unit and unit.proficiencyBonus) or 0)
end

local function applyHeal(hero, amount)
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    if amount > 0 then
        BattleDmgHeal.ApplyHeal(hero, amount, hero)
    end
end

local function getConModifier(hero)
    return math.floor(tonumber(hero and (hero.conMod or hero.constitutionMod or hero.conModifier)) or 0)
end

local function prepareReactionBasicAttack(hero, skillId, label)
    local BuildPassiveCommon = require("skills.build_passive_common")
    local hitBonus = FeatModHelper.GetSkillMod(hero, skillId, "counterBonusHit", 0)
    local bonusDice = hero and hero.buildState and hero.buildState.skillMods
        and hero.buildState.skillMods[tonumber(skillId) or 0]
        and hero.buildState.skillMods[tonumber(skillId) or 0].counterBonusDice
        or nil
    if hitBonus ~= 0 then
        BuildPassiveCommon.AppendPendingBasicAttackHitBonus(hero, hitBonus, label or "反击强化")
    end
    if type(bonusDice) == "string" and bonusDice ~= "" then
        BuildPassiveCommon.AppendPendingBasicAttackBonusDice(hero, bonusDice)
    end
end

local function publishPassiveTriggered(hero, skillName, triggerType, extraInfo)
    if not hero then
        return
    end
    BattleEvent.Publish("PassiveSkillTriggered", {
        eventType = "PassiveSkillTriggered",
        heroId = hero.instanceId or hero.id,
        heroName = hero.name,
        skillName = skillName,
        triggerType = triggerType,
        extraInfo = extraInfo,
    })
end

local function publishCombatLog(message, extraPayload)
    if type(message) ~= "string" or message == "" then
        return
    end
    local payload = {
        message = message,
    }
    if type(extraPayload) == "table" then
        for key, value in pairs(extraPayload) do
            payload[key] = value
        end
    end
    BattleEvent.Publish("CombatLog", payload)
end

function FighterBuildPassives.HasSignatureMastery(hero)
    return ensureRuntime(hero).fighterSignatureMastery == true
end

function FighterBuildPassives.ActivateGuardStance(hero)
    local BattleSkill = require("modules.battle_skill")
    local runtime = ensureRuntime(hero)
    runtime.guardStanceActive = true
    runtime.guardStanceRound = getRound()
    BattleSkill.ApplyBuffFromSkill(hero, hero, GUARD_STANCE_BUFF_ID, nil, {
        duration = 1,
    })

    -- §6 guardEmitsTeamShield：守卫架势激活时为全队叠加护盾 buff。
    local emitsTeamShield = FeatModHelper.HasFlag(hero, IDS.fighter_guard_counter, "guardEmitsTeamShield")
        or (hero and hero.buildState and hero.buildState.classMods and hero.buildState.classMods.guardEmitsTeamShield == true)
    if emitsTeamShield then
        local BattleFormation = require("modules.battle_formation")
        for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
            if isAlive(ally) and not sameUnit(ally, hero) then
                BattleSkill.ApplyBuffFromSkill(hero, ally, GUARD_STANCE_BUFF_ID, nil, {
                    duration = 1,
                })
            end
        end
        publishPassiveTriggered(hero, "护卫架势", "全队护盾", "为全队叠加护盾")
    end
end

function FighterBuildPassives.ClearGuardStance(hero)
    local BattleBuff = require("modules.battle_buff")
    local runtime = ensureRuntime(hero)
    runtime.guardStanceActive = false
    runtime.guardStanceRound = nil
    BattleBuff.DelBuffByBuffIdAndCaster(hero, GUARD_STANCE_BUFF_ID, hero, 1)
end

local function eachGuardCandidate(defender, callback)
    if not isAlive(defender) or type(callback) ~= "function" then
        return nil, nil
    end
    local inspected = {}
    local function visit(unit)
        if not unit then
            return nil, nil
        end
        local unitId = tonumber(unit.instanceId or unit.id) or 0
        if inspected[unitId] then
            return nil, nil
        end
        inspected[unitId] = true
        if isAlive(unit) and hasSkill(unit, IDS.fighter_guard_counter) then
            local runtime = ensureRuntime(unit)
            if runtime.guardStanceActive then
                local ok = callback(unit, runtime)
                if ok then
                    return unit, runtime
                end
            end
        end
        return nil, nil
    end

    local guard, runtime = visit(defender)
    if guard then
        return guard, runtime
    end

    local BattleFormation = require("modules.battle_formation")
    for _, ally in ipairs(BattleFormation.GetFriendTeam(defender) or {}) do
        guard, runtime = visit(ally)
        if guard then
            return guard, runtime
        end
    end
    return nil, nil
end

local function getGuardProtector(defender)
    if hasSkill(defender, IDS.fighter_guard_counter) and ensureRuntime(defender).guardStanceActive then
        return nil, nil
    end
    local guard, runtime = eachGuardCandidate(defender, function(unit)
        return canGuardTarget(unit, defender)
    end)
    return guard, runtime
end

function FighterBuildPassives.ResolveGuardInterception(defender, extraParam)
    local attacker = extraParam and extraParam.attacker or nil
    if not isAlive(defender) or not isAlive(attacker) then
        return defender, nil
    end

    local attackerRuntime = ensureRuntime(attacker)
    if attackerRuntime.__inCounterBasic or attackerRuntime.__inGuardCounter then
        return defender, nil
    end

    local guard, runtime = getGuardProtector(defender)
    if not guard or not runtime then
        return defender, nil
    end

    -- §6 守卫者的 classMod=guardExtendsToRanged 时允许拦截远程；否则仍仅拦截近战。
    if not isMeleeUnit(attacker) then
        local extendsRanged = FeatModHelper.HasFlag(guard, IDS.fighter_guard_counter, "guardExtendsToRanged")
            or (guard.buildState and guard.buildState.classMods and guard.buildState.classMods.guardExtendsToRanged == true)
        if not extendsRanged then
            return defender, nil
        end
    end

    return guard, {
        guard = guard,
        originalDefender = defender,
        redirected = not sameUnit(guard, defender),
    }
end

local function getBasicAttackDamageDice()
    return ClassWeaponConfig.GetWeaponDice(2) or "1d8"
end

local function pickAnotherAliveEnemy(hero, excludedTarget)
    local BattleFormation = require("modules.battle_formation")
    local excludedId = tonumber(excludedTarget and (excludedTarget.instanceId or excludedTarget.id)) or 0
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        local enemyId = tonumber(enemy and (enemy.instanceId or enemy.id)) or 0
        if isAlive(enemy) and enemyId ~= excludedId then
            return enemy
        end
    end
    return nil
end

local function pickBasicAttackTarget(hero, preferredTarget)
    if isAlive(preferredTarget) then
        return preferredTarget
    end
    local BattleSkill = require("modules.battle_skill")
    local picked = BattleSkill.SelectRandomAliveEnemies(hero, 1) or {}
    return picked[1] or nil
end

function FighterBuildPassives.GetGuardStanceAcBonus(defender, attacker)
    if not isAlive(defender) then
        return 0
    end
    local runtime = ensureRuntime(defender)
    local total = 0
    if not hasSkill(defender, IDS.fighter_guard_counter) then
        total = 0
    elseif runtime.guardStanceActive and isAlive(attacker) then
        total = total + 2
    end
    if (tonumber(runtime.secondWindAcExpireRound) or -1) >= getRound() then
        total = total + math.max(0, math.floor(tonumber(runtime.secondWindAcBonus) or 0))
    end
    return total
end

function FighterBuildPassives.ApplyGuardStanceProtection(defender, extraParam)
    local attacker = extraParam and extraParam.attacker or nil
    if not isAlive(defender) or not isAlive(attacker) then
        return
    end

    local originalDefender = extraParam and extraParam.originalDefender or defender
    local guard = extraParam and extraParam.guardDefender or defender
    local runtime = guard and ensureRuntime(guard) or nil
    if not guard or not runtime then
        return
    end

    local payload = {
        attacker = attacker,
        damageContext = extraParam and extraParam.damageContext or nil,
        skill = extraParam and extraParam.skill or nil,
        originalDefender = originalDefender,
        guardDefender = guard,
    }
    local isRangedInterception = not isMeleeUnit(attacker) and not sameUnit(originalDefender, guard)
    if isRangedInterception and FeatModHelper.HasFlag(guard, IDS.fighter_guard_stance, "guardReflectRanged")
        and math.max(0, tonumber(payload.damageContext and payload.damageContext.damage) or 0) <= 0 then
        local BattleSkill = require("modules.battle_skill")
        prepareReactionBasicAttack(guard, IDS.fighter_guard_stance, "护卫反弹")
        BattleSkill.CastSmallSkill(guard, attacker)
        publishPassiveTriggered(guard, "护卫精通", "远程反弹", string.format("将 %s 的远程攻击反打回去", attacker.name or "目标"))
        return
    end
    if not sameUnit(originalDefender, guard) and FeatModHelper.HasFlag(guard, IDS.fighter_guard_stance, "guardHealOnSuccess") then
        local heal = rollDice("1d6")
        applyHeal(guard, heal)
        publishPassiveTriggered(guard, "护卫大师", "护卫成功回复", string.format("回复 %d 生命", heal))
    end
    FighterBuildPassives.TryTriggerGuardCounter(originalDefender, payload)
end

function FighterBuildPassives.RecordAttackVictim(attacker, target, damage)
    if not isAlive(attacker) or not isAlive(target) or (tonumber(damage) or 0) <= 0 then
        return
    end
    local runtime = ensureRuntime(attacker)
    runtime.lastAttackRound = getRound()
    runtime.lastAttackVictimId = target.instanceId or target.id
end

function FighterBuildPassives.BuildBasicAttackResolveOpts(hero, target, skill)
    local runtime = ensureRuntime(hero)
    local ignoreAc = tonumber(runtime.basicAttackIgnoreAc) or 0
    ignoreAc = ignoreAc + (tonumber(runtime.pendingBasicAttackIgnoreAc) or 0)
    local opts = {
        skill = skill,
        damageKind = "direct",
    }
    if ignoreAc > 0 then
        local originalAc = tonumber(target and target.ac) or 0
        opts.targetAC = math.max(0, originalAc - ignoreAc)
        publishCombatLog(string.format("%s 触发精准攻击：%s AC %d -> %d",
            hero and hero.name or "Unknown",
            target and target.name or "目标",
            originalAc,
            opts.targetAC), {
            heroId = hero and (hero.instanceId or hero.id) or nil,
            targetId = target and (target.instanceId or target.id) or nil,
        })
    end
    return opts
end

function FighterBuildPassives.ApplyBasicAttackBonusDamage(hero, target)
    local runtime = ensureRuntime(hero)
    local bonusDice = ""
    if runtime.pendingBasicAttackBonusDice then
        bonusDice = joinDiceParts(bonusDice, runtime.pendingBasicAttackBonusDice)
    end
    if bonusDice == "" then
        return 0
    end

    local BattleSkill = require("modules.battle_skill")
    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        skipCheck = true,
        kind = "physical",
        damageKind = "direct",
        damageDice = bonusDice,
        noWeapon = true,
        noAbilityMod = true,
    })
    return math.max(0, math.floor(tonumber(result and result.damage) or 0))
end

function FighterBuildPassives.AfterBasicAttackResolved(hero, target, damage)
    local runtime = ensureRuntime(hero)
    runtime.lastBasicAttackHit = (tonumber(damage) or 0) > 0
    runtime.lastBasicAttackTargetId = target and (target.instanceId or target.id) or nil
    runtime.pendingBasicAttackBonusDice = nil
    runtime.pendingBasicAttackIgnoreAc = nil
end

function FighterBuildPassives.CastBasicAttackRepeated(hero, target, count)
    local BattleSkill = require("modules.battle_skill")
    local total = 0
    local times = math.max(1, tonumber(count) or 1)
    for _ = 1, times do
        if not isAlive(hero) or not isAlive(target) then
            break
        end
        local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
        if ok then
            local dealt = math.max(0, math.floor(tonumber(result and result.totalDamage) or 0))
            total = total + dealt
        end
    end
    return total
end

function FighterBuildPassives.PublishCombatLog(message)
    publishCombatLog(message)
end

function FighterBuildPassives.ApplyDirectBonusDamage(hero, target, diceExpr)
    if not isAlive(hero) or not isAlive(target) or type(diceExpr) ~= "string" or diceExpr == "" then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        skipCheck = true,
        kind = "physical",
        damageKind = "direct",
        damageDice = diceExpr,
        noWeapon = true,
        noAbilityMod = true,
    })
    local damage = math.max(0, math.floor(tonumber(result and result.damage) or 0))
    if damage > 0 then
        BattleDmgHeal.ApplyDamage(target, damage, hero, { damageKind = "direct" })
    end
    return damage
end

function FighterBuildPassives.TryTriggerSweepingAttack(hero, primaryTarget)
    if not isAlive(hero) then
        return 0
    end
    local secondaryTarget = pickAnotherAliveEnemy(hero, primaryTarget)
    if not isAlive(secondaryTarget) then
        return 0
    end
    local damage = FighterBuildPassives.ApplyDirectBonusDamage(hero, secondaryTarget, getBasicAttackDamageDice())
    if damage > 0 then
        publishPassiveTriggered(hero, "横扫攻击", "追加横扫", string.format("波及 %s 造成 %d 伤害", secondaryTarget.name or "目标", damage))
    end
    return damage
end

function FighterBuildPassives.PerformPressureStrike(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local actualTarget, protectionMeta = FighterBuildPassives.ResolveGuardInterception(target, {
        attacker = hero,
        skill = skill,
    })
    local result = BattleSkill.ResolveScaledDamage(hero, actualTarget, {
        skill = skill,
        damageKind = "direct",
        targetAC = math.max(0, (tonumber(actualTarget.ac) or 0) - 2),
        damageDice = "1d8",
    })
    local damage = tonumber(result and result.damage) or 0
    local damageContext = {
        attacker = hero,
        target = actualTarget,
        originalTarget = target,
        damage = damage,
    }
    BattlePassiveSkill.RunSkillOnDefBeforeDmg(actualTarget, damageContext)
    FighterBuildPassives.ApplyGuardStanceProtection(actualTarget, {
        attacker = hero,
        damageContext = damageContext,
        skill = skill,
        originalDefender = target,
        guardDefender = protectionMeta and protectionMeta.guard or nil,
    })
    damage = math.max(0, math.floor(damageContext.damage or damage))
    if damage > 0 then
        BattleDmgHeal.ApplyDamage(actualTarget, damage, hero, {
            isCrit = result and result.isCrit or false,
            skillId = skill and skill.skillId or nil,
            skillName = skill and skill.name or nil,
            damageKind = "direct",
            attackRoll = result and result.hit or nil,
            damageRoll = result and result.damageRoll or nil,
        })
        BattlePassiveSkill.RunSkillOnDefAfterDmg(actualTarget, { attacker = hero, damage = damage })
        BattleSkill.TriggerDamageBuffs(hero, actualTarget, damage)
        if actualTarget.isDead or (actualTarget.hp or 0) <= 0 then
            BattlePassiveSkill.RunSkillOnDmgMakeKill(hero, { target = actualTarget })
        end
    end
    if damage > 0 and FighterBuildPassives.HasSignatureMastery(hero) and isAlive(actualTarget) then
        damage = damage + FighterBuildPassives.ApplyDirectBonusDamage(hero, actualTarget, "1d6")
    end
    return damage
end

function FighterBuildPassives.TryTriggerGuardCounter(defender, extraParam)
    local attacker = extraParam and extraParam.attacker or nil
    if not isAlive(defender) or not isAlive(attacker) then
        return
    end
    local attackerRuntime = ensureRuntime(attacker)
    if attackerRuntime.__inCounterBasic or attackerRuntime.__inGuardCounter then
        return
    end
    if attackerRuntime.pendingGuardReactionQueued then
        return
    end

    local originalDefender = extraParam and extraParam.originalDefender or defender
    local guard = extraParam and extraParam.guardDefender or nil
    local runtime = guard and ensureRuntime(guard) or nil
    if guard and not canGuardTarget(guard, originalDefender) then
        return
    end
    if (not guard) or (not runtime) then
        guard, runtime = eachGuardCandidate(defender, function(unit, unitRuntime)
            return canGuardTarget(unit, originalDefender) and (not unitRuntime.__inGuardCounter)
        end)
    end
    if not guard or not runtime then
        return
    end

    -- §6 仅在守卫拥有 guardExtendsToRanged 时允许排队远程目标的反击。
    if not isMeleeUnit(attacker) then
        local extendsRanged = FeatModHelper.HasFlag(guard, IDS.fighter_guard_counter, "guardExtendsToRanged")
            or (guard.buildState and guard.buildState.classMods and guard.buildState.classMods.guardExtendsToRanged == true)
        if not extendsRanged then
            return
        end
    end

    attackerRuntime.pendingGuardReactionQueued = true
    runtime.pendingGuardCounterTarget = attacker
    publishPassiveTriggered(guard, "护卫架势", "登记护卫反击", string.format("将对 %s 发动护卫反击", attacker.name or "目标"))
    -- #region debug-point B:queue-guard
    publishCounterDebug("queue_guard_counter", {
        defenderId = originalDefender and (originalDefender.instanceId or originalDefender.id) or defender.instanceId or defender.id,
        defenderName = originalDefender and originalDefender.name or defender.name,
        guardId = guard.instanceId or guard.id,
        guardName = guard.name,
        attackerId = attacker.instanceId or attacker.id,
        attackerName = attacker.name,
    })
    -- #endregion
end

function FighterBuildPassives.ResolveQueuedReactions(attacker)
    if not attacker then
        return
    end
    local BattleFormation = require("modules.battle_formation")
    local BattleSkill = require("modules.battle_skill")
    ensureRuntime(attacker).pendingGuardReactionQueued = false
    local queuedCounters = {}
    local queuedGuards = {}
    for _, hero in ipairs(BattleFormation.GetAllHeroes() or {}) do
        local runtime = ensureRuntime(hero)
        if runtime.pendingCounterBasicTarget and sameUnit(runtime.pendingCounterBasicTarget, attacker) then
            local target = runtime.pendingCounterBasicTarget
            runtime.pendingCounterBasicTarget = nil
            if isAlive(hero) then
                table.insert(queuedCounters, { hero = hero, runtime = runtime, target = target })
            end
        end
        if runtime.pendingGuardCounterTarget and sameUnit(runtime.pendingGuardCounterTarget, attacker) then
            local target = runtime.pendingGuardCounterTarget
            runtime.pendingGuardCounterTarget = nil
            if isAlive(hero) then
                table.insert(queuedGuards, { hero = hero, runtime = runtime, target = target })
            end
        end
    end

    for _, entry in ipairs(queuedCounters) do
        -- #region debug-point D:resolve-counter
        publishCounterDebug("resolve_counter_basic", {
            reactorId = entry.hero.instanceId or entry.hero.id,
            reactorName = entry.hero.name,
            attackerId = attacker.instanceId or attacker.id,
            attackerName = attacker.name,
            targetAlive = isAlive(entry.target),
            inCounter = entry.runtime.__inCounterBasic == true,
        })
        -- #endregion
        if isAlive(entry.target) and not entry.runtime.__inCounterBasic then
            entry.runtime.__inCounterBasic = true
            prepareReactionBasicAttack(entry.hero, IDS.fighter_counter_basic, "反击熟练")
            BattleSkill.CastSmallSkill(entry.hero, entry.target)
            entry.runtime.__inCounterBasic = false
        end
    end

    for _, entry in ipairs(queuedGuards) do
        -- #region debug-point D:resolve-guard
        publishCounterDebug("resolve_guard_counter", {
            reactorId = entry.hero.instanceId or entry.hero.id,
            reactorName = entry.hero.name,
            attackerId = attacker.instanceId or attacker.id,
            attackerName = attacker.name,
            targetAlive = isAlive(entry.target),
            inGuard = entry.runtime.__inGuardCounter == true,
        })
        -- #endregion
        if isAlive(entry.target) and not entry.runtime.__inGuardCounter then
            entry.runtime.__inGuardCounter = true
            prepareReactionBasicAttack(entry.hero, IDS.fighter_guard_stance, "护卫反击强化")
            BattleSkill.CastSmallSkill(entry.hero, entry.target)
            entry.runtime.__inGuardCounter = false
        end
    end
end

function FighterBuildPassives.PerformSecondWindAction(hero, skill)
    if not isAlive(hero) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local maxCharges = 1 + math.max(0, FeatModHelper.GetSkillMod(hero, skill and skill.skillId or IDS.fighter_second_wind_action, "secondWindCharges", 0))
    local used = math.max(0, math.floor(tonumber(runtime.secondWindActionUsed) or 0))
    if used >= maxCharges then
        return 0
    end
    runtime.secondWindActionUsed = used + 1
    local healDice = "1d10"
    local bonusDice = hero and hero.buildState and hero.buildState.skillMods
        and hero.buildState.skillMods[tonumber(skill and skill.skillId or IDS.fighter_second_wind_action) or 0]
        and hero.buildState.skillMods[tonumber(skill and skill.skillId or IDS.fighter_second_wind_action) or 0].bonusHealDice
        or nil
    if type(bonusDice) == "string" and bonusDice ~= "" then
        healDice = joinDiceParts(healDice, bonusDice)
    end
    local heal = rollDice(healDice) + getConModifier(hero)
    applyHeal(hero, heal)
    local acBonus = math.max(0, FeatModHelper.GetSkillMod(hero, skill and skill.skillId or IDS.fighter_second_wind_action, "postUseAcDelta", 0))
    if acBonus > 0 then
        runtime.secondWindAcBonus = acBonus
        runtime.secondWindAcExpireRound = getRound() + 1
    end
    publishCombatLog(string.format("%s 使用回气：回复 %d 生命", hero.name or "Unknown", heal))
    return heal
end

local function buildContextState(context)
    return {
        context = context,
    }
end

function FighterBuildPassives.CreateSecondWindPassive(context)
    local self = buildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        if not isAlive(hero) then
            return
        end
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local incomingDamage = math.max(0, math.floor(tonumber(extraParam.damage) or 0))
        if incomingDamage <= 0 then
            return
        end
        local runtime = ensureRuntime(hero)
        -- §6 secondWindCharges：默认 1 次，feat 可叠加额外充能。
        local maxCharges = 1 + math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.fighter_second_wind, "secondWindCharges", 0)))
        local classExtra = (hero.buildState and hero.buildState.classMods and tonumber(hero.buildState.classMods.secondWindCharges)) or 0
        if classExtra > 0 then
            maxCharges = maxCharges + math.floor(classExtra)
        end
        local used = tonumber(runtime.secondWindChargesUsed) or 0
        if runtime.secondWindUsed and used == 0 then
            used = 1
        end
        if used >= maxCharges then
            return
        end
        local maxHp = tonumber(hero.maxHp) or 1
        if maxHp <= 0 then
            return
        end
        local currentHp = tonumber(hero.hp) or 0
        if currentHp > incomingDamage then
            return
        end
        runtime.secondWindChargesUsed = used + 1
        runtime.secondWindUsed = true
        local heal = math.max(1, math.floor(maxHp * 0.5))
        extraParam.damage = 0
        applyHeal(hero, math.max(0, heal - currentHp))
        local BattleBuff = require("modules.battle_buff")
        for _, buff in ipairs(BattleBuff.GetAllBuffs(hero) or {}) do
            buff.__removeByIndomitableWind = true
        end
        local buffs = BattleBuff.GetAllBuffs(hero) or {}
        for i = #buffs, 1, -1 do
            if buffs[i].__removeByIndomitableWind then
                table.remove(buffs, i)
            end
        end
        publishPassiveTriggered(hero, "不屈之风", "濒死稳固", string.format("保留%d生命并清除状态", heal))
    end

    return self
end

function FighterBuildPassives.CreatePreciseAttackPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        local runtime = ensureRuntime(self.context and self.context.src)
        runtime.basicAttackIgnoreAc = (tonumber(runtime.basicAttackIgnoreAc) or 0) + 2
    end

    return self
end

function FighterBuildPassives.CreateCounterBasicPassive(context)
    local self = buildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local attacker = extraParam.attacker
        if not isAlive(hero) or not isAlive(attacker) or not isMeleeUnit(attacker) then
            return
        end
        local runtime = ensureRuntime(hero)
        local attackerRuntime = ensureRuntime(attacker)
        if runtime.__inCounterBasic or attackerRuntime.__inCounterBasic or attackerRuntime.__inGuardCounter then
            return
        end
        if FeatModHelper.HasFlag(hero, IDS.fighter_counter_basic, "counterBeforeAttack") then
            local BattleSkill = require("modules.battle_skill")
            runtime.__inCounterBasic = true
            prepareReactionBasicAttack(hero, IDS.fighter_counter_basic, "反击大师")
            BattleSkill.CastSmallSkill(hero, attacker)
            runtime.__inCounterBasic = false
            publishPassiveTriggered(hero, "反击大师", "先手反击", string.format("抢先对 %s 发动反击", attacker.name or "目标"))
            return
        end
        runtime.pendingCounterBasicTarget = attacker
        publishPassiveTriggered(hero, "反击", "登记反击", string.format("将对 %s 发动反击", attacker.name or "目标"))
        -- #region debug-point A:queue-counter
        publishCounterDebug("queue_counter_basic", {
            reactorId = hero.instanceId or hero.id,
            reactorName = hero.name,
            attackerId = attacker.instanceId or attacker.id,
            attackerName = attacker.name,
            attackerInCounter = attackerRuntime.__inCounterBasic == true,
        })
        -- #endregion
    end

    return self
end

function FighterBuildPassives.CreateGuardCounterPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        FighterBuildPassives.ClearGuardStance(self.context and self.context.src)
    end

    function self:OnSelfTurnBegin()
        FighterBuildPassives.ClearGuardStance(self.context and self.context.src)
    end

    return self
end

function FighterBuildPassives.CreateSecondWindMasteryPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        ensureRuntime(self.context and self.context.src).fighterSecondWindMastery = true
    end

    return self
end

function FighterBuildPassives.CreateExtraAttackPassive(context)
    local BuildPassiveCommon = require("skills.build_passive_common")
    return BuildPassiveCommon.CreateExtraAttackPassive(context, {
        basicAttackSkillId = IDS.fighter_basic_attack,
        tokenKey = "extraAttackActionToken",
    })
end

function FighterBuildPassives.CreateSweepingAttackPassive(context)
    local self = buildContextState(context)

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not isAlive(hero) or not target then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.fighter_basic_attack then
            return
        end
        if (tonumber(extraParam.damageDealt) or 0) <= 0 then
            return
        end
        local runtime = ensureRuntime(hero)
        if runtime.__inSweepingAttack then
            return
        end
        runtime.__inSweepingAttack = true
        FighterBuildPassives.TryTriggerSweepingAttack(hero, target)
        runtime.__inSweepingAttack = false
    end

    return self
end

return FighterBuildPassives
