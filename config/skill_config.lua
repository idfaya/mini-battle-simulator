-- 技能配置加载模块
-- 加载 res_skill.json 并建立技能 ID 到配置的映射

local SkillConfig = {}

local skillConfigCache = {}

local function Log(msg)
    print("[SkillConfig] " .. msg)
end

local function LogError(msg)
    print("[SkillConfig] [ERROR] " .. msg)
end

local CONFIG_DIR = "config/"

function SkillConfig.Init()
    SkillConfig.LoadSkillConfig()
    Log("初始化完成")
end

function SkillConfig.LoadSkillConfig()
    local json = require("utils.json")
    local paths = {
        CONFIG_DIR .. "res_skill.json",
        "../config/res_skill.json",
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
        LogError("无法打开 res_skill.json")
        return false
    end

    local content = file:read("*a")
    file:close()

    local success, data = pcall(json.JsonDecode, content)
    if not success then
        LogError("解析 res_skill.json 失败: " .. tostring(data))
        return false
    end

    skillConfigCache = {}
    for _, skill in ipairs(data) do
        skillConfigCache[skill.ID] = skill
    end

    Log(string.format("加载了 %d 个技能配置", #data))
    return true
end

function SkillConfig.GetSkillConfig(skillId)
    if not skillId then
        return nil
    end
    return skillConfigCache[skillId]
end

function SkillConfig.GetSkillLuaPath(skillId)
    local config = skillConfigCache[skillId]
    if not config then
        return nil
    end

    local luaFileName = string.format("skill_%d", skillId)
    return string.format("config.skill.%s", luaFileName)
end

function SkillConfig.GetSkillType(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return nil
    end
    return config.Type
end

function SkillConfig.GetSkillParam(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return nil
    end
    return config.SkillParam
end

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

function SkillConfig.GetSkillCooldown(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return 0
    end
    return config.CoolDownR or 0
end

function SkillConfig.GetSkillCost(skillId)
    local config = SkillConfig.GetSkillConfig(skillId)
    if not config then
        return 0
    end
    return config.Cost or 0
end

function SkillConfig.GetSkillLevels(classId)
    local levels = {}
    for _, config in pairs(skillConfigCache) do
        if config.ClassID == classId then
            table.insert(levels, config)
        end
    end

    table.sort(levels, function(a, b)
        return a.SkillLevel < b.SkillLevel
    end)

    return levels
end

function SkillConfig.PrintSkillInfo(skillId)
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
    Log(string.format("  - LuaPath: %s", SkillConfig.GetSkillLuaPath(skillId) or "nil"))
    Log(string.format("  - CoolDown: %d", config.CoolDownR or 0))
    Log(string.format("  - Cost: %d", config.Cost or 0))
end

return SkillConfig
