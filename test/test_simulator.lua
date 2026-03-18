-- 测试模拟器是否可以正常运行
-- 运行一个简单的战斗来验证核心功能

-- 设置包路径
package.path = package.path
    .. ";../?.lua"
    .. ";../core/?.lua"
    .. ";../modules/?.lua"
    .. ";../config/?.lua"
    .. ";../utils/?.lua"

-- 加载必要的模块
require("core.battle_types")
require("core.battle_default_types")
local BattleSimulator = require("core.battle_simulator")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")

local function Log(msg)
    print(string.format("[SIMULATOR TEST] %s", msg))
end

local function LogSuccess(msg)
    print(string.format("[SIMULATOR TEST] [OK] %s", msg))
end

local function LogError(msg)
    print(string.format("[SIMULATOR TEST] [ERROR] %s", msg))
end

-- 创建简单的英雄阵容
local function CreateSimpleHeroTeam()
    local team = {}
    local heroIds = {13101, 13102, 13103} -- 使用3个英雄进行简单测试
    
    for i, heroId in ipairs(heroIds) do
        local heroData, err = AllyData.ConvertToHeroData(heroId, 60, 5)
        if heroData then
            heroData.id = heroId
            heroData.name = string.format("Hero_%d", heroId)
            heroData.side = "left"
            heroData.position = i
            table.insert(team, heroData)
            Log(string.format("添加英雄: ID=%d, HP=%.0f, ATK=%.0f", 
                heroId, heroData.HP or 0, heroData.ATK or 0))
        else
            LogError(string.format("无法创建英雄 %d: %s", heroId, tostring(err)))
        end
    end
    
    return team
end

-- 创建简单的敌人阵容
local function CreateSimpleEnemyTeam()
    local team = {}
    local enemyIds = {20701, 20702} -- 使用2个敌人进行简单测试
    
    for i, enemyId in ipairs(enemyIds) do
        local enemyData = EnemyData.GetEnemy(enemyId)
        if enemyData then
            local enemy = {
                id = enemyId,
                name = string.format("Enemy_%d", enemyId),
                HP = enemyData.HP or 1000,
                ATK = enemyData.ATK or 100,
                DEF = enemyData.DEF or 50,
                side = "right",
                position = i,
                Class = enemyData.Class or 2
            }
            table.insert(team, enemy)
            Log(string.format("添加敌人: ID=%d, HP=%d, ATK=%d", 
                enemyId, enemy.HP, enemy.ATK))
        else
            LogError(string.format("无法获取敌人 %d", enemyId))
        end
    end
    
    return team
end

-- 主测试函数
local function main()
    Log("开始测试模拟器...")
    Log(string.rep("=", 50))
    
    -- 初始化数据
    Log("初始化数据模块...")
    local success, err = pcall(function()
        AllyData.Init()
        EnemyData.Init()
    end)
    
    if not success then
        LogError("初始化失败: " .. tostring(err))
        return false
    end
    LogSuccess("数据模块初始化成功")
    
    -- 创建阵容
    Log("\n创建战斗阵容...")
    local leftTeam = CreateSimpleHeroTeam()
    local rightTeam = CreateSimpleEnemyTeam()
    
    if #leftTeam == 0 or #rightTeam == 0 then
        LogError("阵容创建失败")
        return false
    end
    
    LogSuccess(string.format("阵容创建成功: 左侧%d人, 右侧%d人", #leftTeam, #rightTeam))
    
    -- 创建战斗模拟器
    Log("\n创建战斗模拟器...")
    local simulator = BattleSimulator.new()
    if not simulator then
        LogError("战斗模拟器创建失败")
        return false
    end
    LogSuccess("战斗模拟器创建成功")
    
    -- 初始化战斗
    Log("\n初始化战斗...")
    local battleConfig = {
        leftTeam = leftTeam,
        rightTeam = rightTeam,
        maxRounds = 30,
        seed = 12345
    }
    
    success, err = pcall(function()
        simulator:Init(battleConfig)
    end)
    
    if not success then
        LogError("战斗初始化失败: " .. tostring(err))
        return false
    end
    LogSuccess("战斗初始化成功")
    
    -- 运行战斗
    Log("\n运行战斗模拟...")
    local result
    success, result = pcall(function()
        return simulator:Run()
    end)
    
    if not success then
        LogError("战斗运行失败: " .. tostring(result))
        return false
    end
    
    -- 显示结果
    Log("\n战斗结果:")
    Log(string.format("  获胜方: %s", result.winner or "未知"))
    Log(string.format("  战斗回合: %d", result.rounds or 0))
    Log(string.format("  存活单位 - 左侧: %d, 右侧: %d", 
        result.leftAlive or 0, result.rightAlive or 0))
    
    LogSuccess("战斗模拟完成!")
    
    Log("\n" .. string.rep("=", 50))
    Log("模拟器测试通过!")
    Log(string.rep("=", 50))
    
    return true
end

-- 运行测试
local success = main()
os.exit(success and 0 or 1)
