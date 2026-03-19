--[[
    等级输入随机战斗测试脚本
    使用方法: lua test_level_battle.lua [等级] [英雄数量] [敌人数量]
    示例: lua test_level_battle.lua 50 3 4
--]]

-- 设置UTF-8编码
os.execute("chcp 65001 >nul 2>&1")

-- 添加上级目录到路径（bin的父目录是项目根目录）
package.path = package.path .. ";../?.lua"

-- 解析命令行参数
local targetLevel = tonumber(arg[1]) or 50
local heroCount = tonumber(arg[2]) or 3
local enemyCount = tonumber(arg[3]) or 4

print(string.format("=== 等级 %d 随机战斗测试 ===", targetLevel))
print(string.format("英雄数量: %d, 敌人数量: %d", heroCount, enemyCount))
print("")

-- 加载必要模块
require("core.battle_enum")
require("modules.BattleDefaultTypesOpt")  -- 技能脚本依赖此模块
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local BattleMain = require("modules.battle_main")
local SkillData = require("config.skill_data")
local Logger = require("utils.logger")

-- 设置日志级别为 INFO，显示战斗过程
Logger.SetLogLevel(Logger.LOG_LEVELS.INFO)

-- 加载所有英雄和敌人配置
local allHeroIds = {}
local allEnemyIds = {}

-- 从res_ally_info.json加载英雄ID
local function LoadAllHeroIds()
    local JSON = require("utils.json")
    local file = io.open("../config/res_ally_info.json", "r")
    if file then
        local content = file:read("*a")
        file:close()
        local data = JSON.JsonDecode(content)
        for _, hero in ipairs(data) do
            if hero.IsHero == 1 then
                table.insert(allHeroIds, hero.AllyID)
            end
        end
    end
end

-- 从EnemyData加载普通怪物ID (MonsterType=0，非BOSS非精英)
local function LoadAllEnemyIds()
    -- 只获取普通怪物 (MonsterType=0)
    local enemies = EnemyData.GetEnemiesByMonsterType(0)
    -- 提取敌人ID
    allEnemyIds = {}
    for _, enemy in ipairs(enemies) do
        if enemy.ID then
            table.insert(allEnemyIds, enemy.ID)
        end
    end
end

-- 加载所有Boss ID (MonsterType=2)
local allBossIds = {}
local function LoadAllBossIds()
    local bosses = EnemyData.GetEnemiesByMonsterType(2)
    allBossIds = {}
    for _, boss in ipairs(bosses) do
        if boss.ID then
            table.insert(allBossIds, boss.ID)
        end
    end
end

