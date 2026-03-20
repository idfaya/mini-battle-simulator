--[[
    等级输入随机战斗测试脚本
    使用方法: lua test_level_battle.lua [等级] [英雄数量] [敌人数量] [更新速度(毫秒)]
    示例: lua test_level_battle.lua 50 3 4 500
    更新速度: 0=极速(无延迟), 100=快, 500=正常, 1000=慢
--]]

-- 设置UTF-8编码
os.execute("chcp 65001 >nul 2>&1")

-- 添加上级目录到路径（bin的父目录是项目根目录）
package.path = package.path .. ";../?.lua"

-- 解析命令行参数
local targetLevel = tonumber(arg[1]) or 50
local heroCount = tonumber(arg[2]) or 3
local enemyCount = tonumber(arg[3]) or 4
local updateSpeed = tonumber(arg[4]) or 200  -- 默认200毫秒

print(string.format("=== 等级 %d 随机战斗测试 ===", targetLevel))
print(string.format("英雄数量: %d, 敌人数量: %d", heroCount, enemyCount))
print(string.format("更新速度: %d毫秒 (0=极速)", updateSpeed))
print("")

-- 加载必要模块
require("core.battle_enum")
require("modules.BattleDefaultTypesOpt")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local BattleHeroFactory = require("modules.battle_hero_factory")
local BattleDriver = require("modules.battle_driver")
local BattleDisplay = require("ui.battle_display")
local Logger = require("utils.logger")
local ArrayUtils = require("utils.array_utils")

-- 设置日志级别为 WARN，减少日志干扰显示
Logger.SetLogLevel(Logger.LOG_LEVELS.WARN)

-- 简单的睡眠函数（毫秒）
local function Sleep(ms)
    if ms <= 0 then return end
    local start = os.clock()
    while (os.clock() - start) * 1000 < ms do
        -- 忙等待
    end
end

-- 主函数
local function Main()
    -- 初始化随机种子
    math.randomseed(os.time())
    
    -- 加载所有可用ID
    local allHeroIds = {}
    local allEnemyIds = {}
    local allBossIds = {}
    
    -- 从AllyData加载有技能的英雄ID
    local heroes = AllyData.GetPlayableHeroes()
    for _, hero in ipairs(heroes) do
        if hero.AllyID then
            table.insert(allHeroIds, hero.AllyID)
        end
    end
    
    -- 从EnemyData加载敌人ID
    allEnemyIds = EnemyData.GetAllNormalEnemyIds()
    allBossIds = EnemyData.GetAllBossIds()
    
    print(string.format("可用英雄: %d, 可用小怪: %d, 可用Boss: %d", #allHeroIds, #allEnemyIds, #allBossIds))
    print("")
    
    if #allHeroIds == 0 then
        print("错误: 无法加载英雄配置")
        return
    end
    
    -- 随机选择英雄
    local selectedHeroIds = ArrayUtils.RandomSelect(allHeroIds, heroCount)
    
    -- 随机选择一个Boss作为主敌人
    local selectedEnemyIds = {}
    if #allBossIds > 0 then
        local randomBossId = allBossIds[math.random(#allBossIds)]
        table.insert(selectedEnemyIds, randomBossId)
        print(string.format("\n【本场Boss】ID: %d", randomBossId))
    end
    
    -- 如果还有剩余敌人数量，用小怪填充
    local remainingCount = enemyCount - #selectedEnemyIds
    if remainingCount > 0 and #allEnemyIds > 0 then
        local selectedMobs = ArrayUtils.RandomSelect(allEnemyIds, remainingCount)
        for _, mobId in ipairs(selectedMobs) do
            table.insert(selectedEnemyIds, mobId)
        end
    end
    
    -- 计算等级范围 (目标等级 ± 10级)
    local minLevel = math.max(1, targetLevel - 10)
    local maxLevel = targetLevel + 10
    
    -- 创建英雄阵容
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
    
    -- 创建敌人阵容
    local enemies = {}
    print("\n【敌人阵容】")
    for i, enemyId in ipairs(selectedEnemyIds) do
        local level = math.random(minLevel, maxLevel)
        local enemy = BattleHeroFactory.CreateEnemy(enemyId, level)
        if enemy then
            table.insert(enemies, enemy)
            -- 判断是否是Boss (MonsterType=2)
            local isBoss = enemy._monsterType == 2
            local prefix = isBoss and "【BOSS】" or ""
            print(string.format("  %d. %s%s (Lv.%d %s)", 
                i, prefix, enemy.name, level, enemy._monsterTypeName or ""))
        end
    end
    
    print("\n" .. string.rep("=", 50))
    print("战斗即将开始...")
    Sleep(500)  -- 短暂延迟让用户看清阵容
    
    -- 初始化战斗驱动
    BattleDriver.Init({
        maxSteps = 20000,
        updateInterval = updateSpeed,
        refreshInterval = 10
    })
    
    -- 启动战斗
    local battleResult = nil
    BattleDriver.Start({
        teamLeft = heroes,
        teamRight = enemies,
        seedArray = {os.time(), math.random(1000000), 123456789, 362436069}
    }, function(result)
        battleResult = result
    end)
    
    -- 在 BattleMain.Start 之后注册事件监听器
    BattleDisplay.RegisterEventListeners()
    
    -- 驱动战斗直到结束
    BattleDriver.RunUntilEnd()
    
    -- 显示最终战斗结果
    BattleDisplay.ClearScreen()
    BattleDisplay.ShowVictoryScreen(battleResult and battleResult.winner)
    
    local status = BattleDriver.GetStatus()
    if battleResult then
        if battleResult.totalRound then
            print(string.format("\n总回合数: %d", battleResult.totalRound))
        end
        print(string.format("执行步数: %d", status.step))
    else
        print("△ 战斗未完成或达到最大步数限制")
        print(string.format("执行步数: %d", status.step))
    end
    
    -- 清理
    BattleDriver.Cleanup()
end

-- 运行主函数
Main()
