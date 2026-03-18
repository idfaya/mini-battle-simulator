-- 测试 Skill/Spell/Buff 配置加载
-- 统计并测试所有配置文件的完整性和可加载性

-- 设置包路径
local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = package.path
    .. ";" .. script_dir .. "../?.lua"
    .. ";" .. script_dir .. "../core/?.lua"
    .. ";" .. script_dir .. "../config/?.lua"
    .. ";" .. script_dir .. "../modules/?.lua"

-- 先加载必要的默认类型定义和兼容层
require("core.battle_types")
require("core.battle_default_types")

local function Log(msg)
    print(string.format("[TEST] %s", msg))
end

local function LogError(msg)
    print(string.format("[TEST] [ERROR] %s", msg))
end

local function LogSuccess(msg)
    print(string.format("[TEST] [OK] %s", msg))
end

-- 配置统计信息
local stats = {
    skill = { total = 0, loaded = 0, failed = 0, errors = {} },
    spell = { total = 0, loaded = 0, failed = 0, errors = {} },
    buff = { total = 0, loaded = 0, failed = 0, errors = {} }
}

-- 获取目录下的所有lua文件
local function GetLuaFiles(dir)
    local files = {}
    local cmd = string.format('dir /b /s "%s\\*.lua" 2>nul', dir)
    local handle = io.popen(cmd)
    if handle then
        for line in handle:lines() do
            table.insert(files, line)
        end
        handle:close()
    end
    return files
end

