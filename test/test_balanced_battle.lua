---
--- 平衡战斗测试
--- 使用合理配置的双方队伍进行战斗测试，验证伤害计算
---

package.path = package.path .. ";./?.lua;./core/?.lua;./modules/?.lua;./config/?.lua;./utils/?.lua"

-- 加载全局定义
require("core.battle_enum")

-- 加载必要模块
local BattleMain = require("modules.battle_main")
local BattleFormation = require("modules.battle_formation")
local Logger = require("utils.logger")

print("========================================")
print("平衡战斗测试 - 验证伤害计算")
print("========================================")

-- 创建左侧队伍（3名英雄）
local leftTeam = {
    {
        configId = 1001,
        name = "战士",
        level = 50,
        wpType = 1,
        
        hp = 8000,
        maxHp = 8000,
        atk = 500,
        def = 300,
        speed = 120,
        
        critRate = 2000,    -- 20%暴击率
        critDamage = 15000, -- 150%暴击伤害
        hitRate = 10000,
        dodgeRate = 500,
        
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        skillsConfig = {
            { skillId = 10000, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击", coolDown = 0 },
            { skillId = 10001, skillType = E_SKILL_TYPE_ULTIMATE, name = "猛击", coolDown = 3, damageData = { damageRate = 200 } },
        },
        passiveSkills = {},
        isAlive = true,
        isDead = false,
    },
    {
        configId = 1002,
        name = "法师",
        level = 50,
        wpType = 4,
        
        hp = 6000,
        maxHp = 6000,
        atk = 700,
        def = 200,
        speed = 100,
        
        critRate = 1500,
        critDamage = 15000,
        hitRate = 10000,
        dodgeRate = 300,
        
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        skillsConfig = {
            { skillId = 10000, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击", coolDown = 0 },
            { skillId = 10002, skillType = E_SKILL_TYPE_ULTIMATE, name = "火球术", coolDown = 3, damageData = { damageRate = 250 } },
        },
        passiveSkills = {},
        isAlive = true,
        isDead = false,
    },
    {
        configId = 1003,
        name = "牧师",
        level = 50,
        wpType = 7,
        
        hp = 5500,
        maxHp = 5500,
        atk = 400,
        def = 250,
        speed = 110,
        
        critRate = 1000,
        critDamage = 15000,
        hitRate = 10000,
        dodgeRate = 400,
        
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        skillsConfig = {
            { skillId = 10000, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击", coolDown = 0 },
            { skillId = 10003, skillType = E_SKILL_TYPE_ULTIMATE, name = "治疗术", coolDown = 3, healData = { healRate = 150 } },
        },
        passiveSkills = {},
        isAlive = true,
        isDead = false,
    },
}

-- 创建右侧队伍（3名敌人）- 与左侧队伍属性相近
local rightTeam = {
    {
        configId = 2001,
        name = "兽人战士",
        level = 50,
        wpType = 1,
        
        hp = 8500,
        maxHp = 8500,
        atk = 480,
        def = 320,
        speed = 115,
        
        critRate = 1800,
        critDamage = 15000,
        hitRate = 10000,
        dodgeRate = 400,
        
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        skillsConfig = {
            { skillId = 10000, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击", coolDown = 0 },
            { skillId = 20001, skillType = E_SKILL_TYPE_ULTIMATE, name = "狂暴", coolDown = 3, damageData = { damageRate = 180 } },
        },
        passiveSkills = {},
        isAlive = true,
        isDead = false,
    },
    {
        configId = 2002,
        name = "黑暗法师",
        level = 50,
        wpType = 4,
        
        hp = 5800,
        maxHp = 5800,
        atk = 680,
        def = 210,
        speed = 105,
        
        critRate = 1600,
        critDamage = 15000,
        hitRate = 10000,
        dodgeRate = 350,
        
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        skillsConfig = {
            { skillId = 10000, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击", coolDown = 0 },
            { skillId = 20002, skillType = E_SKILL_TYPE_ULTIMATE, name = "暗影箭", coolDown = 3, damageData = { damageRate = 240 } },
        },
        passiveSkills = {},
        isAlive = true,
        isDead = false,
    },
    {
        configId = 2003,
        name = "亡灵刺客",
        level = 50,
        wpType = 7,
        
        hp = 5200,
        maxHp = 5200,
        atk = 550,
        def = 220,
        speed = 130,
        
        critRate = 3000,    -- 高暴击率
        critDamage = 18000, -- 高暴击伤害
        hitRate = 10000,
        dodgeRate = 800,    -- 高闪避
        
        energy = 0,
        maxEnergy = 100,
        energyType = E_ENERGY_TYPE.Bar,
        
        skillsConfig = {
            { skillId = 10000, skillType = E_SKILL_TYPE_NORMAL, name = "普通攻击", coolDown = 0 },
            { skillId = 20003, skillType = E_SKILL_TYPE_ULTIMATE, name = "背刺", coolDown = 3, damageData = { damageRate = 280 } },
        },
        passiveSkills = {},
        isAlive = true,
        isDead = false,
    },
}

print("\n[队伍配置]")
print("\n左侧队伍:")
for _, hero in ipairs(leftTeam) do
    print(string.format("  %s: HP=%d, ATK=%d, DEF=%d, SPD=%d, CRT=%.1f%%",
        hero.name, hero.maxHp, hero.atk, hero.def, hero.speed, hero.critRate/100))
end

print("\n右侧队伍:")
for _, hero in ipairs(rightTeam) do
    print(string.format("  %s: HP=%d, ATK=%d, DEF=%d, SPD=%d, CRT=%.1f%%",
        hero.name, hero.maxHp, hero.atk, hero.def, hero.speed, hero.critRate/100))
end

-- 计算理论伤害值
print("\n[理论伤害计算]")
print("\n左侧队伍普通攻击理论伤害:")
for _, attacker in ipairs(leftTeam) do
    for _, defender in ipairs(rightTeam) do
        local baseDmg = math.max(1, attacker.atk - defender.def)
        local critDmg = math.floor(baseDmg * 1.5)
        print(string.format("  %s -> %s: 基础=%d, 暴击=%d",
            attacker.name, defender.name, baseDmg, critDmg))
    end
end

print("\n右侧队伍普通攻击理论伤害:")
for _, attacker in ipairs(rightTeam) do
    for _, defender in ipairs(leftTeam) do
        local baseDmg = math.max(1, attacker.atk - defender.def)
        local critDmg = math.floor(baseDmg * 1.5)
        print(string.format("  %s -> %s: 基础=%d, 暴击=%d",
            attacker.name, defender.name, baseDmg, critDmg))
    end
end

-- 启动战斗
print("\n========================================")
print("开始战斗！")
print("========================================\n")

-- 设置更新间隔为0，确保每次Update都能执行
BattleMain.SetUpdateInterval(0)

-- 创建战斗开始状态
local battleBeginState = {
    teamLeft = leftTeam,
    teamRight = rightTeam,
    seedArray = { 12345, 67890, 11111, 22222 },
}

-- 战斗结束回调
local finalResult = nil
local function OnBattleEnd(result)
    finalResult = result
    print("\n========================================")
    print("战斗结束!")
    print("========================================")
    print(string.format("获胜方: %s", result.winner or "unknown"))
    print(string.format("结束原因: %s", result.reason or "unknown"))
    print(string.format("总回合数: %d", result.totalRounds or 0))
end

-- 启动战斗
BattleMain.Start(battleBeginState, OnBattleEnd)

-- 运行战斗循环
local maxRounds = 200
local roundCount = 0

-- 等待战斗结束或达到最大回合数
while BattleMain.IsRunning() and roundCount < maxRounds do
    BattleMain.Update()
    roundCount = roundCount + 1
end

-- 确保战斗已结束
if BattleMain.IsRunning() then
    print("\n[警告] 达到最大回合数限制，强制结束战斗")
    BattleMain.Quit()
end

print("\n========================================")
print("平衡战斗测试完成")
print("========================================")
