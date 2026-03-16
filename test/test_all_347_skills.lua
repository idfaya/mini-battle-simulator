--!/usr/bin/env lua
-- 测试所有347个技能文件

local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
script_dir = script_dir:gsub("test/", "")

package.path = package.path
    .. ";" .. script_dir .. "?.lua"
    .. ";" .. script_dir .. "core/?.lua"
    .. ";" .. script_dir .. "modules/?.lua"
    .. ";" .. script_dir .. "config/?.lua"
    .. ";" .. script_dir .. "utils/?.lua"

print("========================================")
print("  测试所有347个技能文件")
print("========================================\n")

require("core.battle_enum")

-- 从目录获取所有技能文件名
local function GetAllSkillIdsFromFiles()
    local skillIds = {}
    local skillDir = script_dir .. "config/skill/"
    
    -- 使用dir命令
    local cmd = 'dir /b "' .. skillDir .. 'skill_*.lua" 2>nul'
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            -- skill_131010101.lua -> 1310101
            local fullId = line:match("skill_(%d+)%.lua")
            if fullId then
                local classId = math.floor(tonumber(fullId) / 100)
                table.insert(skillIds, classId)
            end
        end
        handle:close()
    end
    
    table.sort(skillIds)
    return skillIds
end

local function LoadSkill(skillId)
    local fullSkillId = skillId * 100 + 1
    local luaFileName = string.format("skill_%d", fullSkillId)
    local luaPath = string.format("config.skill.%s", luaFileName)
    
    local success, result = pcall(require, luaPath)
    if not success then
        return nil, result
    end
    
    return _G[luaFileName], nil
end

local function AnalyzeSkill(skillData)
    local analysis = {hasDamage = false, hasHeal = false, hasBuff = false, hasSpell = false, targetNum = 0}
    
    if not skillData or not skillData.actData then return analysis end
    
    for _, act in ipairs(skillData.actData) do
        if act.keyFrameDatas then
            for _, kf in ipairs(act.keyFrameDatas) do
                if kf.datatype == "DWCommon.DamageData" then analysis.hasDamage = true
                elseif kf.datatype == "DWCommon.HealData" then analysis.hasHeal = true
                elseif kf.datatype == "DWCommon.LaunchBuff" then analysis.hasBuff = true
                elseif kf.datatype == "DWCommon.LaunchSpell" then analysis.hasSpell = true
                end
            end
        end
    end
    
    if skillData.targetsSelections and skillData.targetsSelections.tSConditions then
        analysis.targetNum = skillData.targetsSelections.tSConditions.Num or 0
    end
    
    return analysis
end

-- 获取所有技能ID
local skillIds = GetAllSkillIdsFromFiles()
print(string.format("从文件中找到 %d 个技能\n", #skillIds))

if #skillIds == 0 then
    print("无法读取技能文件列表，使用备用列表...")
    -- 备用：手动列出一些已知的技能ID
    skillIds = {1310101, 1310102, 1310103, 1310201, 1310202, 1310203, 1310301, 1310302, 1310303}
end

local stats = {total = #skillIds, loaded = 0, failed = 0, withDamage = 0, withHeal = 0, withBuff = 0, withSpell = 0, singleTarget = 0, aoeTarget = 0}
local failedList = {}
local samples = {}

for i, skillId in ipairs(skillIds) do
    local skillData, err = LoadSkill(skillId)
    
    if skillData then
        stats.loaded = stats.loaded + 1
        local analysis = AnalyzeSkill(skillData)
        
        if analysis.hasDamage then stats.withDamage = stats.withDamage + 1 end
        if analysis.hasHeal then stats.withHeal = stats.withHeal + 1 end
        if analysis.hasBuff then stats.withBuff = stats.withBuff + 1 end
        if analysis.hasSpell then stats.withSpell = stats.withSpell + 1 end
        
        if analysis.targetNum > 1 then stats.aoeTarget = stats.aoeTarget + 1
        else stats.singleTarget = stats.singleTarget + 1 end
        
        if #samples < 10 then
            table.insert(samples, {id = skillId, name = skillData.Name or "Unknown", analysis = analysis})
        end
        
        if i % 50 == 0 then print(string.format("已测试 %d/%d 个技能...", i, stats.total)) end
    else
        stats.failed = stats.failed + 1
        table.insert(failedList, {id = skillId, error = err})
    end
end

print("\n========================================")
print("  测试结果统计")
print("========================================")
print(string.format("\n总计: %d 个技能文件", stats.total))
print(string.format("成功加载: %d", stats.loaded))
print(string.format("加载失败: %d", stats.failed))

print("\n--- 技能类型 ---")
print(string.format("伤害技能: %d", stats.withDamage))
print(string.format("治疗技能: %d", stats.withHeal))
print(string.format("Buff技能: %d", stats.withBuff))
print(string.format("法术技能: %d", stats.withSpell))

print("\n--- 目标类型 ---")
print(string.format("单体攻击: %d", stats.singleTarget))
print(string.format("范围攻击: %d", stats.aoeTarget))

if #samples > 0 then
    print("\n--- 技能示例 ---")
    for i, skill in ipairs(samples) do
        local types = {}
        if skill.analysis.hasDamage then table.insert(types, "伤害") end
        if skill.analysis.hasHeal then table.insert(types, "治疗") end
        if skill.analysis.hasBuff then table.insert(types, "Buff") end
        if skill.analysis.hasSpell then table.insert(types, "法术") end
        print(string.format("[%d] %s (ID:%d) - %s - %s", 
            i, skill.name, skill.id, 
            #types > 0 and table.concat(types, ",") or "无效果",
            skill.analysis.targetNum > 1 and "范围" or "单体"))
    end
end

if #failedList > 0 then
    print("\n--- 加载失败的技能 (前10个) ---")
    for i = 1, math.min(10, #failedList) do
        print(string.format("[%d] ID:%d, 错误:%s", i, failedList[i].id, tostring(failedList[i].error)))
    end
end

print("\n========================================")
print("  测试完成")
print("========================================")