-- 测试Skill配置
local function TestSkills()
    Log("=== 测试 Skill 配置 ===")
    local skillDir = script_dir .. "../config/skill"
    local files = GetLuaFiles(skillDir)
    stats.skill.total = #files
    
    Log(string.format("发现 %d 个 Skill 文件", #files))
    
    local prefixStats = {}
    for _, filepath in ipairs(files) do
        local filename = filepath:match("([^\\]+)%.lua$")
        if filename then
            -- 提取ID前缀
            local id = filename:match("skill_(%d+)")
            if id then
                local prefix = id:sub(1, 2)
                prefixStats[prefix] = (prefixStats[prefix] or 0) + 1
            end
            
            -- 尝试加载
            local luaPath = "config.skill." .. filename
            local success, result = pcall(function()
                return require(luaPath)
            end)
            
            if success and result then
                stats.skill.loaded = stats.skill.loaded + 1
            else
                stats.skill.failed = stats.skill.failed + 1
                table.insert(stats.skill.errors, { file = filename, error = tostring(result) })
            end
        end
    end
    
    -- 打印前缀统计
    Log("Skill ID前缀分布:")
    for prefix, count in pairs(prefixStats) do
        Log(string.format("  %sxxxxx: %d 个", prefix, count))
    end
    
    LogSuccess(string.format("Skill: %d/%d 加载成功", stats.skill.loaded, stats.skill.total))
    if stats.skill.failed > 0 then
        LogError(string.format("Skill: %d 个加载失败", stats.skill.failed))
    end
end

-- 测试Spell配置
local function TestSpells()
    Log("\n=== 测试 Spell 配置 ===")
    local spellDir = script_dir .. "../config/spell"
    local files = GetLuaFiles(spellDir)
    stats.spell.total = #files
    
    Log(string.format("发现 %d 个 Spell 文件", #files))
    
    local prefixStats = {}
    for _, filepath in ipairs(files) do
        local filename = filepath:match("([^\\]+)%.lua$")
        if filename then
            -- 提取ID前缀
            local id = filename:match("spell_(%d+)")
            if id then
                local prefix = id:sub(1, 2)
                prefixStats[prefix] = (prefixStats[prefix] or 0) + 1
            end
            
            -- 尝试加载
            local luaPath = "config.spell." .. filename
            local success, result = pcall(function()
                return require(luaPath)
            end)
            
            if success and result then
                stats.spell.loaded = stats.spell.loaded + 1
            else
                stats.spell.failed = stats.spell.failed + 1
                table.insert(stats.spell.errors, { file = filename, error = tostring(result) })
            end
        end
    end
    
    -- 打印前缀统计
    Log("Spell ID前缀分布:")
    for prefix, count in pairs(prefixStats) do
        Log(string.format("  %sxxxxx: %d 个", prefix, count))
    end
    
    LogSuccess(string.format("Spell: %d/%d 加载成功", stats.spell.loaded, stats.spell.total))
    if stats.spell.failed > 0 then
        LogError(string.format("Spell: %d 个加载失败", stats.spell.failed))
    end
end

-- 测试Buff配置
local function TestBuffs()
    Log("\n=== 测试 Buff 配置 ===")
    local buffDir = script_dir .. "../config/buff"
    local files = GetLuaFiles(buffDir)
    stats.buff.total = #files
    
    Log(string.format("发现 %d 个 Buff 文件", #files))
    
    local prefixStats = {}
    for _, filepath in ipairs(files) do
        local filename = filepath:match("([^\\]+)%.lua$")
        if filename then
            -- 提取ID前缀
            local id = filename:match("buff_(%d+)")
            if id then
                local prefix = id:sub(1, 2)
                prefixStats[prefix] = (prefixStats[prefix] or 0) + 1
            end
            
            -- 尝试加载
            local luaPath = "config.buff." .. filename
            local success, result = pcall(function()
                return require(luaPath)
            end)
            
            if success and result then
                stats.buff.loaded = stats.buff.loaded + 1
            else
                stats.buff.failed = stats.buff.failed + 1
                table.insert(stats.buff.errors, { file = filename, error = tostring(result) })
            end
        end
    end
    
    -- 打印前缀统计
    Log("Buff ID前缀分布:")
    for prefix, count in pairs(prefixStats) do
        Log(string.format("  %sxxxxx: %d 个", prefix, count))
    end
    
    LogSuccess(string.format("Buff: %d/%d 加载成功", stats.buff.loaded, stats.buff.total))
    if stats.buff.failed > 0 then
        LogError(string.format("Buff: %d 个加载失败", stats.buff.failed))
    end
end

-- 打印详细错误
local function PrintErrors()
    if stats.skill.failed > 0 then
        Log("\n=== Skill 加载错误详情 ===")
        for _, err in ipairs(stats.skill.errors) do
            LogError(string.format("%s: %s", err.file, err.error))
        end
    end
    
    if stats.spell.failed > 0 then
        Log("\n=== Spell 加载错误详情 ===")
        for _, err in ipairs(stats.spell.errors) do
            LogError(string.format("%s: %s", err.file, err.error))
        end
    end
    
    if stats.buff.failed > 0 then
        Log("\n=== Buff 加载错误详情 ===")
        for _, err in ipairs(stats.buff.errors) do
            LogError(string.format("%s: %s", err.file, err.error))
        end
    end
end

-- 打印汇总
local function PrintSummary()
    Log("\n" .. string.rep("=", 50))
    Log("配置测试汇总")
    Log(string.rep("=", 50))
    
    local totalFiles = stats.skill.total + stats.spell.total + stats.buff.total
    local totalLoaded = stats.skill.loaded + stats.spell.loaded + stats.buff.loaded
    local totalFailed = stats.skill.failed + stats.spell.failed + stats.buff.failed
    
    Log(string.format("Skill:  %d 个文件, %d 成功, %d 失败", 
        stats.skill.total, stats.skill.loaded, stats.skill.failed))
    Log(string.format("Spell:  %d 个文件, %d 成功, %d 失败", 
        stats.spell.total, stats.spell.loaded, stats.spell.failed))
    Log(string.format("Buff:   %d 个文件, %d 成功, %d 失败", 
        stats.buff.total, stats.buff.loaded, stats.buff.failed))
    Log(string.rep("-", 50))
    Log(string.format("总计:   %d 个文件, %d 成功, %d 失败", 
        totalFiles, totalLoaded, totalFailed))
    Log(string.format("成功率: %.2f%%", (totalLoaded / totalFiles) * 100))
    Log(string.rep("=", 50))
end

-- 主函数
local function main()
    Log("开始测试配置加载...")
    Log(string.rep("=", 50))
    
    TestSkills()
    TestSpells()
    TestBuffs()
    
    PrintErrors()
    PrintSummary()
    
    Log("\n测试完成!")
end

main()
