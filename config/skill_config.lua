-- 技能配置加载模块
-- 加载 res_skill.json 并建立技能ID到Lua脚本路径的映射

local SkillConfig = {}

-- 技能配置缓存
local skillConfigCache = {}

-- 本地日志函数
local function Log(msg)
    print("[SkillConfig] " .. msg)
end

local function LogError(msg)
    print("[SkillConfig] [ERROR] " .. msg)
end

local function LogWarning(msg)
    print("[SkillConfig] [WARN] " .. msg)
end

-- 技能类ID到Lua文件名的映射
-- 命名规则: skill_{ClassID}0{SkillLevel}1.lua
-- 例如: ClassID=1310101, Level=1 -> skill_131010101.lua

function SkillConfig.Init()
    SkillConfig.LoadSkillConfig()
    Log("初始化完成")
end

-- 配置目录路径（从bin目录运行时的相对路径）
local CONFIG_DIR = "../config/"

function SkillConfig.LoadSkillConfig()
    local json = require("utils.json")
    -- 只使用本地配置路径
    local paths = {
        CONFIG_DIR .. "res_skill.json",
        "config/res_skill.json",
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
        LogError("无法打开 res_skill.json，尝试了以下路径: " .. table.concat(paths, ", "))
        return false
    end
    
    local content = file:read("*a")
    file:close()
    
    local success, data = pcall(json.JsonDecode, content)
    if not success then
        LogError("解析 res_skill.json 失败: " .. tostring(data))
        return false
    end
    
    -- 建立ID到配置的映射
    for _, skill in ipairs(data) do
        skillConfigCache[skill.ID] = skill
    end
    
    Log(string.format("加载了 %d 个技能配置", #data))
    return true
end

-- 获取技能配置
-- 注意: skillId 可能是 7位(ClassID) 或 9位(完整ID)
function SkillConfig.GetSkillConfig(skillId)
    if not skillId then return nil end
    
    local config = skillConfigCache[skillId]
    
    -- 如果找不到，尝试将7位ID转换为9位ID (默认等级1)
    if not config then
        local skillIdStr = tostring(skillId)
        if #skillIdStr == 7 then
            local fullSkillId = tonumber(skillIdStr .. "01")
            config = skillConfigCache[fullSkillId]
        end
    end
    
    return config
end

-- 获取技能Lua脚本路径
-- 命名规则: skill_{ClassID}0{SkillLevel}1.lua
-- 注意: skillId 可能是 7位(ClassID) 或 9位(完整ID)
function SkillConfig.GetSkillLuaPath(skillId)
    if not skillId then return nil end
    
    -- 尝试直接查找配置
    local config = skillConfigCache[skillId]
    
    -- 如果找不到，尝试将7位ID转换为9位ID (默认等级1)
    if not config then
        local skillIdStr = tostring(skillId)
        if #skillIdStr == 7 then
            -- 7位ID是ClassID，需要加上等级和末尾1
            -- 例如: 1310102 -> 131010201
            local fullSkillId = tonumber(skillIdStr .. "01")
            config = skillConfigCache[fullSkillId]
        end
    end
    
    if not config then
        return nil
    end
    
    -- 构建Lua文件名
    -- 命名规则: skill_{完整技能ID}.lua
    -- 完整技能ID = ClassID * 100 + SkillLevel
    -- 例如: ClassID=1310101, SkillLevel=1 -> 131010101 -> skill_131010101.lua
    -- 注意: 技能Lua文件只实现了等级1的版本，所以总是使用等级1
    local fullSkillId = config.ClassID * 100 + 1  -- 总是使用等级1的脚本
    local luaFileName = string.format("skill_%d", fullSkillId)
    
    -- 从本地config目录加载技能Lua
    -- 路径格式: config.skill.skill_131010101
    local luaPath = string.format("config.skill.%s", luaFileName)
    
    return luaPath
end

-- 获取技能类型
function SkillConfig.GetSkillType(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return nil
    end
    return config.Type
end

-- 获取技能参数
function SkillConfig.GetSkillParam(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return nil
    end
    return config.SkillParam
end

-- 获取技能Buff配置
function SkillConfig.GetSkillBuffs(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
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
function SkillConfig.GetSkillCooldown(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return 0
    end
    return config.CoolDownR or 0
end

-- 获取技能消耗
function SkillConfig.GetSkillCost(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return 0
    end
    return config.Cost or 0
end

-- 打印技能信息 (调试用)
function SkillConfig.PrintSkillInfo(skillId)
    local config = skillConfigCache[skillId]
    if not config then
        Log(string.format("技能 %d 不存在", skillId))
        return
    end
    
    Log(string.format("技能 %d 信息:", skillId))
    Log(string.format("  - ClassID: %d", config.ClassID))
    Log(string.format("  - SkillLevel: %d", config.SkillLevel))
    Log(string.format("  - Type: %d", config.Type))
    Log(string.format("  - LuaPath: %s", SkillConfig.GetSkillLuaPath(skillId) or "nil"))
    Log(string.format("  - CoolDown: %d", config.CoolDownR or 0))
    Log(string.format("  - Cost: %d", config.Cost or 0))
end

return SkillConfig
