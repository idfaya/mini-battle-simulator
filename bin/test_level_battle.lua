--[[
    等级输入随机战斗测试脚本
    使用方法: lua test_level_battle.lua [等级] [英雄数量] [敌人数量] [更新速度(毫秒)] [是否包含Boss:1/0]
    示例: lua test_level_battle.lua 20 3 4 500 1
    更新速度: 0=极速(无延迟), 100=快, 500=正常, 1000=慢
--]]

os.execute("chcp 65001 >nul 2>&1")

local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local targetLevel = tonumber(arg[1]) or 20
local heroCount = tonumber(arg[2]) or 3
local enemyCount = tonumber(arg[3]) or 4
local updateSpeed = tonumber(arg[4]) or 200
local includeBoss = tonumber(arg[5])
if includeBoss == nil then
    includeBoss = 1
end

print(string.format("=== 等级 %d 随机战斗测试 ===", targetLevel))
print(string.format("英雄数量: %d, 敌人数量: %d", heroCount, enemyCount))
print(string.format("更新速度: %d毫秒 (0=极速)", updateSpeed))
print(string.format("包含Boss: %s", includeBoss == 1 and "是" or "否"))
print("")

local BattleHeroFactory = require("modules.battle_hero_factory")
local BattleDriver = require("modules.battle_driver")
local BattleMain = require("modules.battle_main")
local Logger = require("utils.logger")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local ArrayUtils = require("utils.array_utils")

Logger.SetLogLevel(Logger.LOG_LEVELS.WARN)

local function Sleep(ms)
    if ms <= 0 then return end
    local start = os.clock()
    while (os.clock() - start) * 1000 < ms do
    end
end

local function Main()
    math.randomseed(os.time())

    local allHeroIds = {}
    local allHeroes = HeroData.GetPlayableHeroes()
    for _, hero in ipairs(allHeroes) do
        if hero.AllyID then table.insert(allHeroIds, hero.AllyID) end
    end
    local allEnemyIds = EnemyData.GetAllEnemyIds()
    local allBossIds = EnemyData.GetAllBossIds()

    print(string.format("可用英雄: %d, 可用小怪: %d, 可用Boss: %d", #allHeroIds, #allEnemyIds, #allBossIds))
    print("")
    
    if #allHeroIds == 0 then
        print("错误: 无法加载英雄配置")
        return
    end
    
    local selectedHeroIds = ArrayUtils.RandomSelect(allHeroIds, heroCount)
    
    local selectedEnemyIds = {}
    if includeBoss == 1 and #allBossIds > 0 then
        local randomBossId = allBossIds[math.random(#allBossIds)]
        table.insert(selectedEnemyIds, randomBossId)
        print(string.format("\n【本场Boss】ID: %d", randomBossId))
    end
    
    local remainingCount = enemyCount - #selectedEnemyIds
    if remainingCount > 0 and #allEnemyIds > 0 then
        local selectedMobs = ArrayUtils.RandomSelect(allEnemyIds, remainingCount)
        for _, mobId in ipairs(selectedMobs) do
            table.insert(selectedEnemyIds, mobId)
        end
    end
    
    local minLevel = math.max(1, targetLevel - 4)
    local maxLevel = math.min(20, targetLevel + 4)
    
    local heroes = {}
    print("【英雄阵容】")
    for i, heroId in ipairs(selectedHeroIds) do
        local level = math.random(minLevel, maxLevel)
        local star = math.random(1, 5)
        local hero = BattleHeroFactory.CreateHero(heroId, level, star)
        if hero then
            table.insert(heroes, hero)
            print(string.format("  %d. %s (Lv.%d ★%d)", 
                i, hero.name, level, star))
        end
    end
    
    local enemies = {}
    print("\n【敌人阵容】")
    for i, enemyId in ipairs(selectedEnemyIds) do
        local level = math.random(minLevel, maxLevel)
        local enemy = BattleHeroFactory.CreateEnemy(enemyId, level)
        if enemy then
            table.insert(enemies, enemy)
            local isBoss = enemy._monsterType == 2
            local prefix = isBoss and "【BOSS】" or ""
            print(string.format("  %d. %s%s (Lv.%d %s)", 
                i, prefix, enemy.name, level, enemy._monsterTypeName or ""))
        end
    end
    
    print("\n" .. string.rep("=", 50))
    print("战斗即将开始...")
    Sleep(500)
    
    BattleDriver.Init({
        maxSteps = 5000,
        updateInterval = updateSpeed,
        refreshInterval = 10
    })
    
    local battleResult = nil
    BattleDriver.Start({
        teamLeft = heroes,
        teamRight = enemies,
        seedArray = {os.time(), math.random(1000000), 123456789, 362436069}
    }, function(result)
        battleResult = result
    end)
    
    BattleDriver.RunUntilEnd()
    
    local status = BattleDriver.GetStatus()
    local currentRound = BattleMain.GetCurrentRound() or 0
    if battleResult then
        if battleResult.totalRound then
            print(string.format("\n总回合数: %d", battleResult.totalRound))
        end
        print(string.format("行动回合数: %d", currentRound))
        print(string.format("近似整轮数: %.2f", currentRound / math.max(1, heroCount + enemyCount)))
        print(string.format("执行步数: %d", status.step))
    else
        print("△ 战斗未完成或达到最大步数限制")
        print(string.format("行动回合数: %d", currentRound))
        print(string.format("执行步数: %d", status.step))
    end
    
    BattleDriver.Cleanup()
end

Main()
