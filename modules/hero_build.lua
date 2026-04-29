local ClassBuildProgression = require("config.class_build_progression")
local FeatBuildConfig = require("config.feat_build_config")
local SkillRuntimeConfig = require("config.skill_runtime_config")

local HeroBuild = {}

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

local function append(list, value)
    list[#list + 1] = value
end

local function appendUnique(list, value)
    for _, existing in ipairs(list) do
        if existing == value then
            return
        end
    end
    list[#list + 1] = value
end

local function addUnique(list, seen, value)
    local id = tonumber(value) or 0
    if id <= 0 or seen[id] then
        return
    end
    seen[id] = true
    list[#list + 1] = id
end

local function mergeInto(target, patch)
    if type(patch) ~= "table" then
        return
    end
    for k, v in pairs(patch) do
        if type(v) == "table" and type(target[k]) == "table" then
            mergeInto(target[k], v)
        else
            target[k] = deepCopy(v)
        end
    end
end

local function addSourceRecord(buildState, skillId, field, featId)
    local source = buildState.sourceMap[skillId]
    if not source then
        source = {
            grantedBy = {},
            modifiedBy = {},
            replacedBy = {},
        }
        buildState.sourceMap[skillId] = source
    end
    appendUnique(source[field], featId)
end

local function gatherFeatIds(classId, level, selectedFeatIds)
    local result = {}
    local seen = {}
    for _, featId in ipairs(ClassBuildProgression.CollectFixedFeatIds(classId, level)) do
        addUnique(result, seen, featId)
    end
    for _, featId in ipairs(selectedFeatIds or {}) do
        addUnique(result, seen, featId)
    end
    table.sort(result)
    return result
end

local function validateSelections(classId, level, selectedFeatIds)
    local selectedByGroup = {}
    for _, featId in ipairs(selectedFeatIds or {}) do
        local feat = FeatBuildConfig.GetFeat(featId)
        if not feat then
            error(string.format("[HeroBuild] Unknown featId: %s", tostring(featId)))
        end
        if tonumber(feat.classId) ~= tonumber(classId) then
            error(string.format("[HeroBuild] feat %s does not belong to class %s", tostring(featId), tostring(classId)))
        end
        if (tonumber(feat.level) or 0) > (tonumber(level) or 0) then
            error(string.format("[HeroBuild] feat %s requires level %d", tostring(featId), tonumber(feat.level) or 0))
        end
        if feat.choiceGroup then
            if selectedByGroup[feat.choiceGroup] then
                error(string.format("[HeroBuild] duplicate choice in group %s", tostring(feat.choiceGroup)))
            end
            selectedByGroup[feat.choiceGroup] = featId
        end
    end

    for _, groupName in ipairs(ClassBuildProgression.CollectChoiceGroups(classId, level)) do
        if not selectedByGroup[groupName] then
            error(string.format("[HeroBuild] missing required feat selection for group %s", tostring(groupName)))
        end
    end
end

local function applyGrantSkill(buildState, featId, skillId)
    local id = tonumber(skillId) or 0
    if id <= 0 then
        return
    end
    buildState.grantedSkillIds[id] = true
    addSourceRecord(buildState, id, "grantedBy", featId)
end

local function applyModifySkill(buildState, featId, skillId, patch)
    local id = tonumber(skillId) or 0
    if id <= 0 then
        return
    end
    buildState.skillMods[id] = buildState.skillMods[id] or {}
    mergeInto(buildState.skillMods[id], patch or {})
    if patch and patch.statMods then
        mergeInto(buildState.statMods, patch.statMods)
    end
    addSourceRecord(buildState, id, "modifiedBy", featId)
end

local function applyReplaceSkill(buildState, featId, oldSkillId, newSkillId)
    local oldId = tonumber(oldSkillId) or 0
    local newId = tonumber(newSkillId) or 0
    if oldId <= 0 or newId <= 0 then
        return
    end
    buildState.grantedSkillIds[oldId] = nil
    buildState.grantedSkillIds[newId] = true
    buildState.replacedSkills[oldId] = newId
    if buildState.skillMods[oldId] then
        buildState.skillMods[newId] = buildState.skillMods[newId] or {}
        mergeInto(buildState.skillMods[newId], buildState.skillMods[oldId])
        buildState.skillMods[oldId] = nil
    end
    addSourceRecord(buildState, oldId, "replacedBy", featId)
    addSourceRecord(buildState, newId, "grantedBy", featId)
end

local function finalizeSkills(buildState)
    local activeSkills = {}
    local passiveSkills = {}
    for skillId in pairs(buildState.grantedSkillIds) do
        local entry = SkillRuntimeConfig.Get(skillId)
        if entry then
            local mods = buildState.skillMods[skillId]
            if mods then
                mergeInto(entry, mods)
                if mods.statMods then
                    mergeInto(buildState.statMods, mods.statMods)
                end
            end
            if entry.tags then
                for _, tag in ipairs(entry.tags) do
                    buildState.grantedTags[tag] = true
                end
            end
            if entry.runtimeKind == "active" then
                activeSkills[#activeSkills + 1] = entry
            else
                passiveSkills[#passiveSkills + 1] = entry
            end
        end
    end

    table.sort(activeSkills, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)
    table.sort(passiveSkills, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    buildState.activeSkills = activeSkills
    buildState.passiveSkills = passiveSkills
end

---@param classId integer
---@param level integer
---@param selectedFeatIds integer[]|nil
---@return table|nil
function HeroBuild.TryCompileBuild(classId, level, selectedFeatIds)
    local ok, result = pcall(HeroBuild.CompileBuild, classId, level, selectedFeatIds)
    if ok then
        return result
    end
    return nil
end

---@param classId integer
---@param level integer
---@param selectedFeatIds integer[]|nil
---@return table
function HeroBuild.CompileBuild(classId, level, selectedFeatIds)
    local resolvedClassId = tonumber(classId) or 0
    local resolvedLevel = math.max(1, tonumber(level) or 1)
    validateSelections(resolvedClassId, resolvedLevel, selectedFeatIds or {})

    local buildState = {
        classId = resolvedClassId,
        level = resolvedLevel,
        selectedFeatIds = deepCopy(selectedFeatIds or {}),
        featIds = gatherFeatIds(resolvedClassId, resolvedLevel, selectedFeatIds or {}),
        activeSkills = {},
        passiveSkills = {},
        skillMods = {},
        replacedSkills = {},
        grantedTags = {},
        statMods = {},
        sourceMap = {},
        grantedSkillIds = {},
    }

    for _, featId in ipairs(buildState.featIds) do
        local feat = FeatBuildConfig.GetFeat(featId)
        if feat then
            for _, effect in ipairs(feat.effects or {}) do
                if effect.type == "grant_skill" then
                    applyGrantSkill(buildState, featId, effect.skill)
                elseif effect.type == "modify_skill" then
                    applyModifySkill(buildState, featId, effect.skill, effect.add)
                elseif effect.type == "replace_skill" then
                    applyReplaceSkill(buildState, featId, effect.oldSkill, effect.newSkill)
                else
                    error(string.format("[HeroBuild] unsupported feat effect type: %s", tostring(effect.type)))
                end
            end
        end
    end

    finalizeSkills(buildState)
    return buildState
end

return HeroBuild
