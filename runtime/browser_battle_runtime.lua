local BattleMain = require("modules.battle_main")
local BattleFormation = require("modules.battle_formation")
local BattleBuff = require("modules.battle_buff")
local BattleSkill = require("modules.battle_skill")
local BattleEnergy = require("modules.battle_energy")
local BattleActionOrder = require("modules.battle_action_order")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local BattleEnergyConfig = require("config.battle_energy_config")
local BattleRhythmConfig = require("config.battle_rhythm_config")
local ClassRoleConfig = require("config.class_role_config")
local ArrayUtils = require("utils.array_utils")
local Logger = require("utils.logger")

local Runtime = {}

local LOGIC_STEP_MS = tonumber(BattleRhythmConfig.logicStepMs) or 80
local MAX_QUEUED_COMMANDS = tonumber(BattleRhythmConfig.maxQueuedCommands) or 4
local DEFAULT_INITIAL_ENERGY = BattleEnergyConfig.defaultInitialEnergy or 40
local DEFAULT_WP_TYPES = { 1, 2, 3, 4, 5, 6 }

local function safeClock()
    local ok, result = pcall(function()
        if os and os.clock then
            return os.clock()
        end
        return 0
    end)

    if ok and type(result) == "number" then
        return result
    end

    return 0
end

local state = {
    accumulatorMs = 0,
    queuedCommands = {},
    events = {},
    readyMap = {},
    activeHeroId = nil,
    battleEnded = false,
    battleResult = nil,
    currentConfig = nil,
}

local visualEvents = {
    BattleVisualEvents.HERO_STATE_CHANGED,
    BattleVisualEvents.DAMAGE_DEALT,
    BattleVisualEvents.HEAL_RECEIVED,
    BattleVisualEvents.BUFF_ADDED,
    BattleVisualEvents.BUFF_REMOVED,
    BattleVisualEvents.BUFF_STACK_CHANGED,
    BattleVisualEvents.SKILL_CAST_STARTED,
    BattleVisualEvents.SKILL_CAST_COMPLETED,
    BattleVisualEvents.SKILL_TIMELINE_STARTED,
    BattleVisualEvents.SKILL_TIMELINE_FRAME,
    BattleVisualEvents.SKILL_TIMELINE_COMPLETED,
    BattleVisualEvents.TURN_STARTED,
    BattleVisualEvents.TURN_ENDED,
    BattleVisualEvents.ACTION_ORDER_CHANGED,
    BattleVisualEvents.BATTLE_STARTED,
    BattleVisualEvents.BATTLE_ENDED,
    BattleVisualEvents.VICTORY,
    BattleVisualEvents.DEFEAT,
    BattleVisualEvents.DRAW,
    BattleVisualEvents.HERO_DIED,
    BattleVisualEvents.HERO_REVIVED,
    BattleVisualEvents.ENERGY_CHANGED,
    BattleVisualEvents.DODGE,
    BattleVisualEvents.MISS,
    BattleVisualEvents.BLOCK,
    BattleVisualEvents.CRIT,
    "PassiveSkillTriggered",
    "DebugCounterTiming",
}

local visualHandlers = {}

local function resetState()
    state.accumulatorMs = 0
    state.queuedCommands = {}
    state.events = {}
    state.readyMap = {}
    state.activeHeroId = nil
    state.battleEnded = false
    state.battleResult = nil
end

local function cloneArray(input)
    local result = {}
    for i, value in ipairs(input or {}) do
        result[i] = value
    end
    return result
end

