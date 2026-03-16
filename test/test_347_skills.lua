--!/usr/bin/env lua

--============================================================================
-- 测试所有347个技能文件
--============================================================================

-- 获取脚本所在目录并设置包路径
local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
script_dir = script_dir:gsub("test/", "")

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
print("  测试所有347个技能文件")
print("========================================\n")

-- 加载必要模块
require("core.battle_enum")

-- 获取目录下所有技能文件
local function GetAllSkillFiles()
    local skillFiles = {}
    local skillDir = script_dir .. "config/skill/"
    
    -- 使用dir命令获取文件列表
    local cmd = 'dir /b "' .. skillDir .. 'skill_*.lua" 2>nul'
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            -- 提取技能ID (skill_123456789.lua -> 123456789)
            local skillId = line:match("skill_(%d+)%.lua")
            if skillId then
                table.insert(skillFiles, tonumber(skillId))
            end
        end
        handle:close()
    end
    
    return skillFiles
end

-- 加载技能
local function LoadSkill(fullSkillId)
    local luaFileName = string.format("skill_%d", fullSkillId)
    local luaPath = string.format("config.skill.%s", luaFileName)
    
    local success, result = pcall(require, luaPath)
    if not success then
        return nil, result
    end
    
    return _G[luaFileName], nil
end

-- 分析技能数据结构
local function AnalyzeSkill(skillData)
    local analysis = {
        hasDamage = false,
        hasHeal = false,
        hasBuff = false,
        hasSpell = false,
        damageCount = 0,
        healCount = 0,
        buffCount = 0,
        spellCount = 0,
        targetNum = 0,
    }
    
    if not skillData then
        return analysis
    end
    
    -- 检查 actData
    if skillData.actData then
        for _, act in ipairs(skillData.actData) do
            if act.keyFrameDatas then
                for _, kf in ipairs(act.keyFrameDatas) do
                    if kf.datatype == "DWCommon.DamageData" then
                        analysis.hasDamage = true
                        analysis.damageCount = analysis.damageCount + 1
                    elseif kf.datatype == "DWCommon.HealData" then
                        analysis.hasHeal = true
                        analysis.healCount = analysis.healCount + 1
                    elseif kf.datatype == "DWCommon.LaunchBuff" then
                        analysis.hasBuff = true
                        analysis.buffCount = analysis.buffCount + 1
                    elseif kf.datatype == "DWCommon.LaunchSpell" then
                        analysis.hasSpell = true
                        analysis.spellCount = analysis.spellCount + 1
                    end
                end
            end
        end
    end
    
    -- 检查目标数量
    if skillData.targetsSelections and skillData.targetsSelections.tSConditions then
        analysis.targetNum = skillData.targetsSelections.tSConditions.Num or 0
    end
    
    return analysis
end

