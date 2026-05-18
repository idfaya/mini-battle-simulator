local ConfigJsonLoader = require("config.json_loader")

local ClassesTable = {}

local classesById = {}
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

local function buildClassIndex(entries)
    local result = {}
    for _, rawEntry in ipairs(entries or {}) do
        local classId = tonumber(rawEntry and rawEntry.classId)
        if classId then
            result[classId] = rawEntry
        end
    end
    return result
end

local function ensureLoaded()
    if loaded then
        return
    end
    local data = assert(ConfigJsonLoader.Load("data/classes.json", { expectedType = "table" }))
    classesById = buildClassIndex(data)
    loaded = true
end

local function getClassEntry(classId)
    ensureLoaded()
    return classesById[tonumber(classId) or 0]
end

function ClassesTable.Reload()
    loaded = false
    ensureLoaded()
    return true
end

function ClassesTable.GetClass(classId)
    local entry = getClassEntry(classId)
    if not entry then
        return nil
    end
    return deepCopy(entry)
end

function ClassesTable.GetAllClasses()
    ensureLoaded()
    local result = {}
    for _, entry in pairs(classesById) do
        result[#result + 1] = deepCopy(entry)
    end
    table.sort(result, function(a, b)
        return (tonumber(a.classId) or 0) < (tonumber(b.classId) or 0)
    end)
    return result
end

function ClassesTable.GetRole(classId)
    local entry = getClassEntry(classId)
    return entry and deepCopy(entry.role) or nil
end

function ClassesTable.GetIcon(classId)
    local role = getClassEntry(classId)
    return role and role.role and role.role.icon or "?"
end

function ClassesTable.GetName(classId)
    local role = getClassEntry(classId)
    return role and role.role and role.role.name or "未知"
end

function ClassesTable.IsMelee(classId)
    local role = getClassEntry(classId)
    return role and role.role and role.role.isMelee == true or false
end

function ClassesTable.PreferFrontRow(classId)
    local role = getClassEntry(classId)
    return role and role.role and role.role.preferRow == "front" or false
end

function ClassesTable.GetWeaponDice(classId)
    local entry = getClassEntry(classId)
    return entry and entry.weapon and entry.weapon.weaponDice or nil
end

function ClassesTable.GetRhythm(classId)
    local entry = getClassEntry(classId)
    return entry and deepCopy(entry.rhythm) or {}
end

function ClassesTable.GetBuildProgression(classId)
    local entry = getClassEntry(classId)
    return entry and deepCopy(entry.build) or {}
end

function ClassesTable.GetProgression(classId)
    local result = {}
    for _, entry in ipairs(ClassesTable.GetBuildProgression(classId)) do
        result[tonumber(entry.level) or 0] = {
            fixed = deepCopy(entry.fixed or nil),
            choiceGroup = entry.choiceGroup,
        }
    end
    return next(result) and result or nil
end

function ClassesTable.GetBuildEntry(classId, level)
    local targetLevel = tonumber(level) or 0
    for _, entry in ipairs(ClassesTable.GetBuildProgression(classId)) do
        if tonumber(entry.level) == targetLevel then
            return entry
        end
    end
    return nil
end

function ClassesTable.GetLevelEntry(classId, level)
    return ClassesTable.GetBuildEntry(classId, level)
end

function ClassesTable.CollectFixedFeatIds(classId, toLevel)
    local result = {}
    local maxLevel = math.max(1, tonumber(toLevel) or 1)
    for _, entry in ipairs(ClassesTable.GetBuildProgression(classId)) do
        if (tonumber(entry.level) or 0) <= maxLevel then
            for _, featId in ipairs(entry.fixed or {}) do
                result[#result + 1] = featId
            end
        end
    end
    return result
end

function ClassesTable.CollectChoiceGroups(classId, toLevel)
    local result = {}
    local maxLevel = math.max(1, tonumber(toLevel) or 1)
    for _, entry in ipairs(ClassesTable.GetBuildProgression(classId)) do
        if (tonumber(entry.level) or 0) <= maxLevel and entry.choiceGroup then
            result[#result + 1] = entry.choiceGroup
        end
    end
    return result
end

function ClassesTable.GetLevelGrant(classId, level)
    local targetLevel = tonumber(level) or 0
    local entry = getClassEntry(classId)
    for _, grant in ipairs(entry and entry.grants or {}) do
        if tonumber(grant.level) == targetLevel then
            return deepCopy(grant)
        end
    end
    return nil
end

function ClassesTable.GetLevelGrantsInRange(classId, fromLevel, toLevel)
    local lo = math.max(1, tonumber(fromLevel) or 1)
    local hi = math.max(lo, tonumber(toLevel) or lo)
    local result = {}
    local entry = getClassEntry(classId)
    for _, grant in ipairs(entry and entry.grants or {}) do
        local level = tonumber(grant.level) or 0
        if level >= lo and level <= hi then
            result[#result + 1] = deepCopy(grant)
        end
    end
    table.sort(result, function(a, b)
        return (tonumber(a.level) or 0) < (tonumber(b.level) or 0)
    end)
    return result
end

return ClassesTable
