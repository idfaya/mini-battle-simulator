--!/usr/bin/env lua

--============================================================================
-- 测试所有347个技能文件 (简化版)
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

print("========================================")
print("  测试所有347个技能文件")
print("========================================\n")

-- 加载必要模块
require("core.battle_enum")

-- 从res_skill.json获取所有技能ID
local SkillConfig = require("config.skill_config")
SkillConfig.Init()

-- 获取所有技能ID (从缓存中提取ClassID)
local allSkillIds = {}
for skillId, config in pairs(SkillConfig.skillConfigCache or {}) do
    if config.ClassID then
        allSkillIds[config.ClassID] = true
    end
end

-- 转换为列表
local skillIdList = {}
for id, _ in pairs(allSkillIds) do
    table.insert(skillIdList, id)
end

table.sort(skillIdList)

print(string.format("从配置中找到 %d 个技能ClassID\n", #skillIdList))

-- 加载技能
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

-- 分析技能
local function AnalyzeSkill(skillData)
    local analysis = {
        hasDamage = false,
        hasHeal = false,
        hasBuff = false,
        hasSpell = false,
        targetNum = 0,
    }
    
    if not skillData or not skillData.actData then
        return analysis
    end
    
    for _, act in ipairs(skillData.actData) do
        if act.keyFrameDatas then
            for _, kf in ipairs(act.keyFrameDatas) do
                if kf.datatype == "DWCommon.DamageData" then
                    analysis.hasDamage = true
                elseif kf.datatype == "DWCommon.HealData" then
                    analysis.hasHeal = true
                elseif kf.datatype == "DWCommon.LaunchBuff" then
                    analysis.hasBuff = true
                elseif kf.datatype == "DWCommon.LaunchSpell" then
                    analysis.hasSpell = true
                end
            end
        end
    end
    
    if skillData.targetsSelections and skillData.targetsSelections.tSConditions then
        analysis.targetNum = skillData.targetsSelections.tSConditions.Num or 0
    end
    
    return analysis
end

-- 统计
local stats = {
    total = #skillIdList,
    loaded = 0,
    failed = 0,
    withDamage = 0,
    withHeal = 0,
    withBuff = 0,
    withSpell = 0,
    singleTarget = 0,
    aoeTarget = 0,
}

local sampleSkills = {}

-- 测试每个技能
for i, skillId in ipairs(skillIdList) do
    local skillData, err = LoadSkill(skillId)
    
    if skillData then
        stats.loaded = stats.loaded + 1
        
        local analysis = AnalyzeSkill(skillData)
        
        if analysis.hasDamage then stats.withDamage = stats.withDamage + 1 end
        if analysis.hasHeal then stats.withHeal = stats.withHeal + 1 end
        if analysis.hasBuff then stats.withBuff = stats.withBuff + 1 end
        if analysis.hasSpell then stats.withSpell = stats.withSpell + 1 end
        
        if analysis.targetNum > 1 then
            stats.aoeTarget = stats.aoeTarget + 1
        else
            stats.singleTarget = stats.singleTarget + 1
        end
        
        -- 保存样本
        if #sampleSkills < 10 then
            table.insert(sampleSkills, {
                id = skillId,
                name = skillData.Name or "Unknown",
                analysis = analysis
            })
        end
        
        if i % 100 == 0 then
            print(string.format("已测试 %d/%d 个技能...", i, stats.total))
        end
    else
        stats.failed = stats.failed + 1
    end
end

-- 输出结果
print("\n========================================")
print("  测试结果统计")
print("========================================")

print(string.format("\n总计: %d 个技能", stats.total))
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

print("\n--- 技能示例 ---")
for i, skill in ipairs(sampleSkills) do
    local types = {}
    if skill.analysis.hasDamage then table.insert(types, "伤害") end
    if skill.analysis.hasHeal then table.insert(types, "治疗") end
    if skill.analysis.hasBuff then table.insert(types, "Buff") end
    if skill.analysis.hasSpell then table.insert(types, "法术") end
    
    print(string.format("[%d] %s (ID:%d) - %s - 目标:%s",
        i,
        skill.name,
        skill.id,
        table.concat(types, ","),
        skill.analysis.targetNum > 1 and "范围" or "单体"
    ))
end

print("\n========================================")
print("  测试完成")
print("========================================")
