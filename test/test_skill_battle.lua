#!/usr/bin/env lua

---============================================================================
--- 技能系统战斗测试
--- 测试技能释放、冷却、伤害效果
---============================================================================

local SkillBattleTest = {}

function SkillBattleTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    print("\n========================================")
    print("    技能系统战斗测试")
    print("========================================\n")

    -- 加载核心模块
    require("core.battle_enum")
    local BattleMain = require("modules.battle_main")
    local BattleFormation = require("modules.battle_formation")
    local BattleAttribute = require("modules.battle_attribute")
    local BattleSkill = require("modules.battle_skill")
    local Logger = require("utils.logger")

    -- ==================== 创建带技能的英雄 ====================
    print("[步骤1] 创建带技能的英雄...")
    
    local leftHeroes = {
        {
            configId = 1001,
            name = "技能测试英雄",
            level = 50,
            wpType = 1,
            
            hp = 5000,
            maxHp = 5000,
            atk = 500,
            def = 200,
            speed = 150,
            
            critRate = 2000,
            critDamage = 15000,
            hitRate = 10000,
            dodgeRate = 500,
            
            energy = 0,
            maxEnergy = 100,
            energyType = E_ENERGY_TYPE.Bar,
            
            -- 配置多个技能
            skillsConfig = {
                {
                    skillId = 1001,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "普通攻击",
                    coolDown = 0,
                    damageData = {
                        damageRate = 100,  -- 100%攻击力
                    },
                },
                {
                    skillId = 2001,
                    skillType = E_SKILL_TYPE_ULTIMATE,
                    name = "强力一击",
                    coolDown = 2,  -- 2回合冷却
                    damageData = {
                        damageRate = 200,  -- 200%攻击力
                    },
                },
                {
                    skillId = 2002,
                    skillType = E_SKILL_TYPE_ULTIMATE,
                    name = "群体攻击",
                    coolDown = 3,  -- 3回合冷却
                    damageData = {
                        damageRate = 150,  -- 150%攻击力
                        isAoE = true,  -- 群体攻击
                    },
                },
            },
            passiveSkills = {},
            
            isAlive = true,
            isDead = false,
        },
        {
            configId = 1002,
            name = "辅助英雄",
            level = 50,
            wpType = 2,
            
            hp = 4000,
            maxHp = 4000,
            atk = 300,
            def = 150,
            speed = 120,
            
            critRate = 1000,
            critDamage = 12000,
            hitRate = 10000,
            dodgeRate = 300,
            
            energy = 0,
            maxEnergy = 100,
            energyType = E_ENERGY_TYPE.Bar,
            
            skillsConfig = {
                {
                    skillId = 1001,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "普通攻击",
                    coolDown = 0,
                    damageData = {
                        damageRate = 100,
                    },
                },
                {
                    skillId = 3001,
                    skillType = E_SKILL_TYPE_ULTIMATE,
                    name = "治疗术",
                    coolDown = 2,
                    healData = {
                        healRate = 150,  -- 150%攻击力治疗
                    },
                },
            },
            passiveSkills = {},
            
            isAlive = true,
            isDead = false,
        },
    }
    
    local rightHeroes = {
        {
            configId = 2001,
            name = "敌方前排",
            level = 50,
            wpType = 1,
            
            hp = 6000,
            maxHp = 6000,
            atk = 400,
            def = 300,
            speed = 100,
            
            critRate = 1500,
            critDamage = 13000,
            hitRate = 10000,
            dodgeRate = 200,
            blockRate = 2000,
            
            energy = 0,
            maxEnergy = 100,
            energyType = E_ENERGY_TYPE.Bar,
            
            skillsConfig = {
                {
                    skillId = 1001,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "普通攻击",
                    coolDown = 0,
                    damageData = {
                        damageRate = 100,
                    },
                },
            },
            passiveSkills = {},
            
            isAlive = true,
            isDead = false,
        },
        {
            configId = 2002,
            name = "敌方后排",
            level = 50,
            wpType = 2,
            
            hp = 3500,
            maxHp = 3500,
            atk = 600,
            def = 100,
            speed = 130,
            
            critRate = 2500,
            critDamage = 16000,
            hitRate = 10000,
            dodgeRate = 400,
            
            energy = 0,
            maxEnergy = 100,
            energyType = E_ENERGY_TYPE.Bar,
            
            skillsConfig = {
                {
                    skillId = 1001,
                    skillType = E_SKILL_TYPE_NORMAL,
                    name = "普通攻击",
                    coolDown = 0,
                    damageData = {
                        damageRate = 100,
                    },
                },
                {
                    skillId = 2003,
                    skillType = E_SKILL_TYPE_ULTIMATE,
                    name = "暴击射击",
                    coolDown = 2,
                    damageData = {
                        damageRate = 180,
                        critBonus = 5000,  -- 额外50%暴击率
                    },
                },
            },
            passiveSkills = {},
            
            isAlive = true,
            isDead = false,
        },
    }
    
    print(string.format("  左侧队伍: %d 名英雄", #leftHeroes))
    for _, hero in ipairs(leftHeroes) do
        print(string.format("    - %s (ATK:%d, DEF:%d, HP:%d, SPD:%d)",
            hero.name, hero.atk, hero.def, hero.maxHp, hero.speed))
        print(string.format("      技能: %d 个", #hero.skillsConfig))
        for _, skill in ipairs(hero.skillsConfig) do
            print(string.format("        - %s (ID:%d, CD:%d)",
                skill.name, skill.skillId, skill.coolDown or 0))
        end
    end
    
    print(string.format("  右侧队伍: %d 名敌人", #rightHeroes))
    for _, hero in ipairs(rightHeroes) do
        print(string.format("    - %s (ATK:%d, DEF:%d, HP:%d, SPD:%d)",
            hero.name, hero.atk, hero.def, hero.maxHp, hero.speed))
        print(string.format("      技能: %d 个", #hero.skillsConfig))
        for _, skill in ipairs(hero.skillsConfig) do
            print(string.format("        - %s (ID:%d, CD:%d)",
                skill.name, skill.skillId, skill.coolDown or 0))
        end
    end
    print("")

    -- ==================== 启动战斗 ====================
    print("[步骤2] 启动战斗...")
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
    
    -- ==================== 战斗主循环 ====================
    print("[步骤3] 开始战斗主循环...\n")
    
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
        
        -- 每30次更新打印进度
        if updateCount % 30 == 0 then
            local round = BattleMain.GetCurrentRound()
            print(string.format("[进度] 更新次数: %d, 当前回合: %d", updateCount, round))
            
            -- 打印技能冷却状态
            local teamLeft, teamRight = BattleFormation.GetTeams()
            print("  技能冷却状态:")
            for _, hero in ipairs(teamLeft) do
                if hero.isAlive and hero.skillData and hero.skillData.coolDowns then
                    local cds = {}
                    for skillId, cd in pairs(hero.skillData.coolDowns) do
                        if cd > 0 then
                            table.insert(cds, string.format("%d:%d", skillId, cd))
                        end
                    end
                    if #cds > 0 then
                        print(string.format("    %s: %s", hero.name, table.concat(cds, ", ")))
                    end
                end
            end
        end
    end
    
    print("\n============================================")
    print("            战斗循环结束")
    print("============================================")
    
    -- ==================== 战斗结果 ====================
    print("\n[步骤4] 战斗结果统计：")
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
    print("\n[步骤5] 清理战斗资源...")
    BattleMain.Quit()
    
    print("\n========================================")
    print("        技能战斗测试完成")
    print("========================================\n")
    
    return finalResult
end

-- 如果是直接运行此文件，则执行测试
if arg and arg[0] and arg[0]:match("test_skill_battle%.lua$") then
    SkillBattleTest.Run()
end

return SkillBattleTest
