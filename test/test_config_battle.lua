#!/usr/bin/env lua

---============================================================================
--- 使用项目配置的战斗测试
--- 使用 ally_data 和 spell 配置进行战斗
---============================================================================

local ConfigBattleTest = {}

function ConfigBattleTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    print("\n========================================")
    print("    项目配置战斗测试")
    print("========================================\n")

    -- 加载核心模块
    require("core.battle_enum")
    local BattleMain = require("modules.battle_main")
    local BattleFormation = require("modules.battle_formation")
    local BattleAttribute = require("modules.battle_attribute")
    local BattleSkill = require("modules.battle_skill")
    local Logger = require("utils.logger")
    local AllyData = require("config.ally_data")
    local EnemyData = require("config.enemy_data")
    local SkillLoader = require("core.skill_loader")

    -- ==================== 加载英雄配置 ====================
    print("[步骤1] 从配置加载英雄...")
    
    -- 获取可玩英雄列表
    local playableHeroes = AllyData.GetPlayableHeroes()
    print(string.format("  找到 %d 个可玩英雄", #playableHeroes))
    
    -- 选择前3个英雄作为左侧队伍
    local leftHeroes = {}
    for i = 1, math.min(3, #playableHeroes) do
        local hero = playableHeroes[i]
        local heroData = AllyData.ConvertToHeroData(hero.AllyID, 50, 5)  -- 50级5星
        if heroData then
            print(string.format("  左侧英雄 %d: %s (ATK:%d, DEF:%d, HP:%d)",
                i, heroData.name, heroData.atk, heroData.def, heroData.maxHp))
            
            -- 打印技能信息
            print(string.format("    技能数量: %d", #heroData.skills))
            for _, skill in ipairs(heroData.skills) do
                print(string.format("      - SkillID: %d, Level: %d", skill.id, skill.level))
            end
            
            table.insert(leftHeroes, heroData)
        end
    end
    
    -- ==================== 转换英雄数据为战斗格式 ====================
    print("\n[步骤2] 转换英雄数据为战斗格式...")
    
    local function ConvertToBattleHero(heroData, teamSide)
        -- 构建技能配置
        local skillsConfig = {}
        
        -- 添加普通攻击（默认）
        table.insert(skillsConfig, {
            skillId = 10000,  -- 默认普通攻击技能ID
            skillType = E_SKILL_TYPE_NORMAL,
            name = "普通攻击",
            coolDown = 0,
        })
        
        -- 从英雄配置加载技能（简化版：为每个技能创建默认配置）
        for i, skillInfo in ipairs(heroData.skills or {}) do
            local skillId = skillInfo.id
            local skillLevel = skillInfo.level
            
            -- 尝试加载技能配置
            local spellConfig = SkillLoader.LoadSkillConfig(skillId)
            local skillName = "技能" .. skillId
            local damageRate = 150 + (skillLevel - 1) * 10  -- 简化：基础150%，每级增加10%
            local coolDown = 2  -- 固定2回合冷却
            
            if spellConfig then
                local varName = "spell_" .. tostring(skillId)
                local spellData = spellConfig[varName]
                
                if spellData then
                    -- 解析技能数据
                    skillName = spellData.Name or skillName
                    
                    -- 从Trigger中读取伤害数据
                    if spellData.Trigger and spellData.Trigger.damageData then
                        -- 这里可以根据配置解析具体数值
                        damageRate = 150 + (skillLevel - 1) * 10
                    end
                    
                    print(string.format("    从配置加载技能: %s (ID:%d, Level:%d, 伤害:%d%%)",
                        skillName, skillId, skillLevel, damageRate))
                else
                    print(string.format("    使用默认技能: %s (ID:%d, Level:%d, 伤害:%d%%) - 配置数据为空",
                        skillName, skillId, skillLevel, damageRate))
                end
            else
                print(string.format("    使用默认技能: %s (ID:%d, Level:%d, 伤害:%d%%) - 配置文件不存在",
                    skillName, skillId, skillLevel, damageRate))
            end
            
            -- 添加技能配置（大招）
            table.insert(skillsConfig, {
                skillId = skillId,
                skillType = E_SKILL_TYPE_ULTIMATE,
                name = skillName,
                coolDown = coolDown,
                damageData = {
                    damageRate = damageRate,
                },
            })
        end
        
        return {
            configId = heroData.id,
            name = heroData.name,
            level = heroData.level,
            wpType = heroData.class or 1,
            
            hp = heroData.hp,
            maxHp = heroData.maxHp,
            atk = heroData.atk,
            def = heroData.def,
            speed = 100 + (heroData.quality or 1) * 20,  -- 根据品质计算速度
            
            critRate = 2000,
            critDamage = 15000,
            hitRate = 10000,
            dodgeRate = 500,
            
            energy = 0,
            maxEnergy = 100,
            energyType = E_ENERGY_TYPE.Bar,
            
            skillsConfig = skillsConfig,
            passiveSkills = {},
            
            isAlive = true,
            isDead = false,
        }
    end
    
    -- 转换左侧队伍
    local leftBattleHeroes = {}
    for _, heroData in ipairs(leftHeroes) do
        table.insert(leftBattleHeroes, ConvertToBattleHero(heroData, "left"))
    end
    
    -- 创建右侧敌人队伍（使用敌人配置）
    local rightBattleHeroes = {}
    local allEnemies = EnemyData.GetAllEnemies()
    for i = 1, math.min(3, #allEnemies) do
        local enemy = allEnemies[i]
        local enemyData = EnemyData.ConvertToHeroData(enemy.ID)
        if enemyData then
            -- 简化敌人技能配置
            local enemySkills = {
                {
                    skillId = 10000,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "普通攻击",
                    coolDown = 0,
                },
                {
                    skillId = 200000 + i,
                    skillType = E_SKILL_TYPE_ULTIMATE,
                    name = "敌人技能" .. i,
                    coolDown = 3,
                    damageData = {
                        damageRate = 120 + i * 20,
                    },
                },
            }
            
            table.insert(rightBattleHeroes, {
                configId = enemyData.id,
                name = enemyData.name or ("敌人" .. i),
                level = enemyData.level or 50,
                wpType = enemyData.wpType or 1,
                
                hp = enemyData.hp or 5000,
                maxHp = enemyData.maxHp or 5000,
                atk = enemyData.atk or 400,
                def = enemyData.def or 200,
                speed = enemyData.speed or 100,
                
                critRate = 1500,
                critDamage = 13000,
                hitRate = 10000,
                dodgeRate = 300,
                
                energy = 0,
                maxEnergy = 100,
                energyType = E_ENERGY_TYPE.Bar,
                
                skillsConfig = enemySkills,
                passiveSkills = {},
                
                isAlive = true,
                isDead = false,
            })
        end
    end
    
    print(string.format("\n  左侧队伍: %d 名英雄", #leftBattleHeroes))
    print(string.format("  右侧队伍: %d 名敌人", #rightBattleHeroes))
    
    -- ==================== 启动战斗 ====================
    print("\n[步骤3] 启动战斗...")
    print("============================================")
    print("            战斗开始！")
    print("============================================\n")
    
    -- 创建战斗开始状态
    local battleBeginState = {
        teamLeft = leftBattleHeroes,
        teamRight = rightBattleHeroes,
        seedArray = { 12345, 67890, 11111, 22222 },
    }
    
    -- 战斗结束回调
    local finalResult = nil
    local function OnBattleEnd(result)
        finalResult = result
    end
    
    -- 启动战斗
    BattleMain.Start(battleBeginState, OnBattleEnd)
    BattleMain.SetUpdateInterval(0)
    
    -- ==================== 战斗主循环 ====================
    print("[步骤4] 开始战斗主循环...\n")
    
    local maxUpdates = 500
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
    
    -- ==================== 战斗结果 ====================
    print("\n[步骤5] 战斗结果统计：")
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
    
    -- ==================== 清理 ====================
    print("\n[步骤6] 清理战斗资源...")
    BattleMain.Quit()
    
    print("\n========================================")
    print("        项目配置战斗测试完成")
    print("========================================\n")
    
    return finalResult
end

-- 如果是直接运行此文件，则执行测试
if arg and arg[0] and arg[0]:match("test_config_battle%.lua$") then
    ConfigBattleTest.Run()
end

return ConfigBattleTest
