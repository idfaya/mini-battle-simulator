--[[
    随机战斗测试脚本
    使用方法: lua test_random_battle.lua [等级] [英雄数量] [敌人数量]
    示例: lua test_random_battle.lua 60 3 4
--]]

-- 设置UTF-8编码
os.execute("chcp 65001 >nul 2>&1")

-- 添加上级目录到路径
package.path = package.path .. ";../?.lua"

-- 解析命令行参数
local targetLevel = tonumber(arg[1]) or 60
local heroCount = tonumber(arg[2]) or 3
local enemyCount = tonumber(arg[3]) or 4

print(string.format("=== 随机战斗测试 (等级 %d) ===", targetLevel))
print(string.format("英雄数量: %d, 敌人数量: %d", heroCount, enemyCount))
print("")

-- 加载必要模块
require("core.battle_enum")
local AllyData = require("config.ally_data")
local EnemyData = require("config.enemy_data")
local BattleMain = require("modules.battle_main")
local SkillData = require("config.skill_data")

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

-- 从res_enemy_info.json加载敌人ID
local function LoadAllEnemyIds()
    local JSON = require("utils.json")
    local file = io.open("../config/res_enemy_info.json", "r")
    if file then
        local content = file:read("*a")
        file:close()
        local data = JSON.JsonDecode(content)
        for _, enemy in ipairs(data) do
            table.insert(allEnemyIds, enemy.ID)
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
    
    -- 获取英雄技能
    local relationConfigId = heroData.config and heroData.config.RelationConfigID or heroId
    heroData.skillsConfig = {}
    
    for i = 1, 5 do
        local skillClassId = relationConfigId * 100 + i
        local skills = SkillData.GetSkillsByClass(skillClassId)
        
        for _, skill in ipairs(skills) do
            table.insert(heroData.skillsConfig, {
                skillId = skill.ID,
                skillType = skill.Type == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL,
                name = skill.Name,
                skillCost = skill.Type == 2 and 100 or 0
            })
        end
    end
    
    return heroData
end

-- 创建敌人数据
local function CreateEnemy(enemyId, level)
    local enemyData = EnemyData.ConvertToEnemyData(enemyId, level)
    if not enemyData then return nil end
    
    local enemyConfig = EnemyData.GetEnemyConfig(enemyId)
    enemyData.skillsConfig = {}
    
    if enemyConfig and enemyConfig.Skill then
        for _, skillId in ipairs(enemyConfig.Skill) do
            if skillId > 0 then
                local skillConfig = SkillData.GetSkill(skillId)
                if skillConfig then
                    table.insert(enemyData.skillsConfig, {
                        skillId = skillId,
                        skillType = skillConfig.Type == 2 and E_SKILL_TYPE_ULTIMATE or E_SKILL_TYPE_NORMAL,
                        name = skillConfig.Name,
                        skillCost = skillConfig.Type == 2 and 100 or 0
                    })
                end
            end
        end
    end
    
    return enemyData
end

-- 主函数
local function Main()
    math.randomseed(os.time())
    
    LoadAllHeroIds()
    LoadAllEnemyIds()
    
    print(string.format("可用英雄: %d, 可用敌人: %d", #allHeroIds, #allEnemyIds))
    print("")
    
    if #allHeroIds == 0 or #allEnemyIds == 0 then
        print("错误: 无法加载英雄或敌人配置")
        return
    end
    
    -- 随机选择
    local selectedHeroIds = RandomSelect(allHeroIds, heroCount)
    local selectedEnemyIds = RandomSelect(allEnemyIds, enemyCount)
    
    -- 创建英雄阵容
    local heroes = {}
    print("【英雄阵容】")
    for i, heroId in ipairs(selectedHeroIds) do
        local level = targetLevel + math.random(-5, 5)
        if level < 1 then level = 1 end
        local star = math.random(3, 5)
        local hero = CreateHero(heroId, level, star)
        if hero then
            table.insert(heroes, hero)
            print(string.format("  %d. %s (Lv.%d ★%d) HP:%d ATK:%d DEF:%d SPD:%d", 
                i, hero.name, level, star, hero.maxHp, hero.atk, hero.def, hero.spd))
        end
    end
    
    -- 创建敌人阵容
    local enemies = {}
    print("\n【敌人阵容】")
    for i, enemyId in ipairs(selectedEnemyIds) do
        local level = targetLevel + math.random(-5, 5)
        if level < 1 then level = 1 end
        local enemy = CreateEnemy(enemyId, level)
        if enemy then
            table.insert(enemies, enemy)
            print(string.format("  %d. %s (Lv.%d) HP:%d ATK:%d DEF:%d SPD:%d", 
                i, enemy.name, level, enemy.maxHp, enemy.atk, enemy.def, enemy.spd))
        end
    end
    
    print("\n" .. string.rep("=", 50))
    
    -- 执行战斗
    local result = BattleMain.Start(heroes, enemies)
    
    -- 输出结果
    print("\n【战斗结果】")
    if result.winner == "left" then
        print("✓ 英雄方胜利!")
    elseif result.winner == "right" then
        print("✗ 敌人方胜利!")
    else
        print("△ 战斗平局!")
    end
    
    print(string.format("\n总回合数: %d", result.roundCount))
    print(string.format("存活英雄: %d/%d", result.leftAlive, result.leftTotal))
    print(string.format("存活敌人: %d/%d", result.rightAlive, result.rightTotal))
end

Main()
