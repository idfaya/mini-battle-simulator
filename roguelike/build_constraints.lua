---@class BuildConstraints
---@field public CanAddEquipment fun(runState: table, equipmentId: integer): boolean, string|nil, integer|nil
---@field public CanAddBlessing fun(runState: table, blessingId: integer): boolean, string|nil
---@field public AddEquipment fun(runState: table, equipmentId: integer): boolean, string|nil, integer|nil
---@field public AddBlessing fun(runState: table, blessingId: integer): boolean, string|nil

-- 构筑数值约束统一接入点（character_progression_design.md §5）：
--   1. mutuallyExclusiveGroup：同组装备视为「同槽位」，新装备直接替换旧装备（覆盖语义）；
--   2. 同 tag 上限：同 tag 装备/祝福不超过 2 件（防止全队同向叠加爆表）；
--   3. 祝福总数上限：bless 总数硬上限 6（防三层叠加）。
-- 所有入库点（roguelike_reward / roguelike_shop / roguelike_camp / 章节奖励）必须改走本模块的 AddEquipment / AddBlessing。

local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")

local BuildConstraints = {}

local SAME_TAG_LIMIT = 2          -- 同 tag 装备/祝福同 run 最多 2 件
local BLESSING_TOTAL_LIMIT = 6    -- 祝福总数上限

local function arrayContains(arr, value)
    for _, v in ipairs(arr or {}) do
        if v == value then
            return true
        end
    end
    return false
end

local function tagsHasOverlap(existingTags, newTags, limit)
    if not newTags or #newTags == 0 then
        return false
    end
    -- existingTags : 已入库个体的 tag 命中累计计数
    for _, tag in ipairs(newTags) do
        if (existingTags[tag] or 0) >= limit then
            return true, tag
        end
    end
    return false
end

local function addTagsToCounter(counter, tags)
    for _, tag in ipairs(tags or {}) do
        counter[tag] = (counter[tag] or 0) + 1
    end
end

local function subtractTagsFromCounter(counter, tags)
    for _, tag in ipairs(tags or {}) do
        local cur = counter[tag] or 0
        if cur > 0 then
            counter[tag] = cur - 1
        end
    end
end

-- 装备：找到当前已持有、与新装备 mutuallyExclusiveGroup 相同的旧装备（用于覆盖替换）。
local function findEquipmentReplaceTarget(runState, group)
    if not group or not runState or not runState.equipmentIds then
        return nil, nil
    end
    for idx, equipmentId in ipairs(runState.equipmentIds) do
        local entry = RunEquipmentConfig.GetEquipment(equipmentId)
        if entry and entry.mutuallyExclusiveGroup == group then
            return idx, equipmentId
        end
    end
    return nil, nil
end

-- 计算已入库装备的 tag 命中表
local function summarizeEquipmentTags(runState)
    local tagCounter = {}
    for _, equipmentId in ipairs(runState and runState.equipmentIds or {}) do
        local entry = RunEquipmentConfig.GetEquipment(equipmentId)
        if entry then
            addTagsToCounter(tagCounter, entry.tags)
        end
    end
    return tagCounter
end

local function summarizeBlessings(runState)
    local tagCounter = {}
    local groupOccupied = {}
    for _, blessingId in ipairs(runState and runState.blessingIds or {}) do
        local entry = RunBlessingConfig.GetBlessing(blessingId)
        if entry then
            addTagsToCounter(tagCounter, entry.tags)
            if entry.mutuallyExclusiveGroup then
                groupOccupied[entry.mutuallyExclusiveGroup] = true
            end
        end
    end
    return tagCounter, groupOccupied
end

-- 检查能否新增装备（不真的写入）。返回 (ok, reason, replaceEquipmentId)。
-- 当 mutuallyExclusiveGroup 命中已有装备时，replaceEquipmentId 为待被覆盖的旧装备 ID（仍返回 ok=true）。
function BuildConstraints.CanAddEquipment(runState, equipmentId)
    if type(runState) ~= "table" then
        return false, "invalid_run_state"
    end
    local entry = RunEquipmentConfig.GetEquipment(tonumber(equipmentId) or -1)
    if not entry then
        return false, "equipment_not_found"
    end
    -- 同 ID 去重（避免同一件装备重复入库）
    if arrayContains(runState.equipmentIds, equipmentId) then
        return false, "duplicate_equipment"
    end
    local tagCounter = summarizeEquipmentTags(runState)
    local _, replaceEquipmentId = findEquipmentReplaceTarget(runState, entry.mutuallyExclusiveGroup)
    -- 替换语义下，先把被覆盖装备的 tag 计数撤掉，再校验 tag 上限。
    if replaceEquipmentId then
        local replaced = RunEquipmentConfig.GetEquipment(replaceEquipmentId)
        if replaced then
            subtractTagsFromCounter(tagCounter, replaced.tags)
        end
    end
    local overflow, tag = tagsHasOverlap(tagCounter, entry.tags, SAME_TAG_LIMIT)
    if overflow then
        return false, "tag_limit:" .. tostring(tag)
    end
    return true, nil, replaceEquipmentId
end

function BuildConstraints.CanAddBlessing(runState, blessingId)
    if type(runState) ~= "table" then
        return false, "invalid_run_state"
    end
    local entry = RunBlessingConfig.GetBlessing(tonumber(blessingId) or -1)
    if not entry then
        return false, "blessing_not_found"
    end
    if arrayContains(runState.blessingIds, blessingId) then
        return false, "duplicate_blessing"
    end
    local total = #(runState.blessingIds or {})
    if total >= BLESSING_TOTAL_LIMIT then
        return false, "blessing_total_limit"
    end
    local tagCounter, groupOccupied = summarizeBlessings(runState)
    if entry.mutuallyExclusiveGroup and groupOccupied[entry.mutuallyExclusiveGroup] then
        return false, "exclusive_group_occupied"
    end
    local overflow, tag = tagsHasOverlap(tagCounter, entry.tags, SAME_TAG_LIMIT)
    if overflow then
        return false, "tag_limit:" .. tostring(tag)
    end
    return true
end

-- 实际入库：成功才追加；命中 mutuallyExclusiveGroup 时直接覆盖旧装备。
-- 返回 (ok, reason, replacedEquipmentId)。replacedEquipmentId 用于让上层做 UI/日志提示。
function BuildConstraints.AddEquipment(runState, equipmentId)
    local ok, reason, replaceEquipmentId = BuildConstraints.CanAddEquipment(runState, equipmentId)
    if not ok then
        return false, reason
    end
    runState.equipmentIds = runState.equipmentIds or {}
    if replaceEquipmentId then
        for idx, existingId in ipairs(runState.equipmentIds) do
            if existingId == replaceEquipmentId then
                table.remove(runState.equipmentIds, idx)
                break
            end
        end
    end
    runState.equipmentIds[#runState.equipmentIds + 1] = equipmentId
    return true, nil, replaceEquipmentId
end

function BuildConstraints.AddBlessing(runState, blessingId)
    local ok, reason = BuildConstraints.CanAddBlessing(runState, blessingId)
    if not ok then
        return false, reason
    end
    runState.blessingIds = runState.blessingIds or {}
    runState.blessingIds[#runState.blessingIds + 1] = blessingId
    return true
end

BuildConstraints.SAME_TAG_LIMIT = SAME_TAG_LIMIT
BuildConstraints.BLESSING_TOTAL_LIMIT = BLESSING_TOTAL_LIMIT

return BuildConstraints
