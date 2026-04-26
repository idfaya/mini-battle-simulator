local Runtime = require("modules.browser_battle_runtime")

local SingleBattleTest = {}

local DEFAULT_CONFIG = {
    level = 1,
    heroIds = { 900005, 900007, 900002 },
    enemyIds = { 910004, 910002, 910003 },
    initialEnergy = 90,
    seed = 101001,
}

local function cloneArray(input)
    local result = {}
    for i, value in ipairs(input or {}) do
        result[i] = value
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

    local sawReady = false
    local steps = 0
    local maxSteps = tonumber(options and options.maxSteps) or 5000
    local autoUltimate = options == nil or options.autoUltimate ~= false

    while steps < maxSteps and not snapshot.result do
        steps = steps + 1
        local events = Runtime.tick(80)
        snapshot = Runtime.getSnapshot()

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

    print("")
    if snapshot.result then
        print(string.format(
            "战斗结束: winner=%s reason=%s round=%d steps=%d",
            tostring(snapshot.result.winner),
            tostring(snapshot.result.reason),
            tonumber(snapshot.round) or 0,
            steps
        ))
    else
        print(string.format("战斗未结束: round=%d steps=%d/%d", tonumber(snapshot.round) or 0, steps, maxSteps))
    end
    print(string.format("自动大招触发: %s", sawReady and "是" or "否"))

    return {
        config = config,
        snapshot = snapshot,
        steps = steps,
        sawReady = sawReady,
    }
end

return SingleBattleTest
