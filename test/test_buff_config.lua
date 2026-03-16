--!/usr/bin/env lua

--============================================================================
-- Buff配置测试
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

-- 颜色代码
local COLORS = {
    RESET = "\27[0m",
    RED = "\27[31m",
    GREEN = "\27[32m",
    YELLOW = "\27[33m",
    BLUE = "\27[34m",
}

local function printColor(color, msg)
    print(color .. msg .. COLORS.RESET)
end

print("========================================")
print("  Buff配置测试")
print("========================================\n")

-- 加载Buff配置
local BuffConfig = require("config.buff_config")
BuffConfig.Init()

-- 测试获取Buff配置
print("\n--- 测试获取Buff配置 ---")

local testBuffIds = {10001, 10002, 10003, 10004, 20001, 20002}

for _, buffId in ipairs(testBuffIds) do
    local config = BuffConfig.GetBuffConfig(buffId)
    if config then
        printColor(COLORS.GREEN, string.format("✓ Buff %d: %s", buffId, config.Name))
        print(string.format("  - 主类型: %d, 子类型: %d", config.MainType, config.SubType))
        print(string.format("  - 最大层数: %d", config.MaxLimit))
        
        if config.AttributeType and #config.AttributeType > 0 then
            print(string.format("  - 属性效果:"))
            for i, attrType in ipairs(config.AttributeType) do
                print(string.format("    [%d] 属性类型=%d, 值=%d", i, attrType, config.AttributeValue[i] or 0))
            end
        end
        
        -- 测试转换为BattleBuff配置
        local battleConfig = BuffConfig.ConvertToBattleBuffConfig(buffId)
        if battleConfig then
            print(string.format("  - BattleBuff配置: 名称=%s, 效果数=%d", 
                battleConfig.name, #battleConfig.effects))
        end
    else
        printColor(COLORS.RED, string.format("✗ Buff %d 未找到", buffId))
    end
end

-- 测试Buff效果应用
print("\n--- 测试Buff效果应用 ---")

-- 先加载 battle_enum
require("core.battle_enum")

local BattleBuff = require("modules.battle_buff")
BattleBuff.Init()

-- 创建测试英雄
local hero = {
    id = "test_hero",
    name = "测试英雄",
    atk = 1000,
    def = 500,
    maxHp = 10000,
    hp = 10000,
    isAlive = true,
    isDead = false,
}

-- 使用实际Buff ID (10001) 添加Buff
local buffConfig = BuffConfig.ConvertToBattleBuffConfig(10001)
if buffConfig then
    print(string.format("添加Buff前英雄属性: ATK=%d, DEF=%d", hero.atk, hero.def))
    
    BattleBuff.Add(hero, hero, buffConfig)
    
    local buffs = BattleBuff.GetAllBuffs(hero)
    print(string.format("添加Buff后Buff数量: %d", #buffs))
    
    if #buffs > 0 then
        for i, buff in ipairs(buffs) do
            print(string.format("Buff[%d]: %s (ID=%d), 层数=%d", 
                i, buff.name, buff.buffId, buff.stackCount))
            if buff.effects and #buff.effects > 0 then
                print(string.format("  效果数: %d", #buff.effects))
                for j, effect in ipairs(buff.effects) do
                    print(string.format("    [%d] 类型=%s, 属性=%d, 值=%d", 
                        j, effect.type, effect.attrType, effect.value))
                end
            end
        end
    end
else
    printColor(COLORS.RED, "✗ 无法获取Buff 10001配置")
end

print("\n========================================")
print("  测试完成")
print("========================================")
