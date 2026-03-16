--!/usr/bin/env lua

--============================================================================
-- 分析未找到的技能
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
print("  分析未找到的技能")
print("========================================\n")

-- 测试的技能ID列表
local testSkillIds = {
    1310101, 1310102, 1310103, 1310201, 1310202, 1310203,
    1310301, 1310302, 1310303, 1310401, 1310402, 1310403,
    1310501, 1310502, 1310503, 1310601, 1310602, 1310603,
    1310701, 1310702, 1310703, 1310801, 1310802, 1310803,
    1310901, 1310902, 1310903, 1311001, 1311002, 1311003,
    1320001, 1320002, 1320003,
}

-- 检查技能文件是否存在
local function CheckSkillFile(skillId)
    local fullSkillId = skillId * 100 + 1
    local fileName = string.format("skill_%d.lua", fullSkillId)
    local filePath = script_dir .. "config/skill/" .. fileName
    
    local file = io.open(filePath, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- 检查原工程中的技能文件
local function CheckOriginalSkillFile(skillId)
    local fullSkillId = skillId * 100 + 1
    local fileName = string.format("skill_%d.lua", fullSkillId)
    -- 使用正斜杠路径
    local filePath = "c:/work/yangfan.752_Dgame/D-Game/Dev/trunk/client/Assets/Lua/Modules/Battle/SkillNewLua/" .. fileName
    
    local file = io.open(filePath, "r")
    if file then
        file:close()
        return true
    end
    return false
end

print("检查技能文件存在情况...\n")

local found = 0
local notFound = 0
local notFoundInOriginal = 0
local missingList = {}

for _, skillId in ipairs(testSkillIds) do
    local fullSkillId = skillId * 100 + 1
    local exists = CheckSkillFile(skillId)
    local existsInOriginal = CheckOriginalSkillFile(skillId)
    
    if exists then
        found = found + 1
    else
        notFound = notFound + 1
        table.insert(missingList, {
            id = skillId,
            fullId = fullSkillId,
            fileName = string.format("skill_%d.lua", fullSkillId),
            existsInOriginal = existsInOriginal
        })
        
        if not existsInOriginal then
            notFoundInOriginal = notFoundInOriginal + 1
        end
    end
end

print(string.format("总计检查: %d 个技能", #testSkillIds))
print(string.format("找到: %d", found))
print(string.format("未找到: %d", notFound))
print(string.format("原项目中也不存在: %d\n", notFoundInOriginal))

if #missingList > 0 then
    print("--- 未找到的技能列表 ---")
    print(string.format("%-10s %-20s %-30s %s", "技能ID", "完整ID", "文件名", "原项目存在"))
    print(string.rep("-", 80))
    
    for _, info in ipairs(missingList) do
        print(string.format("%-10d %-20d %-30s %s",
            info.id,
            info.fullId,
            info.fileName,
            info.existsInOriginal and "是" or "否"
        ))
    end
end

-- 检查实际存在的技能文件数量
print("\n--- 实际文件统计 ---")
local configCount = 0
local originalCount = 0

-- 统计config目录
local cmd1 = 'dir /b "' .. script_dir .. 'config/skill/skill_*.lua" 2>nul | find /c /v ""'
local handle1 = io.popen(cmd1)
if handle1 then
    configCount = tonumber(handle1:read("*a")) or 0
    handle1:close()
end

-- 统计原工程目录 (使用正斜杠避免转义问题)
local cmd2 = 'dir /b "c:/work/yangfan.752_Dgame/D-Game/Dev/trunk/client/Assets/Lua/Modules/Battle/SkillNewLua/skill_*.lua" 2>nul | find /c /v ""'
local handle2 = io.popen(cmd2)
if handle2 then
    originalCount = tonumber(handle2:read("*a")) or 0
    handle2:close()
end

print(string.format("config/skill 目录: %d 个文件", configCount))
print(string.format("原工程目录: %d 个文件", originalCount))

print("\n========================================")
print("  分析完成")
print("========================================")
