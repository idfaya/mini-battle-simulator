local BattleRuntime = require("runtime.browser_battle_runtime")
local BattleFormation = require("modules.battle_formation")
local SkillConfig = require("config.skill_config")
local BattleEnergy = require("modules.battle_energy")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local BattleEvent = require("core.battle_event")
local ClassRoleConfig = require("config.class_role_config")
local RunEncounterBudget = require("config.roguelike.run_encounter_budget")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")
local RunChapterConfig = require("config.roguelike.run_chapter_config")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local RoguelikeRoster = require("roguelike.roguelike_roster")

local RoguelikeBattleBridge = {}

local FRONT_POSITIONS = { 2, 1, 3 }
local BACK_POSITIONS = { 5, 4, 6 }
local function roundInt(value)
    local v = tonumber(value) or 0
    if v >= 0 then
        return math.floor(v + 0.5)
    end
    return math.ceil(v - 0.5)
end

local function clamp(value, minValue, maxValue)
    local v = tonumber(value) or 0
    return math.max(minValue, math.min(maxValue, v))
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function resolveEquipment(equipmentId)
    return RunEquipmentConfig.GetEquipment(equipmentId)
end

local function resolveBlessing(blessingId)
    return RunBlessingConfig.GetBlessing(blessingId)
end

local function assignWpTypes(teamRoster)
    local frontIndex = 1
    local backIndex = 1
    for _, hero in ipairs(teamRoster or {}) do
        if not hero.isDead then
            if ClassRoleConfig.PreferFrontRow(hero.classId) and frontIndex <= #FRONT_POSITIONS then
                hero.wpType = FRONT_POSITIONS[frontIndex]
                frontIndex = frontIndex + 1
            else
                hero.wpType = BACK_POSITIONS[backIndex] or FRONT_POSITIONS[frontIndex] or 1
                backIndex = backIndex + 1
            end
        end
    end
end

local function applyClassFlat(modMap, classIds, value)
    for _, classId in ipairs(classIds or {}) do
        modMap[classId] = (modMap[classId] or 0) + (tonumber(value) or 0)
    end
end

local function buildBattleModifiers(runState, battleProfile)
    local result = {
        battleRoundsHitDelta = 0,
        battleRoundsSaveDelta = 0,
        battleRounds = 0,
        battleStartTempHp = 0,
        hitDeltaByClass = {},
        acDeltaByClass = {},
        spellDCDeltaByClass = {},
        saveDeltaByClass = {},
        weaponDamageBonusByClass = {},
        healingFlatBonusByClass = {},
        damageReduceByClass = {},
        spellDamageReduceByClass = {},
        bonusGold = 0,
        postBattleHealPct = 0,
    }

    for _, equipmentId in ipairs(runState.equipmentIds or {}) do
        local equipment = resolveEquipment(equipmentId)
        local params = equipment and equipment.params or nil
        if equipment and params then
            if equipment.effectType == "martial_weapon" or equipment.effectType == "ranged_weapon" then
                applyClassFlat(result.hitDeltaByClass, params.classIds, params.hitDelta)
                applyClassFlat(result.weaponDamageBonusByClass, params.classIds, params.weaponDamageBonus)
            elseif equipment.effectType == "armor_ac" then
                applyClassFlat(result.acDeltaByClass, params.classIds, params.acDelta)
            elseif equipment.effectType == "shield_ac" then
                applyClassFlat(result.acDeltaByClass, params.classIds, params.acDelta)
            elseif equipment.effectType == "spell_focus" then
                applyClassFlat(result.spellDCDeltaByClass, params.classIds, params.spellDCDelta)
            elseif equipment.effectType == "holy_symbol" then
                applyClassFlat(result.spellDCDeltaByClass, params.classIds, params.spellDCDelta)
            elseif equipment.effectType == "saving_throw_charm" then
                applyClassFlat(result.acDeltaByClass, params.classIds, params.acDelta)
                applyClassFlat(result.saveDeltaByClass, params.classIds, params.saveDelta)
            end
        end
    end

    for _, blessingId in ipairs(runState.blessingIds or {}) do
        local blessing = resolveBlessing(blessingId)
        local params = blessing and blessing.params or nil
        if blessing and blessing.effectType == "battle_rounds_hit_and_save" then
            result.battleRoundsHitDelta = result.battleRoundsHitDelta + (tonumber(params.hitDelta) or 0)
            result.battleRoundsSaveDelta = result.battleRoundsSaveDelta + (tonumber(params.saveDelta) or 0)
            result.battleRounds = math.max(result.battleRounds, tonumber(params.rounds) or 0)
        elseif blessing and blessing.effectType == "battle_start_temp_hp" then
            result.battleStartTempHp = result.battleStartTempHp + (tonumber(params.tempHp) or 0)
        elseif blessing and blessing.effectType == "class_healing_bonus" then
            applyClassFlat(result.healingFlatBonusByClass, params.classIds, params.healingBonus)
        elseif blessing and blessing.effectType == "class_ac" then
            applyClassFlat(result.acDeltaByClass, params.classIds, params.acDelta)
        elseif blessing and blessing.effectType == "class_damage_reduce" then
            applyClassFlat(result.damageReduceByClass, params.classIds, params.damageReduce)
        elseif blessing and blessing.effectType == "class_spell_protection" then
            applyClassFlat(result.saveDeltaByClass, params.classIds, params.saveDelta)
            applyClassFlat(result.spellDamageReduceByClass, params.classIds, params.spellDamageReduce)
        end
    end

    return result
