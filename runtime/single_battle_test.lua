local Runtime = require("runtime.browser_battle_runtime")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")

local SingleBattleTest = {}

local DEFAULT_CONFIG = {
    level = 1,
    heroIds = { 900005, 900007, 900002 },
    enemyIds = { 910004, 910002, 910003 },
    initialEnergy = 90,
    seed = 101001,
}

local REINFORCEMENT_REASON = "右侧战场已清空且无后备敌人"
local BOSS_CLEAR_REASON = "右侧战场已清空且无后备敌人"

local function cloneArray(input)
    local result = {}
    for i, value in ipairs(input or {}) do
        result[i] = value
    end
    return result
end

local function shallowCopy(input)
    local result = {}
    for key, value in pairs(input or {}) do
        result[key] = value
    end
    return result
end

local function mergeConfig(options)
    options = options or {}
    return {
        level = tonumber(options.level) or DEFAULT_CONFIG.level,
        heroIds = cloneArray(options.heroIds or DEFAULT_CONFIG.heroIds),
        enemyIds = cloneArray(options.enemyIds or DEFAULT_CONFIG.enemyIds),
        initialEnergy = tonumber(options.initialEnergy) or DEFAULT_CONFIG.initialEnergy,
        seed = tonumber(options.seed) or DEFAULT_CONFIG.seed,
    }
end

local function printTeam(title, team)
    print(title)
    for index, unit in ipairs(team or {}) do
        print(string.format(
            "  %d. %s Lv? HP %d/%d AC %d INIT %d",
            index,
            unit.name or tostring(unit.id),
            tonumber(unit.hp) or 0,
            tonumber(unit.maxHp) or 0,
            tonumber(unit.ac) or 0,
            tonumber(unit.initiative) or 0
        ))
    end
end

