#!/usr/bin/env lua

---============================================================================
--- 技能系统测试
--- Skill System Test
---============================================================================

local SkillTest = {}

function SkillTest.Run()
    -- 设置 Windows 控制台为 UTF-8 编码
    if os.getenv("OS") == "Windows_NT" then
        os.execute("chcp 65001 >nul 2>&1")
    end

    print("\n========================================")
    print("        技能系统测试")
    print("========================================\n")

    -- 加载模块
    require("core.battle_enum")  -- 加载枚举定义
    local BattleSkill = require("modules.battle_skill")
    local BattleAttribute = require("modules.battle_attribute")
    local SkillLoader = require("core.skill_loader")
    local Logger = require("utils.logger")

    -- 日志级别已在Logger模块中设置

    -- 创建测试英雄
    local hero1 = {
        instanceId = 1,
        name = "测试英雄1",
        atk = 1000,
        def = 500,
        hp = 5000,
        maxHp = 5000,
        critRate = 3000,  -- 30%暴击率
        critDamage = 15000,  -- 150%暴击伤害
        speed = 120,
        isAlive = true,
        isDead = false,
    }

    local hero2 = {
        instanceId = 2,
        name = "测试英雄2",
        atk = 800,
        def = 600,
        hp = 6000,
        maxHp = 6000,
        critRate = 2000,
        critDamage = 15000,
        speed = 100,
        blockRate = 2000,  -- 20%格挡率
        isAlive = true,
        isDead = false,
    }

    -- 初始化英雄属性
    local attributeMap1 = {
        [BattleAttribute.ATTR_ID.ATK] = hero1.atk,
        [BattleAttribute.ATTR_ID.DEF] = hero1.def,
        [BattleAttribute.ATTR_ID.HP] = hero1.maxHp,
        [BattleAttribute.ATTR_ID.SPEED] = hero1.speed,
        [BattleAttribute.ATTR_ID.CRIT_RATE] = hero1.critRate,
        [BattleAttribute.ATTR_ID.CRIT_DMG] = hero1.critDamage,
    }
    BattleAttribute.Init(hero1, attributeMap1)

    local attributeMap2 = {
        [BattleAttribute.ATTR_ID.ATK] = hero2.atk,
        [BattleAttribute.ATTR_ID.DEF] = hero2.def,
        [BattleAttribute.ATTR_ID.HP] = hero2.maxHp,
        [BattleAttribute.ATTR_ID.SPEED] = hero2.speed,
        [BattleAttribute.ATTR_ID.CRIT_RATE] = hero2.critRate,
        [BattleAttribute.ATTR_ID.CRIT_DMG] = hero2.critDamage,
    }
    BattleAttribute.Init(hero2, attributeMap2)

    print("[测试1] 技能配置加载测试")
    print("----------------------------------------")
    
    -- 测试加载技能配置
    local skillId = 10000
    local config = SkillLoader.LoadSkillConfig(skillId)
    if config then
        local varName = "spell_" .. tostring(skillId)
        local spellConfig = config[varName]
        if spellConfig then
            print(string.format("✓ 技能配置加载成功: %s", spellConfig.Name or "Unknown"))
            print(string.format("  - 技能ID: %d", skillId))
            if spellConfig.Trigger and spellConfig.Trigger.damageData then
                print(string.format("  - 伤害倍率: %.2f%%", (spellConfig.Trigger.damageData.damageRate or 10000) / 100))
            end
        else
            print(string.format("✗ 技能配置格式错误: %s", varName))
        end
    else
        print(string.format("✗ 无法加载技能配置: %d", skillId))
    end
    print("")

    print("[测试2] 普通攻击伤害测试")
    print("----------------------------------------")
    
    -- 测试普通攻击
    local normalAttackSkill = {
        skillId = 1001,
        skillType = 1,  -- 普通攻击
        name = "普通攻击",
        maxCoolDown = 0,
    }
    
    -- 模拟10次攻击，观察暴击和格挡
    local critCount = 0
    local blockCount = 0
    local totalDamage = 0
    
    for i = 1, 10 do
        local initialHp = BattleAttribute.GetHeroCurHp(hero2)
        
        -- 执行攻击
        BattleSkill.ExecuteDefaultAttack(hero1, {hero2}, normalAttackSkill)
        
        local finalHp = BattleAttribute.GetHeroCurHp(hero2)
        local damage = initialHp - finalHp
        totalDamage = totalDamage + damage
        
        print(string.format("攻击 %d: 造成 %d 伤害", i, damage))
        
        -- 恢复HP用于下次测试
        BattleAttribute.SetHpByVal(hero2, hero2.maxHp)
    end
    
    print(string.format("平均伤害: %.1f", totalDamage / 10))
    print("")

    print("[测试3] 技能冷却测试")
    print("----------------------------------------")
    
    -- 创建带冷却的技能
    local skillWithCD = {
        skillId = 2001,
        skillType = 1,
        name = "强力攻击",
        maxCoolDown = 3,  -- 3回合冷却
    }
    
    -- 初始化技能
    BattleSkill.Init(hero1, {skillWithCD})
    
    -- 检查初始冷却
    local initialCD = BattleSkill.GetSkillCurCoolDown(hero1, 2001)
    print(string.format("初始冷却: %d", initialCD))
    
    -- 模拟释放技能
    BattleSkill.SetSkillCurCoolDown(hero1, 2001, skillWithCD.maxCoolDown)
    print(string.format("释放后冷却: %d", BattleSkill.GetSkillCurCoolDown(hero1, 2001)))
    
    -- 模拟回合减少冷却
    for i = 1, 3 do
        BattleSkill.ReduceCoolDown(hero1, 1)
        print(string.format("回合 %d 后冷却: %d", i, BattleSkill.GetSkillCurCoolDown(hero1, 2001)))
    end
    print("")

    print("[测试4] Buff配置加载测试")
    print("----------------------------------------")
    
    -- 测试加载Buff配置
    local buffId = 90000
    local buffConfig = BattleSkill.LoadBuffConfig(buffId)
    if buffConfig then
        print(string.format("✓ Buff配置加载成功: %s", buffConfig.Name or "Unknown"))
        print(string.format("  - BuffID: %d", buffId))
        print(string.format("  - 主类型: %d", buffConfig.mainType or 0))
        print(string.format("  - 持续时间: %d", buffConfig.duration or 1))
    else
        print(string.format("✗ 无法加载Buff配置: %d", buffId))
    end
    print("")

    print("[测试5] 多目标技能测试")
    print("----------------------------------------")
    
    -- 创建多个目标
    local hero3 = {
        instanceId = 3,
        name = "测试英雄3",
        hp = 4000,
        maxHp = 4000,
        def = 400,
        isAlive = true,
        isDead = false,
    }
    
    local attributeMap3 = {
        [BattleAttribute.ATTR_ID.DEF] = hero3.def,
        [BattleAttribute.ATTR_ID.HP] = hero3.maxHp,
    }
    BattleAttribute.Init(hero3, attributeMap3)
    
    -- 重置hero2的HP
    BattleAttribute.SetHpByVal(hero2, hero2.maxHp)
    
    -- 执行群体攻击
    print("群体攻击前:")
    print(string.format("  %s HP: %d/%d", hero2.name, BattleAttribute.GetHeroCurHp(hero2), hero2.maxHp))
    print(string.format("  %s HP: %d/%d", hero3.name, BattleAttribute.GetHeroCurHp(hero3), hero3.maxHp))
    
    BattleSkill.ExecuteDefaultAttack(hero1, {hero2, hero3}, normalAttackSkill)
    
    print("群体攻击后:")
    print(string.format("  %s HP: %d/%d", hero2.name, BattleAttribute.GetHeroCurHp(hero2), hero2.maxHp))
    print(string.format("  %s HP: %d/%d", hero3.name, BattleAttribute.GetHeroCurHp(hero3), hero3.maxHp))
    print("")

    print("========================================")
    print("        技能系统测试完成")
    print("========================================\n")

    return true
end

return SkillTest
