#!/usr/bin/env lua

---============================================================================
--- 使用项目接口的战斗测试
--- Battle Test using Project Interfaces
---============================================================================

-- 获取脚本所在目录并设置包路径
local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
script_dir = script_dir:gsub("test/", "")  -- 回到上级目录

-- 设置 Lua 包路径
package.path = package.path
    .. ";" .. script_dir .. "?.lua"
    .. ";" .. script_dir .. "core/?.lua"
    .. ";" .. script_dir .. "modules/?.lua"
    .. ";" .. script_dir .. "config/?.lua"
    .. ";" .. script_dir .. "utils/?.lua"
    .. ";" .. script_dir .. "Assets/Lua/Modules/Battle/SkillNewLua/?.lua"
    .. ";" .. script_dir .. "Assets/Lua/Modules/?.lua"
    .. ";" .. script_dir .. "Assets/Lua/?.lua"

local InterfaceBattleTest = {}

function InterfaceBattleTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    print("\n========================================")
    print("    使用项目接口的战斗测试")
    print("========================================\n")

    -- 加载核心模块
    require("core.battle_enum")
    local BattleMain = require("modules.battle_main")
    local BattleFormation = require("modules.battle_formation")
    local BattleAttribute = require("modules.battle_attribute")
    local BattleSkill = require("modules.battle_skill")
    local HeroData = require("config.hero_data")
    local EnemyData = require("config.enemy_data")
    local AllyData = require("config.ally_data")
    local Logger = require("utils.logger")

    -- ==================== 步骤1: 查看可用英雄 ====================
    print("[步骤1] 查看可用英雄...")
    
    local playableHeroes = AllyData.GetPlayableHeroes()
    print(string.format("  可用英雄数量: %d", #playableHeroes))
    
    -- 显示前5个英雄
    for i = 1, math.min(5, #playableHeroes) do
        local hero = playableHeroes[i]
        local heroData = AllyData.ConvertToHeroData(hero.AllyID, 50, 5)
        print(string.format("  [%d] ID:%d %s (ATK:%d, DEF:%d, HP:%d)",
            i, hero.AllyID, heroData.name, heroData.atk, heroData.def, heroData.hp))
    end
    print("")

    -- ==================== 步骤2: 查看可用敌人 ====================
    print("[步骤2] 查看可用敌人...")
    
    local allEnemies = EnemyData.GetAllEnemies()
    print(string.format("  可用敌人数量: %d", #allEnemies))
    
    -- 显示前5个敌人
    for i = 1, math.min(5, #allEnemies) do
        local enemy = allEnemies[i]
        local heroData = EnemyData.ConvertToHeroData(enemy.ID)
        print(string.format("  [%d] ID:%d %s (Class:%s, Level:%d)",
            i, enemy.ID, heroData.name, heroData._className, heroData._level))
    end
    print("")

    -- ==================== 步骤3: 创建战斗阵容 ====================
    print("[步骤3] 创建战斗阵容...")
    
    -- 使用接口创建左侧队伍（玩家英雄）- 英雄等级比敌人高一倍
    local leftHeroes = {}
    local heroLevel = 100  -- 敌人等级50，英雄等级100
    local heroStar = 5
    
    if #playableHeroes >= 3 then
        for i = 1, 3 do
            local hero = playableHeroes[i]
            local heroData = AllyData.ConvertToHeroData(hero.AllyID, heroLevel, heroStar)
            
            table.insert(leftHeroes, {
                configId = hero.AllyID,
                name = heroData.name,
                level = heroLevel,
                wpType = i,
                
                hp = heroData.hp,
                maxHp = heroData.maxHp,
                atk = heroData.atk,
                def = heroData.def,
                speed = heroData.speed or 100,
                
                critRate = 3000,
                critDamage = 15000,
                hitRate = 10000,
                dodgeRate = 1000,
                
                energy = 0,
                maxEnergy = 100,
                energyType = E_ENERGY_TYPE.Bar,
                
                skillsConfig = {},
                passiveSkills = {},
                
                isAlive = true,
                isDead = false,
            })
            
            -- 添加技能
            for _, skill in ipairs(heroData.skills) do
                table.insert(leftHeroes[#leftHeroes].skillsConfig, {
                    skillId = skill.id,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "技能" .. skill.id,
                })
            end
        end
    end
    
    -- 使用接口创建右侧队伍（敌人）- 选择低等级敌人
    local rightHeroes = {}
    -- 使用等级50的低等级敌人ID
    local enemyIds = {20000, 20001, 20002}  -- Level 50 的敌人
    
    for i = 1, 3 do
        local enemyId = enemyIds[i]
        local heroData = EnemyData.ConvertToHeroData(enemyId)
        
        if heroData then
            table.insert(rightHeroes, {
                configId = enemyId,
                name = heroData.name,
                level = heroData._level,
                wpType = i,
                
                hp = heroData.hp,
                maxHp = heroData.hp,
                atk = heroData.atk,
                def = heroData.def,
                speed = heroData.speed,
                
                critRate = math.floor((heroData.critRate or 0.1) * 10000),
                critDamage = math.floor((heroData.critDmg or 1.5) * 10000),
                hitRate = 10000,
                dodgeRate = 300,
                blockRate = 2000,
                
                energy = 0,
                maxEnergy = 100,
                energyType = E_ENERGY_TYPE.Bar,
                
                skillsConfig = {},
                passiveSkills = {},
                
                isAlive = true,
                isDead = false,
            })
            
            -- 添加技能
            for _, skillId in ipairs(heroData.skills) do
                table.insert(rightHeroes[#rightHeroes].skillsConfig, {
                    skillId = skillId,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "技能" .. skillId,
                })
            end
        end
    end
    
    print(string.format("  左侧队伍: %d 名英雄", #leftHeroes))
    for _, hero in ipairs(leftHeroes) do
        print(string.format("    - %s (ATK:%d, DEF:%d, HP:%d, SPD:%d)",
            hero.name, hero.atk, hero.def, hero.maxHp, hero.speed))
    end
    
    print(string.format("  右侧队伍: %d 名敌人", #rightHeroes))
    for _, hero in ipairs(rightHeroes) do
        print(string.format("    - %s (ATK:%d, DEF:%d, HP:%d, SPD:%d)",
            hero.name, hero.atk, hero.def, hero.maxHp, hero.speed))
    end
    print("")

    -- ==================== 步骤4: 启动战斗 ====================
    print("[步骤4] 启动战斗...")
    print("============================================")
    print("            战斗开始！")
    print("============================================\n")
    
    -- 创建战斗开始状态
    local battleBeginState = {
        teamLeft = leftHeroes,
        teamRight = rightHeroes,
        seedArray = { 12345, 67890, 11111, 22222 },
    }
    
    -- 战斗结束回调
    local finalResult = nil
    local function OnBattleEnd(result)
        finalResult = result
    end
    
    -- 启动战斗
    BattleMain.Start(battleBeginState, OnBattleEnd)
    
    -- 设置更新间隔为0
    BattleMain.SetUpdateInterval(0)
    
    -- ==================== 步骤5: 战斗主循环 ====================
    print("[步骤5] 开始战斗主循环...\n")
    
    local maxUpdates = 1000
    local updateCount = 0
    local battleFinished = false
    
    while updateCount < maxUpdates do
        updateCount = updateCount + 1
        BattleMain.Update()
        
        local result = BattleMain.GetBattleResult()
        if result and result.isFinished then
            battleFinished = true
            break
        end
        
        -- 每50次更新打印进度
        if updateCount % 50 == 0 then
            local round = BattleMain.GetCurrentRound()
            print(string.format("[进度] 更新次数: %d, 当前回合: %d", updateCount, round))
        end
    end
    
    print("\n============================================")
    print("            战斗循环结束")
    print("============================================")
    
    -- ==================== 步骤6: 战斗结果 ====================
    print("\n[步骤6] 战斗结果统计：")
    print("--------------------------------------------")
    
    if battleFinished then
        print(string.format("战斗正常结束！"))
        print(string.format("  获胜方: %s", finalResult.winner or "平局"))
        print(string.format("  结束原因: %s", finalResult.reason or "未知"))
        print(string.format("  总回合数: %d", BattleMain.GetCurrentRound()))
    else
        print(string.format("战斗达到最大更新次数限制 (%d次)，强制结束", maxUpdates))
        print(string.format("  当前回合: %d", BattleMain.GetCurrentRound()))
    end
    
    -- 获取最终状态
    local teamLeft, teamRight = BattleFormation.GetTeams()
    
    print("\n左侧队伍最终状态：")
    for _, hero in ipairs(teamLeft) do
        print(string.format("  %s: HP=%d/%d %s",
            hero.name, hero.hp, hero.maxHp,
            hero.isAlive and "(存活)" or "(死亡)"))
    end
    
    print("\n右侧队伍最终状态：")
    for _, hero in ipairs(teamRight) do
        print(string.format("  %s: HP=%d/%d %s",
            hero.name, hero.hp, hero.maxHp,
            hero.isAlive and "(存活)" or "(死亡)"))
    end
    
    -- ==================== 步骤7: 清理 ====================
    print("\n[步骤7] 清理战斗资源...")
    BattleMain.Quit()
    
    print("\n========================================")
    print("        接口战斗测试完成")
    print("========================================\n")
    
    return finalResult
end

-- 如果是直接运行此文件，则执行测试
if arg and arg[0] and arg[0]:match("test_interface_battle%.lua$") then
    InterfaceBattleTest.Run()
end

return InterfaceBattleTest
