--[[
    Viewport 渲染器战斗测试脚本
    展示标准的 2D 回合制游戏表现
--]]

os.execute("chcp 65001 >nul 2>&1")

package.path = package.path .. ";../?.lua"

local targetLevel = tonumber(arg[1]) or 50
local heroCount = math.min(tonumber(arg[2]) or 3, 6)
local enemyCount = math.min(tonumber(arg[3]) or 4, 6)
local updateSpeed = tonumber(arg[4]) or 500

print("=== Viewport 2D 战斗表现测试 ===")

require("core.battle_enum")
require("modules.BattleDefaultTypesOpt")
local BattleHeroFactory = require("modules.battle_hero_factory")
local BattleDriver = require("modules.battle_driver")
local ViewportRenderer = require("ui.viewport_renderer")
local Logger = require("utils.logger")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local ArrayUtils = require("utils.array_utils")

Logger.SetLogLevel(Logger.LOG_LEVELS.WARN)
ViewportRenderer.SetFastMode(updateSpeed <= 0)

local function Main()
    math.randomseed(os.time())
    
    local allHeroIds = {}
    local allHeroes = AllyData.GetPlayableHeroes()
    for _, hero in ipairs(allHeroes) do
        if hero.AllyID then table.insert(allHeroIds, hero.AllyID) end
    end
    local allEnemyIds = EnemyData.GetAllEnemyIds()
    local allBossIds = EnemyData.GetAllBossIds()
    
    local selectedHeroIds = ArrayUtils.RandomSelect(allHeroIds, heroCount)
    local selectedEnemyIds = {}
    if #allBossIds > 0 then
        table.insert(selectedEnemyIds, allBossIds[math.random(#allBossIds)])
    end
    local remainingCount = enemyCount - #selectedEnemyIds
    if remainingCount > 0 then
        local selectedMobs = ArrayUtils.RandomSelect(allEnemyIds, remainingCount)
        for _, id in ipairs(selectedMobs) do table.insert(selectedEnemyIds, id) end
    end
    
    local heroes = {}
    for i, id in ipairs(selectedHeroIds) do
        local h = BattleHeroFactory.CreateHero(id, targetLevel, 5)
        if h then 
            h.wpType = i
            table.insert(heroes, h) 
        end
    end
    
    local enemies = {}
    for i, id in ipairs(selectedEnemyIds) do
        local e = BattleHeroFactory.CreateEnemy(id, targetLevel)
        if e then 
            e.wpType = i
            table.insert(enemies, e) 
        end
    end
    
    BattleDriver.Init({
        maxSteps = 20000,
        updateInterval = updateSpeed,
    })
    
    BattleDriver.Start({
        teamLeft = heroes,
        teamRight = enemies,
        seedArray = {os.time(), math.random(1000000), 123456789, 362436069},
        disableDefaultRenderer = true,
        renderer = ViewportRenderer
    }, function(result)
    end)
    
    BattleDriver.RunUntilEnd()
    
    print("\n战斗结束！请查看上方 Viewport 画面。")
end

Main()