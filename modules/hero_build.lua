local ClassBuildProgression = require("config.tables.classes")
local FeatBuildConfig = require("config.tables.feats")
local SkillRuntimeConfig = require("config.tables.skill_runtime")

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

local DICE_MERGE_KEYS = {
    vsMarkBonusDice = true,
}

local function joinDiceModExpr(existing, incoming)
    existing = type(existing) == "string" and existing or ""
    incoming = type(incoming) == "string" and incoming or ""
    if existing == "" then
        return incoming
    end
    if incoming == "" then
        return existing
    end
    return existing .. ";" .. incoming
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

--- §5 单轨：Lv1 fixed feat（含训练 + R 节点）由 classes.json/lv1FeatIds 自动注入；
--- 其它等级的 feat 来自玩家自选 selectedFeatIds（必须属于该职业 treePool）。
local function gatherFeatIds(classId, level, selectedFeatIds)
    local result = {}
    local seen = {}
    for _, featId in ipairs(ClassBuildProgression.GetLv1FeatIds(classId)) do
        addUnique(result, seen, featId)
    end
    for _, featId in ipairs(selectedFeatIds or {}) do
        addUnique(result, seen, featId)
    end
    table.sort(result)
    return result
end

--- §5 单轨：校验玩家自选 feat 必须满足
---   1. feat 存在且 classId 匹配；
---   2. feat.level <= 角色等级；
---   3. prerequisites 默认至少一个已被 owned；requireAllPrerequisites=true 时必须全部满足；
---   4. 同一棵树同一节点不可重复选择。
--- 不再要求每个 choiceGroup 必须填满（§5 树形选择是开放式 build path）。
local function validateSelections(classId, level, selectedFeatIds)
    local owned = {}
    for _, featId in ipairs(ClassBuildProgression.GetLv1FeatIds(classId)) do
        owned[tonumber(featId) or 0] = true
    end
    local selectedSet = {}
    for _, featId in ipairs(selectedFeatIds or {}) do
        local fid = tonumber(featId) or 0
        local feat = FeatBuildConfig.GetFeat(fid)
        if not feat then
            error(string.format("[HeroBuild] Unknown featId: %s", tostring(featId)))
        end
        if tonumber(feat.classId) ~= tonumber(classId) then
            error(string.format("[HeroBuild] feat %s does not belong to class %s", tostring(featId), tostring(classId)))
        end
        if (tonumber(feat.level) or 0) > (tonumber(level) or 0) then
            error(string.format("[HeroBuild] feat %s requires level %d", tostring(featId), tonumber(feat.level) or 0))
        end
        if selectedSet[fid] then
            error(string.format("[HeroBuild] duplicate feat selection: %s", tostring(featId)))
        end
        selectedSet[fid] = true
    end
    -- prerequisites 校验：按 selectedFeatIds 给定顺序逐步推进 owned 集合。
    for _, featId in ipairs(selectedFeatIds or {}) do
        local fid = tonumber(featId) or 0
        local feat = FeatBuildConfig.GetFeat(fid)
        if feat and type(feat.prerequisites) == "table" and #feat.prerequisites > 0 then
            local ok = feat.requireAllPrerequisites == true
            for _, pid in ipairs(feat.prerequisites) do
                local hasParent = owned[tonumber(pid) or 0] == true
                if feat.requireAllPrerequisites == true then
                    if not hasParent then
                        ok = false
                        break
                    end
                elseif hasParent then
                    ok = true
                    break
                end
            end
            if not ok then
                error(string.format("[HeroBuild] feat %s prerequisites not satisfied", tostring(featId)))
            end
        end
        owned[fid] = true
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
    local target = buildState.skillMods[id]
    local rest = {}
    for k, v in pairs(patch or {}) do
        if DICE_MERGE_KEYS[k] and type(v) == "string" then
            target[k] = joinDiceModExpr(target[k], v)
        else
            rest[k] = v
        end
    end
    mergeInto(target, rest)
    if patch and patch.statMods then
        mergeInto(buildState.statMods, patch.statMods)
    end
    if patch and patch.classMods then
        buildState.classMods = buildState.classMods or {}
        for k, v in pairs(patch.classMods) do
            if DICE_MERGE_KEYS[k] and type(v) == "string" then
                buildState.classMods[k] = joinDiceModExpr(buildState.classMods[k], v)
            else
                buildState.classMods[k] = deepCopy(v)
            end
        end
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
    -- §5 单轨：当调用方未显式传 selection 且 level>=2 时，自动取 canonical 默认链路（trunk T1/T2/Capstone + B/J 顺序兜底），
    -- 保证 hero_data.ConvertToHeroData 等单点入口在 web/战斗场景下也能获得高阶节点。
    if (not selectedFeatIds or #selectedFeatIds == 0) and resolvedLevel >= 2 then
        local lv1Set = {}
        for _, fid in ipairs(ClassBuildProgression.GetLv1FeatIds(resolvedClassId)) do
            lv1Set[tonumber(fid) or 0] = true
        end
        local canonical = {}
        for _, fid in ipairs(ClassBuildProgression.GetCanonicalFeatChain(resolvedClassId, resolvedLevel)) do
            if not lv1Set[tonumber(fid) or 0] then
                canonical[#canonical + 1] = fid
            end
        end
        selectedFeatIds = canonical
    end
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
        classMods = {},
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
