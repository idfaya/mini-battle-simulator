local ConfigJsonLoader = require("config.json_loader")

local SkillsTable = {}

local skillConfigCache = {}
local allSkills = {}
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

local function hasLuaSkillModule(skillId)
    local paths = {
        string.format("config/skill/skill_%d.lua", skillId),
        string.format("../config/skill/skill_%d.lua", skillId),
    }
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            return true
        end
    end
    return false
end

local function deriveClassId(classGroupId, skillId)
    local rawClassGroupId = tonumber(classGroupId) or 0
    if rawClassGroupId > 0 then
        return math.floor((rawClassGroupId % 10000) / 100)
    end
    local id = tonumber(skillId) or 0
    return math.floor(id / 1000) % 100
end

local function inferRuntimeKind(skillType, rawSkill)
    if type(rawSkill and rawSkill.runtimeKind) == "string" then
        return rawSkill.runtimeKind
    end
    return tonumber(skillType) == 4 and "passive" or "active"
end

local function inferDesignKind(runtimeKind, skillType, rawSkill)
    if type(rawSkill and rawSkill.designKind) == "string" then
        return rawSkill.designKind
    end
    if runtimeKind == "passive" then
        return "passive"
    end
    if tonumber(skillType) == 3 then
        return "ultimate"
    end
    return "active"
end

local function inferLuaFile(skillId, rawSkill)
    if type(rawSkill and rawSkill.luaFile) == "string" and rawSkill.luaFile ~= "" then
        return rawSkill.luaFile
    end
    if hasLuaSkillModule(skillId) then
        return string.format("config.skill.skill_%d", skillId)
    end
    return nil
end

local function normalizeSkill(rawSkill)
    local skillId = tonumber(rawSkill and rawSkill.id)
    if not skillId then
        return nil
    end

    local classGroupId = tonumber(rawSkill.classGroupId)
    local classId = tonumber(rawSkill.classId) or deriveClassId(classGroupId, skillId)
    local skillType = tonumber(rawSkill.skillType)
        or (type(rawSkill.runtimeData) == "table" and tonumber(rawSkill.runtimeData.skillType))
        or 0
    local cooldown = tonumber(rawSkill.cooldown) or 0
    local skillCost = tonumber(rawSkill.skillCost)
        or (type(rawSkill.runtimeData) == "table" and tonumber(rawSkill.runtimeData.skillCost))
        or 0
    local runtimeKind = inferRuntimeKind(skillType, rawSkill)
    local designKind = inferDesignKind(runtimeKind, skillType, rawSkill)

    return {
        id = skillId,
        symbol = rawSkill.symbol,
        name = rawSkill.name or ("Skill_" .. tostring(skillId)),
        description = rawSkill.description or "",
        icon = rawSkill.icon or "",
        classId = classId,
        classGroupId = classGroupId,
        skillTier = tonumber(rawSkill.skillTier),
        unlockLevel = tonumber(rawSkill.unlockLevel) or 1,
        skillType = skillType,
        cooldown = cooldown,
        skillCost = skillCost,
        hidden = rawSkill.hidden == true,
        runtimeKind = runtimeKind,
        designKind = designKind,
        luaFile = inferLuaFile(skillId, rawSkill),
        trigger = rawSkill.trigger,
        execution = deepCopy(rawSkill.execution),
        tags = deepCopy(rawSkill.tags or {}),
        runtimeData = deepCopy(rawSkill.runtimeData or {}),
        rules = deepCopy(rawSkill.rules or {}),
        skillParam = deepCopy(rawSkill.skillParam or {}),
        buffs = deepCopy(rawSkill.buffs or {}),
    }
end

local function rebuildAllSkills()
    allSkills = {}
    for _, entry in pairs(skillConfigCache) do
        allSkills[#allSkills + 1] = entry
    end
    table.sort(allSkills, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)
end

local function ensureLoaded()
    if loaded then
        return true
    end
    return SkillsTable.Reload()
end

function SkillsTable.Reload()
    local data = assert(ConfigJsonLoader.Load("data/skills.json", { expectedType = "table" }))
    skillConfigCache = {}

    if #data > 0 then
        for _, rawSkill in ipairs(data) do
            local entry = normalizeSkill(rawSkill)
            if entry then
                skillConfigCache[entry.id] = entry
            end
        end
    else
        for key, rawSkill in pairs(data) do
            if type(rawSkill) == "table" then
                rawSkill.id = rawSkill.id or tonumber(key)
                local entry = normalizeSkill(rawSkill)
                if entry then
                    skillConfigCache[entry.id] = entry
                end
            end
        end
    end

    rebuildAllSkills()
    loaded = true
    return true
end

function SkillsTable.Init()
    return ensureLoaded()
end

function SkillsTable.GetSkillConfig(skillId)
    if not skillId then
        return nil
    end
    ensureLoaded()
    return skillConfigCache[tonumber(skillId) or 0]
end

function SkillsTable.GetAllSkills()
    ensureLoaded()
    return allSkills
end

return SkillsTable


