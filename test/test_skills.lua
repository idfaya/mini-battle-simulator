--!/usr/bin/env lua

--============================================================================
-- 技能系统测试
-- 测试各种技能类型：伤害、Buff、治疗、大招
--============================================================================

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

local SkillTest = {}

-- 颜色代码
local COLORS = {
    RESET = "\27[0m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
    MAGENTA = "\27[35m",
    CYAN = "\27[36m",
}

local function printColor(color, msg)
    print(color .. msg .. COLORS.RESET)
end

local function printHeader(title)
    print("\n" .. COLORS.CYAN .. "========================================" .. COLORS.RESET)
    print(COLORS.CYAN .. "  " .. title .. COLORS.RESET)
    print(COLORS.CYAN .. "========================================" .. COLORS.RESET .. "\n")
end

local function printSubHeader(title)
    print("\n" .. COLORS.YELLOW .. "--- " .. title .. " ---" .. COLORS.RESET)
end

-- 加载必要的模块
local function LoadModules()
    require("core.battle_enum")
    require("core.battle_formula")
    require("modules.battle_attribute")
    require("modules.battle_buff")
    require("modules.battle_dmg_heal")
    require("core.skill_executor")
    require("config.skill_config")
    
    -- 加载技能Lua文件
    local skillFiles = {
        "Assets.Lua.Modules.Battle.SkillNewLua.skill_131010101",
        "Assets.Lua.Modules.Battle.SkillNewLua.skill_131010301",
        "Assets.Lua.Modules.Battle.SkillNewLua.skill_131020101",
        "Assets.Lua.Modules.Battle.SkillNewLua.skill_131030101",
        "Assets.Lua.Modules.Battle.SkillNewLua.skill_131030301",
    }
    
    for _, file in ipairs(skillFiles) do
        pcall(require, file)
    end
end

-- 创建测试英雄
local function CreateTestHero(id, name, atk, def, hp, level)
    return {
        id = id,
        name = name,
        level = level or 100,
        atk = atk or 1000,
        def = def or 500,
        maxHp = hp or 10000,
        hp = hp or 10000,
        speed = 100,
        critRate = 1000,
        critDamage = 15000,
        isAlive = true,
        isDead = false,
        attributes = {
            base = {},
            bonus = {},
            final = {},
        },
        buffs = {},
    }
end

