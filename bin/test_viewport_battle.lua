--[[
    Viewport 渲染器战斗测试脚本
    展示标准的 2D 回合制游戏表现
--]]

-- 设置UTF-8编码
os.execute("chcp 65001 >nul 2>&1")

-- 添加上级目录到路径
package.path = package.path .. ";../?.lua"

-- 解析命令行参数
local targetLevel = tonumber(arg[1]) or 50
local heroCount = math.min(tonumber(arg[2]) or 3, 6)
local enemyCount = math.min(tonumber(arg[3]) or 4, 6)
local updateSpeed = tonumber(arg[4]) or 500  -- Viewport 模式下 500ms 比较合适看动画

print("=== Viewport 2D 战斗表现测试 ===")

-- 加载必要模块
require("core.battle_enum")
require("modules.BattleDefaultTypesOpt")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local BattleHeroFactory = require("modules.battle_hero_factory")
local BattleDriver = require("modules.battle_driver")
local ViewportRenderer = require("ui.viewport_renderer")
local Logger = require("utils.logger")
local ArrayUtils = require("utils.array_utils")

-- 设置日志级别为 WARN，避免干扰 Viewport 渲染
Logger.SetLogLevel(Logger.LOG_LEVELS.WARN)

-- 主函数
local function Main()
    -- 初始化随机种子
    math.randomseed(os.time())
    
    -- 加载所有可用ID
    local allHeroIds = {}
    local heroes_data = AllyData.GetPlayableHeroes()
    for _, hero in ipairs(heroes_data) do
        if hero.AllyID then table.insert(allHeroIds, hero.AllyID) end
    end
    
    local allEnemyIds = EnemyData.GetAllNormalEnemyIds()
    local allBossIds = EnemyData.GetAllBossIds()
    
    -- 随机选择阵容
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
    
    -- 创建阵容
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
    
    -- 1. 准备阶段 (不需要手动初始化 ViewportRenderer，由 BattleMain 负责)
    
    -- 2. 初始化战斗驱动
    BattleDriver.Init({
        maxSteps = 20000,
        updateInterval = updateSpeed,
    })
    
    -- 3. 启动战斗 (禁用默认的 ConsoleRenderer，传入新渲染器)
    BattleDriver.Start({
        teamLeft = heroes,
        teamRight = enemies,
        seedArray = {os.time(), math.random(1000000), 123456789, 362436069},
        disableDefaultRenderer = true, -- 告诉 BattleMain 不要启动默认渲染器
        renderer = ViewportRenderer    -- 传入新渲染器，让 BattleMain 在正确时机初始化它
    }, function(result)
        -- 战斗结束后的处理
    end)
    
    -- 4. 驱动战斗直到结束
    BattleDriver.RunUntilEnd()
    
    print("\n战斗结束！请查看上方 Viewport 画面。")
end

Main()
