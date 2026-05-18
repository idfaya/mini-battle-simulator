---@class RuntimeSkillEntry
---@field id integer
---@field symbol string|nil
---@field runtimeKind "active"|"passive"
---@field designKind string|nil
---@field classId integer
---@field name string
---@field hidden boolean
---@field cooldown integer
---@field luaFile string|nil
---@field trigger string|nil
---@field execution table|nil
---@field tags string[]
---@field runtimeData table|nil

local SkillConfig = require("config.tables.skills")

local SkillRuntimeConfig = {}
SkillRuntimeConfig.Ids = {}

---@type table<integer, RuntimeSkillEntry>
local SKILLS = {}
local loaded = false

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for k, v in pairs(value) do
        result[k] = deepCopy(v)
    end
    return result
end

---@param skillId integer
---@return RuntimeSkillEntry|nil
function SkillRuntimeConfig.Get(skillId)
    if not loaded then
        SkillRuntimeConfig.Reload()
    end
    local entry = SKILLS[tonumber(skillId) or 0]
    if not entry then
        return nil
    end
    return deepCopy(entry)
end

---@param classId integer
---@return RuntimeSkillEntry[]
function SkillRuntimeConfig.GetByClass(classId)
    if not loaded then
        SkillRuntimeConfig.Reload()
    end
    local result = {}
    for _, entry in pairs(SKILLS) do
        if tonumber(entry.classId) == tonumber(classId) then
            result[#result + 1] = deepCopy(entry)
        end
    end
    table.sort(result, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)
    return result
end

---@param skillId integer
---@return boolean
function SkillRuntimeConfig.IsBasicAttackSkill(skillId)
    if not loaded then
        SkillRuntimeConfig.Reload()
    end
    local entry = SKILLS[tonumber(skillId) or 0]
    if not entry then
        return false
    end
    for _, tag in ipairs(entry.tags or {}) do
        if tag == "basic_attack" then
            return true
        end
    end
    return false
end

function SkillRuntimeConfig.Reload()
    SKILLS = {}
    for key in pairs(SkillRuntimeConfig.Ids) do
        SkillRuntimeConfig.Ids[key] = nil
    end

    for _, skill in ipairs(SkillConfig.GetAllSkills()) do
        local runtimeData = deepCopy(skill.runtimeData or {})
        if runtimeData.skillType == nil and skill.skillType ~= nil then
            runtimeData.skillType = skill.skillType
        end
        if runtimeData.skillCost == nil and skill.skillCost ~= nil then
            runtimeData.skillCost = skill.skillCost
        end

        SKILLS[skill.id] = {
            id = skill.id,
            symbol = skill.symbol,
            runtimeKind = skill.runtimeKind or (tonumber(skill.skillType) == 4 and "passive" or "active"),
            designKind = skill.designKind,
            classId = tonumber(skill.classId) or 0,
            name = skill.name or ("Skill_" .. tostring(skill.id)),
            hidden = skill.hidden == true,
            cooldown = tonumber(skill.cooldown) or 0,
            luaFile = skill.luaFile,
            trigger = skill.trigger,
            execution = deepCopy(skill.execution),
            tags = deepCopy(skill.tags or {}),
            runtimeData = runtimeData,
        }

        if type(skill.symbol) == "string" and skill.symbol ~= "" then
            SkillRuntimeConfig.Ids[skill.symbol] = skill.id
        end
    end

    loaded = true
end

SkillRuntimeConfig.Reload()

return SkillRuntimeConfig
