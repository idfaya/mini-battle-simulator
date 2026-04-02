-- Roguelike Buff配置加载模块
-- 加载 res_buff_template_rgl.json 并建立Buff ID到配置的映射

local BuffRglConfig = {}

-- Buff配置缓存
local buffConfigCache = {}

-- 本地日志函数
local function Log(msg)
    print("[BuffRglConfig] " .. msg)
end

local function LogError(msg)
    print("[BuffRglConfig] [ERROR] " .. msg)
end

-- 配置目录路径
local CONFIG_DIR = "config/"

function BuffRglConfig.Init()
    BuffRglConfig.LoadBuffConfig()
    Log("初始化完成")
end

-- 加载Roguelike Buff配置
function BuffRglConfig.LoadBuffConfig()
    local json = require("utils.json")
    local paths = {
        CONFIG_DIR .. "res_buff_template_rgl.json",
        "../config/res_buff_template_rgl.json",
    }
    
    local file = nil
    for _, path in ipairs(paths) do
        file = io.open(path, "r")
        if file then
            Log("找到Buff配置文件: " .. path)
            break
        end
    end
    
    if not file then
        LogError("无法打开 res_buff_template_rgl.json")
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    local success, data = pcall(json.JsonDecode, content)
    if not success then
        LogError("解析 res_buff_template_rgl.json 失败: " .. tostring(data))
        return false
    end
    
    -- 建立ID到配置的映射
    for _, buff in ipairs(data) do
        buffConfigCache[buff.ID] = buff
    end
    
    Log(string.format("加载了 %d 个Roguelike Buff配置", #data))
    return true
end

-- 获取Buff配置
function BuffRglConfig.GetBuffConfig(buffId)
    return buffConfigCache[buffId]
end

-- 获取Buff Lua脚本路径
function BuffRglConfig.GetBuffLuaPath(buffId)
    local config = buffConfigCache[buffId]
    if not config then
        return nil
    end
    
    -- 构建Lua文件名: buff_{buffId}.lua
    local luaFileName = string.format("buff_%d", buffId)
    
    -- 从 buff_rgl 目录加载
    local luaPath = string.format("config.buff_rgl.%s", luaFileName)
    
    return luaPath
end

-- 将Buff配置转换为BattleBuff需要的格式
function BuffRglConfig.ConvertToBattleBuffConfig(buffId)
    local config = buffConfigCache[buffId]
    if not config then
        return nil
    end
    
    -- 构建效果列表
    local effects = {}
    if config.AttributeType and config.AttributeValue then
        for i, attrType in ipairs(config.AttributeType) do
            table.insert(effects, {
                type = "attribute",
                attrType = attrType,
                value = config.AttributeValue[i] or 0,
            })
        end
    end
    
    return {
        buffId = buffId,
        name = config.Name or "UnknownBuff",
        mainType = config.MainType or 1,
        subType = config.SubType or 0,
        duration = config.Duration or 3,
        initialStack = 1,
        maxStack = config.MaxLimit or 1,
        canStack = config.StackType ~= 0,
        stackType = config.StackType or 0,
        icon = "",
        desc = "",
        effects = effects,
    }
end

-- 根据MainType获取所有Buff
function BuffRglConfig.GetBuffsByMainType(mainType)
    local buffs = {}
    for buffId, config in pairs(buffConfigCache) do
        if config.MainType == mainType then
            table.insert(buffs, config)
        end
    end
    return buffs
end

-- 根据SubType获取Buff
function BuffRglConfig.GetBuffBySubType(subType)
    for buffId, config in pairs(buffConfigCache) do
        if config.SubType == subType then
            return config
        end
    end
    return nil
end

-- 打印Buff信息 (调试用)
function BuffRglConfig.PrintBuffInfo(buffId)
    local config = buffConfigCache[buffId]
    if not config then
        Log(string.format("Buff %d 不存在", buffId))
        return
    end
    
    Log(string.format("Buff %d 信息:", buffId))
    Log(string.format("  - 名称: %s", config.Name))
    Log(string.format("  - MainType: %d", config.MainType))
    Log(string.format("  - SubType: %d", config.SubType))
    Log(string.format("  - StackType: %d", config.StackType))
    Log(string.format("  - MaxLimit: %d", config.MaxLimit))
    Log(string.format("  - Duration: %d", config.Duration))
    Log(string.format("  - LuaPath: %s", BuffRglConfig.GetBuffLuaPath(buffId) or "nil"))
end

return BuffRglConfig
