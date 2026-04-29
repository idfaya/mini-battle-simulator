local SkillRuntime = {}

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

local function toSkillType(entry)
    local runtimeData = entry.runtimeData or {}
    if runtimeData.skillType ~= nil then
        return runtimeData.skillType
    end
    if entry.runtimeKind == "passive" then
        return E_SKILL_TYPE_PASSIVE
    end
    return E_SKILL_TYPE_ACTIVE
end

local function buildSkillConfig(entry)
    local runtimeData = deepCopy(entry.runtimeData or {})
    local skillConfig = {
        skillId = entry.id,
        classId = entry.classId,
        name = entry.name,
        skillType = toSkillType(entry),
        level = tonumber(runtimeData.level) or 1,
        skillCost = tonumber(runtimeData.skillCost) or 0,
        coolDown = tonumber(entry.cooldown) or 0,
        hidden = entry.hidden == true,
        runtimeKind = entry.runtimeKind,
        designKind = entry.designKind,
        runtimeData = runtimeData,
        tags = deepCopy(entry.tags or {}),
        luaFile = entry.luaFile,
        trigger = entry.trigger,
        execution = deepCopy(entry.execution),
    }

    if runtimeData.maxCoolDown == nil then
        runtimeData.maxCoolDown = skillConfig.coolDown
    end
    if runtimeData.hidden == nil then
        runtimeData.hidden = skillConfig.hidden
    end

    for k, v in pairs(runtimeData) do
        if skillConfig[k] == nil then
            skillConfig[k] = deepCopy(v)
        end
    end

    return skillConfig
end

---@param buildState table|nil
---@return table[]
function SkillRuntime.BuildSkillsConfig(buildState)
    if type(buildState) ~= "table" then
        return {}
    end

    local result = {}
    for _, entry in ipairs(buildState.activeSkills or {}) do
        result[#result + 1] = buildSkillConfig(entry)
    end
    for _, entry in ipairs(buildState.passiveSkills or {}) do
        result[#result + 1] = buildSkillConfig(entry)
    end
    return result
end

return SkillRuntime
