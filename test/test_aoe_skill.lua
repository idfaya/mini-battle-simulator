--!/usr/bin/env lua

--============================================================================
-- 范围攻击(AOE)技能测试
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

-- 颜色代码
local COLORS = {
    RESET = "\27[0m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
    CYAN = "\27[36m",
}

local function printColor(color, msg)
    print(color .. msg .. COLORS.RESET)
end

print("========================================")
print("  范围攻击(AOE)技能测试")
print("========================================\n")

-- 加载模块
require("core.battle_enum")
require("core.battle_formula")
require("modules.battle_attribute")
require("modules.battle_buff")
require("modules.battle_dmg_heal")
require("core.skill_executor")
require("config.skill_config")
require("config.buff_config")

-- 加载技能文件
pcall(require, "Assets.Lua.Modules.Battle.SkillNewLua.skill_194410101")

-- 创建测试英雄
local function CreateTestHero(id, name, atk, def, hp)
    return {
        id = id,
        name = name,
        atk = atk or 1000,
        def = def or 500,
        maxHp = hp or 10000,
        hp = hp or 10000,
        isAlive = true,
        isDead = false,
    }
end

-- 测试单体攻击 vs 范围攻击
print("\n--- 测试单体攻击技能 (131010101) ---")
local skill_single = _G["skill_131010101"]
if skill_single then
    print("技能配置:")
    if skill_single.targetsSelections then
        local ts = skill_single.targetsSelections
        print(string.format("  castTarget: %d", ts.castTarget or 0))
        if ts.tSConditions then
            print(string.format("  Num (目标数量): %d", ts.tSConditions.Num or 0))
            print(string.format("  measureType: %d", ts.tSConditions.measureType or 0))
        end
    end
    
    -- 统计伤害效果数量
    local damageCount = 0
    if skill_single.actData then
        for _, act in ipairs(skill_single.actData) do
            if act.keyFrameDatas then
                for _, kf in ipairs(act.keyFrameDatas) do
                    if kf.datatype == "DWCommon.DamageData" then
                        damageCount = damageCount + 1
                    end
                end
            end
        end
    end
    print(string.format("  伤害效果数量: %d", damageCount))
else
    printColor(COLORS.RED, "✗ 无法加载单体攻击技能")
end

print("\n--- 测试范围攻击技能 (194410101) ---")
local skill_aoe = _G["skill_194410101"]
if skill_aoe then
    print("技能配置:")
    if skill_aoe.targetsSelections then
        local ts = skill_aoe.targetsSelections
        print(string.format("  castTarget: %d", ts.castTarget or 0))
        if ts.tSConditions then
            print(string.format("  Num (目标数量): %d", ts.tSConditions.Num or 0))
            print(string.format("  measureType: %d", ts.tSConditions.measureType or 0))
        end
    end
    
    -- 统计伤害效果数量
    local damageCount = 0
    if skill_aoe.actData then
        for _, act in ipairs(skill_aoe.actData) do
            if act.keyFrameDatas then
                for _, kf in ipairs(act.keyFrameDatas) do
                    if kf.datatype == "DWCommon.DamageData" or kf.datatype == "DWCommon.LaunchSpell" then
                        damageCount = damageCount + 1
                    end
                end
            end
        end
    end
    print(string.format("  伤害/法术效果数量: %d", damageCount))
    
    -- 测试范围伤害
    print("\n--- 执行范围攻击测试 ---")
    local attacker = CreateTestHero("atk", "攻击者", 2000, 500, 10000)
    local targets = {
        CreateTestHero("def1", "目标1", 1000, 800, 10000),
        CreateTestHero("def2", "目标2", 1000, 800, 10000),
        CreateTestHero("def3", "目标3", 1000, 800, 10000),
    }
    
    print("攻击前目标HP:")
    for i, t in ipairs(targets) do
        print(string.format("  %s: %d/%d", t.name, t.hp, t.maxHp))
    end
    
    -- 使用SkillExecutor执行技能
    local SkillExecutor = require("core.skill_executor")
    local success = SkillExecutor.ExecuteSkill(attacker, targets, skill_aoe, {})
    
    if success then
        printColor(COLORS.GREEN, "\n✓ 范围攻击执行成功")
        print("攻击后目标HP:")
        for i, t in ipairs(targets) do
            local damage = 10000 - t.hp
            print(string.format("  %s: %d/%d (受到 %d 伤害)", t.name, t.hp, t.maxHp, damage))
        end
    else
        printColor(COLORS.YELLOW, "\n⚠ 范围攻击没有造成伤害（技能可能使用LaunchSpell而不是DamageData）")
    end
else
    printColor(COLORS.RED, "✗ 无法加载范围攻击技能")
end

print("\n========================================")
print("  测试完成")
print("========================================")