-- 主测试
local skillFiles = GetAllSkillFiles()
print(string.format("找到 %d 个技能文件\n", #skillFiles))

local stats = {
    total = #skillFiles,
    loaded = 0,
    failed = 0,
    withDamage = 0,
    withHeal = 0,
    withBuff = 0,
    withSpell = 0,
    singleTarget = 0,
    aoeTarget = 0,
}

local failedSkills = {}
local damageSkills = {}
local healSkills = {}
local buffSkills = {}
local spellSkills = {}
local aoeSkills = {}

-- 测试每个技能
for i, fullSkillId in ipairs(skillFiles) do
    local skillData, err = LoadSkill(fullSkillId)
    
    if skillData then
        stats.loaded = stats.loaded + 1
        
        local analysis = AnalyzeSkill(skillData)
        
        if analysis.hasDamage then
            stats.withDamage = stats.withDamage + 1
            table.insert(damageSkills, {id = fullSkillId, name = skillData.Name or "Unknown"})
        end
        
        if analysis.hasHeal then
            stats.withHeal = stats.withHeal + 1
            table.insert(healSkills, {id = fullSkillId, name = skillData.Name or "Unknown"})
        end
        
        if analysis.hasBuff then
            stats.withBuff = stats.withBuff + 1
            table.insert(buffSkills, {id = fullSkillId, name = skillData.Name or "Unknown"})
        end
        
        if analysis.hasSpell then
            stats.withSpell = stats.withSpell + 1
            table.insert(spellSkills, {id = fullSkillId, name = skillData.Name or "Unknown"})
        end
        
        if analysis.targetNum > 1 then
            stats.aoeTarget = stats.aoeTarget + 1
            table.insert(aoeSkills, {id = fullSkillId, num = analysis.targetNum})
        else
            stats.singleTarget = stats.singleTarget + 1
        end
        
        -- 每50个显示一次进度
        if i % 50 == 0 then
            print(string.format("已测试 %d/%d 个技能...", i, stats.total))
        end
    else
        stats.failed = stats.failed + 1
        table.insert(failedSkills, {id = fullSkillId, error = err})
    end
end

-- 输出统计
print("\n========================================")
print("  测试结果统计")
print("========================================")

print(string.format("\n总计: %d 个技能文件", stats.total))
printColor(COLORS.GREEN, string.format("✓ 成功加载: %d", stats.loaded))
if stats.failed > 0 then
    printColor(COLORS.RED, string.format("✗ 加载失败: %d", stats.failed))
end

print("\n--- 技能类型统计 ---")
print(string.format("伤害技能: %d", stats.withDamage))
print(string.format("治疗技能: %d", stats.withHeal))
print(string.format("Buff技能: %d", stats.withBuff))
print(string.format("法术技能: %d", stats.withSpell))

print("\n--- 目标类型统计 ---")
print(string.format("单体攻击: %d", stats.singleTarget))
print(string.format("范围攻击: %d", stats.aoeTarget))

-- 显示部分伤害技能
if #damageSkills > 0 then
    print("\n--- 伤害技能示例 (前10个) ---")
    for i = 1, math.min(10, #damageSkills) do
        local skill = damageSkills[i]
        print(string.format("  [%d] %s (ID: %d)", i, skill.name, skill.id))
    end
    print(string.format("  ... 共 %d 个", #damageSkills))
end

-- 显示治疗技能
if #healSkills > 0 then
    print("\n--- 治疗技能示例 (前10个) ---")
    for i = 1, math.min(10, #healSkills) do
        local skill = healSkills[i]
        print(string.format("  [%d] %s (ID: %d)", i, skill.name, skill.id))
    end
    print(string.format("  ... 共 %d 个", #healSkills))
end

-- 显示Buff技能
if #buffSkills > 0 then
    print("\n--- Buff技能示例 (前10个) ---")
    for i = 1, math.min(10, #buffSkills) do
        local skill = buffSkills[i]
        print(string.format("  [%d] %s (ID: %d)", i, skill.name, skill.id))
    end
    print(string.format("  ... 共 %d 个", #buffSkills))
end

-- 显示法术技能
if #spellSkills > 0 then
    print("\n--- 法术技能示例 (前10个) ---")
    for i = 1, math.min(10, #spellSkills) do
        local skill = spellSkills[i]
        print(string.format("  [%d] %s (ID: %d)", i, skill.name, skill.id))
    end
    print(string.format("  ... 共 %d 个", #spellSkills))
end

-- 显示范围攻击技能
if #aoeSkills > 0 then
    print("\n--- 范围攻击技能示例 (前10个) ---")
    for i = 1, math.min(10, #aoeSkills) do
        local skill = aoeSkills[i]
        print(string.format("  [%d] ID: %d, 目标数: %d", i, skill.id, skill.num))
    end
    print(string.format("  ... 共 %d 个", #aoeSkills))
end

-- 显示失败的技能
if #failedSkills > 0 then
    print("\n--- 加载失败的技能 ---")
    for i, fail in ipairs(failedSkills) do
        print(string.format("  [%d] ID: %d, 错误: %s", i, fail.id, tostring(fail.error)))
    end
end

-- 详细测试一个技能
print("\n========================================")
print("  详细技能示例")
print("========================================")

if #damageSkills > 0 then
    local testSkill = damageSkills[1]
    print(string.format("\n技能: %s (ID: %d)", testSkill.name, testSkill.id))
    
    local skillData = LoadSkill(testSkill.id)
    if skillData then
        print(string.format("  名称: %s", skillData.Name or "N/A"))
        print(string.format("  优先级: %d", skillData.Priorities or 0))
        print(string.format("  冷却时间: %.2f秒", skillData.CoolDownR or 0))
        
        if skillData.targetsSelections then
            local ts = skillData.targetsSelections
            print(string.format("  目标选择:"))
            print(string.format("    - castTarget: %d", ts.castTarget or 0))
            if ts.tSConditions then
                print(string.format("    - 目标数量: %d", ts.tSConditions.Num or 0))
            end
        end
        
        local analysis = AnalyzeSkill(skillData)
        print(string.format("  效果统计:"))
        print(string.format("    - 伤害效果: %d", analysis.damageCount))
        print(string.format("    - 治疗效果: %d", analysis.healCount))
        print(string.format("    - Buff效果: %d", analysis.buffCount))
        print(string.format("    - 法术效果: %d", analysis.spellCount))
    end
end

print("\n========================================")
print("  测试完成")
print("========================================")