local function buildHeroTeam(heroIds, level)
    local result = {}
    for index, heroId in ipairs(heroIds or {}) do
        local heroData = HeroData.ConvertToHeroData(heroId, level, 5)
        if heroData then
            heroData.wpType = heroData.wpType or index
            result[#result + 1] = heroData
        end
    end
    return result
end

local function buildEnemy(enemyId, level, overrides)
    local enemyData = EnemyData.ConvertToHeroData(enemyId, level)
    if not enemyData then
        return nil
    end
    for key, value in pairs(overrides or {}) do
        enemyData[key] = value
    end
    return enemyData
end

local function runRuntime(config, options)
    local snapshot = Runtime.init(config)
    local sawReady = false
    local steps = 0
    local maxSteps = tonumber(options and options.maxSteps) or 5000
    local autoUltimate = options == nil or options.autoUltimate ~= false
    local maxSpawned = tonumber(snapshot.battleRules and snapshot.battleRules.totalSpawned) or 0
    local minReserveRemaining = tonumber(snapshot.reserveRemaining) or 0

    while steps < maxSteps and not snapshot.result do
        steps = steps + 1
        local events = Runtime.tick(80)
        snapshot = Runtime.getSnapshot()
        maxSpawned = math.max(maxSpawned, tonumber(snapshot.battleRules and snapshot.battleRules.totalSpawned) or 0)
        minReserveRemaining = math.min(minReserveRemaining, tonumber(snapshot.reserveRemaining) or 0)
        if type(options and options.onTick) == "function" then
            options.onTick(snapshot, events, steps)
        end

        if autoUltimate and snapshot.pendingCommands == 0 then
            for _, event in ipairs(events) do
                if event.type == "ultimate_ready" and event.payload and event.payload.heroId then
                    sawReady = true
                    Runtime.queueCommand({
                        type = "cast_ultimate",
                        heroId = event.payload.heroId,
                    })
                    break
                end
            end
        end
    end

    return {
        snapshot = snapshot,
        steps = steps,
        sawReady = sawReady,
        maxSpawned = maxSpawned,
        minReserveRemaining = minReserveRemaining,
    }
end

function SingleBattleTest.Run(options)
    local config = mergeConfig(options)
    config.heroCount = #config.heroIds
    config.enemyCount = #config.enemyIds

    local snapshot = Runtime.init(config)
    print("=== 单场战斗测试 ===")
    print(string.format(
        "等级: %d, 英雄: %d, 敌人: %d, 初始能量: %d, seed: %d",
        config.level,
        #config.heroIds,
        #config.enemyIds,
        config.initialEnergy,
        config.seed
    ))
    printTeam("【英雄阵容】", snapshot.leftTeam)
    printTeam("【敌人阵容】", snapshot.rightTeam)

    local runResult = runRuntime(config, options)
    snapshot = runResult.snapshot

    print("")
    if snapshot.result then
        print(string.format(
            "战斗结束: winner=%s reason=%s round=%d steps=%d",
            tostring(snapshot.result.winner),
            tostring(snapshot.result.reason),
            tonumber(snapshot.round) or 0,
            runResult.steps
        ))
    else
        print(string.format(
            "战斗未结束: round=%d steps=%d/%d",
            tonumber(snapshot.round) or 0,
            runResult.steps,
            tonumber(options and options.maxSteps) or 5000
        ))
    end
    print(string.format("自动大招触发: %s", runResult.sawReady and "是" or "否"))

    return {
        config = config,
        snapshot = snapshot,
        steps = runResult.steps,
        sawReady = runResult.sawReady,
        maxSpawned = runResult.maxSpawned,
        minReserveRemaining = runResult.minReserveRemaining,
    }
end

function SingleBattleTest.RunScenarioAssertions()
    print("=== 单场战斗专项断言 ===")

    local reinforcementConfig = {
        level = 3,
        teamLeft = buildHeroTeam({ 900005, 900007, 900002 }, 3),
        teamRight = {
            buildEnemy(910001, 1, { hp = 12, maxHp = 12, wpType = 1 }),
        },
        enemyReserve = {
            buildEnemy(910001, 1, { hp = 12, maxHp = 12, wpType = 0 }),
            buildEnemy(910002, 1, { hp = 16, maxHp = 16, wpType = 0 }),
        },
        refreshOnClear = true,
        refreshTurns = 0,
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        initialEnergy = 100,
    }
    local sawWaveCleanup = false
    local reinforcementResult = runRuntime(reinforcementConfig, {
        maxSteps = 2500,
        onTick = function(snapshot, events)
            local spawnedThisTick = false
            for _, event in ipairs(events or {}) do
                if event.type == "CombatLog"
                    and event.payload
                    and event.payload.extra
                    and event.payload.extra.trigger
                    and event.payload.extra.removedDead ~= nil then
                    spawnedThisTick = true
                    break
                end
            end
            if not spawnedThisTick then
                return
            end
            local rightTeam = snapshot and snapshot.rightTeam or {}
            for _, unit in ipairs(rightTeam) do
                assert(unit.isAlive, "reinforcement spawn tick should not retain dead enemies from previous wave")
            end
            sawWaveCleanup = true
        end,
    })
    local reinforcementSnapshot = reinforcementResult.snapshot
    assert(reinforcementSnapshot.result ~= nil, "reinforcement scenario should complete")
    assert(reinforcementSnapshot.result.winner == "left", "reinforcement scenario should be won by left team")
    assert(reinforcementSnapshot.result.reason == REINFORCEMENT_REASON, "reinforcement scenario should end after reserve is exhausted")
    assert(reinforcementResult.maxSpawned >= 2, "reinforcement scenario should spawn reserve enemies")
    assert((tonumber(reinforcementSnapshot.reserveRemaining) or 0) == 0, "reinforcement scenario should consume all reserve enemies")
    assert(sawWaveCleanup, "reinforcement scenario should observe a cleaned battlefield after reserve spawn")
    print(string.format("reinforcement: ok (spawned=%d, reserveRemaining=%d)", reinforcementResult.maxSpawned, tonumber(reinforcementSnapshot.reserveRemaining) or 0))

    local bossConfig = {
        level = 4,
        teamLeft = buildHeroTeam({ 900005, 900007, 900002 }, 4),
        teamRight = {
            buildEnemy(910007, 1, { hp = 8, maxHp = 8, wpType = 1, id = 910007, enemyId = 910007, monsterType = 2 }),
        },
        enemyReserve = {
            buildEnemy(910004, 2, { hp = 40, maxHp = 40, wpType = 0 }),
            buildEnemy(910003, 2, { hp = 40, maxHp = 40, wpType = 0 }),
        },
        refreshOnClear = false,
        refreshTurns = 0,
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        bossId = 910007,
        initialEnergy = 100,
    }
    local bossResult = runRuntime(bossConfig, { maxSteps = 2500 })
    local bossSnapshot = bossResult.snapshot
    assert(bossSnapshot.result ~= nil, "boss clear scenario should complete")
    assert(bossSnapshot.result.winner == "left", "boss clear scenario should be won by left team")
    assert(bossSnapshot.result.reason == BOSS_CLEAR_REASON, "boss clear scenario should end only after all enemies die")
    assert((tonumber(bossSnapshot.reserveRemaining) or 0) == 0, "boss clear scenario should consume all reserve enemies")
    print(string.format("boss_clear: ok (reserveRemaining=%d)", tonumber(bossSnapshot.reserveRemaining) or 0))

    return {
        reinforcement = shallowCopy(reinforcementResult),
        bossClear = shallowCopy(bossResult),
    }
end

return SingleBattleTest
