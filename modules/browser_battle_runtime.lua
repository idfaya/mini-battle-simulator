local BattleMain = require("modules.battle_main")
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleEnergy = require("modules.battle_energy")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local BattleEnergyConfig = require("config.battle_energy_config")
local BattleRhythmConfig = require("config.battle_rhythm_config")
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
    BattleVisualEvents.BLOCK,
    BattleVisualEvents.CRIT,
}

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

local function canCastUltimate(hero)
    if not hero or hero.isDead or not hero.isAlive or not hero.isLeft then
        return false
    end

    local skill = getUltimateSkill(hero)
    if not skill then
        return false
    end

    if BattleSkill.GetSkillCurCoolDown(hero, skill.skillId) > 0 then
        return false
    end

    return BattleEnergy.CanCastUltimate(hero, skill)
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
    for _, buff in ipairs(hero.buffs or {}) do
        buffs[#buffs + 1] = serializeBuff(buff)
    end

    return {
        id = tostring(hero.instanceId),
        name = hero.name,
        team = hero.isLeft and "left" or "right",
        position = hero.wpType or 0,
        hp = hero.hp or 0,
        maxHp = hero.maxHp or 0,
        energy = hero.curEnergy or 0,
        maxEnergy = hero.maxEnergy or 100,
        isAlive = hero.isAlive and not hero.isDead,
        buffs = buffs,
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
        pendingCommands = #state.queuedCommands,
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
        BattleEvent.AddListener(eventName, function(payload)
            if eventName == BattleVisualEvents.TURN_STARTED then
                state.activeHeroId = payload and (payload.heroId or payload.instanceId) or state.activeHeroId
            elseif eventName == BattleVisualEvents.TURN_ENDED then
                state.activeHeroId = nil
            elseif eventName == BattleVisualEvents.BATTLE_ENDED then
                state.battleEnded = true
                state.battleResult = payload
            end

            emitEvent(eventName, payload)
        end)
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

    unit.wpType = DEFAULT_WP_TYPES[index] or index
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

local function buildRuntimeTeamConfig(options)
    local level = clamp(tonumber(options and options.level) or 50, 1, 100)
    local heroCount = clamp(math.floor(tonumber(options and options.heroCount) or 3), 1, 6)
    local enemyCount = clamp(math.floor(tonumber(options and options.enemyCount) or 4), 1, 6)
    local initialEnergy = clamp(math.floor(tonumber(options and options.initialEnergy) or DEFAULT_INITIAL_ENERGY), 0, 100)
    local seedArray = buildSeedArray()

    math.randomseed(seedArray[1])

    local selectedHeroIds = {}
    local allHeroes = HeroData.GetPlayableHeroes()
    for _, hero in ipairs(ArrayUtils.RandomSelect(allHeroes, heroCount)) do
        if hero and hero.AllyID then
            table.insert(selectedHeroIds, hero.AllyID)
        end
    end

    local allEnemyIds = EnemyData.GetAllEnemyIds()
    local allBossIds = EnemyData.GetAllBossIds()
    local selectedEnemyIds = {}
    local selectedEnemyMap = {}

    local function addEnemyId(enemyId)
        if enemyId and not selectedEnemyMap[enemyId] then
            selectedEnemyMap[enemyId] = true
            table.insert(selectedEnemyIds, enemyId)
        end
    end

    if #allBossIds > 0 then
        addEnemyId(ArrayUtils.RandomSelect(allBossIds, 1)[1])
    end

    local remainingEnemyCount = enemyCount - #selectedEnemyIds
    if remainingEnemyCount > 0 then
        for _, enemyId in ipairs(ArrayUtils.RandomSelect(allEnemyIds, remainingEnemyCount)) do
            addEnemyId(enemyId)
        end
    end

    if #selectedEnemyIds < enemyCount then
        for _, enemyId in ipairs(allEnemyIds) do
            addEnemyId(enemyId)
            if #selectedEnemyIds >= enemyCount then
                break
            end
        end
    end

    local leftTeam = {}
    for index, heroId in ipairs(selectedHeroIds) do
        local heroData = HeroData.ConvertToHeroData(heroId, level, 5)
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
        level = 50,
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
    local skill = getUltimateSkill(hero)
    if not skill then
        return false, "ultimate_not_found"
    end

    if BattleSkill.GetSkillCurCoolDown(hero, skill.skillId) > 0 then
        return false, "ultimate_on_cooldown"
    end

    if not BattleEnergy.CanCastUltimate(hero, skill) then
        return false, "energy_not_enough"
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

    if BattleMain.GetActiveHeroInstanceId and BattleMain.GetActiveHeroInstanceId() then
        return false
    end

    local command = table.remove(state.queuedCommands, 1)
    if not command or command.type ~= "cast_ultimate" then
        rejectCommand(command, "unsupported_command")
        return true
    end

    local hero = BattleFormation.FindHeroByInstanceId(tonumber(command.heroId))
    if not hero or hero.isDead or not hero.isAlive or not hero.isLeft then
        rejectCommand(command, "hero_unavailable")
        return true
    end

    local success, reason = castUltimateNow(hero)
    if not success then
        rejectCommand(command, reason)
    end

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

    state.queuedCommands[#state.queuedCommands + 1] = {
        type = "cast_ultimate",
        heroId = tostring(command.heroId),
    }

    emitEvent("ultimate_cast_queued", {
        heroId = tostring(command.heroId),
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