end

local function buildHeroForBattle(rosterHero, modifiers)
    local heroData = HeroData.ConvertClassUnitToHeroData(rosterHero)
    if not heroData then
        return nil
    end

    -- #region debug-point B:roguelike-build-battle-hero
    if tonumber(rosterHero.classId) == 2 then
        BattleEvent.Publish("DebugCounterTiming", {
            stage = "roguelike_build_hero_for_battle",
            source = "roguelike.roguelike_battle_bridge",
            data = {
                heroName = rosterHero.name,
                heroId = rosterHero.heroId,
                level = rosterHero.level,
                feats = rosterHero.feats,
                passiveSkills = rosterHero.buildState and rosterHero.buildState.passiveSkills or nil,
                activeSkills = rosterHero.buildState and rosterHero.buildState.activeSkills or nil,
            },
        })
    end
    -- #endregion

    local oldMaxHp = heroData.maxHp or 1

    heroData.maxHp = math.max(1, math.floor(oldMaxHp))
    local baseCurrentHp = tonumber(rosterHero.currentHp or oldMaxHp) or oldMaxHp
    baseCurrentHp = math.max(1, math.min(oldMaxHp, baseCurrentHp))
    heroData.hp = math.max(1, math.min(heroData.maxHp, math.floor(baseCurrentHp)))
    heroData.def = math.max(0, math.floor((heroData.def or 0)))
    heroData.hit = math.max(0, math.floor((heroData.hit or 0) + (modifiers.hitDeltaByClass[rosterHero.classId] or 0)))
    heroData.atk = heroData.hit
    heroData.ac = math.max(0, math.floor((heroData.ac or 0) + (modifiers.acDeltaByClass[rosterHero.classId] or 0)))
    heroData.spellDC = math.max(0, math.floor((heroData.spellDC or 0) + (modifiers.spellDCDeltaByClass[rosterHero.classId] or 0)))
    local saveDelta = modifiers.saveDeltaByClass[rosterHero.classId] or 0
    if saveDelta ~= 0 then
        heroData.saveFort = math.max(0, math.floor((heroData.saveFort or 0) + saveDelta))
        heroData.saveRef = math.max(0, math.floor((heroData.saveRef or 0) + saveDelta))
        heroData.saveWill = math.max(0, math.floor((heroData.saveWill or 0) + saveDelta))
    end
    heroData.healingFlatBonus = math.max(0, math.floor((heroData.healingFlatBonus or 0) + (modifiers.healingFlatBonusByClass[rosterHero.classId] or 0)))
    heroData.damageReduce = math.max(0, math.floor((heroData.damageReduce or 0) + (modifiers.damageReduceByClass[rosterHero.classId] or 0)))
    heroData.spellDamageReduce = math.max(0, math.floor((heroData.spellDamageReduce or 0) + (modifiers.spellDamageReduceByClass[rosterHero.classId] or 0)))
    heroData.tempHp = math.max(0, math.floor((heroData.tempHp or 0) + (tonumber(modifiers.battleStartTempHp) or 0)))
    heroData.blessBattleRoundsHitDelta = math.max(0, math.floor(tonumber(modifiers.battleRoundsHitDelta) or 0))
    heroData.blessBattleRoundsSaveDelta = math.max(0, math.floor(tonumber(modifiers.battleRoundsSaveDelta) or 0))
    heroData.blessBattleRounds = math.max(0, math.floor(tonumber(modifiers.battleRounds) or 0))
    heroData.wpType = rosterHero.wpType or 1
    heroData.id = rosterHero.heroId
    heroData.ultimateChargesMax = tonumber(rosterHero.ultimateChargesMax) or 1
    heroData.ultimateCharges = tonumber(rosterHero.ultimateCharges)
    if heroData.ultimateCharges == nil then
        heroData.ultimateCharges = heroData.ultimateChargesMax
    end

    -- Inject persisted cooldowns from roguelike roster into battle heroes.
    -- BattleSkill.Init reads hero.initialCooldowns and seeds hero.skillData.coolDowns.
    heroData.initialCooldowns = rosterHero.skillCooldowns
    return heroData
