--!/usr/bin/env lua

--============================================================================
-- 所有法术技能批量测试
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
    CYAN = "\27[36m",
}

local function printColor(color, msg)
    print(color .. msg .. COLORS.RESET)
end

print("========================================")
print("  所有法术技能批量测试")
print("========================================\n")

-- 加载必要模块
require("core.battle_enum")
require("core.battle_formula")
require("modules.battle_attribute")
require("modules.battle_dmg_heal")

-- 获取目录下所有法术文件
local function GetSpellFiles()
    local spellFiles = {}
    
    -- 使用预定义的法术ID列表（因为Lua在Windows上遍历目录较复杂）
    -- 这里列出一些常见的法术ID进行测试
    local commonSpellIds = {
        10000, 131010301, 131010302, 131020101, 131020102, 131020301, 131020302,
        131030701, 131030702, 131410101, 131410201, 131420401, 131420402, 131420403,
        131420404, 131420405, 131420406, 131430301, 131440101, 131440102, 131440103,
        131440201, 131440202, 131440203, 131480101, 131480201, 131480202, 131500101,
        131500301, 131510101, 131510102, 131510103, 131530101, 131530201, 131570201,
        131570202, 131630101, 131630102, 131710201, 131840101, 131870101, 131870102,
        131870201, 131870202, 131940201, 131950201, 131960101, 13280301, 13280302,
        192420401, 192420402, 192420403, 192420404, 192420405, 192500201, 200020101,
        200020201, 200020301, 200040101, 201010101, 201020101, 201040101, 201040201,
        203020101, 203020201, 203040101, 204020101, 204020201, 204020202, 204040101,
        204040201, 207020101, 207020201, 207040101, 207040201, 212010101, 212010501,
        212050101, 212060101, 212070101, 212080101, 212110101, 212110201, 212120301,
        212160101, 213010101, 213020101, 213020201, 213040101, 302010101, 302010102,
        302010103, 302010104, 302010105, 302030101, 99999
    }
    
    -- 尝试加载每个法术，只保留存在的
    for _, spellId in ipairs(commonSpellIds) do
        local spellFileName = string.format("spell_%d", spellId)
        local luaFile = string.format("config.spell.%s", spellFileName)
        
        local success, result = pcall(require, luaFile)
        if success and _G[spellFileName] then
            table.insert(spellFiles, spellId)
        end
    end
    
    return spellFiles
end

-- 加载法术
local function LoadSpell(spellId)
    local spellFileName = string.format("spell_%d", spellId)
    local luaFile = string.format("config.spell.%s", spellFileName)
    
    local success, result = pcall(require, luaFile)
    if not success then
        return nil, result
    end
    
    local globalVarName = spellFileName
    return _G[globalVarName], nil
end

-- 分析法术数据结构
local function AnalyzeSpell(spellData, spellId)
    local analysis = {
        hasDamage = false,
        hasHeal = false,
        hasBuff = false,
        hasDispel = false,
        damageCount = 0,
        healCount = 0,
        buffCount = 0,
        dispelCount = 0,
    }
    
    if not spellData then
        return analysis
    end
    
    -- 检查 NewAttackDrop
    if spellData.NewAttackDrop then
        local drop = spellData.NewAttackDrop
        
        if drop.damageData then
            analysis.hasDamage = true
            analysis.damageCount = analysis.damageCount + 1
        end
        
        if drop.healData then
            analysis.hasHeal = true
            analysis.healCount = analysis.healCount + 1
        end
        
        if drop.dispelData and drop.dispelData.associate and drop.dispelData.associate > 0 then
            analysis.hasDispel = true
            analysis.dispelCount = analysis.dispelCount + 1
        end
    end
    
    -- 检查是否有持续效果（如Buff）
    if spellData.IntervalTimeS and spellData.IntervalTimeS > 0 then
        -- 有间隔时间，可能有持续效果
    end
    
    return analysis
end