-- 测试技能数据解析
function SkillTest.TestSkillDataParsing()
    printSubHeader("测试技能数据解析")
    
    local SkillExecutor = require("core.skill_executor")
    
    -- 测试技能 1310103 (大招，有伤害)
    local skillData = _G["skill_131010301"]
    if skillData then
        printColor(COLORS.GREEN, "✓ 成功加载技能 131010301")
        local effects = SkillExecutor.ExtractSkillEffects(skillData)
        print(string.format("  - 伤害效果: %d 个", #effects.damages))
        print(string.format("  - Buff效果: %d 个", #effects.buffs))
        print(string.format("  - 治疗效果: %d 个", #effects.heals))
        
        if #effects.damages > 0 then
            printColor(COLORS.BLUE, "  伤害配置:")
            for i, dmg in ipairs(effects.damages) do
                print(string.format("    [%d] 攻击类型:%d, 伤害类型:%d, 命中类型:%d", 
                    i, dmg.attackType, dmg.damageType, dmg.hitType))
            end
        end
    else
        printColor(COLORS.RED, "✗ 无法加载技能 131010301")
    end
    
    -- 测试技能 1310303 (大招，有Buff)
    local skillData2 = _G["skill_131030301"]
    if skillData2 then
        printColor(COLORS.GREEN, "✓ 成功加载技能 131030301")
        local effects2 = SkillExecutor.ExtractSkillEffects(skillData2)
        print(string.format("  - 伤害效果: %d 个", #effects2.damages))
        print(string.format("  - Buff效果: %d 个", #effects2.buffs))
        
        if #effects2.buffs > 0 then
            printColor(COLORS.BLUE, "  Buff配置:")
            for i, buff in ipairs(effects2.buffs) do
                print(string.format("    [%d] BuffID:%d", i, buff.buffId))
            end
        end
    else
        printColor(COLORS.RED, "✗ 无法加载技能 131030301")
    end
end

-- 测试伤害技能
function SkillTest.TestDamageSkill()
    printSubHeader("测试伤害技能")
    
    local SkillExecutor = require("core.skill_executor")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    
    -- 创建攻击者和目标
    local attacker = CreateTestHero("test_atk", "测试攻击者", 2000, 500, 10000, 100)
    local defender = CreateTestHero("test_def", "测试防御者", 1000, 800, 10000, 100)
    
    local initialHp = defender.hp
    print(string.format("攻击前目标HP: %d/%d", defender.hp, defender.maxHp))
    
    -- 加载技能数据
    local skillData = _G["skill_131010301"]  -- 大招，160%伤害
    if skillData then
        -- 模拟技能参数 [16000, ...]
        local skillConfig = { skillParam = {16000, 0, 0, 0, 0} }
        
        -- 执行技能
        local success = SkillExecutor.ExecuteSkill(attacker, {defender}, skillData, skillConfig)
        
        if success then
            local damage = initialHp - defender.hp
            printColor(COLORS.GREEN, string.format("✓ 伤害技能执行成功"))
            print(string.format("  造成伤害: %d", damage))
            print(string.format("  攻击后目标HP: %d/%d", defender.hp, defender.maxHp))
            
            if damage > 0 then
                printColor(COLORS.GREEN, "✓ 伤害数值正常")
            else
                printColor(COLORS.RED, "✗ 伤害为0，可能有问题")
            end
        else
            printColor(COLORS.RED, "✗ 技能执行失败")
        end
    else
        printColor(COLORS.RED, "✗ 无法加载技能数据")
    end
end

-- 测试Buff技能
function SkillTest.TestBuffSkill()
    printSubHeader("测试Buff技能")
    
    local SkillExecutor = require("core.skill_executor")
    local BattleBuff = require("modules.battle_buff")
    
    -- 初始化Buff系统
    BattleBuff.Init()
    
    -- 创建施法者和目标
    local caster = CreateTestHero("test_caster", "测试施法者", 1000, 500, 10000, 100)
    local target = CreateTestHero("test_target", "测试目标", 1000, 500, 10000, 100)
    
    -- 获取Buff列表（使用BattleBuff.GetAllBuffs）
    local buffsBefore = BattleBuff.GetAllBuffs(target)
    print(string.format("施加Buff前目标Buff数量: %d", #buffsBefore))
    
    -- 加载技能数据
    local skillData = _G["skill_131030301"]  -- 有Buff的技能
    if skillData then
        -- 执行技能
        local success = SkillExecutor.ExecuteSkill(caster, {target}, skillData, {})
        
        if success then
            printColor(COLORS.GREEN, "✓ Buff技能执行成功")
            
            -- 获取施加后的Buff列表
            local buffsAfter = BattleBuff.GetAllBuffs(target)
            print(string.format("  施加Buff后目标Buff数量: %d", #buffsAfter))
            
            if #buffsAfter > 0 then
                printColor(COLORS.GREEN, "✓ Buff成功施加")
                for i, buff in ipairs(buffsAfter) do
                    print(string.format("  Buff[%d]: ID=%d, 名称=%s, 层数=%d, 持续=%d回合", 
                        i, buff.buffId, buff.name, buff.stackCount, buff.duration))
                end
            else
                printColor(COLORS.YELLOW, "⚠ Buff未生效（可能没有Buff数据或BuffID为0）")
            end
        else
            printColor(COLORS.RED, "✗ 技能执行失败")
        end
    else
        printColor(COLORS.RED, "✗ 无法加载技能数据")
    end
end

-- 测试各种技能倍率
function SkillTest.TestSkillDamageRates()
    printSubHeader("测试不同倍率的技能伤害")
    
    local SkillExecutor = require("core.skill_executor")
    local SkillConfig = require("config.skill_config")
    
    -- 测试不同技能
    local testSkills = {
        {id = 1310101, name = "普通攻击(85%)", expectedRate = 8500},
        {id = 1310103, name = "大招(160%)", expectedRate = 16000},
        {id = 1310201, name = "普通攻击(60%)", expectedRate = 6000},
        {id = 1310301, name = "普通攻击(85%)", expectedRate = 8500},
    }
    
    local attacker = CreateTestHero("test_atk", "测试攻击者", 2000, 500, 10000, 100)
    
    for _, skillInfo in ipairs(testSkills) do
        local skillConfig = SkillConfig.GetSkillConfig(skillInfo.id * 100 + 1)
        if skillConfig then
            local actualRate = skillConfig.SkillParam and skillConfig.SkillParam[1] or 0
            print(string.format("技能 %d (%s): 配置倍率=%d, 期望倍率=%d %s", 
                skillInfo.id, 
                skillInfo.name, 
                actualRate, 
                skillInfo.expectedRate,
                actualRate == skillInfo.expectedRate and COLORS.GREEN .. "✓" or COLORS.RED .. "✗"
            ))
        else
            printColor(COLORS.RED, string.format("✗ 无法获取技能 %d 配置", skillInfo.id))
        end
    end
end

-- 测试技能目标选择
function SkillTest.TestSkillTargeting()
    printSubHeader("测试技能目标选择")
    
    -- 创建测试英雄
    local hero = CreateTestHero("hero1", "测试英雄", 1000, 500, 10000, 100)
    hero.skills = {
        {id = 1310101, type = 1},  -- 普通攻击
        {id = 1310103, type = 3},  -- 大招
    }
    hero.curEnergy = 50
    hero.maxEnergy = 100
    
    -- 创建敌人
    local enemies = {
        CreateTestHero("enemy1", "敌人1", 800, 400, 8000, 100),
        CreateTestHero("enemy2", "敌人2", 800, 400, 8000, 100),
        CreateTestHero("enemy3", "敌人3", 800, 400, 8000, 100),
    }
    
    -- 简单测试：选择第一个可用技能
    local availableSkill = hero.skills[1]
    if availableSkill then
        printColor(COLORS.GREEN, string.format("✓ 选择到可用技能: %d (类型:%d)", availableSkill.id, availableSkill.type))
        
        -- 测试选择目标（选择第一个存活的敌人）
        local targets = {}
        for _, enemy in ipairs(enemies) do
            if enemy.isAlive and not enemy.isDead then
                table.insert(targets, enemy)
                break
            end
        end
        
        if #targets > 0 then
            printColor(COLORS.GREEN, string.format("✓ 选择到 %d 个目标", #targets))
            for i, target in ipairs(targets) do
                print(string.format("  目标[%d]: %s", i, target.name))
            end
        else
            printColor(COLORS.YELLOW, "⚠ 未选择到目标")
        end
    else
        printColor(COLORS.YELLOW, "⚠ 无可用技能")
    end
end

-- 运行所有测试
function SkillTest.RunAllTests()
    printHeader("技能系统全面测试")
    
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end
    
    -- 加载模块
    print("正在加载模块...")
    local success, err = pcall(LoadModules)
    if not success then
        printColor(COLORS.RED, "模块加载失败: " .. tostring(err))
        return
    end
    printColor(COLORS.GREEN, "✓ 模块加载成功\n")
    
    -- 初始化技能配置
    local SkillConfig = require("config.skill_config")
    SkillConfig.Init()
    
    -- 初始化Buff配置
    local BuffConfig = require("config.buff_config")
    BuffConfig.Init()
    
    -- 运行各项测试
    SkillTest.TestSkillDataParsing()
    SkillTest.TestDamageSkill()
    SkillTest.TestBuffSkill()
    SkillTest.TestSkillDamageRates()
    SkillTest.TestSkillTargeting()
    
    printHeader("测试完成")
end

-- 运行测试
SkillTest.RunAllTests()
