package.path = package.path .. ";../?.lua"

require("core.battle_enum")
require("modules.BattleDefaultTypesOpt")

local BattleHeroFactory = require("modules.battle_hero_factory")
local BattleDriver = require("modules.battle_driver")
local BattleMain = require("modules.battle_main")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local ArrayUtils = require("utils.array_utils")
local Logger = require("utils.logger")

Logger.SetLogLevel(Logger.LOG_LEVELS.ERROR)

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local function collectPlayableHeroIds()
    local result = {}
    for _, hero in ipairs(HeroData.GetPlayableHeroes()) do
        if hero.AllyID then
            table.insert(result, hero.AllyID)
        end
    end
    return result
end

local function run_once(level, heroCount, enemyCount, seed)
    math.randomseed(seed)

    local heroIds = collectPlayableHeroIds()
    local enemyIds = EnemyData.GetAllEnemyIds()
    local selectedHeroIds = ArrayUtils.RandomSelect(heroIds, heroCount)
    local selectedEnemyIds = ArrayUtils.RandomSelect(enemyIds, enemyCount)

    local minLevel = math.max(1, level - 4)
    local maxLevel = math.min(20, level + 4)
    local heroes = {}
    local enemies = {}

    for _, heroId in ipairs(selectedHeroIds) do
        heroes[#heroes + 1] = BattleHeroFactory.CreateHero(heroId, math.random(minLevel, maxLevel), math.random(1, 5))
    end
    for _, enemyId in ipairs(selectedEnemyIds) do
        enemies[#enemies + 1] = BattleHeroFactory.CreateEnemy(enemyId, math.random(minLevel, maxLevel))
    end

    BattleDriver.Init({
        maxSteps = 5000,
        updateInterval = 0,
        refreshInterval = 10,
    })

    local battleResult = nil
    BattleDriver.Start({
        teamLeft = heroes,
        teamRight = enemies,
        seedArray = { seed, seed * 3 + 1, seed * 7 + 2, seed * 11 + 3 },
        disableDefaultRenderer = true,
    }, function(result)
        battleResult = result
    end)

    BattleDriver.RunUntilEnd()
    local round = BattleMain.GetCurrentRound() or 0
    BattleDriver.Cleanup()

    return {
        winner = battleResult and battleResult.winner or "none",
        actionRound = round,
    }
end

local function sample_case(level, heroCount, enemyCount, baseSeed, runs)
    local totalRound = 0
    local drawCount = 0
    for i = 1, runs do
        local result = run_once(level, heroCount, enemyCount, baseSeed + i)
        totalRound = totalRound + result.actionRound
        if result.winner == "draw" then
            drawCount = drawCount + 1
        end
    end

    local avgActionRound = totalRound / runs
    local approxFullRounds = avgActionRound / (heroCount + enemyCount)
    return {
        avgActionRound = avgActionRound,
        approxFullRounds = approxFullRounds,
        drawCount = drawCount,
    }
end

local case33 = sample_case(20, 3, 3, 6000, 12)
local case34 = sample_case(20, 3, 4, 7000, 12)

print(string.format("[Rhythm] 3v3 avgActionRound=%.2f approxFullRounds=%.2f draws=%d",
    case33.avgActionRound, case33.approxFullRounds, case33.drawCount))
print(string.format("[Rhythm] 3v4 avgActionRound=%.2f approxFullRounds=%.2f draws=%d",
    case34.avgActionRound, case34.approxFullRounds, case34.drawCount))

assert_true(case33.approxFullRounds <= 7.0, string.format("3v3 节奏偏慢: %.2f", case33.approxFullRounds))
assert_true(case34.approxFullRounds <= 6.5, string.format("3v4 节奏偏慢: %.2f", case34.approxFullRounds))
assert_true(case33.drawCount <= 1, string.format("3v3 平局过多: %d", case33.drawCount))
assert_true(case34.drawCount <= 1, string.format("3v4 平局过多: %d", case34.drawCount))

print("[PASS] Battle rhythm regression")
