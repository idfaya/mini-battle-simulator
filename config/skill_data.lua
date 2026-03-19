---
--- Skill Data Module
--- 加载和管理技能配置数据 (res_skill)
---

local JSON = require("utils.json")
local SkillData = {}

-- 本地日志函数
local function Log(msg)
    print(msg)
end

local function LogError(msg)
    print("[ERROR] " .. msg)
end

-- 配置目录路径（从bin目录运行时的相对路径）
local CONFIG_DIR = "../config/"

-- 内部数据存储
local skillMap = {}      -- SkillID -> skill config
local skillsByClass = {} -- ClassID -> {skill1, skill2, ...}

--- 加载技能配置数据
local function LoadSkillData()
    local file = io.open(CONFIG_DIR .. "res_skill.json", "r")
    if not file then
        LogError("[SkillData] Failed to open res_skill.json")
        return
    end

    local content = file:read("*a")
    file:close()

    local data = JSON.JsonDecode(content)
    if not data then
        LogError("[SkillData] Failed to parse res_skill.json")
        return
    end

    for _, skill in ipairs(data) do
        skillMap[skill.ID] = skill

        -- 按ClassID分类
        local classId = skill.ClassID
        if not skillsByClass[classId] then
            skillsByClass[classId] = {}
        end
        table.insert(skillsByClass[classId], skill)
    end

    Log(string.format("[SkillData] Loaded %d skills", #data))
end

--- 获取技能配置
---@param skillId number 技能ID
---@return table|nil 技能配置
function SkillData.GetSkill(skillId)
    return skillMap[skillId]
end

--- 通过ClassID获取技能列表
---@param classId number 技能类别ID
---@return table 技能列表
function SkillData.GetSkillsByClass(classId)
    return skillsByClass[classId] or {}
end

--- 获取技能类型
---@param skillId number 技能ID
---@return number 技能类型 (1=小技能, 2=大招, 3=被动)
function SkillData.GetSkillType(skillId)
    local skill = skillMap[skillId]
    if skill then
        return skill.Type
    end
    return 1  -- 默认小技能
end

--- 获取技能优先级
---@param skillId number 技能ID
---@return number 优先级
function SkillData.GetSkillPriority(skillId)
    local skill = skillMap[skillId]
    if skill then
        return skill.SkillPriorities or 999
    end
    return 999
end

--- 获取技能冷却
---@param skillId number 技能ID
---@return number 冷却回合
function SkillData.GetSkillCoolDown(skillId)
    local skill = skillMap[skillId]
    if skill then
        return skill.CoolDownR or 0
    end
    return 0
end

--- 获取技能消耗
---@param skillId number 技能ID
---@return number 能量消耗
function SkillData.GetSkillCost(skillId)
    local skill = skillMap[skillId]
    if skill then
        return skill.Cost or 0
    end
    return 0
end

--- 获取技能参数
---@param skillId number 技能ID
---@return table 参数数组
function SkillData.GetSkillParam(skillId)
    local skill = skillMap[skillId]
    if skill and skill.SkillParam then
        return skill.SkillParam
    end
    return {}
end

--- 获取技能Buff列表
---@param skillId number 技能ID
---@return table BuffID数组
function SkillData.GetSkillBuffs(skillId)
    local skill = skillMap[skillId]
    if not skill then
        return {}
    end

    local buffs = {}
    for i = 1, 5 do
        local buffKey = "Buff" .. i
        if skill[buffKey] and #skill[buffKey] > 0 then
            for _, buffId in ipairs(skill[buffKey]) do
                if buffId > 0 then
                    table.insert(buffs, buffId)
                end
            end
        end
    end
    return buffs
end

--- 获取技能模板ID (ClassID + "01")
---@param skillId number 技能ID
---@return string 模板ID
function SkillData.GetSkillTemplateId(skillId)
    local skill = skillMap[skillId]
    if skill then
        return skill.ClassID .. "01"
    end
    return nil
end

--- 获取技能ClassID
---@param skillId number 技能ID
---@return number|nil ClassID
function SkillData.GetSkillClassId(skillId)
    local skill = skillMap[skillId]
    if skill then
        return skill.ClassID
    end
    return nil
end

--- 获取所有技能ID列表
---@return table 技能ID列表
function SkillData.GetAllSkillIds()
    local ids = {}
    for id, _ in pairs(skillMap) do
        table.insert(ids, id)
    end
    table.sort(ids)
    return ids
end

--- 打印技能信息（调试用）
---@param skillId number 技能ID
function SkillData.PrintSkillInfo(skillId)
    local skill = skillMap[skillId]
    if not skill then
        Log("[SkillData] Skill not found: " .. tostring(skillId))
        return
    end

    Log("[SkillData] Skill Info:")
    Log("  ID: " .. skill.ID)
    Log("  ClassID: " .. skill.ClassID)
    Log("  Name: " .. tostring(skill.Name))
    Log("  Type: " .. skill.Type)
    Log("  Level: " .. skill.SkillLevel)
    Log("  Priority: " .. skill.SkillPriorities)
    Log("  CoolDown: " .. skill.CoolDownR)
    Log("  Cost: " .. skill.Cost)
    Log("  SkillParam: " .. table.concat(skill.SkillParam or {}, ", "))
end

-- 初始化
LoadSkillData()

return SkillData
