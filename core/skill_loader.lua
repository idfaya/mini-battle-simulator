local SkillLoader = {}

-- 缓存表
local skillCache = {}
local configCache = {}

-- 路径配置
local SKILL_PATH = "skills/skill_%s.lua"
local CONFIG_PATH = "config/spell/spell_%s.lua"

-- 日志前缀
local LOG_TAG = "[SkillLoader]"

--- 获取技能文件路径
-- @param skillId 技能ID
-- @return string 文件路径
local function GetSkillPath(skillId)
    return string.format(SKILL_PATH, tostring(skillId))
end

--- 获取配置文件路径
-- @param skillId 技能ID
-- @return string 文件路径
local function GetConfigPath(skillId)
    return string.format(CONFIG_PATH, tostring(skillId))
end

--- 加载Lua模块（内部函数）
-- @param filePath 文件路径
-- @return table|nil, string|nil 成功返回模块，失败返回nil和错误信息
local function LoadModule(filePath)
    local success, result = pcall(function()
        return require(filePath)
    end)
    
    if success then
        return result, nil
    else
        return nil, tostring(result)
    end
end

--- 加载技能脚本
-- @param skillId 技能ID
-- @return table|nil, string|nil 成功返回技能模块，失败返回nil和错误信息
function SkillLoader.Load(skillId)
    if skillId == nil then
        return nil, "skillId is nil"
    end
    
    local id = tostring(skillId)
    
    -- 检查缓存
    if skillCache[id] then
        return skillCache[id], nil
    end
    
    local filePath = GetSkillPath(skillId)
    local module, err = LoadModule(filePath)
    
    if module then
        skillCache[id] = module
        return module, nil
    else
        return nil, string.format("Failed to load skill '%s': %s", id, err or "unknown error")
    end
end

--- 加载技能配置
-- @param skillId 技能ID
-- @return table|nil, string|nil 成功返回配置表，失败返回nil和错误信息
function SkillLoader.LoadSkillConfig(skillId)
    if skillId == nil then
        return nil, "skillId is nil"
    end
    
    local id = tostring(skillId)
    
    -- 检查缓存
    if configCache[id] then
        return configCache[id], nil
    end
    
    local filePath = GetConfigPath(skillId)
    local module, err = LoadModule(filePath)
    
    if module then
        configCache[id] = module
        return module, nil
    else
        return nil, string.format("Failed to load skill config '%s': %s", id, err or "unknown error")
    end
end

--- 强制重新加载技能（热重载）
-- @param skillId 技能ID
-- @return table|nil, string|nil 成功返回新的技能模块，失败返回nil和错误信息
function SkillLoader.Reload(skillId)
    if skillId == nil then
        return nil, "skillId is nil"
    end
    
    local id = tostring(skillId)
    
    -- 清除缓存
    skillCache[id] = nil
    
    -- 清除Lua模块缓存（如果环境支持package.loaded）
    if package and package.loaded then
        local filePath = GetSkillPath(skillId)
        package.loaded[filePath] = nil
    end
    
    -- 重新加载
    return SkillLoader.Load(skillId)
end

--- 从缓存卸载技能
-- @param skillId 技能ID
-- @return boolean 是否成功卸载
function SkillLoader.Unload(skillId)
    if skillId == nil then
        return false
    end
    
    local id = tostring(skillId)
    
    if skillCache[id] ~= nil then
        skillCache[id] = nil
        
        -- 清除Lua模块缓存
        if package and package.loaded then
            local filePath = GetSkillPath(skillId)
            package.loaded[filePath] = nil
        end
        
        return true
    end
    
    return false
end

--- 清除所有缓存的技能
function SkillLoader.ClearCache()
    -- 清除Lua模块缓存
    if package and package.loaded then
        for id, _ in pairs(skillCache) do
            local filePath = GetSkillPath(id)
            package.loaded[filePath] = nil
        end
        for id, _ in pairs(configCache) do
            local filePath = GetConfigPath(id)
            package.loaded[filePath] = nil
        end
    end
    
    -- 清除内部缓存
    skillCache = {}
    configCache = {}
end

--- 获取缓存统计信息
-- @return table 包含缓存统计信息的表
function SkillLoader.GetCacheInfo()
    local skillCount = 0
    local configCount = 0
    local skillList = {}
    local configList = {}
    
    for id, _ in pairs(skillCache) do
        skillCount = skillCount + 1
        table.insert(skillList, id)
    end
    
    for id, _ in pairs(configCache) do
        configCount = configCount + 1
        table.insert(configList, id)
    end
    
    -- 排序以便查看
    table.sort(skillList)
    table.sort(configList)
    
    return {
        skillCount = skillCount,
        configCount = configCount,
        totalCount = skillCount + configCount,
        skillList = skillList,
        configList = configList,
    }
end

--- 检查技能是否在缓存中
-- @param skillId 技能ID
-- @return boolean
function SkillLoader.IsCached(skillId)
    if skillId == nil then
        return false
    end
    return skillCache[tostring(skillId)] ~= nil
end

--- 检查技能配置是否在缓存中
-- @param skillId 技能ID
-- @return boolean
function SkillLoader.IsConfigCached(skillId)
    if skillId == nil then
        return false
    end
    return configCache[tostring(skillId)] ~= nil
end

return SkillLoader
