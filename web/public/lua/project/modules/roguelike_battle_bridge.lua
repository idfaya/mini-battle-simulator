local BattleRuntime = require("modules.browser_battle_runtime")
local BattleFormation = require("modules.battle_formation")
local BattleEnergy = require("modules.battle_energy")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local ClassRoleConfig = require("config.class_role_config")
local RunRelicConfig = require("config.roguelike.run_relic_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")

local RoguelikeBattleBridge = {}

local FRONT_POSITIONS = { 2, 1, 3 }
local BACK_POSITIONS = { 5, 4, 6 }
local DEFAULT_PLAYER_SCALE = {
    hp = 1.0,
    atk = 1.0,
    def = 1.0,
    energyBonus = 0,
}

local DEFAULT_ENEMY_SCALE = {
    hp = 1.0,
    atk = 1.0,
    def = 1.0,
}

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function resolveRelic(relicId)
    return RunRelicConfig.GetRelic(relicId)
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

local function applyClassPct(modMap, classIds, value)
    for _, classId in ipairs(classIds or {}) do
        modMap[classId] = (modMap[classId] or 0) + (tonumber(value) or 0)
    end
end

local function buildBattleModifiers(runState, encounter)
    local playerScale = encounter.playerScale or DEFAULT_PLAYER_SCALE
    local result = {
        extraEnergy = tonumber(playerScale.energyBonus) or 0,
        atkPctByClass = {},
        hpPctByClass = {},
        defPctByClass = {},
        damageIncreaseByClass = {},
        healBonusByClass = {},
        bonusGold = 0,
        postBattleHealPct = 0,
    }

    for _, relicId in ipairs(runState.relicIds or {}) do
        local relic = resolveRelic(relicId)
        local params = relic and relic.params or nil
        if relic and relic.effectType == "team_energy_flat" then
            result.extraEnergy = result.extraEnergy + (params.amount or 0)
        elseif relic and relic.effectType == "class_attack_pct" then
            applyClassPct(result.atkPctByClass, params.classIds, params.value)
        elseif relic and relic.effectType == "bonus_gold_by_battle_kind" then
            result.bonusGold = result.bonusGold + (params[encounter.kind] or 0)
        elseif relic and relic.effectType == "team_heal_pct" and encounter.kind == "elite" then
            result.postBattleHealPct = result.postBattleHealPct + (params.value or 0)
        end
    end

    for _, blessingId in ipairs(runState.blessingIds or {}) do
        local blessing = resolveBlessing(blessingId)
        local params = blessing and blessing.params or nil
        if blessing and blessing.effectType == "class_stat_pct" then
            applyClassPct(result.hpPctByClass, params.classIds, params.hpPct)
            applyClassPct(result.defPctByClass, params.classIds, params.defPct)
        elseif blessing and blessing.effectType == "turn_start_energy" then
            result.extraEnergy = result.extraEnergy + (params.amount or 0)
        elseif blessing and blessing.effectType == "class_heal_bonus_pct" then
            applyClassPct(result.healBonusByClass, params.classIds, params.value)
        elseif blessing and blessing.effectType == "class_dot_damage_pct" then
            applyClassPct(result.damageIncreaseByClass, params.classIds, params.value)
        elseif blessing and blessing.effectType == "damage_pct_vs_monster_type" then
            local monsterType = 0
            if encounter.kind == "elite" then
                monsterType = 1
            elseif encounter.kind == "boss" then
                monsterType = 2
            end
            if contains(params.monsterTypes, monsterType) then
                for _, hero in ipairs(runState.teamRoster or {}) do
                    result.atkPctByClass[hero.classId] = (result.atkPctByClass[hero.classId] or 0) + (params.value or 0)
                end
            end
        end
    end

    return result
end

local function buildHeroForBattle(rosterHero, modifiers, encounter)
    local heroData = HeroData.ConvertToHeroData(rosterHero.heroId, rosterHero.level, rosterHero.star)
    if not heroData then
        return nil
    end

    local playerScale = encounter.playerScale or DEFAULT_PLAYER_SCALE
    local hpScale = (tonumber(playerScale.hp) or 1.0) + (modifiers.hpPctByClass[rosterHero.classId] or 0)
    local atkScale = (tonumber(playerScale.atk) or 1.0) + (modifiers.atkPctByClass[rosterHero.classId] or 0)
    local defScale = (tonumber(playerScale.def) or 1.0) + (modifiers.defPctByClass[rosterHero.classId] or 0)
    local oldMaxHp = heroData.maxHp or 1

    heroData.maxHp = math.max(1, math.floor(oldMaxHp * hpScale))
    heroData.hp = math.max(1, math.min(heroData.maxHp, math.floor((rosterHero.currentHp or oldMaxHp) * hpScale)))
    heroData.atk = math.max(1, math.floor((heroData.atk or 0) * atkScale))
    heroData.def = math.max(0, math.floor((heroData.def or 0) * defScale))
    heroData.damageIncrease = math.max(0, math.floor((heroData.damageIncrease or 0) + ((modifiers.damageIncreaseByClass[rosterHero.classId] or 0) * 10000)))
    heroData.healBonus = math.max(0, math.floor((heroData.healBonus or 0) + ((modifiers.healBonusByClass[rosterHero.classId] or 0) * 10000)))
    heroData.wpType = rosterHero.wpType or 1
    heroData.id = rosterHero.heroId
    return heroData
