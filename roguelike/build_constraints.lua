---@class BuildConstraints
---@field public CanAddEquipment fun(runState: table, equipmentId: integer): boolean, string|nil
---@field public CanAddBlessing fun(runState: table, blessingId: integer): boolean, string|nil
---@field public AddEquipment fun(runState: table, equipmentId: integer): boolean, string|nil
---@field public AddBlessing fun(runState: table, blessingId: integer): boolean, string|nil

-- 构筑数值约束统一接入点（character_progression_design.md §5）：
--   1. mutuallyExclusiveGroup：同组装备/祝福仅允许保留 1 件；
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

-- 计算已入库装备的 tag 命中表 + 互斥组占用集
local function summarizeEquipments(runState)
    local tagCounter = {}
    local groupOccupied = {}
    for _, equipmentId in ipairs(runState and runState.equipmentIds or {}) do
        local entry = RunEquipmentConfig.GetEquipment(equipmentId)
        if entry then
            addTagsToCounter(tagCounter, entry.tags)
            if entry.mutuallyExclusiveGroup then
                groupOccupied[entry.mutuallyExclusiveGroup] = true
            end
        end
    end
    return tagCounter, groupOccupied
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

-- 检查能否新增装备（不真的写入）。返回 (ok, reason)。
function BuildConstraints.CanAddEquipment(runState, equipmentId)
    if type(runState) ~= "table" then
        return false, "invalid_run_state"
    end
    local entry = RunEquipmentConfig.GetEquipment(tonumber(equipmentId) or -1)
    if not entry then
        return false, "equipment_not_found"
    end
    -- 同 ID 去重（兼容旧 addUnique 行为）
    if arrayContains(runState.equipmentIds, equipmentId) then
        return false, "duplicate_equipment"
    end
    local tagCounter, groupOccupied = summarizeEquipments(runState)
    if entry.mutuallyExclusiveGroup and groupOccupied[entry.mutuallyExclusiveGroup] then
        return false, "exclusive_group_occupied"
    end
    local overflow, tag = tagsHasOverlap(tagCounter, entry.tags, SAME_TAG_LIMIT)
    if overflow then
        return false, "tag_limit:" .. tostring(tag)
    end
    return true
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

-- 实际入库（成功才追加；失败原样返回 (false, reason)）。
function BuildConstraints.AddEquipment(runState, equipmentId)
    local ok, reason = BuildConstraints.CanAddEquipment(runState, equipmentId)
    if not ok then
        return false, reason
    end
    runState.equipmentIds = runState.equipmentIds or {}
    runState.equipmentIds[#runState.equipmentIds + 1] = equipmentId
    return true
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
