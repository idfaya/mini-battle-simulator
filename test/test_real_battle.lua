#!/usr/bin/env lua

---============================================================================
--- 使用原项目配置的真实战斗测试
--- Real Battle Test with Original Project Configs
---============================================================================

local RealBattleTest = {}

function RealBattleTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    print("\n========================================")
    print("    使用原项目配置的战斗测试")
    print("========================================\n")

    -- 加载核心模块
    require("core.battle_enum")
    local BattleMain = require("modules.battle_main")
    local BattleFormation = require("modules.battle_formation")
    local BattleAttribute = require("modules.battle_attribute")
    local BattleSkill = require("modules.battle_skill")
    local SkillLoader = require("core.skill_loader")
    local Logger = require("utils.logger")

    -- 日志级别使用默认设置

    -- ==================== 步骤1: 加载英雄配置 ====================
    print("[步骤1] 加载英雄配置...")
    
    -- 使用原项目的英雄配置
    local heroConfig1 = require("config.hero.hero_1001")  -- 烈焰战士
    local heroConfig2 = require("config.hero.hero_2001")  -- 钢铁守卫
    
    local heroData1 = heroConfig1.hero_1001
    local heroData2 = heroConfig2.hero_2001
    
    print(string.format("✓ 加载英雄: %s (ID: %d)", heroData1.Name, heroData1.Id))
    print(string.format("✓ 加载英雄: %s (ID: %d)", heroData2.Name, heroData2.Id))
    print("")

    -- ==================== 步骤2: 加载技能配置 ====================
    print("[步骤2] 加载技能配置...")
    
    -- 获取英雄的技能ID列表
    local skillIds1 = heroData1.Skill or {}
    local skillIds2 = heroData2.Skill or {}
    
    print(string.format("  %s 拥有 %d 个技能", heroData1.Name, #skillIds1))
    print(string.format("  %s 拥有 %d 个技能", heroData2.Name, #skillIds2))
    
    -- 加载第一个技能配置作为示例
    if #skillIds1 > 0 then
        local skillConfig1 = SkillLoader.LoadSkillConfig(skillIds1[1])
        if skillConfig1 then
            local varName = "spell_" .. skillIds1[1]
            local spellData = skillConfig1[varName]
            if spellData then
                print(string.format("  ✓ 技能示例: %s (ID: %d)", spellData.Name or "Unknown", skillIds1[1]))
            end
        end
    end
    print("")

    -- ==================== 步骤3: 创建战斗英雄 ====================
    print("[步骤3] 创建战斗英雄...")
    
    -- 创建左侧英雄
    local hero_left = {
        configId = heroData1.Id,
        name = heroData1.Name,
        level = 50,
        wpType = 1,
        
        -- 基础属性
        hp = heroData1.Hp or 5000,
        maxHp = heroData1.Hp or 5000,
        atk = heroData1.Atk or 800,
        def = heroData1.Def or 300,
        speed = heroData1.Speed or 120,
        
        -- 战斗属性
        critRate = heroData1.Crit or 2000,
        critDamage = heroData1.CritDamage or 15000,
        hitRate = heroData1.Hit or 10000,
        dodgeRate = heroData1.Dodge or 500,
        
        -- 能量
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        -- 技能配置
        skillsConfig = {},
        passiveSkills = {},
        
        isAlive = true,
        isDead = false,
    }
    
    -- 创建右侧英雄
    local hero_right = {
        configId = heroData2.Id,
        name = heroData2.Name,
        level = 50,
        wpType = 1,
        
        hp = heroData2.Hp or 8000,
        maxHp = heroData2.Hp or 8000,
        atk = heroData2.Atk or 500,
        def = heroData2.Def or 500,
        speed = heroData2.Speed or 100,
        
        critRate = heroData2.Crit or 1000,
        critDamage = heroData2.CritDamage or 15000,
        hitRate = heroData2.Hit or 10000,
        dodgeRate = heroData2.Dodge or 300,
        blockRate = heroData2.Block or 2000,
        
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        skillsConfig = {},
        passiveSkills = {},
        
        isAlive = true,
        isDead = false,
    }
    
    -- 构建技能配置
    for _, skillId in ipairs(skillIds1) do
        if skillId > 0 then
            table.insert(hero_left.skillsConfig, {
                skillId = skillId,
                skillType = E_SKILL_TYPE_NORMAL,
                name = "技能" .. skillId,
            })
        end
    end
    
    for _, skillId in ipairs(skillIds2) do
        if skillId > 0 then
            table.insert(hero_right.skillsConfig, {
                skillId = skillId,
                skillType = E_SKILL_TYPE_NORMAL,
                name = "技能" .. skillId,
            })
        end
    end
    
    print(string.format("  左侧英雄: %s (HP:%d, ATK:%d, DEF:%d, SPD:%d)",
        hero_left.name, hero_left.maxHp, hero_left.atk, hero_left.def, hero_left.speed))
    print(string.format("  右侧英雄: %s (HP:%d, ATK:%d, DEF:%d, SPD:%d)",
        hero_right.name, hero_right.maxHp, hero_right.atk, hero_right.def, hero_right.speed))
    print("")

    -- ==================== 步骤4: 启动战斗 ====================
    print("[步骤4] 启动战斗...")
    print("============================================")
    print("            战斗开始！")
    print("============================================\n")
    
    -- 创建战斗开始状态
    local battleBeginState = {
        teamLeft = { hero_left },
        teamRight = { hero_right },
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
    print("        真实战斗测试完成")
    print("========================================\n")
    
    return finalResult
end

return RealBattleTest