end

local function buildEnemyForBattle(enemyId, level, wpType, encounter)
    local enemyData = EnemyData.ConvertToHeroData(enemyId, level)
    if not enemyData then
        return nil
    end
    local enemyScale = encounter.enemyScale or DEFAULT_ENEMY_SCALE
    enemyData.hp = math.max(1, math.floor((enemyData.hp or 1) * (tonumber(enemyScale.hp) or 1.0)))
    enemyData.maxHp = enemyData.hp
    enemyData.atk = math.max(1, math.floor((enemyData.atk or 0) * (tonumber(enemyScale.atk) or 1.0)))
    enemyData.def = math.max(0, math.floor((enemyData.def or 0) * (tonumber(enemyScale.def) or 1.0)))
    enemyData.wpType = wpType
    return enemyData
end

local function buildDeterministicSeedArray(runState, encounter)
    -- Deterministic battle RNG:
    -- - Keeps roguelike flow stable for tests and avoids flaky outcomes caused by wall-clock seeds.
    -- - Still varies by node/encounter so different nodes don't share identical RNG.
    local chapterId = tonumber(runState and runState.chapterId) or 0
    local nodeId = tonumber(runState and runState.currentNodeId) or 0
    local encounterId = tonumber(encounter and encounter.id) or 0
    local base = (chapterId * 1000003 + nodeId * 10007 + encounterId * 131 + 12345) % 2147483647
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

local function buildBattleConfig(runState, encounter)
    assignWpTypes(runState.teamRoster)
    local modifiers = buildBattleModifiers(runState, encounter)
    local teamLeft = {}
    for _, rosterHero in ipairs(runState.teamRoster or {}) do
        if not rosterHero.isDead and (rosterHero.currentHp or 0) > 0 then
            local heroData = buildHeroForBattle(rosterHero, modifiers, encounter)
            if heroData then
                teamLeft[#teamLeft + 1] = heroData
            end
        end
    end

    local teamRight = {}
    for index, enemyId in ipairs(encounter.enemyIds or {}) do
        local wpType = index <= 3 and FRONT_POSITIONS[index] or BACK_POSITIONS[index - 3] or index
        local enemyData = buildEnemyForBattle(enemyId, encounter.level, wpType, encounter)
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
        seedArray = buildDeterministicSeedArray(runState, encounter),
        initialEnergy = encounter.initialEnergy or 40,
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

function RoguelikeBattleBridge.StartBattle(runState, encounter)
    local config, modifiers, reason = buildBattleConfig(runState, encounter)
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

function RoguelikeBattleBridge.ResolveBattle(runState, encounter)
    local snapshot = RoguelikeBattleBridge.GetSnapshot()
    if not snapshot or not snapshot.result then
        return nil
    end

    local leftTeam, _ = BattleFormation.GetTeams()
    local aliveRoster = {}
    for _, rosterHero in ipairs(runState.teamRoster or {}) do
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
        else
            rosterHero.currentHp = 0
            rosterHero.isDead = true
        end
    end

    local won = snapshot.result.winner == "left"
    local minGold = ((encounter.gold or {}).min) or 0
    local maxGold = ((encounter.gold or {}).max) or minGold
    local earnedGold = won and math.random(minGold, maxGold) or 0
    local modifiers = runState.currentBattleModifiers or {}
    if won then
        earnedGold = earnedGold + (modifiers.bonusGold or 0)
        runState.gold = (runState.gold or 0) + earnedGold
        if (modifiers.postBattleHealPct or 0) > 0 then
            for _, hero in ipairs(runState.teamRoster or {}) do
                if not hero.isDead then
                    local heal = math.floor((hero.maxHp or 0) * modifiers.postBattleHealPct)
                    hero.currentHp = math.min(hero.maxHp or 0, (hero.currentHp or 0) + heal)
                end
            end
        end
    end

    runState.lastBattleSummary = {
        won = won,
        earnedGold = earnedGold,
        result = snapshot.result,
    }
    runState.currentBattleModifiers = nil

    return runState.lastBattleSummary
end

return RoguelikeBattleBridge
