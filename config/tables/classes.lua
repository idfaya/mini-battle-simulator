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

--- §5 SSOT：返回 Lv1 自动获得的 feat id 列表（含训练技能 + R 根节点）。
--- 单轨树形模型下 Lv1 不需要玩家选择，由 classes.json 的 lv1FeatIds 字段决定。
---@param classId integer
---@return integer[]
function ClassesTable.GetLv1FeatIds(classId)
    local entry = getClassEntry(classId)
    if not entry or type(entry.lv1FeatIds) ~= "table" then
        return {}
    end
    local result = {}
    for _, id in ipairs(entry.lv1FeatIds) do
        result[#result + 1] = tonumber(id) or 0
    end
    return result
end

--- §5 SSOT：返回该职业可选树节点 id 池（B/J/C + 子职 T1/T2 替代节点）。
---@param classId integer
---@return integer[]
function ClassesTable.GetTreePool(classId)
    local entry = getClassEntry(classId)
    if not entry or type(entry.treePool) ~= "table" then
        return {}
    end
    local pool = {}
    for _, id in ipairs(entry.treePool) do
        pool[#pool + 1] = id
    end
    return pool
end

--- §5 §4 落地用：返回该职业从 Lv1 走到 toLevel 的"canonical 默认链路"。
--- 规则（与 design/roguelike_feat_skill_fill_sheet.md §3 / §4 对齐）：
---   Lv1 → 全部 lv1FeatIds（fixed，含 R）
---   Lv2/4/6/7/8/9 → 在 treePool 中第一个 prerequisites 已满足、treeSlot ∈ {B,J} 的节点
---   Lv3 → treePool 中第一个 trunk == "T1" 的节点
---   Lv5 → treePool 中第一个 trunk == "T2" 的节点
---   Lv10 → treePool 中第一个 isCapstone == true 且前置已满足的节点
--- 用于测试 / hero_data 的默认 build 选择，不参与玩家自定义 selection 校验。
---@param classId integer
---@param toLevel integer
---@return integer[]
function ClassesTable.GetCanonicalFeatChain(classId, toLevel)
    local FeatBuildConfig = require("config.tables.feats")
    local maxLevel = math.max(1, tonumber(toLevel) or 1)
    local result = {}
    local seen = {}
    local owned = {}
    local function add(id)
        local fid = tonumber(id) or 0
        if fid <= 0 or seen[fid] then
            return
        end
        seen[fid] = true
        owned[fid] = true
        result[#result + 1] = fid
    end
    -- Lv1 fixed
    for _, id in ipairs(ClassesTable.GetLv1FeatIds(classId)) do
        local feat = FeatBuildConfig.GetFeat(id)
        if feat then
            add(id)
        end
    end
    if maxLevel < 2 then
        return result
    end
    local pool = ClassesTable.GetTreePool(classId)
    local function prereqsOk(feat)
        if type(feat.prerequisites) ~= "table" or #feat.prerequisites == 0 then
            return true
        end
        for _, pid in ipairs(feat.prerequisites) do
            if owned[tonumber(pid) or 0] then
                return true
            end
        end
        return false
    end
    local function pickBy(level, predicate)
        for _, fid in ipairs(pool) do
            local feat = FeatBuildConfig.GetFeat(fid)
            if feat and not seen[fid] and (tonumber(feat.level) or 0) <= level and predicate(feat) and prereqsOk(feat) then
                add(fid)
                return true
            end
        end
        return false
    end
    for lv = 2, maxLevel do
        if lv == 3 then
            -- Lv3 优先 trunk=T1；若 treePool 中没标 trunk 则取该 level 的第一个 isSubclassCore=true 节点
            if not pickBy(lv, function(f) return f.trunk == "T1" or f.treeSlot == "T1" end) then
                pickBy(lv, function(f) return tonumber(f.level) == 3 and (f.tier == "medium" or f.isSubclassCore == true) end)
            end
        elseif lv == 5 then
            if not pickBy(lv, function(f) return f.trunk == "T2" or f.treeSlot == "T2" end) then
                pickBy(lv, function(f) return tonumber(f.level) == 5 and (f.tier == "high" or f.isSubclassCore == true) end)
            end
        elseif lv == 10 then
            pickBy(lv, function(f) return f.isCapstone == true end)
        else
            pickBy(lv, function(f)
                local slot = f.treeSlot
                return (slot == "B" or slot == "J") and f.isCapstone ~= true
            end)
        end
    end
    return result
end

--- 兼容入口：CompileBuild 在没有显式 selection 时使用 canonical 链路。
---@param classId integer
---@param toLevel integer
---@return boolean
function ClassesTable.HasClass(classId)
    return getClassEntry(classId) ~= nil
end

return ClassesTable
