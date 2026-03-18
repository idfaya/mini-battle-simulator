-- 测试技能系统是否正常工作

package.path = package.path
    .. ";./?.lua"
    .. ";./core/?.lua"
    .. ";./config/?.lua"
    .. ";./utils/?.lua"

require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")

local SkillData = require("config.skill_data")
local SkillExecutor = require("core.skill_executor")
local SkillLoader = require("core.skill_loader")

local function Log(msg)
    print(string.format("[SKILL TEST] %s", msg))
end

local function LogError(msg)
    print(string.format("[SKILL TEST] [ERROR] %s", msg))
end

local function LogSuccess(msg)
    print(string.format("[SKILL TEST] [OK] %s", msg))
end

-- 测试技能数据加载
local function TestSkillData()
    Log("=== 测试 SkillData 模块 ===")
    
    -- SkillData 在 require 时自动加载
    -- 不需要手动调用 Init
    
    -- 测试获取技能
    local testSkillIds = {131010101, 131020101, 131030101, 100001}
    local successCount = 0
    
    for _, skillId in ipairs(testSkillIds) do
        local skill = SkillData.GetSkill(skillId)
        if skill then
            Log(string.format("技能 %d: %s (类型:%d, 职业:%d)", 
                skillId, skill.Name or "Unknown", skill.Type or 0, skill.ClassID or 0))
            successCount = successCount + 1
        else
            LogError(string.format("技能 %d 未找到", skillId))
        end
    end
    
    LogSuccess(string.format("SkillData: %d/%d 技能加载成功", successCount, #testSkillIds))
    return successCount == #testSkillIds
end

-- 测试技能Loader
local function TestSkillLoader()
    Log("\n=== 测试 SkillLoader 模块 ===")
    
    local testSkillIds = {131010101, 131020101, 100001}
    local successCount = 0
    
    for _, skillId in ipairs(testSkillIds) do
        local skillLua, err = SkillLoader.Load(skillId)
        if skillLua then
            Log(string.format("技能Lua %d 加载成功", skillId))
            successCount = successCount + 1
        else
            LogError(string.format("技能Lua %d 加载失败: %s", skillId, err or "unknown"))
        end
    end
    
    LogSuccess(string.format("SkillLoader: %d/%d 技能Lua加载成功", successCount, #testSkillIds))
    return successCount == #testSkillIds
end

-- 测试技能执行器
local function TestSkillExecutor()
    Log("\n=== 测试 SkillExecutor 模块 ===")
    
    local testSkillIds = {131010101, 131020101}
    local successCount = 0
    
    for _, skillId in ipairs(testSkillIds) do
        local skillLua, err = SkillLoader.Load(skillId)
        if skillLua then
            local effects = SkillExecutor.ExtractSkillEffects(skillLua)
            Log(string.format("技能 %d 效果解析: %d个伤害, %d个Buff, %d个治疗", 
                skillId, 
                #effects.damages, 
                #effects.buffs, 
                #effects.heals))
            
            -- 显示详细效果
            if #effects.damages > 0 then
                for i, dmg in ipairs(effects.damages) do
                    Log(string.format("  伤害%d: 攻击类型=%d, 伤害类型=%d", 
                        i, dmg.attackType, dmg.damageType))
                end
            end
            
            if #effects.buffs > 0 then
                for i, buff in ipairs(effects.buffs) do
                    Log(string.format("  Buff%d: BuffID=%d", i, buff.buffId))
                end
            end
            
            successCount = successCount + 1
        else
            LogError(string.format("技能 %d 无法加载用于执行器测试: %s", skillId, err or "unknown"))
        end
    end
    
    LogSuccess(string.format("SkillExecutor: %d/%d 技能效果解析成功", successCount, #testSkillIds))
    return successCount == #testSkillIds
end

-- 测试技能配置Lua文件
local function TestSkillConfigFiles()
    Log("\n=== 测试技能配置文件 ===")
    
    local testFiles = {
        "config.skill.skill_131010101",
        "config.skill.skill_131020101", 
        "config.skill.skill_100001"
    }
    
    local successCount = 0
    for _, filePath in ipairs(testFiles) do
        local success, result = pcall(function()
            return require(filePath)
        end)
        
        if success and result then
            Log(string.format("配置文件 %s 加载成功", filePath))
            successCount = successCount + 1
        else
            LogError(string.format("配置文件 %s 加载失败: %s", filePath, tostring(result)))
        end
    end
    
    LogSuccess(string.format("配置文件: %d/%d 加载成功", successCount, #testFiles))
    return successCount == #testFiles
end

-- 主测试函数
local function main()
    Log("开始技能系统测试...")
    Log(string.rep("=", 50))
    
    local results = {}
    
    -- 运行所有测试
    table.insert(results, {name = "SkillData", result = TestSkillData()})
    table.insert(results, {name = "SkillLoader", result = TestSkillLoader()})
    table.insert(results, {name = "SkillExecutor", result = TestSkillExecutor()})
    table.insert(results, {name = "SkillConfigFiles", result = TestSkillConfigFiles()})
    
    -- 打印汇总
    Log("\n" .. string.rep("=", 50))
    Log("技能系统测试汇总")
    Log(string.rep("=", 50))
    
    local allPassed = true
    for _, test in ipairs(results) do
        local status = test.result and "通过" or "失败"
        Log(string.format("%s: %s", test.name, status))
        if not test.result then
            allPassed = false
        end
    end
    
    Log(string.rep("=", 50))
    if allPassed then
        LogSuccess("所有测试通过！技能系统正常工作。")
    else
        LogError("部分测试失败，请检查技能系统配置。")
    end
    
    return allPassed
end

return main()