-- 随机打乱数组
local function ShuffleArray(arr)
    local result = {}
    for i = 1, #arr do
        result[i] = arr[i]
    end
    for i = #result, 2, -1 do
        local j = math.random(i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

-- 随机选择N个元素
local function RandomSelect(arr, n)
    if #arr <= n then
        return arr
    end
    local shuffled = ShuffleArray(arr)
    local result = {}
    for i = 1, n do
        table.insert(result, shuffled[i])
    end
    return result
end

-- 创建英雄数据
local function CreateHero(heroId, level, star)
    local heroData = AllyData.ConvertToHeroData(heroId, level, star)
    if not heroData then return nil end
    
    -- skillsConfig 已由 AllyData.ConvertToHeroData 自动生成
    -- 只需要转换 skillType 为战斗系统使用的枚举值
    if heroData.skillsConfig then
        for _, cfg in ipairs(heroData.skillsConfig) do
            cfg.skillType = cfg.skillType == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL
        end
    end
    
    return heroData
end

-- 创建敌人数据
local function CreateEnemy(enemyId, level)
    local enemyData = EnemyData.ConvertToHeroData(enemyId)
    if not enemyData then return nil end
    
    -- skillsConfig 已由 EnemyData.ConvertToHeroData 自动生成
    -- 只需要转换 skillType 为战斗系统使用的枚举值
    if enemyData.skillsConfig then
        for _, cfg in ipairs(enemyData.skillsConfig) do
            cfg.skillType = cfg.skillType == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL
        end
    end
    
    return enemyData
end

-- 主函数
local function Main()
    -- 初始化随机种子
    math.randomseed(os.time())
    
    -- 加载所有可用ID
    LoadAllHeroIds()
    LoadAllEnemyIds()
    LoadAllBossIds()
    
    print(string.format("可用英雄: %d, 可用小怪: %d, 可用Boss: %d", #allHeroIds, #allEnemyIds, #allBossIds))
    print("")
    
    if #allHeroIds == 0 then
        print("错误: 无法加载英雄配置")
        return
    end
    
    -- 随机选择英雄
    local selectedHeroIds = RandomSelect(allHeroIds, heroCount)
    
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
        local selectedMobs = RandomSelect(allEnemyIds, remainingCount)
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
        local hero = CreateHero(heroId, level, star)
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
        local enemy = CreateEnemy(enemyId, level)
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
    print("【战斗开始】")
    print("")
    
    -- 执行战斗（使用回调方式获取结果）
    local battleResult = nil
    local battleFinished = false
    
    -- 检查英雄数据
    print(string.format("[调试] 英雄数量: %d, 敌人数量: %d", #heroes, #enemies))
    for i, hero in ipairs(heroes) do
        print(string.format("[调试] 英雄 %d: %s, atk=%d, spd=%d", i, hero.name, hero.atk, hero.spd))
    end
    
    -- 设置更新间隔为0，确保每次Update都执行
    BattleMain.SetUpdateInterval(0)
    
    BattleMain.Start({
        teamLeft = heroes,
        teamRight = enemies,
        seedArray = {os.time(), math.random(1000000), 123456789, 362436069}
    }, function(result)
        battleResult = result
        battleFinished = true
    end)
    
    -- 驱动战斗循环
    local maxSteps = 20000
    local step = 0
    local lastRound = 0
    local lastHPLeft = 0
    local lastHPRight = 0
    
    while not battleFinished and step < maxSteps do
        BattleMain.Update()
        step = step + 1
        
        -- 每100步检查一次战斗状态并输出简要信息
        if step % 100 == 0 then
            -- 获取当前战斗状态
            local currentRound = 0
            local totalHPLeft = 0
            local totalHPRight = 0
            
            -- 尝试获取战斗信息（如果模块支持）
            local BattleFormation = require("modules.battle_formation")
            if BattleFormation and BattleFormation.GetAllHeroes then
                local allHeroes = BattleFormation.GetAllHeroes()
                for _, hero in ipairs(allHeroes or {}) do
                    if hero then
                        local hp = hero.hp or 0
                        if hero.side == "left" then
                            totalHPLeft = totalHPLeft + hp
                        elseif hero.side == "right" then
                            totalHPRight = totalHPRight + hp
                        end
                    end
                end
            end
            
            -- 如果HP有变化，输出战斗进展
            if totalHPLeft ~= lastHPLeft or totalHPRight ~= lastHPRight then
                print(string.format("  步数 %d | 英雄方 HP: %d | 敌人方 HP: %d", 
                    step, totalHPLeft, totalHPRight))
                lastHPLeft = totalHPLeft
                lastHPRight = totalHPRight
            end
        end
        
        -- 每5000步输出一次进度
        if step % 5000 == 0 then
            print(string.format("  ...战斗中，已执行 %d 步", step))
        end
    end
    
    -- 输出结果
    print("\n【战斗结果】")
    if battleResult then
        if battleResult.winner == "left" then
            print("✓ 英雄方胜利!")
        elseif battleResult.winner == "right" then
            print("✗ 敌人方胜利!")
        else
            print("△ 战斗平局!")
        end
        
        if battleResult.totalRound then
            print(string.format("\n总回合数: %d", battleResult.totalRound))
        end
        print(string.format("执行步数: %d", step))
    else
        print("△ 战斗未完成或达到最大步数限制")
        print(string.format("执行步数: %d", step))
    end
    
    -- 清理
    BattleMain.Quit()
end

-- 运行主函数
Main()
