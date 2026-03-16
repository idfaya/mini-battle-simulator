-- Buff配置加载模块
-- 加载 res_buff_template.json 并建立Buff ID到配置的映射

local BuffConfig = {}

-- Buff配置缓存
local buffConfigCache = {}

-- 本地日志函数
local function Log(msg)
    print("[BuffConfig] " .. msg)
end

local function LogError(msg)
    print("[BuffConfig] [ERROR] " .. msg)
end

-- 加载Buff配置
function BuffConfig.LoadBuffConfig()
    local json = require("utils.json")
    
    -- 尝试多个可能的路径
    local paths = {
        "config/res_buff_template.json",
        "Assets/Res/Data/res_buff_template.json",
        "../Assets/Res/Data/res_buff_template.json",
    }
    
    local file = nil
    local usedPath = nil
    for _, path in ipairs(paths) do
        file = io.open(path, "r")
        if file then
            usedPath = path
            break
        end
    end
    
    if not file then
        LogError("无法打开 res_buff_template.json")
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    local success, data = pcall(json.JsonDecode, content)
    if not success then
        LogError("解析 res_buff_template.json 失败: " .. tostring(data))
        return false
    end
    
    -- 建立ID到配置的映射
    for _, buff in ipairs(data) do
        buffConfigCache[buff.ID] = buff
    end
    
    Log(string.format("加载了 %d 个Buff配置", #data))
    return true
end

-- 获取Buff配置
function BuffConfig.GetBuffConfig(buffId)
    return buffConfigCache[buffId]
end

-- 将Buff配置转换为BattleBuff需要的格式
function BuffConfig.ConvertToBattleBuffConfig(buffId)
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
        duration = 3,  -- 默认持续3回合
        initialStack = 1,
        maxStack = config.MaxLimit or 1,
        canStack = config.StackType ~= 0,
        icon = config.BuffIcon or "",
        desc = config.Des or "",
        effects = effects,
    }
end

-- 初始化
function BuffConfig.Init()
    BuffConfig.LoadBuffConfig()
    Log("初始化完成")
end

return BuffConfig
