-- Roguelike 技能配置加载模块
-- 加载 res_skill_rgl.json 并建立技能ID到配置的映射

local SkillRglConfig = {}

-- 技能配置缓存
local skillConfigCache = {}

-- 本地日志函数
local function Log(msg)
    print("[SkillRglConfig] " .. msg)
end

local function LogError(msg)
    print("[SkillRglConfig] [ERROR] " .. msg)
end

-- 配置目录路径
local CONFIG_DIR = "config/"

function SkillRglConfig.Init()
    SkillRglConfig.LoadSkillConfig()
    Log("初始化完成")
end

-- 加载Roguelike技能配置
function SkillRglConfig.LoadSkillConfig()
    local json = require("utils.json")
    local paths = {
        CONFIG_DIR .. "res_skill_rgl.json",
        "../config/res_skill_rgl.json",
    }
    
    local file = nil
    for _, path in ipairs(paths) do
        file = io.open(path, "r")
        if file then
            Log("找到技能配置文件: " .. path)
            break
        end
    end
    
    if not file then
        LogError("无法打开 res_skill_rgl.json")
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    local success, data = pcall(json.JsonDecode, content)
    if not success then
        LogError("解析 res_skill_rgl.json 失败: " .. tostring(data))
        return false
    end
    
    -- 建立ID到配置的映射
    for _, skill in ipairs(data) do
        skillConfigCache[skill.ID] = skill
    end
    
    Log(string.format("加载了 %d 个Roguelike技能配置", #data))
    return true
end

-- 获取技能配置
function SkillRglConfig.GetSkillConfig(skillId)
    if not skillId then return nil end
    return skillConfigCache[skillId]
end

-- 获取技能Lua脚本路径
function SkillRglConfig.GetSkillLuaPath(skillId)
    local config = skillConfigCache[skillId]
    if not config then
        return nil
    end
    
    -- 构建Lua文件名: skill_{完整技能ID}.lua
    -- 完整技能ID = ClassID * 100 + SkillLevel
    local fullSkillId = config.ClassID * 100 + config.SkillLevel
    local luaFileName = string.format("skill_%d", fullSkillId)
    
    -- 从 skill_rgl 目录加载
    local luaPath = string.format("config.skill_rgl.%s", luaFileName)
    
    return luaPath
end

-- 获取技能类型
function SkillRglConfig.GetSkillType(skillId)
    local config = SkillRglConfig.GetSkillConfig(skillId)
    if not config then
        return nil
    end
    return config.Type
end

-- 获取技能参数
function SkillRglConfig.GetSkillParam(skillId)
    local config = SkillRglConfig.GetSkillConfig(skillId)
    if not config then
        return nil
    end
    return config.SkillParam
end

-- 获取技能Buff配置
function SkillRglConfig.GetSkillBuffs(skillId)
    local config = SkillRglConfig.GetSkillConfig(skillId)
    if not config then
        return nil
    end
    
    local buffs = {}
    for i = 1, 5 do
        local buffKey = "Buff" .. i
        if config[buffKey] and #config[buffKey] > 0 then
            table.insert(buffs, config[buffKey])
        end
    end
    return buffs
end

-- 获取技能冷却时间
function SkillRglConfig.GetSkillCooldown(skillId)
    local config = SkillRglConfig.GetSkillConfig(skillId)
    if not config then
        return 0
    end
    return config.CoolDownR or 0
end

-- 获取技能消耗
function SkillRglConfig.GetSkillCost(skillId)
    local config = SkillRglConfig.GetSkillConfig(skillId)
    if not config then
        return 0
    end
    return config.Cost or 0
end

-- 根据ClassID获取所有等级
function SkillRglConfig.GetSkillLevels(classId)
    local levels = {}
    for skillId, config in pairs(skillConfigCache) do
        if config.ClassID == classId then
            table.insert(levels, config)
        end
    end
    -- 按SkillLevel排序
    table.sort(levels, function(a, b) return a.SkillLevel < b.SkillLevel end)
    return levels
end

-- 打印技能信息 (调试用)
function SkillRglConfig.PrintSkillInfo(skillId)
    local config = skillConfigCache[skillId]
    if not config then
        Log(string.format("技能 %d 不存在", skillId))
        return
    end
    
    Log(string.format("技能 %d 信息:", skillId))
    Log(string.format("  - 名称: %s", config.Name))
    Log(string.format("  - ClassID: %d", config.ClassID))
    Log(string.format("  - SkillLevel: %d", config.SkillLevel))
    Log(string.format("  - Type: %d", config.Type))
    Log(string.format("  - LuaPath: %s", SkillRglConfig.GetSkillLuaPath(skillId) or "nil"))
    Log(string.format("  - CoolDown: %d", config.CoolDownR or 0))
    Log(string.format("  - Cost: %d", config.Cost or 0))
end

return SkillRglConfig
