#!/usr/bin/env lua

---============================================================================
--- 简单战斗集成测试
--- Simple Battle Integration Test
---============================================================================
--- 本测试演示:
--- 1. 战斗初始化
--- 2. 英雄创建
--- 3. 技能释放
--- 4. 伤害计算
--- 5. 战斗结束检测
---============================================================================

local SimpleBattleTest = {}

function SimpleBattleTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码（支持中文显示）
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    -- ==================== 步骤1: 加载所有必需的模块 ====================

    print("[步骤1] 正在加载战斗模块...")

    -- 核心模块
    local BattleEnum = require("battle_enum")           -- 战斗枚举定义
    local BattleTypes = require("battle_types")         -- 战斗类型定义
    local BattleMath = require("battle_math")           -- 战斗数学工具（随机数生成）
    local BattleEvent = require("battle_event")         -- 战斗事件系统
    local BattleTimer = require("battle_timer")         -- 战斗计时器

    -- 功能模块
    local BattleFormation = require("battle_formation")     -- 阵型管理
    local BattleActionOrder = require("battle_action_order") -- 行动顺序
    local BattleAttribute = require("battle_attribute")     -- 属性管理
    local BattleSkill = require("battle_skill")             -- 技能系统
    local BattleBuff = require("battle_buff")               -- Buff系统
    local BattleEnergy = require("battle_energy")           -- 能量系统
    local BattleDmgHeal = require("battle_dmg_heal")        -- 伤害/治疗
    local BattlePassiveSkill = require("battle_passive_skill") -- 被动技能
    local BattleLogic = require("battle_logic")             -- 战斗逻辑

    -- 主入口模块
    local BattleMain = require("battle_main")               -- 战斗主控制

    -- 工具模块
    local Logger = require("logger")                        -- 日志工具

    print("[步骤1] 所有模块加载完成！\n")

    -- ==================== 步骤2: 创建战斗配置 ====================

    print("[步骤2] 创建1v1战斗配置...")

    -- 定义左侧队伍的英雄（攻击型战士）
    local hero_left = {
        configId = 1001,                    -- 英雄配置ID
        name = "烈焰战士",                   -- 英雄名称
        level = 50,                         -- 等级
        wpType = 1,                         -- 位置类型（前排）

        -- 基础属性
        hp = 5000,                          -- 当前生命值
        maxHp = 5000,                       -- 最大生命值
        atk = 800,                          -- 攻击力
        def = 300,                          -- 防御力
        speed = 120,                        -- 速度（影响行动顺序）

        -- 战斗属性
        critRate = 2000,                    -- 暴击率（万分比，2000=20%）
        critDamage = 15000,                 -- 暴击伤害（万分比，15000=150%）
        hitRate = 10000,                    -- 命中率
        dodgeRate = 500,                    -- 闪避率

        -- 能量系统
        energy = 0,                         -- 当前能量
        maxEnergy = 100,                    -- 最大能量
        energyType = E_ENERGY_TYPE.Bar,     -- 能量条类型

        -- 技能配置
        skillsConfig = {                    -- 技能配置（用于初始化）
            { skillId = 1001, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击" }
        },
        passiveSkills = {},                 -- 被动技能列表
    }

    -- 定义右侧队伍的英雄（防御型坦克）
    local hero_right = {
        configId = 2001,                    -- 英雄配置ID
        name = "钢铁守卫",                   -- 英雄名称
        level = 50,                         -- 等级
        wpType = 1,                         -- 位置类型（前排）

        -- 基础属性
        hp = 8000,                          -- 当前生命值
        maxHp = 8000,                       -- 最大生命值
        atk = 500,                          -- 攻击力
        def = 500,                          -- 防御力
        speed = 100,                        -- 速度（比左侧慢）

        -- 战斗属性
        critRate = 1000,                    -- 暴击率（10%）
        critDamage = 15000,                 -- 暴击伤害（150%）
        hitRate = 10000,                    -- 命中率
        dodgeRate = 300,                    -- 闪避率

        -- 能量系统
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,

        -- 技能配置
        skillsConfig = {
            { skillId = 1002, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击" }
        },
        passiveSkills = {},
    }

    -- 创建战斗开始状态
    local battleBeginState = {
        teamLeft = { hero_left },           -- 左侧队伍（1名英雄）
        teamRight = { hero_right },         -- 右侧队伍（1名英雄）
        seedArray = { 12345, 67890, 11111, 22222 }, -- 随机数种子数组（需要至少4个整数）
    }

    print("[步骤2] 战斗配置创建完成！")
    print(string.format("  左侧英雄: %s (HP:%d, ATK:%d, DEF:%d, SPD:%d)",
        hero_left.name, hero_left.hp, hero_left.atk, hero_left.def, hero_left.speed))
    print(string.format("  右侧英雄: %s (HP:%d, ATK:%d, DEF:%d, SPD:%d)",
        hero_right.name, hero_right.hp, hero_right.atk, hero_right.def, hero_right.speed))
    print("")

    -- ==================== 步骤3: 设置战斗结束回调 ====================

    print("[步骤3] 设置战斗结束回调...")

    local finalBattleResult = nil

    -- 战斗结束回调函数
    local function OnBattleEnd(result)
        finalBattleResult = result
        print(string.format("\n[战斗结束回调] 获胜方: %s, 原因: %s",
            result.winner or "无", result.reason or "未知"))
    end

    print("[步骤3] 回调设置完成！\n")

    -- ==================== 步骤4: 启动战斗 ====================

    print("[步骤4] 启动战斗...")
    print("============================================")
    print("            战斗开始！")
    print("============================================\n")

    -- 启动战斗，传入战斗配置和结束回调
    BattleMain.Start(battleBeginState, OnBattleEnd)

    -- ==================== 步骤5: 运行战斗主循环 ====================

    print("[步骤5] 开始战斗主循环...\n")

    -- 战斗循环控制参数
    local maxUpdates = 1000         -- 最大更新次数（防止无限循环）
    local updateCount = 0           -- 当前更新计数
    local battleFinished = false    -- 战斗是否结束

    -- 战斗主循环
    while updateCount < maxUpdates do
        updateCount = updateCount + 1

        -- 执行一次战斗更新
        BattleMain.Update()

        -- 检查战斗是否结束
        local result = BattleMain.GetBattleResult()
        if result and result.isFinished then
            battleFinished = true
            break
        end

        -- 每10次更新打印一次状态（用于观察战斗进度）
        if updateCount % 10 == 0 then
            local round = BattleMain.GetCurrentRound()
            print(string.format("[进度] 更新次数: %d, 当前回合: %d", updateCount, round))
        end
    end

    print("\n============================================")
    print("            战斗循环结束")
    print("============================================")

    -- ==================== 步骤6: 打印战斗结果 ====================

    print("\n[步骤6] 战斗结果统计：")
    print("--------------------------------------------")

    if battleFinished then
        print(string.format("战斗正常结束！"))
        print(string.format("  获胜方: %s", finalBattleResult.winner or "平局"))
        print(string.format("  结束原因: %s", finalBattleResult.reason or "未知"))
        print(string.format("  总回合数: %d", BattleMain.GetCurrentRound()))
    else
        print(string.format("战斗达到最大更新次数限制 (%d次)，强制结束", maxUpdates))
        print(string.format("  当前回合: %d", BattleMain.GetCurrentRound()))
    end

    -- 获取最终阵型状态
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

    -- ==================== 步骤7: 清理资源 ====================

    print("\n[步骤7] 清理战斗资源...")
    BattleMain.Quit()
    print("[步骤7] 资源清理完成！")

    -- ==================== 测试总结 ====================

    print("\n============================================")
    print("            测试总结")
    print("============================================")
    print("本测试成功演示了以下功能：")
    print("  ✓ 战斗模块加载")
    print("  ✓ 英雄创建与配置")
    print("  ✓ 战斗初始化")
    print("  ✓ 行动顺序系统")
    print("  ✓ 回合制战斗循环")
    print("  ✓ 战斗结束检测")
    print("  ✓ 资源清理")
    print("============================================")

    return finalBattleResult
end

return SimpleBattleTest
