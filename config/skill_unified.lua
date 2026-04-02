-- 技能配置统一接口模块
-- 整合原始技能配置和Roguelike技能配置，提供统一的访问接口

local SkillUnified = {}

-- 缓存原始配置模块
local skillConfig = nil
local skillRglConfig = nil

-- 本地日志函数
local function Log(msg)
    print("[SkillUnified] " .. msg)
end

local function LogError(msg)
    print("[SkillUnified] [ERROR] " .. msg)
end

-- 初始化
function SkillUnified.Init()
    -- 加载原始技能配置
    skillConfig = require("config.skill_config")
    if skillConfig and skillConfig.Init then
        skillConfig.Init()
    end
    
    -- 加载Roguelike技能配置
    skillRglConfig = require("config.skill_rgl_config")
    if skillRglConfig and skillRglConfig.Init then
        skillRglConfig.Init()
    end
    
    Log("初始化完成")
end

-- 判断是否为Roguelike技能ID
function SkillUnified.IsRglSkillId(skillId)
    if not skillId then return false end
    return skillId >= 800000001 and skillId <= 800010000
end

-- 获取技能配置（统一接口）
function SkillUnified.GetSkillConfig(skillId)
    if not skillId then return nil end
    
    -- 根据ID范围选择配置源
    if SkillUnified.IsRglSkillId(skillId) then
        if skillRglConfig then
            return skillRglConfig.GetSkillConfig(skillId)
        end
    else
        if skillConfig then
            return skillConfig.GetSkillConfig(skillId)
        end
    end
    
    return nil
end

-- 获取技能Lua脚本路径（统一接口）
function SkillUnified.GetSkillLuaPath(skillId)
    if not skillId then return nil end
    
    -- 根据ID范围选择配置源
    if SkillUnified.IsRglSkillId(skillId) then
        if skillRglConfig then
            return skillRglConfig.GetSkillLuaPath(skillId)
        end
    else
        if skillConfig then
            return skillConfig.GetSkillLuaPath(skillId)
        end
    end
    
    return nil
end

-- 获取技能类型（统一接口）
function SkillUnified.GetSkillType(skillId)
    if not skillId then return nil end
    
    if SkillUnified.IsRglSkillId(skillId) then
        if skillRglConfig then
            return skillRglConfig.GetSkillType(skillId)
        end
    else
        if skillConfig then
            return skillConfig.GetSkillType(skillId)
        end
    end
    
    return nil
end

-- 获取技能参数（统一接口）
function SkillUnified.GetSkillParam(skillId)
    if not skillId then return nil end
    
    if SkillUnified.IsRglSkillId(skillId) then
        if skillRglConfig then
            return skillRglConfig.GetSkillParam(skillId)
        end
    else
        if skillConfig then
            return skillConfig.GetSkillParam(skillId)
        end
    end
    
    return nil
end

-- 获取技能Buff配置（统一接口）
function SkillUnified.GetSkillBuffs(skillId)
    if not skillId then return nil end
    
    if SkillUnified.IsRglSkillId(skillId) then
        if skillRglConfig then
            return skillRglConfig.GetSkillBuffs(skillId)
        end
    else
        if skillConfig then
            return skillConfig.GetSkillBuffs(skillId)
        end
    end
    
    return nil
end

-- 获取技能冷却时间（统一接口）
function SkillUnified.GetSkillCooldown(skillId)
    if not skillId then return 0 end
    
    if SkillUnified.IsRglSkillId(skillId) then
        if skillRglConfig then
            return skillRglConfig.GetSkillCooldown(skillId)
        end
    else
        if skillConfig then
            return skillConfig.GetSkillCooldown(skillId)
        end
    end
    
    return 0
end

-- 获取技能消耗（统一接口）
function SkillUnified.GetSkillCost(skillId)
    if not skillId then return 0 end
    
    if SkillUnified.IsRglSkillId(skillId) then
        if skillRglConfig then
            return skillRglConfig.GetSkillCost(skillId)
        end
    else
        if skillConfig then
            return skillConfig.GetSkillCost(skillId)
        end
    end
    
    return 0
end

-- 打印技能信息（统一接口）
function SkillUnified.PrintSkillInfo(skillId)
    if not skillId then
        Log("技能ID为空")
        return
    end
    
    Log(string.format("技能 %d 信息:", skillId))
    
    if SkillUnified.IsRglSkillId(skillId) then
        Log("  - 类型: Roguelike技能")
        if skillRglConfig then
            skillRglConfig.PrintSkillInfo(skillId)
        end
    else
        Log("  - 类型: 原始技能")
        if skillConfig then
            skillConfig.PrintSkillInfo(skillId)
        end
    end
end

-- 获取所有Roguelike技能（用于技能树展示）
function SkillUnified.GetAllRglSkills()
    if not skillRglConfig then
        return {}
    end
    
    local skills = {}
    -- 遍历所有可能的Roguelike技能ID范围
    for id = 800000001, 800010000 do
        local config = skillRglConfig.GetSkillConfig(id)
        if config then
            table.insert(skills, config)
        end
    end
    
    return skills
end

-- 根据ClassID获取Roguelike技能的所有等级
function SkillUnified.GetRglSkillLevels(classId)
    if not skillRglConfig then
        return {}
    end
    
    return skillRglConfig.GetSkillLevels(classId)
end

-- 获取Roguelike技能配置模块（用于高级操作）
function SkillUnified.GetRglConfigModule()
    return skillRglConfig
end

-- 获取原始技能配置模块（用于高级操作）
function SkillUnified.GetOriginalConfigModule()
    return skillConfig
end

return SkillUnified