end

local function buildBattleBudgetAdjust(runState, battleProfileLike, aliveCount)
    local budget = battleProfileLike and battleProfileLike.budget
    if not budget then
        return {
            hpMul = 1.0,
            atkMul = 1.0,
            defMul = 1.0,
            hitDelta = 0,
            spellDCDelta = 0,
            saveDelta = 0,
            report = nil,
        }
    end

    local enemyMetas = {}
    for _, enemyId in ipairs(battleProfileLike.enemyIds or {}) do
        enemyMetas[#enemyMetas + 1] = EnemyData.GetChallengeMeta(enemyId)
    end
    local report = RunEncounterBudget.BuildReport(
        tonumber(runState and runState.partyLevel) or tonumber(battleProfileLike.level) or 1,
        aliveCount,
        enemyMetas,
        budget.difficulty or "deadly",
        budget.pressureFactor or 1.0
    )
    local gap = (report.targetAdjustedXp > 0) and (report.targetAdjustedXp / math.max(1, report.adjustedXp)) or 1.0
    return {
        hpMul = clamp(1.00 + (gap - 1.0) * 0.06, 0.90, 1.25),
        atkMul = clamp(1.00 + (gap - 1.0) * 0.08, 0.90, 1.25),
        defMul = clamp(1.00 + (gap - 1.0) * 0.04, 0.95, 1.15),
        hitDelta = roundInt(clamp((gap - 1.0) * 0.45, -1, 2)),
        spellDCDelta = roundInt(clamp((gap - 1.0) * 0.35, -1, 2)),
        saveDelta = roundInt(clamp((gap - 1.0) * 0.25, -1, 1)),
        report = report,
    }
end

local function buildEnemyForBattle(enemyId, level, wpType, budgetAdjust)
    local enemyData = EnemyData.ConvertToHeroData(enemyId, level)
    if not enemyData then
        return nil
    end
    local budgetHp = tonumber(budgetAdjust and budgetAdjust.hpMul) or 1.0
    local budgetDef = tonumber(budgetAdjust and budgetAdjust.defMul) or 1.0
    enemyData.hp = math.max(1, math.floor((enemyData.hp or 1) * budgetHp))
    enemyData.maxHp = enemyData.hp
    enemyData.def = math.max(0, math.floor((enemyData.def or 0) * budgetDef))
    enemyData.hit = math.max(0, math.floor((enemyData.hit or 0) + (tonumber(budgetAdjust and budgetAdjust.hitDelta) or 0)))
    enemyData.atk = enemyData.hit
    enemyData.spellDC = math.max(0, math.floor((enemyData.spellDC or 0) + (tonumber(budgetAdjust and budgetAdjust.spellDCDelta) or 0)))
    local sd = tonumber(budgetAdjust and budgetAdjust.saveDelta) or 0
    if sd ~= 0 then
        enemyData.saveFort = math.max(0, math.floor((enemyData.saveFort or 0) + sd))
        enemyData.saveRef = math.max(0, math.floor((enemyData.saveRef or 0) + sd))
        enemyData.saveWill = math.max(0, math.floor((enemyData.saveWill or 0) + sd))
    end
    enemyData.wpType = wpType
    return enemyData
end

local function appendEnemyId(target, enemyId)
    local id = tonumber(enemyId)
    if id then
        target[#target + 1] = id
    end
end

local function appendEnemyGroupIds(target, groupId)
    local group = RunEnemyGroup.GetGroup(tonumber(groupId))
    if not group then
        return
    end
    for _, enemyId in ipairs(group.front or {}) do
        appendEnemyId(target, enemyId)
    end
    for _, enemyId in ipairs(group.back or {}) do
        appendEnemyId(target, enemyId)
    end
    for _, enemyId in ipairs(group.elite or {}) do
        appendEnemyId(target, enemyId)
    end
    appendEnemyId(target, group.boss)
    for _, enemyId in ipairs(group.guards or {}) do
        appendEnemyId(target, enemyId)
    end
end

local function getBattleWaveGroupIds(battle)
    local waveGroupIds = {}
    if not battle then
        return waveGroupIds
    end
    for _, groupId in ipairs(battle.waveGroupIds or {}) do
        local id = tonumber(groupId)
        if id then
            waveGroupIds[#waveGroupIds + 1] = id
        end
    end
    return waveGroupIds
end

local function flattenBattleEnemyIds(battle)
    local enemyIds = {}
    if not battle then
        return enemyIds
    end
    for _, groupId in ipairs(getBattleWaveGroupIds(battle)) do
        appendEnemyGroupIds(enemyIds, groupId)
    end
    return enemyIds
end

local function pickInitialEnemyIds(battle)
    local enemyIds = {}
    if not battle then
        return enemyIds
    end
    local waveGroupIds = getBattleWaveGroupIds(battle)
    local openingGroupId = waveGroupIds[1]
    if not openingGroupId then
        return enemyIds
    end
    appendEnemyGroupIds(enemyIds, openingGroupId)
    return enemyIds
end

local function buildReserveEnemies(battle, level, budgetAdjust)
    local reserve = {}
    if not battle then
        return reserve
    end
    local waveGroupIds = getBattleWaveGroupIds(battle)
    for waveIndex = 2, #waveGroupIds do
        local groupEnemyIds = {}
        appendEnemyGroupIds(groupEnemyIds, waveGroupIds[waveIndex])
        for _, enemyId in ipairs(groupEnemyIds) do
            local enemyData = buildEnemyForBattle(enemyId, level, 0, budgetAdjust)
            if enemyData then
                enemyData.wpType = 0
                reserve[#reserve + 1] = enemyData
            end
        end
    end
    return reserve
end

local function resolveBattleBossId(battle)
    local explicitBossId = tonumber(battle and battle.bossId)
    if explicitBossId then
        return explicitBossId
    end
    local openingGroupId = getBattleWaveGroupIds(battle)[1]
    if not openingGroupId then
        return nil
    end
    local opening = RunEnemyGroup.GetGroup(openingGroupId)
    return tonumber(opening and opening.boss) or nil
end

local function buildDeterministicSeedArray(runState, battleProfileOrBattle)
    -- Deterministic battle RNG:
    -- - Keeps roguelike flow stable for tests and avoids flaky outcomes caused by wall-clock seeds.
    -- - Still varies by node/battle so different nodes don't share identical RNG.
    local chapterId = tonumber(runState and runState.chapterId) or 0
    local nodeId = tonumber(runState and runState.currentNodeId) or 0
    local battleId = tonumber(battleProfileOrBattle and battleProfileOrBattle.id) or 0
    local base = (chapterId * 1000003 + nodeId * 10007 + battleId * 131 + 12345) % 2147483647
    if base <= 0 then
        base = 123456789
    end
    return {
        base,
        (base * 1103515245 + 12345) % 2147483647,
        (base * 69069 + 1) % 2147483647,
        (base * 1664525 + 1013904223) % 2147483647,
    }
end

local function buildBattleConfig(runState, battle, battleProfile)
    local teamRoster = RoguelikeRoster.GetTeamUnits(runState)
    assignWpTypes(teamRoster)
    local modifiers = buildBattleModifiers(runState, battleProfile)
    local teamLeft = {}
    for _, rosterHero in ipairs(teamRoster) do
        if not rosterHero.isDead and (rosterHero.currentHp or 0) > 0 then
            local heroData = buildHeroForBattle(rosterHero, modifiers)
            if heroData then
                teamLeft[#teamLeft + 1] = heroData
            end
        end
    end

    local teamRight = {}
    local battleProfileForBudget = {
        -- Use the full battle footprint so reserve waves still contribute to overall pressure.
        -- The final scalar is intentionally clamped in buildBattleBudgetAdjust.
        enemyIds = flattenBattleEnemyIds(battle),
        budget = battleProfile and battleProfile.budget or nil,
        level = tonumber(battleProfile and battleProfile.level) or tonumber(runState and runState.partyLevel) or 1,
    }
    local budgetAdjust = buildBattleBudgetAdjust(runState, battleProfileForBudget, #teamLeft)
    runState.currentBattleBudget = budgetAdjust.report

    -- Keep enemy level close to the party's recommended level.
    -- Battle profiles still define "intended" pacing (battleProfile.level), but we cap how far
    -- above the party enemies can be to avoid hard wipes after moving to single-hero leveling.
    local partyLevel = tonumber(runState and runState.partyLevel) or tonumber(battleProfile and battleProfile.level) or 1
    local baseLevel = tonumber(battleProfile and battleProfile.level) or partyLevel
    local kindOffset = 0
    local battleKind = battleProfile and battleProfile.kind or battle.kind
    if battleKind == "elite" then
        kindOffset = 1
    elseif battleKind == "boss" then
        kindOffset = 2
    end
    local minEnemyLevel = partyLevel - 1
    if battleKind == "normal" or battleKind == "event_battle" then
        -- Normal fights keep density for atmosphere; allow level to sit up to 4 below party
        -- so balance can be tuned by stats instead of reducing unit count.
        minEnemyLevel = partyLevel - 4
    elseif battleKind == "boss" then
        -- Boss still stays above normal pressure, but should honor battle profile level tuning.
        minEnemyLevel = partyLevel - 3
    end
    local effectiveEnemyLevel = clamp(baseLevel, math.max(1, minEnemyLevel), partyLevel + 1 + kindOffset)

    local openingEnemyIds = pickInitialEnemyIds(battle)
    for index, enemyId in ipairs(openingEnemyIds or {}) do
        local wpType = index <= 3 and FRONT_POSITIONS[index] or BACK_POSITIONS[index - 3] or index
        local enemyData = buildEnemyForBattle(enemyId, effectiveEnemyLevel, wpType, budgetAdjust)
        if enemyData then
            teamRight[#teamRight + 1] = enemyData
        end
    end

    if #teamLeft == 0 then
        return nil, nil, "no_alive_team"
    end
    if #teamRight == 0 then
        return nil, nil, "no_enemy_team"
    end

    return {
        teamLeft = teamLeft,
        teamRight = teamRight,
        enemyReserve = buildReserveEnemies(battle, effectiveEnemyLevel, budgetAdjust),
        refreshTurns = tonumber(battle and battle.refreshTurns) or 0,
        refreshOnClear = battle and battle.refreshOnClear == true,
        spawnOrder = battle and battle.spawnOrder or nil,
        winRule = battle and battle.winRule or nil,
        loseRule = battle and battle.loseRule or nil,
        bossId = resolveBattleBossId(battle),
        seedArray = buildDeterministicSeedArray(runState, battleProfile or battle),
        initialEnergy = (battleProfile and battleProfile.initialEnergy) or 40,
        disableDefaultRenderer = true,
    }, modifiers
end

local function applyLeftEnergyBonus(extraEnergy)
    if (tonumber(extraEnergy) or 0) <= 0 then
        return
    end
    local leftTeam = BattleFormation.GetTeams()
    for _, hero in ipairs(leftTeam or {}) do
        BattleEnergy.AddEnergy(hero, extraEnergy)
    end
end

local function applyPostBattleRest(runState)
    local chapter = RunChapterConfig.GetChapter(runState.chapterId) or {}
    local rest = chapter.postBattleRest or {}
    local healPct = tonumber(rest.healPct) or 0
    local clearCooldowns = rest.clearCooldowns ~= false
    local restoreUltimateCharges = rest.restoreUltimateCharges == true
    local reviveDead = rest.reviveDead == true

    for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if hero.isDead and reviveDead then
            hero.isDead = false
            hero.teamState = "active"
            hero.currentHp = math.max(1, math.floor((hero.maxHp or 0) * healPct))
        elseif not hero.isDead and healPct > 0 then
            local heal = math.floor((hero.maxHp or 0) * healPct)
            hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
        end
        if not hero.isDead then
            if clearCooldowns then
                hero.skillCooldowns = hero.skillCooldowns or {}
                for skillId, _ in pairs(hero.skillCooldowns) do
                    hero.skillCooldowns[skillId] = 0
                end
            end
            if restoreUltimateCharges then
                hero.ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1
                hero.ultimateCharges = hero.ultimateChargesMax
            end
        end
    end
end

function RoguelikeBattleBridge.StartBattle(runState, battle, battleProfile)
    local config, modifiers, reason = buildBattleConfig(runState, battle, battleProfile)
    if not config then
        return false, reason
    end

    local snapshot = BattleRuntime.init(config)
    applyLeftEnergyBonus(modifiers.extraEnergy)
    runState.currentBattleModifiers = modifiers
    return true, snapshot
end

function RoguelikeBattleBridge.Tick(deltaMs)
    local dt = tonumber(deltaMs) or 16
    if dt <= 0 then
        return {}
    end

    -- Substep to keep simulation stable regardless of frame delta / speed multiplier.
    local step = 33
    local events = {}
    while dt > 0 do
        local slice = math.min(step, dt)
        local batch = BattleRuntime.tick(slice) or {}
        for _, e in ipairs(batch) do
            events[#events + 1] = e
        end
        dt = dt - slice
    end
    return events
end

function RoguelikeBattleBridge.QueueCommand(command)
    return BattleRuntime.queueCommand(command)
end

function RoguelikeBattleBridge.GetSnapshot()
    return BattleRuntime.getSnapshot()
end

function RoguelikeBattleBridge.ResolveBattle(runState, battle, battleProfile)
    local snapshot = RoguelikeBattleBridge.GetSnapshot()
    if not snapshot or not snapshot.result then
        return nil
    end

    local leftTeam, _ = BattleFormation.GetTeams()
    local aliveRoster = {}
    for _, rosterHero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
        if not rosterHero.isDead and (rosterHero.currentHp or 0) > 0 then
            aliveRoster[#aliveRoster + 1] = rosterHero
        end
    end

    for index, rosterHero in ipairs(aliveRoster) do
        local battleHero = (leftTeam or {})[index]
        if battleHero then
            rosterHero.maxHp = math.max(rosterHero.maxHp or 1, battleHero.maxHp or rosterHero.maxHp or 1)
            rosterHero.currentHp = math.max(0, math.floor(battleHero.hp or 0))
            rosterHero.isDead = not (battleHero.isAlive and not battleHero.isDead)
            rosterHero.teamState = rosterHero.isDead and "dead" or "active"
            rosterHero.ultimateChargesMax = tonumber(battleHero.ultimateChargesMax) or tonumber(rosterHero.ultimateChargesMax) or 1
            rosterHero.ultimateCharges = tonumber(battleHero.ultimateCharges)
                or tonumber(rosterHero.ultimateCharges)
                or rosterHero.ultimateChargesMax

            -- Persist cooldowns back to roster for cross-battle carry.
            rosterHero.skillCooldowns = rosterHero.skillCooldowns or {}
            local cds = (battleHero.skillData and battleHero.skillData.coolDowns) or {}
            for skillId, cd in pairs(cds) do
                local sid = tonumber(skillId)
                if sid then
                    rosterHero.skillCooldowns[sid] = math.max(0, math.floor(tonumber(cd) or 0))
                end
            end

            for skillId, cd in pairs(rosterHero.skillCooldowns) do
                local sid = tonumber(skillId)
                if sid and (tonumber(SkillConfig.GetSkillType(sid)) or 0) ~= 3 then
                    rosterHero.skillCooldowns[sid] = math.max(0, math.floor(tonumber(cd) or 0))
                end
            end
        else
            rosterHero.currentHp = 0
            rosterHero.isDead = true
            rosterHero.teamState = "dead"
        end
    end

    local won = snapshot.result.winner == "left"
    local minGold = (((battleProfile or {}).gold or {}).min) or 0
    local maxGold = (((battleProfile or {}).gold or {}).max) or minGold
    local earnedGold = won and math.random(minGold, maxGold) or 0
    local modifiers = runState.currentBattleModifiers or {}
    if won then
        earnedGold = earnedGold + (modifiers.bonusGold or 0)
        runState.gold = (runState.gold or 0) + earnedGold
        if (modifiers.postBattleHealPct or 0) > 0 then
            for _, hero in ipairs(RoguelikeRoster.GetTeamUnits(runState)) do
                if not hero.isDead then
                    local heal = math.floor((hero.maxHp or 0) * modifiers.postBattleHealPct)
                    hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
                end
            end
        end
        applyPostBattleRest(runState)
    end

    runState.lastBattleSummary = {
        won = won,
        earnedGold = earnedGold,
        result = snapshot.result,
        battleNodeId = tonumber(runState.currentNodeId) or 0,
    }
    runState.currentBattleModifiers = nil

    return runState.lastBattleSummary
end

return RoguelikeBattleBridge
