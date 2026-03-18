-- 测试角色配置加载和属性计算
-- 测试英雄和敌人数据的完整性和正确性

-- 切换到项目根目录以便正确加载配置
local oldCwd = os.getenv("PWD") or "."
os.execute("cd ..")
package.path = package.path .. ";./?.lua"

-- 加载必要的模块
require("core.battle_types")
require("core.battle_default_types")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local JSON = require("utils.json")

local function Log(msg)
    print(string.format("[TEST] %s", msg))
end

local function LogError(msg)
    print(string.format("[TEST] [ERROR] %s", msg))
end

local function LogSuccess(msg)
    print(string.format("[TEST] [OK] %s", msg))
end

-- 统计信息
local stats = {
    heroes = { total = 0, tested = 0, errors = {} },
    enemies = { total = 0, tested = 0, errors = {} }
}

-- 测试英雄数据
local function TestHeroes()
    Log("=== 测试英雄角色 ===")
    
    -- 初始化AllyData
    local success, err = pcall(function()
        AllyData.Init()
    end)
    
    if not success then
        LogError("初始化AllyData失败: " .. tostring(err))
        return
    end
    
    -- 获取所有可用英雄
    local heroes = AllyData.GetPlayableHeroes()
    stats.heroes.total = #heroes
    
    Log(string.format("发现 %d 个可用英雄", #heroes))
    
    -- 按职业统计
    local classCount = { [1] = 0, [2] = 0, [3] = 0 }
    local factionCount = {}
    local qualityCount = {}
    
    for _, hero in ipairs(heroes) do
        -- 统计职业
        local class = hero.Class or 1
        classCount[class] = (classCount[class] or 0) + 1
        
        -- 统计阵营
        local faction = hero.Faction or 0
        factionCount[faction] = (factionCount[faction] or 0) + 1
        
        -- 统计品质
        local quality = hero.BaseQuality or hero.Quality or 1
        qualityCount[quality] = (qualityCount[quality] or 0) + 1
        
        -- 测试获取英雄数据
        local heroData = AllyData.GetAlly(hero.AllyID)
        if not heroData then
            table.insert(stats.heroes.errors, { id = hero.AllyID, error = "无法获取英雄数据" })
        else
            stats.heroes.tested = stats.heroes.tested + 1
        end
        
        -- 测试转换为战斗数据
        local battleData, err = AllyData.ConvertToHeroData(hero.AllyID, 60, 5)
        if not battleData then
            table.insert(stats.heroes.errors, { 
                id = hero.AllyID, 
                error = "转换战斗数据失败: " .. tostring(err) 
            })
        end
    end
    
    -- 打印统计
    Log("职业分布:")
    Log(string.format("  前排(Class=1): %d", classCount[1] or 0))
    Log(string.format("  中排(Class=2): %d", classCount[2] or 0))
    Log(string.format("  后排(Class=3): %d", classCount[3] or 0))
    
    Log("阵营分布:")
    for faction, count in pairs(factionCount) do
        Log(string.format("  Faction=%d: %d", faction, count))
    end
    
    Log("品质分布:")
    for quality = 1, 6 do
        local count = qualityCount[quality] or 0
        if count > 0 then
            local qualityNames = { "普通", "优秀", "精良", "史诗", "传说", "神话" }
            Log(string.format("  %s(Quality=%d): %d", qualityNames[quality] or "未知", quality, count))
        end
    end
    
    -- 打印样本数据
    Log("\n样本英雄数据 (前3个):")
    for i = 1, math.min(3, #heroes) do
        local hero = heroes[i]
        Log(string.format("  [%d] ID=%d, Model=%d, Class=%d, Faction=%d, Quality=%d", 
            i, hero.AllyID, hero.ModelID, hero.Class, hero.Faction, 
            hero.BaseQuality or hero.Quality or 1))
        
        -- 显示技能
        if hero.ParsedSkills and #hero.ParsedSkills > 0 then
            local skillStr = ""
            for _, skill in ipairs(hero.ParsedSkills) do
                skillStr = skillStr .. string.format("[%d:Lv%d] ", skill.skillId, skill.level)
            end
            Log(string.format("      技能: %s", skillStr))
        end
    end
    
    LogSuccess(string.format("英雄测试: %d/%d 成功", stats.heroes.tested, stats.heroes.total))
    if #stats.heroes.errors > 0 then
        LogError(string.format("英雄错误: %d 个", #stats.heroes.errors))
        for _, err in ipairs(stats.heroes.errors) do
            LogError(string.format("  ID=%d: %s", err.id, err.error))
        end
    end
end

-- 测试敌人数据
local function TestEnemies()
    Log("\n=== 测试敌人角色 ===")
    
    -- 初始化EnemyData
    local success, err = pcall(function()
        EnemyData.Init()
    end)
    
    if not success then
        LogError("初始化EnemyData失败: " .. tostring(err))
        return
    end
    
    -- 获取所有敌人ID
    local enemyIds = EnemyData.GetAllEnemyIds()
    stats.enemies.total = #enemyIds
    
    Log(string.format("发现 %d 个敌人", #enemyIds))
    
    -- 按类型统计
    local typeCount = { [0] = 0, [1] = 0, [2] = 0 }
    local classCount = { [1] = 0, [2] = 0, [3] = 0 }
    
    for _, enemyId in ipairs(enemyIds) do
        local enemy = EnemyData.GetEnemy(enemyId)
        if enemy then
            stats.enemies.tested = stats.enemies.tested + 1
            
            -- 统计类型
            local monsterType = enemy.MonsterType or 0
            typeCount[monsterType] = (typeCount[monsterType] or 0) + 1
            
            -- 统计职业
            local class = enemy.Class or 1
            classCount[class] = (classCount[class] or 0) + 1
        else
            table.insert(stats.enemies.errors, { id = enemyId, error = "无法获取敌人数据" })
        end
    end
    
    -- 打印统计
    Log("类型分布:")
    Log(string.format("  普通(MonsterType=0): %d", typeCount[0] or 0))
    Log(string.format("  精英(MonsterType=1): %d", typeCount[1] or 0))
    Log(string.format("  BOSS(MonsterType=2): %d", typeCount[2] or 0))
    
    Log("职业分布:")
    Log(string.format("  前排(Class=1): %d", classCount[1] or 0))
    Log(string.format("  中排(Class=2): %d", classCount[2] or 0))
    Log(string.format("  后排(Class=3): %d", classCount[3] or 0))
    
    -- 打印样本数据
    Log("\n样本敌人数据 (前5个):")
    for i = 1, math.min(5, #enemyIds) do
        local enemyId = enemyIds[i]
        local enemy = EnemyData.GetEnemy(enemyId)
        if enemy then
            local typeNames = { [0] = "普通", [1] = "精英", [2] = "BOSS" }
            Log(string.format("  [%d] ID=%d, Type=%s, Class=%d, Level=%d", 
                i, enemy.ID, typeNames[enemy.MonsterType or 0] or "未知", 
                enemy.Class or 1, enemy.Level or 1))
        end
    end
    
    LogSuccess(string.format("敌人测试: %d/%d 成功", stats.enemies.tested, stats.enemies.total))
    if #stats.enemies.errors > 0 then
        LogError(string.format("敌人错误: %d 个", #stats.enemies.errors))
        for _, err in ipairs(stats.enemies.errors) do
            LogError(string.format("  ID=%d: %s", err.id, err.error))
        end
    end
end

-- 测试特定角色属性
local function TestSpecificCharacters()
    Log("\n=== 测试特定角色属性 ===")
    
    -- 测试几个特定的英雄
    local testHeroIds = { 13101, 13102, 13103, 13104, 13105 }
    Log("测试英雄属性转换:")
    
    for _, heroId in ipairs(testHeroIds) do
        local hero = AllyData.GetAlly(heroId)
        if hero then
            -- 测试不同等级和星级
            for _, level in ipairs({ 1, 60, 100 }) do
                for _, star in ipairs({ 1, 5, 7 }) do
                    local battleData, err = AllyData.ConvertToHeroData(heroId, level, star)
                    if battleData then
                        Log(string.format("  Hero[%d] Lv%d ★%d -> HP=%.0f, ATK=%.0f, DEF=%.0f", 
                            heroId, level, star, 
                            battleData.HP or 0, battleData.ATK or 0, battleData.DEF or 0))
                    else
                        LogError(string.format("  Hero[%d] Lv%d ★%d 转换失败: %s", 
                            heroId, level, star, tostring(err)))
                    end
                end
            end
            Log("") -- 空行分隔
        else
            LogError(string.format("  找不到英雄[%d]", heroId))
        end
    end
    
    -- 测试几个特定的敌人
    local testEnemyIds = { 20701, 20702, 20703 }
    Log("测试敌人属性:")
    
    for _, enemyId in ipairs(testEnemyIds) do
        local enemy = EnemyData.GetEnemy(enemyId)
        if enemy then
            Log(string.format("  Enemy[%d] Level=%d, HP=%d, ATK=%d, DEF=%d", 
                enemyId, enemy.Level or 1, 
                enemy.HP or 0, enemy.ATK or 0, enemy.DEF or 0))
        else
            LogError(string.format("  找不到敌人[%d]", enemyId))
        end
    end
end

-- 打印汇总
local function PrintSummary()
    Log("\n" .. string.rep("=", 50))
    Log("角色配置测试汇总")
    Log(string.rep("=", 50))
    
    Log(string.format("英雄: %d 个可用, %d 个测试成功, %d 个错误", 
        stats.heroes.total, stats.heroes.tested, #stats.heroes.errors))
    Log(string.format("敌人: %d 个总数, %d 个测试成功, %d 个错误", 
        stats.enemies.total, stats.enemies.tested, #stats.enemies.errors))
    
    local totalErrors = #stats.heroes.errors + #stats.enemies.errors
    if totalErrors == 0 then
        Log("状态: ✓ 所有角色配置测试通过!")
    else
        Log(string.format("状态: ✗ 发现 %d 个错误", totalErrors))
    end
    
    Log(string.rep("=", 50))
end

-- 主函数
local function main()
    Log("开始测试角色配置...")
    Log(string.rep("=", 50))
    
    TestHeroes()
    TestEnemies()
    TestSpecificCharacters()
    PrintSummary()
    
    Log("\n测试完成!")
end

main()
