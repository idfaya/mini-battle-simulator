#!/usr/bin/env lua

---============================================================================
--- BattleSkillSeq 生命周期测试
--- 验证 BattleSkillSeq 在战斗生命周期内正确初始化与清理
---============================================================================

local SkillSeqLifecycleTest = {}

function SkillSeqLifecycleTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    print("========================================")
    print("BattleSkillSeq 生命周期测试")
    print("========================================")

    -- 加载必需模块
    local Logger = require("utils.logger")
    local BattleMain = require("modules.battle_main")
    local BattleSkillSeq = require("modules.battle_skill_seq")
    local BattleFormation = require("modules.battle_formation")

    -- ==================== 测试1: 初始状态验证 ====================
    print("\n[测试1] 验证初始状态...")
    
    -- 直接调用 Init 确保状态干净
    BattleSkillSeq.Init()
    
    local ultimateCount = BattleSkillSeq.GetUltimateSkillCount()
    local hideCount = BattleSkillSeq.GetHideSkillCount()
    local noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
    
    print(string.format("  终极技能队列: %d", ultimateCount))
    print(string.format("  隐藏技能队列: %d", hideCount))
    print(string.format("  无消耗大招队列: %d", noCostCount))
    
    if ultimateCount == 0 and hideCount == 0 and noCostCount == 0 then
        print("  ✓ 初始状态正确（所有队列为空）")
    else
        print("  ✗ 初始状态异常！")
        return false
    end

    -- ==================== 测试2: 模拟添加技能后状态 ====================
    print("\n[测试2] 模拟添加技能到队列...")
    
    -- 创建一个模拟英雄
    local mockHero = {
        id = 9999,
        name = "测试英雄",
        isAlive = true,
        isDead = false,
        skills = {
            { skillId = 1001, skillType = E_SKILL_TYPE_ULTIMATE, name = "测试大招", skillCost = 50 }
        }
    }
    
    -- 添加隐藏技能
    BattleSkillSeq.AddHideSkill(mockHero, nil, 12345)
    hideCount = BattleSkillSeq.GetHideSkillCount()
    print(string.format("  添加隐藏技能后队列: %d", hideCount))
    
    -- 添加无消耗大招
    BattleSkillSeq.AddUltimateSkillNoCost(mockHero, nil)
    noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
    print(string.format("  添加无消耗大招后队列: %d", noCostCount))
    
    if hideCount == 1 and noCostCount == 1 then
        print("  ✓ 技能添加成功")
    else
        print("  ✗ 技能添加失败！")
        return false
    end

    -- ==================== 测试3: 模拟战斗退出后状态 ====================
    print("\n[测试3] 模拟战斗退出后状态...")
    
    -- 调用 OnFinal 清理
    BattleSkillSeq.OnFinal()
    
    ultimateCount = BattleSkillSeq.GetUltimateSkillCount()
    hideCount = BattleSkillSeq.GetHideSkillCount()
    noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
    
    print(string.format("  终极技能队列: %d", ultimateCount))
    print(string.format("  隐藏技能队列: %d", hideCount))
    print(string.format("  无消耗大招队列: %d", noCostCount))
    
    if ultimateCount == 0 and hideCount == 0 and noCostCount == 0 then
        print("  ✓ 清理后状态正确（所有队列为空）")
    else
        print("  ✗ 清理后状态异常！")
        return false
    end

    -- ==================== 测试4: 验证 BattleMain 集成 ====================
    print("\n[测试4] 验证 BattleMain 集成...")
    
    -- 创建简单的战斗配置
    local hero_left = {
        configId = 1001,
        name = "左侧英雄",
        level = 50,
        hp = 5000,
        maxHp = 5000,
        atk = 800,
        def = 300,
        speed = 120,
        skillsConfig = {
            { skillId = 1001, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击" }
        },
    }

    local hero_right = {
        configId = 2001,
        name = "右侧英雄",
        level = 50,
        hp = 5000,
        maxHp = 5000,
        atk = 800,
        def = 300,
        speed = 100,
        skillsConfig = {
            { skillId = 1002, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击" }
        },
    }

    local battleBeginState = {
        teamLeft = { hero_left },
        teamRight = { hero_right },
        seedArray = { 12345, 67890, 11111, 22222 },
    }

    -- 启动战斗
    local battleEnded = false
    BattleMain.Start(battleBeginState, function(result)
        battleEnded = true
    end)

    -- 检查战斗启动后队列状态
    ultimateCount = BattleSkillSeq.GetUltimateSkillCount()
    hideCount = BattleSkillSeq.GetHideSkillCount()
    noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
    
    print(string.format("  战斗启动后 - 终极技能队列: %d, 隐藏技能队列: %d, 无消耗大招队列: %d",
        ultimateCount, hideCount, noCostCount))
    
    if ultimateCount == 0 and hideCount == 0 and noCostCount == 0 then
        print("  ✓ BattleMain.Start 正确初始化了 BattleSkillSeq")
    else
        print("  ✗ BattleMain.Start 后状态异常！")
        BattleMain.Quit()
        return false
    end

    -- 快速运行几个回合
    BattleMain.SetUpdateInterval(0)
    for i = 1, 10 do
        BattleMain.Update()
        if BattleMain.GetBattleResult().isFinished then
            break
        end
    end

    -- 退出战斗
    BattleMain.Quit()

    -- 检查退出后状态
    ultimateCount = BattleSkillSeq.GetUltimateSkillCount()
    hideCount = BattleSkillSeq.GetHideSkillCount()
    noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
    
    print(string.format("  战斗退出后 - 终极技能队列: %d, 隐藏技能队列: %d, 无消耗大招队列: %d",
        ultimateCount, hideCount, noCostCount))
    
    if ultimateCount == 0 and hideCount == 0 and noCostCount == 0 then
        print("  ✓ BattleMain.Quit 正确清理了 BattleSkillSeq")
    else
        print("  ✗ BattleMain.Quit 后状态异常！")
        return false
    end

    -- ==================== 测试5: 连续战斗测试 ====================
    print("\n[测试5] 连续战斗测试...")
    
    for round = 1, 3 do
        -- 启动战斗
        BattleMain.Start(battleBeginState, function(result)
            battleEnded = true
        end)
        
        -- 检查初始状态
        hideCount = BattleSkillSeq.GetHideSkillCount()
        noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
        
        if hideCount ~= 0 or noCostCount ~= 0 then
            print(string.format("  ✗ 第 %d 场战斗启动时状态异常！", round))
            BattleMain.Quit()
            return false
        end
        
        -- 添加一些技能
        local allHeroes = BattleFormation.GetAllHeroes()
        if #allHeroes > 0 then
            BattleSkillSeq.AddHideSkill(allHeroes[1], nil, 12345)
        end
        
        -- 退出战斗
        BattleMain.Quit()
        
        -- 验证清理
        hideCount = BattleSkillSeq.GetHideSkillCount()
        noCostCount = BattleSkillSeq.GetNoCostUltimateCount()
        
        if hideCount ~= 0 or noCostCount ~= 0 then
            print(string.format("  ✗ 第 %d 场战斗退出后状态未清理！", round))
            return false
        end
        
        print(string.format("  第 %d 场战斗: 启动干净 ✓, 退出清理 ✓", round))
    end
    
    print("  ✓ 连续战斗测试通过")

    -- ==================== 测试总结 ====================
    print("\n========================================")
    print("测试总结")
    print("========================================")
    print("所有测试通过！")
    print("  ✓ BattleSkillSeq.Init 正确初始化队列")
    print("  ✓ BattleSkillSeq.OnFinal 正确清理队列")
    print("  ✓ BattleMain 正确集成 BattleSkillSeq 生命周期")
    print("  ✓ 连续战斗不会出现状态串扰")
    print("========================================")

    return true
end

-- 如果直接运行此脚本
if arg and arg[0] and arg[0]:match("test_skillseq_lifecycle%.lua$") then
    SkillSeqLifecycleTest.Run()
end

return SkillSeqLifecycleTest
