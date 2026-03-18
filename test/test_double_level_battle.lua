#!/usr/bin/env lua

---============================================================================
--- 100级英雄 vs 100级敌人 5v5 战斗测试
--- 使用配置文件中实际存在的英雄和敌人数据
--- 英雄等级 = 敌人等级 = 100
---============================================================================

local DoubleLevelBattleTest = {}

function DoubleLevelBattleTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    print("\n========================================")
    print("    100级英雄 vs 100级敌人 5v5 战斗测试")
    print("    (使用配置文件中的实际数据)")
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

    -- ==================== 配置 ====================
    local BATTLE_LEVEL = 100  -- 战斗等级（英雄和敌人都用100级）
    local HERO_LEVEL = BATTLE_LEVEL
    local ENEMY_BASE_LEVEL = BATTLE_LEVEL
    
    -- 使用配置文件中实际存在的英雄ID (5个)
    local HERO_IDS = {13101, 13102, 13103, 13104, 13105}  -- 从 res_ally_info.json 中选择
    -- 使用配置文件中实际存在的普通敌人ID (MonsterType=0) (5个)
    local ENEMY_IDS = {20701, 20702, 20703, 20704, 20705}  -- 从 res_enemy.json 中选择普通怪物
    
    print(string.format("[配置] 战斗等级: %d", BATTLE_LEVEL))
    print(string.format("[英雄ID] %s", table.concat(HERO_IDS, ", ")))
    print(string.format("[敌人ID] %s", table.concat(ENEMY_IDS, ", ")))
    print("")

    -- ==================== 加载英雄配置 ====================
    print("[步骤1] 从配置加载英雄 (等级 " .. HERO_LEVEL .. ")...")
    
    local leftHeroes = {}
    for i, allyId in ipairs(HERO_IDS) do
        local heroData = AllyData.ConvertToHeroData(allyId, HERO_LEVEL, 5)  -- 2倍等级，5星
        if heroData then
            print(string.format("  左侧英雄 %d: %s (Lv.%d, ATK:%d, DEF:%d, HP:%d)",
                i, heroData.name, heroData.level, heroData.atk, heroData.def, heroData.maxHp))
            
            -- 打印技能信息
            print(string.format("    技能数量: %d", #heroData.skills))
            for _, skill in ipairs(heroData.skills) do
                print(string.format("      - SkillID: %d, Level: %d", skill.id, skill.level))
            end
            
            table.insert(leftHeroes, heroData)
        else
            print(string.format("  [错误] 无法加载英雄 %d", allyId))
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
        
        -- 从英雄配置加载技能
        for i, skillInfo in ipairs(heroData.skills or {}) do
            local skillId = skillInfo.id
            local skillLevel = skillInfo.level
            
            -- 尝试加载技能配置
            local spellConfig = SkillLoader.LoadSkillConfig(skillId)
            local skillName = "技能" .. skillId
            local damageRate = 150 + (skillLevel - 1) * 10
            local coolDown = 2
            
            if spellConfig then
                local varName = "spell_" .. tostring(skillId)
                local spellData = spellConfig[varName]
                
                if spellData then
                    skillName = spellData.Name or skillName
                    print(string.format("    从配置加载技能: %s (ID:%d, Level:%d, 伤害:%d%%)",
                        skillName, skillId, skillLevel, damageRate))
                else
                    print(string.format("    使用默认技能: %s (ID:%d, Level:%d, 伤害:%d%%)",
                        skillName, skillId, skillLevel, damageRate))
                end
            else
                print(string.format("    使用默认技能: %s (ID:%d, Level:%d, 伤害:%d%%)",
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
            speed = 100 + (heroData.quality or 1) * 20,
            
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
    
    -- ==================== 加载敌人配置 ====================
    print("\n[步骤3] 从配置加载敌人 (等级 " .. ENEMY_BASE_LEVEL .. ")...")
    local rightBattleHeroes = {}
    
    for i, enemyId in ipairs(ENEMY_IDS) do
        local enemy = EnemyData.GetEnemy(enemyId)
        if enemy then
            -- 使用ConvertToHeroData并指定等级
            local enemyData = EnemyData.ConvertToHeroData(enemyId)
            if enemyData then
                -- 根据等级调整敌人属性
                local levelRatio = ENEMY_BASE_LEVEL / (enemyData._level or 50)
                enemyData.level = ENEMY_BASE_LEVEL
                enemyData.atk = math.floor(enemyData.atk * levelRatio)
                enemyData.def = math.floor(enemyData.def * levelRatio)
                enemyData.hp = math.floor(enemyData.hp * levelRatio)
                enemyData.maxHp = enemyData.hp
                
                print(string.format("  右侧敌人 %d: %s (Lv.%d, ATK:%d, DEF:%d, HP:%d, 类型:%s)",
                    i, enemyData.name, enemyData.level, 
                    enemyData.atk, enemyData.def, enemyData.maxHp,
                    enemyData._monsterTypeName or "未知"))
                
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
                    level = enemyData.level,
                    wpType = enemyData.wpType or 1,
                    
                    hp = enemyData.hp,
                    maxHp = enemyData.maxHp,
                    atk = enemyData.atk,
                    def = enemyData.def,
                    speed = enemyData.speed or 100,
                    
                    critRate = 1000,
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
            else
                print(string.format("  [错误] 无法转换敌人 %d", enemyId))
            end
        else
            print(string.format("  [错误] 无法找到敌人 %d", enemyId))
        end
    end
    
    print(string.format("\n  左侧队伍: %d 名英雄 (等级 %d)", #leftBattleHeroes, HERO_LEVEL))
    print(string.format("  右侧队伍: %d 名敌人 (等级 %d)", #rightBattleHeroes, ENEMY_BASE_LEVEL))
    
    -- 计算总战力对比
    local leftTotalAtk = 0
    local leftTotalHp = 0
    local rightTotalAtk = 0
    local rightTotalHp = 0
    
    for _, hero in ipairs(leftBattleHeroes) do
        leftTotalAtk = leftTotalAtk + hero.atk
        leftTotalHp = leftTotalHp + hero.maxHp
    end
    
    for _, enemy in ipairs(rightBattleHeroes) do
        rightTotalAtk = rightTotalAtk + enemy.atk
        rightTotalHp = rightTotalHp + enemy.maxHp
    end
    
    print(string.format("\n[战力对比]"))
    print(string.format("  左侧队伍: 总ATK=%d, 总HP=%d", leftTotalAtk, leftTotalHp))
    print(string.format("  右侧队伍: 总ATK=%d, 总HP=%d", rightTotalAtk, rightTotalHp))
    if rightTotalAtk > 0 and rightTotalHp > 0 then
        print(string.format("  攻击比: %.1f:1, 生命比: %.1f:1", 
            leftTotalAtk / rightTotalAtk, leftTotalHp / rightTotalHp))
    end
    
    -- ==================== 启动战斗 ====================
    print("\n[步骤4] 启动战斗...")
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
    print("[步骤5] 开始战斗主循环...\n")
    
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
    
    print("\n左侧队伍最终状态（100级英雄）：")
    for _, hero in ipairs(teamLeft) do
        print(string.format("  %s (Lv.%d): HP=%d/%d %s",
            hero.name, hero.level, hero.hp, hero.maxHp,
            hero.isAlive and "(存活)" or "(死亡)"))
    end
    
    print("\n右侧队伍最终状态（100级敌人）：")
    for _, hero in ipairs(teamRight) do
        print(string.format("  %s (Lv.%d): HP=%d/%d %s",
            hero.name, hero.level, hero.hp, hero.maxHp,
            hero.isAlive and "(存活)" or "(死亡)"))
    end
    
    -- ==================== 清理 ====================
    print("\n[步骤7] 清理战斗资源...")
    BattleMain.Quit()
    
    print("\n========================================")
    print("        100级战斗测试完成")
    print("========================================\n")
    
    return finalResult
end

-- 如果是直接运行此文件，则执行测试
if arg and arg[0] and arg[0]:match("test_double_level_battle%.lua$") then
    DoubleLevelBattleTest.Run()
end

return DoubleLevelBattleTest