local function emitEvent(eventType, payload)
    local function sanitize(value, visited)
        local valueType = type(value)
        if valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string" then
            return value
        end

        if valueType ~= "table" then
            return nil
        end

        visited = visited or {}
        if visited[value] then
            return nil
        end
        visited[value] = true

        local result = {}
        local isArray = true
        local index = 1
        for key in pairs(value) do
            if key ~= index then
                isArray = false
                break
            end
            index = index + 1
        end

        if isArray then
            for i, item in ipairs(value) do
                result[#result + 1] = sanitize(item, visited)
            end
        else
            for key, item in pairs(value) do
                if type(key) == "string" or type(key) == "number" then
                    local sanitized = sanitize(item, visited)
                    if sanitized ~= nil then
                        result[key] = sanitized
                    end
                end
            end
        end

        visited[value] = nil
        return result
    end

    table.insert(state.events, {
        type = eventType,
        ts = safeClock(),
        payload = sanitize(payload or {}) or {},
    })
end

local function getUltimateSkill(hero)
    local instances = hero and hero.skillData and hero.skillData.skillInstances or nil
    if not instances then
        return nil
    end

    for _, skill in pairs(instances) do
        if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then
            return skill
        end
    end

    return nil
end

local function hasDeadAlly(hero)
    for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
        if ally and (ally.isDead or ally.isAlive == false or (ally.hp or 0) <= 0) then
            return true
        end
    end
    return false
end

local function passesUltimateSemanticRules(hero, skill)
    local skillId = tonumber(skill and skill.skillId) or 0
    if skillId == 80006004 then
        return hasDeadAlly(hero)
    end
    return true
end

local function canCastUltimate(hero)
    if not hero or hero.isDead or not hero.isAlive or not hero.isLeft then
        return false
    end

    if hero.__pendingCast then
        return false
    end

    local skill = getUltimateSkill(hero)
    if not skill then
        return false
    end

    if BattleSkill.GetSkillCurCoolDown(hero, skill.skillId) > 0 then
        return false
    end

    -- Ultimate is charge-gated (per rest), not energy-gated.
    local charges = tonumber(hero.ultimateCharges)
    local maxCharges = tonumber(hero.ultimateChargesMax) or 1
    if charges == nil then
        charges = maxCharges
    end
    return charges > 0 and passesUltimateSemanticRules(hero, skill)
end

local function serializeBuff(buff)
    return {
        buffId = buff.buffId,
        name = buff.name,
        stackCount = buff.stackCount or 1,
        duration = buff.duration or 0,
    }
end

local function serializeHero(hero)
    local skill = getUltimateSkill(hero)
    local buffs = {}
    local initiative = BattleActionOrder.GetHeroInitiative and BattleActionOrder.GetHeroInitiative(hero) or { roll = 0, mod = 0, total = 0 }
    for _, buff in ipairs(BattleBuff.GetAllBuffs(hero) or {}) do
        buffs[#buffs + 1] = serializeBuff(buff)
    end

    local classId = tonumber(hero.class or hero.Class or hero._class) or 0
    local className = hero._className
    if not className or className == "" then
        if hero.isLeft then
            className = HeroData.GetClassName and HeroData.GetClassName(classId) or tostring(classId)
        else
            className = EnemyData.GetClassName and EnemyData.GetClassName(classId) or tostring(classId)
        end
    end

    return {
        id = tostring(hero.instanceId),
        name = hero.name,
        team = hero.isLeft and "left" or "right",
        position = hero.wpType or 0,
        classId = classId,
        className = className or "Unknown",
        classIcon = ClassRoleConfig.GetIcon(classId),
        hp = hero.hp or 0,
        maxHp = hero.maxHp or 0,
        -- 5e-style debug stats (shown in web status panel)
        speed = hero.speed or hero.spd or 0,
        initiativeRoll = initiative.roll or 0,
        initiativeMod = initiative.mod or 0,
        initiative = initiative.total or 0,
        ac = hero.ac or 0,
        hit = hero.hit or 0,
        spellDC = hero.spellDC or 0,
        saveFort = hero.saveFort or 0,
        saveRef = hero.saveRef or 0,
        saveWill = hero.saveWill or 0,
        energy = hero.curEnergy or 0,
        maxEnergy = hero.maxEnergy or 100,
        ultimateCharges = tonumber(hero.ultimateCharges) or tonumber(hero.ultimateChargesMax) or 1,
        ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1,
        isAlive = hero.isAlive and not hero.isDead,
        isChanting = hero.__pendingCast ~= nil,
        pendingSkillName = hero.__pendingCast and hero.__pendingCast.skillName or nil,
        isConcentrating = hero.__concentrationSkillId ~= nil,
        concentrationSkillId = hero.__concentrationSkillId or nil,
        concentrationSkillName = hero.__concentrationSkillName or nil,
        buffs = buffs,
        actionBar = BattleActionOrder.GetHeroActionBar and BattleActionOrder.GetHeroActionBar(hero) or 0,
        actionBarMax = BattleActionOrder.GetActionBarThreshold and BattleActionOrder.GetActionBarThreshold() or 1000,
        ultimateReady = canCastUltimate(hero),
        ultimateSkillName = skill and skill.name or "ULT",
    }
end

local function serializeTeams()
    local left, right = BattleFormation.GetTeams()
    local leftSerialized = {}
    local rightSerialized = {}

    for _, hero in ipairs(left or {}) do
        leftSerialized[#leftSerialized + 1] = serializeHero(hero)
    end
    for _, hero in ipairs(right or {}) do
        rightSerialized[#rightSerialized + 1] = serializeHero(hero)
    end

    return leftSerialized, rightSerialized
end

local function buildSnapshot()
    local leftTeam, rightTeam = serializeTeams()
    local unitById = {}
    for _, unit in ipairs(leftTeam) do
        unitById[unit.id] = unit
    end
    for _, unit in ipairs(rightTeam) do
        unitById[unit.id] = unit
    end

    local actionOrder = {}
    if BattleActionOrder.GetActionOrder then
        for _, item in ipairs(BattleActionOrder.GetActionOrder() or {}) do
            local heroId = item.hero and item.hero.instanceId and tostring(item.hero.instanceId) or nil
            local unit = heroId and unitById[heroId] or nil
            if unit then
                actionOrder[#actionOrder + 1] = {
                    id = unit.id,
                    name = unit.name,
                    team = unit.team,
                    classId = unit.classId,
                    classIcon = unit.classIcon,
                    progress = item.progress or unit.actionBar or 0,
                    max = unit.actionBarMax or 1000,
                    initiative = unit.initiative or 0,
                    isAlive = unit.isAlive,
                }
            end
        end
    end
    local result = nil
    local battleResult = BattleMain.GetBattleResult and BattleMain.GetBattleResult() or state.battleResult

    if battleResult and battleResult.isFinished then
        result = {
            winner = battleResult.winner or "draw",
            reason = battleResult.reason or "",
        }
    end

    return {
        phase = result and "ended" or "running",
        round = BattleMain.GetCurrentRound and BattleMain.GetCurrentRound() or 0,
        activeHeroId = tostring((BattleMain.GetActiveHeroInstanceId and BattleMain.GetActiveHeroInstanceId()) or state.activeHeroId or "") ~= ""
            and tostring((BattleMain.GetActiveHeroInstanceId and BattleMain.GetActiveHeroInstanceId()) or state.activeHeroId)
            or nil,
        leftTeam = leftTeam,
        rightTeam = rightTeam,
        actionOrder = actionOrder,
        pendingCommands = #state.queuedCommands + (BattleMain.GetQueuedUltimateCount and BattleMain.GetQueuedUltimateCount() or 0),
        result = result,
    }
end

local function refreshUltimateReadiness()
    local left, _ = BattleFormation.GetTeams()

    for _, hero in ipairs(left or {}) do
        local heroId = tostring(hero.instanceId)
        local ready = canCastUltimate(hero)
        local previous = state.readyMap[heroId]
        if previous == nil then
            state.readyMap[heroId] = ready
            if ready then
                local skill = getUltimateSkill(hero)
                emitEvent("ultimate_ready", {
                    heroId = heroId,
                    heroName = hero.name,
                    skillName = skill and skill.name or "ULT",
                })
            end
        elseif previous ~= ready then
            state.readyMap[heroId] = ready
            if ready then
                local skill = getUltimateSkill(hero)
                emitEvent("ultimate_ready", {
                    heroId = heroId,
                    heroName = hero.name,
                    skillName = skill and skill.name or "ULT",
                })
            end
        end
    end
end

local function registerVisualListeners()
    for _, eventName in ipairs(visualEvents) do
        if visualHandlers[eventName] then
            BattleEvent.RemoveListener(eventName, visualHandlers[eventName])
            visualHandlers[eventName] = nil
        end

        local handler = function(payload)
            if eventName == BattleVisualEvents.TURN_STARTED then
                state.activeHeroId = payload and (payload.heroId or payload.instanceId) or state.activeHeroId
            elseif eventName == BattleVisualEvents.TURN_ENDED then
                state.activeHeroId = nil
            elseif eventName == BattleVisualEvents.BATTLE_ENDED then
                state.battleEnded = true
                state.battleResult = payload
            end

            emitEvent(eventName, payload)
        end

        visualHandlers[eventName] = handler
        BattleEvent.AddListener(eventName, handler)
    end
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function assignDefaultWpType(unit, index)
    if not unit then
        return
    end

    local requestedWpType = tonumber(unit.wpType) or 0
    if requestedWpType >= 1 and requestedWpType <= 6 then
        unit.wpType = math.floor(requestedWpType)
        return
    end

    unit.wpType = 0
end

local function buildSeedArray()
    local base = math.floor(safeClock() * 1000000)
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

local function normalizeIdList(input, maxCount)
    local result = {}
    if type(input) == "table" then
        for _, value in ipairs(input) do
            local id = tonumber(value)
            if id then
                result[#result + 1] = id
                if maxCount and #result >= maxCount then
                    break
                end
            end
        end
    elseif type(input) == "string" then
        for part in string.gmatch(input, "[^,%s]+") do
            local id = tonumber(part)
            if id then
                result[#result + 1] = id
                if maxCount and #result >= maxCount then
                    break
                end
            end
        end
    elseif type(input) == "number" then
        result[1] = input
    end
    return result
end

local function normalizeIdMatrix(input, maxGroups, maxPerGroup)
    local result = {}
    if type(input) ~= "table" then
        return result
    end
    for i = 1, #input do
        if maxGroups and #result >= maxGroups then
            break
        end
        local ids = normalizeIdList(input[i], maxPerGroup)
        if #ids > 0 then
            result[#result + 1] = ids
        end
    end
    return result
end

local function normalizeSeedArray(options)
    local provided = options and options.seedArray
    if type(provided) == "table" and #provided > 0 then
        local result = {}
        for i = 1, math.min(4, #provided) do
            result[i] = tonumber(provided[i]) or (123456789 + i)
        end
        while #result < 4 do
            result[#result + 1] = (result[#result] * 1103515245 + 12345) % 2147483647
        end
        return result
    end

    local seed = tonumber(options and options.seed)
    if seed then
        local base = math.max(1, math.floor(seed) % 2147483647)
        return {
            base,
            (base * 1103515245 + 12345) % 2147483647,
            (base * 69069 + 1) % 2147483647,
            (base * 1664525 + 1013904223) % 2147483647,
        }
    end

    return buildSeedArray()
end

local function buildRuntimeTeamConfig(options)
    local level = clamp(tonumber(options and options.level) or 1, 1, 20)
    local heroCount = clamp(math.floor(tonumber(options and options.heroCount) or 3), 1, 6)
    local enemyCount = clamp(math.floor(tonumber(options and options.enemyCount) or 4), 1, 6)
    local initialEnergy = clamp(math.floor(tonumber(options and options.initialEnergy) or DEFAULT_INITIAL_ENERGY), 0, 100)
    local seedArray = normalizeSeedArray(options)
    local fixedHeroIds = normalizeIdList(options and options.heroIds, 6)
    local fixedEnemyIds = normalizeIdList(options and options.enemyIds, 6)
    local fighterBuildFeatIds = normalizeIdList(options and options.fighterBuildFeatIds, 12)
    local fighterBuildFeatIdsByHero = normalizeIdMatrix(options and options.fighterBuildFeatIdsByHero, 6, 12)
    if #fixedHeroIds > 0 then
        heroCount = clamp(#fixedHeroIds, 1, 6)
    end
    if #fixedEnemyIds > 0 then
        enemyCount = clamp(#fixedEnemyIds, 1, 6)
    end

    math.randomseed(seedArray[1])

    local function computeRowSplit(total)
        local front = math.min(3, math.floor((total + 1) / 2))
        local back = math.max(0, total - front)
        return front, back
    end

    local function partitionByRowPreference(units, readClassId)
        local front = {}
        local back = {}
        for _, unit in ipairs(units or {}) do
            local classId = readClassId(unit)
            if ClassRoleConfig.PreferFrontRow(classId) then
                table.insert(front, unit)
            else
                table.insert(back, unit)
            end
        end
        return front, back
    end

    local function randomPickInto(result, pool, count, readId, seen)
        if count <= 0 then
            return
        end
        local picked = ArrayUtils.RandomSelect(pool or {}, count) or {}
        for _, item in ipairs(picked) do
            local id = readId(item)
            if id and not seen[id] then
                seen[id] = true
                table.insert(result, id)
            end
        end
    end

    local function fillFromPool(result, pool, targetCount, readId, seen)
        for _, item in ipairs(pool or {}) do
            if #result >= targetCount then
                return
            end
            local id = readId(item)
            if id and not seen[id] then
                seen[id] = true
                table.insert(result, id)
            end
        end
    end

    local selectedHeroIds = cloneArray(fixedHeroIds)
    local selectedHeroMap = {}
    for _, heroId in ipairs(selectedHeroIds) do
        selectedHeroMap[heroId] = true
    end
    local allHeroes = HeroData.GetPlayableHeroes()
    if #selectedHeroIds == 0 then
        local heroFrontNeed, heroBackNeed = computeRowSplit(heroCount)
        local frontHeroes, backHeroes = partitionByRowPreference(allHeroes, function(hero)
            return hero and hero.Class or 0
        end)
        randomPickInto(selectedHeroIds, frontHeroes, heroFrontNeed, function(hero)
            return hero and hero.AllyID
        end, selectedHeroMap)
        randomPickInto(selectedHeroIds, backHeroes, heroBackNeed, function(hero)
            return hero and hero.AllyID
        end, selectedHeroMap)
    end
    if #selectedHeroIds < heroCount then
        -- Fallback if one side pool is insufficient.
        fillFromPool(selectedHeroIds, allHeroes, heroCount, function(hero)
            return hero and hero.AllyID
        end, selectedHeroMap)
    end

    local allEnemyIds = EnemyData.GetAllEnemyIds()
    local allBossIds = EnemyData.GetAllBossIds()
    local selectedEnemyIds = cloneArray(fixedEnemyIds)
    local selectedEnemyMap = {}
    for _, enemyId in ipairs(selectedEnemyIds) do
        selectedEnemyMap[enemyId] = true
    end

    local function addEnemyId(enemyId)
        if enemyId and not selectedEnemyMap[enemyId] then
            selectedEnemyMap[enemyId] = true
            table.insert(selectedEnemyIds, enemyId)
        end
    end

    if #fixedEnemyIds == 0 then
        if #allBossIds > 0 then
            addEnemyId(ArrayUtils.RandomSelect(allBossIds, 1)[1])
        end

        local enemyFrontNeed, enemyBackNeed = computeRowSplit(enemyCount)
        if #selectedEnemyIds > 0 then
            local bossId = selectedEnemyIds[1]
            local boss = bossId and EnemyData.GetEnemy and EnemyData.GetEnemy(bossId) or nil
            local bossClass = boss and boss.Class or 0
            if ClassRoleConfig.PreferFrontRow(bossClass) then
                enemyFrontNeed = math.max(0, enemyFrontNeed - 1)
            else
                enemyBackNeed = math.max(0, enemyBackNeed - 1)
            end
        end

        local enemyObjs = {}
        for _, enemyId in ipairs(allEnemyIds or {}) do
            local enemy = EnemyData.GetEnemy and EnemyData.GetEnemy(enemyId) or nil
            if enemy and enemy.ID then
                table.insert(enemyObjs, enemy)
            end
        end
        local frontEnemies, backEnemies = partitionByRowPreference(enemyObjs, function(enemy)
            return enemy and enemy.Class or 0
        end)

        -- Random select per row buckets, then fill any remaining from the full pool.
        local function enemyReadId(enemy)
            return enemy and enemy.ID
        end
        local function addFromPool(pool, count)
            if count <= 0 then
                return
            end
            for _, enemy in ipairs(ArrayUtils.RandomSelect(pool or {}, count) or {}) do
                addEnemyId(enemyReadId(enemy))
            end
        end
        addFromPool(frontEnemies, enemyFrontNeed)
        addFromPool(backEnemies, enemyBackNeed)
        if #selectedEnemyIds < enemyCount then
            for _, enemyId in ipairs(allEnemyIds or {}) do
                addEnemyId(enemyId)
                if #selectedEnemyIds >= enemyCount then
                    break
                end
            end
        end
    end

    local leftTeam = {}
    for index, heroId in ipairs(selectedHeroIds) do
        local heroInfo = HeroData.GetHeroInfo and HeroData.GetHeroInfo(heroId) or nil
        local heroOverride = nil
        local slotBuildFeatIds = fighterBuildFeatIdsByHero[index]
        if heroInfo and tonumber(heroInfo.Class) == 2 and ((slotBuildFeatIds and #slotBuildFeatIds > 0) or #fighterBuildFeatIds > 0) then
            heroOverride = {
                buildFeatIds = (slotBuildFeatIds and #slotBuildFeatIds > 0) and slotBuildFeatIds or fighterBuildFeatIds,
            }
        end
        local heroData = HeroData.ConvertToHeroData(heroId, level, 5, heroOverride)
        if heroData then
            assignDefaultWpType(heroData, index)
            table.insert(leftTeam, heroData)
        end
    end

    local rightTeam = {}
    for index, enemyId in ipairs(selectedEnemyIds) do
        local enemyData = EnemyData.ConvertToHeroData(enemyId, level)
        if enemyData then
            assignDefaultWpType(enemyData, index)
            table.insert(rightTeam, enemyData)
        end
    end

    if #leftTeam == 0 or #rightTeam == 0 then
        error("Failed to build browser battle teams from runtime options")
    end

    return {
        teamLeft = leftTeam,
        teamRight = rightTeam,
        seedArray = seedArray,
        initialEnergy = initialEnergy,
        disableDefaultRenderer = true,
    }
end

local function createDefaultConfig()
    return buildRuntimeTeamConfig({
        level = 1,
        heroCount = 3,
        enemyCount = 4,
    })
end

local function normalizeConfig(config)
    if not config or not config.teamLeft or not config.teamRight then
        return buildRuntimeTeamConfig(config)
    end

    return {
        teamLeft = config.teamLeft,
        teamRight = config.teamRight,
        seedArray = config.seedArray or { 123456789, 362436069, 521288629, 88675123 },
        initialEnergy = clamp(math.floor(tonumber(config.initialEnergy) or DEFAULT_INITIAL_ENERGY), 0, 100),
        disableDefaultRenderer = true,
    }
end

local function rejectCommand(command, reason)
    emitEvent("command_rejected", {
        type = command and command.type or "unknown",
        heroId = command and command.heroId or nil,
        reason = reason or "invalid_command",
    })
end

local function castUltimateNow(hero)
    if hero and hero.__pendingCast then
        return false, "pending_cast"
    end

    local skill = getUltimateSkill(hero)
    if not skill then
        return false, "ultimate_not_found"
    end

    if BattleSkill.GetSkillCurCoolDown(hero, skill.skillId) > 0 then
        return false, "ultimate_on_cooldown"
    end

    local charges = tonumber(hero.ultimateCharges)
    local maxCharges = tonumber(hero.ultimateChargesMax) or 1
    if charges == nil then
        charges = maxCharges
    end
    if charges <= 0 then
        return false, "ultimate_no_charges"
    end

    local targetId = BattleFormation.GetRandomEnemyInstanceId(hero)
    if not targetId then
        return false, "no_target"
    end

    local target = BattleFormation.FindHeroByInstanceId(targetId)
    if not target then
        return false, "target_not_found"
    end

    state.activeHeroId = hero.instanceId
    local success = BattleSkill.StartSkillCastInSeq(hero, target, skill.skillId, function()
        state.activeHeroId = nil
    end)

    if success then
        refreshUltimateReadiness()
        return true
    end

    return false, "cast_failed"
end

local function processNextCommand()
    if #state.queuedCommands == 0 then
        return false
    end

    local command = table.remove(state.queuedCommands, 1)
    if not command or command.type ~= "cast_ultimate" then
        rejectCommand(command, "unsupported_command")
        return false
    end

    local hero = BattleFormation.FindHeroByInstanceId(tonumber(command.heroId))
    if not hero or hero.isDead or not hero.isAlive or not hero.isLeft then
        rejectCommand(command, "hero_unavailable")
        return false
    end

    if not canCastUltimate(hero) then
        rejectCommand(command, "ultimate_not_reasonable")
        return false
    end

    if BattleMain.HasQueuedUltimate and BattleMain.HasQueuedUltimate(command.heroId) then
        rejectCommand(command, "ultimate_already_queued")
        return false
    end

    if not BattleMain.QueueUltimate or not BattleMain.QueueUltimate(command.heroId) then
        rejectCommand(command, "queue_failed")
        return false
    end

    refreshUltimateReadiness()
    return true
end

function Runtime.init(config)
    local function runStage(name, fn)
        local ok, result = pcall(fn)
        if not ok then
            error("Runtime.init stage '" .. tostring(name) .. "' failed [type=" .. type(result) .. "] " .. tostring(result))
        end
        return result
    end

    if BattleMain.IsRunning and BattleMain.IsRunning() then
        runStage("quit_existing_battle", function()
            BattleMain.Quit()
        end)
    end

    runStage("reset_state", function()
        resetState()
    end)
    runStage("set_log_level", function()
        Logger.SetLogLevel(Logger.LOG_LEVELS.ERROR)
    end)

    state.currentConfig = runStage("normalize_config", function()
        return normalizeConfig(config)
    end)

    runStage("battle_start", function()
        BattleMain.Start(state.currentConfig, function(result)
            state.battleEnded = true
            state.battleResult = result
        end)
    end)
    runStage("seed_initial_energy", function()
        local leftTeam, rightTeam = BattleFormation.GetTeams()
        for _, hero in ipairs(leftTeam or {}) do
            BattleEnergy.AddEnergy(hero, state.currentConfig.initialEnergy or DEFAULT_INITIAL_ENERGY)
        end
        for _, hero in ipairs(rightTeam or {}) do
            BattleEnergy.AddEnergy(hero, state.currentConfig.initialEnergy or DEFAULT_INITIAL_ENERGY)
        end
    end)

    runStage("register_visual_listeners", function()
        registerVisualListeners()
    end)
    runStage("emit_battle_started", function()
        emitEvent("battle_started", {
            teamLeft = state.currentConfig.teamLeft,
            teamRight = state.currentConfig.teamRight,
        })
        -- #region debug-point D:battle-team-skills
        local teamDebug = {}
        for _, hero in ipairs(state.currentConfig.teamLeft or {}) do
            local skillIds = {}
            for _, skillCfg in ipairs(hero.skillsConfig or {}) do
                skillIds[#skillIds + 1] = skillCfg.skillId
            end
            teamDebug[#teamDebug + 1] = {
                heroId = hero.id,
                heroName = hero.name,
                skillIds = skillIds,
            }
        end
        emitEvent("DebugCounterTiming", {
            stage = "battle_started_team_skills",
            source = "runtime.browser_battle_runtime",
            data = {
                teamLeft = teamDebug,
            },
        })
        -- #endregion
    end)
    runStage("refresh_ultimate_readiness", function()
        refreshUltimateReadiness()
    end)

    return runStage("build_snapshot", function()
        return buildSnapshot()
    end)
end

function Runtime.tick(deltaMs)
    if not (BattleMain.IsRunning and BattleMain.IsRunning()) then
        return {}
    end

    state.accumulatorMs = state.accumulatorMs + math.max(0, deltaMs or 0)
    if state.accumulatorMs < LOGIC_STEP_MS then
        if #state.events == 0 then
            return {}
        end

        local pendingEvents = state.events
        state.events = {}
        return pendingEvents
    end

    local steps = math.floor(state.accumulatorMs / LOGIC_STEP_MS)
    state.accumulatorMs = state.accumulatorMs - (steps * LOGIC_STEP_MS)

    for _ = 1, steps do
        if state.battleEnded then
            break
        end

        local handledCommand = processNextCommand()
        if not handledCommand then
            BattleMain.Update(LOGIC_STEP_MS)
        end
        refreshUltimateReadiness()
    end

    local events = state.events
    state.events = {}
    return events
end

function Runtime.queueCommand(command)
    if type(command) ~= "table" or command.type ~= "cast_ultimate" then
        rejectCommand(command, "invalid_command")
        return false
    end

    if #state.queuedCommands >= MAX_QUEUED_COMMANDS then
        rejectCommand(command, "queue_full")
        return false
    end

    local heroId = tostring(command.heroId)
    if BattleMain.HasQueuedUltimate and BattleMain.HasQueuedUltimate(heroId) then
        rejectCommand(command, "ultimate_already_queued")
        return false
    end

    for _, queuedCommand in ipairs(state.queuedCommands) do
        if queuedCommand and queuedCommand.type == "cast_ultimate" and tostring(queuedCommand.heroId) == heroId then
            rejectCommand(command, "ultimate_already_queued")
            return false
        end
    end

    state.queuedCommands[#state.queuedCommands + 1] = {
        type = "cast_ultimate",
        heroId = heroId,
    }

    emitEvent("ultimate_cast_queued", {
        heroId = heroId,
    })
    return true
end

function Runtime.getSnapshot()
    refreshUltimateReadiness()
    return buildSnapshot()
end

function Runtime.restart(config)
    return Runtime.init(config or state.currentConfig)
end

return Runtime