-- 主测试
local spellFiles = GetSpellFiles()
print(string.format("找到 %d 个法术技能文件\n", #spellFiles))

local stats = {
    total = #spellFiles,
    loaded = 0,
    failed = 0,
    withDamage = 0,
    withHeal = 0,
    withBuff = 0,
    withDispel = 0,
}

local failedSpells = {}
local damageSpells = {}
local healSpells = {}

-- 测试每个法术
for i, spellId in ipairs(spellFiles) do
    local spellData, err = LoadSpell(spellId)
    
    if spellData then
        stats.loaded = stats.loaded + 1
        
        local analysis = AnalyzeSpell(spellData, spellId)
        
        if analysis.hasDamage then
            stats.withDamage = stats.withDamage + 1
            table.insert(damageSpells, {id = spellId, name = spellData.Name or "Unknown"})
        end
        
        if analysis.hasHeal then
            stats.withHeal = stats.withHeal + 1
            table.insert(healSpells, {id = spellId, name = spellData.Name or "Unknown"})
        end
        
        if analysis.hasBuff then
            stats.withBuff = stats.withBuff + 1
        end
        
        if analysis.hasDispel then
            stats.withDispel = stats.withDispel + 1
        end
        
        -- 每10个显示一次进度
        if i % 10 == 0 then
            print(string.format("已测试 %d/%d 个法术...", i, stats.total))
        end
    else
        stats.failed = stats.failed + 1
        table.insert(failedSpells, {id = spellId, error = err})
        printColor(COLORS.RED, string.format("✗ 法术 %d 加载失败: %s", spellId, tostring(err)))
    end
end

-- 输出统计
print("\n========================================")
print("  测试结果统计")
print("========================================")

print(string.format("\n总计: %d 个法术", stats.total))
printColor(COLORS.GREEN, string.format("✓ 成功加载: %d", stats.loaded))
if stats.failed > 0 then
    printColor(COLORS.RED, string.format("✗ 加载失败: %d", stats.failed))
end

print("\n--- 法术类型统计 ---")
print(string.format("伤害法术: %d", stats.withDamage))
print(string.format("治疗法术: %d", stats.withHeal))
print(string.format("Buff法术: %d", stats.withBuff))
print(string.format("驱散法术: %d", stats.withDispel))

-- 显示部分伤害法术
if #damageSpells > 0 then
    print("\n--- 部分伤害法术示例 ---")
    for i = 1, math.min(10, #damageSpells) do
        local spell = damageSpells[i]
        print(string.format("  [%d] %s (ID: %d)", i, spell.name, spell.id))
    end
    if #damageSpells > 10 then
        print(string.format("  ... 还有 %d 个", #damageSpells - 10))
    end
end

-- 显示部分治疗法术
if #healSpells > 0 then
    print("\n--- 部分治疗法术示例 ---")
    for i = 1, math.min(10, #healSpells) do
        local spell = healSpells[i]
        print(string.format("  [%d] %s (ID: %d)", i, spell.name, spell.id))
    end
    if #healSpells > 10 then
        print(string.format("  ... 还有 %d 个", #healSpells - 10))
    end
end

-- 显示失败的法术
if #failedSpells > 0 then
    print("\n--- 加载失败的法术 ---")
    for i, fail in ipairs(failedSpells) do
        print(string.format("  [%d] ID: %d, 错误: %s", i, fail.id, tostring(fail.error)))
    end
end

-- 详细测试一个法术
print("\n========================================")
print("  详细法术示例")
print("========================================")

if #damageSpells > 0 then
    local testSpell = damageSpells[1]
    print(string.format("\n法术: %s (ID: %d)", testSpell.name, testSpell.id))
    
    local spellData = LoadSpell(testSpell.id)
    if spellData then
        print(string.format("  名称: %s", spellData.Name or "N/A"))
        print(string.format("  间隔时间: %.2f秒", spellData.IntervalTimeS or 0))
        print(string.format("  是否爆炸: %s", tostring(spellData.IsHitExplosion)))
        print(string.format("  是否移动到目标: %s", tostring(spellData.IsMoveToTarget)))
        
        if spellData.NewAttackDrop then
            local drop = spellData.NewAttackDrop
            print("  攻击效果:")
            
            if drop.damageData then
                print(string.format("    - 伤害类型: %d", drop.damageData.damageType or 0))
                print(string.format("    - 攻击类型: %d", drop.damageData.attackType or 0))
                print(string.format("    - 命中类型: %d", drop.damageData.hitType or 0))
            end
            
            if drop.healData then
                print(string.format("    - 治疗属性类型: %d", drop.healData.attributeType or 0))
            end
            
            if drop.targetsSelections then
                local ts = drop.targetsSelections
                if ts.tSConditions then
                    print(string.format("    - 目标数量: %d", ts.tSConditions.Num or 0))
                end
            end
        end
    end
end

print("\n========================================")
print("  测试完成")
print("========================================")
