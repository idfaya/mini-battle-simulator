---@class RunEnemyGroupEntry
---@field id integer
---@field code string
---@field name string
---@field front integer[]
---@field back integer[]
---@field elite integer[]
---@field boss integer|nil
---@field guards integer[]

---@class RunEnemyGroupModule
---@field GROUPS table<integer, RunEnemyGroupEntry>
---@field GetGroup fun(groupId: integer): RunEnemyGroupEntry|nil
---@field RegisterRuntimeGroup fun(entry: RunEnemyGroupEntry): integer
---@field ResetRuntimeGroups fun()

---@type RunEnemyGroupModule
local RunEnemyGroup = {}
local RUNTIME_GROUP_START = 900000
local nextRuntimeGroupId = RUNTIME_GROUP_START
local runtimeGroupIds = {}

---@type table<integer, RunEnemyGroupEntry>
RunEnemyGroup.GROUPS = {
    [101001] = {
        id = 101001,
        code = "frontier_scouts_opening",
        name = "Frontier Scouts Opening",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101002] = {
        id = 101002,
        code = "snowfield_ambush_opening",
        name = "Snowfield Ambush Opening",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101003] = {
        id = 101003,
        code = "collapsed_bridge_opening",
        name = "Collapsed Bridge Opening",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101101] = {
        id = 101101,
        code = "bone_patrol_opening",
        name = "Bone Patrol Opening",
        front = { 910003, 910002 },
        back = { 910002, 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101102] = {
        id = 101102,
        code = "dark_cabal_opening",
        name = "Dark Cabal Opening",
        front = { 910005, 910004 },
        back = { 910003, 910004 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101103] = {
        id = 101103,
        code = "frostbite_raid_opening",
        name = "Frostbite Raid Opening",
        front = { 910003, 910002 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101104] = {
        id = 101104,
        code = "ember_ambush_opening",
        name = "Ember Ambush Opening",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101201] = {
        id = 101201,
        code = "frozen_gate_opening",
        name = "Frozen Gate Opening",
        front = { 910002, 910001 },
        back = { 910001, 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201001] = {
        id = 201001,
        code = "frontier_scouts_wave_2",
        name = "Frontier Scouts Wave 2",
        front = { 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201002] = {
        id = 201002,
        code = "snowfield_ambush_wave_2",
        name = "Snowfield Ambush Wave 2",
        front = { 910001 },
        back = { 910002 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201003] = {
        id = 201003,
        code = "collapsed_bridge_wave_2",
        name = "Collapsed Bridge Wave 2",
        front = { 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201004] = {
        id = 201004,
        code = "collapsed_bridge_wave_3",
        name = "Collapsed Bridge Wave 3",
        front = { 910001 },
        back = {},
        elite = {},
        boss = nil,
        guards = {},
    },
    [201101] = {
        id = 201101,
        code = "bone_patrol_wave_2",
        name = "Bone Patrol Wave 2",
        front = { 910003 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201102] = {
        id = 201102,
        code = "dark_cabal_wave_2",
        name = "Dark Cabal Wave 2",
        front = { 910003 },
        back = { 910005 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201103] = {
        id = 201103,
        code = "frostbite_raid_wave_2",
        name = "Frostbite Raid Wave 2",
        front = { 910001 },
        back = { 910002 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201104] = {
        id = 201104,
        code = "ember_ambush_wave_2",
        name = "Ember Ambush Wave 2",
        front = { 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201201] = {
        id = 201201,
        code = "frozen_gate_wave_2",
        name = "Frozen Gate Wave 2",
        front = { 910007 },
        back = {},
        elite = {},
        boss = nil,
        guards = {},
    },
}

function RunEnemyGroup.GetGroup(groupId)
    return RunEnemyGroup.GROUPS[groupId]
end

function RunEnemyGroup.RegisterRuntimeGroup(entry)
    local group = entry or {}
    local groupId = tonumber(group.id)
    if not groupId or RunEnemyGroup.GROUPS[groupId] then
        groupId = nextRuntimeGroupId
        nextRuntimeGroupId = nextRuntimeGroupId + 1
    end
    group.id = groupId
    group.code = group.code or ("runtime_enemy_group_" .. tostring(groupId))
    group.name = group.name or ("Runtime Enemy Group " .. tostring(groupId))
    group.front = group.front or {}
    group.back = group.back or {}
    group.elite = group.elite or {}
    group.guards = group.guards or {}
    RunEnemyGroup.GROUPS[groupId] = group
    runtimeGroupIds[#runtimeGroupIds + 1] = groupId
    return groupId
end

function RunEnemyGroup.ResetRuntimeGroups()
    for _, groupId in ipairs(runtimeGroupIds) do
        RunEnemyGroup.GROUPS[groupId] = nil
    end
    runtimeGroupIds = {}
    nextRuntimeGroupId = RUNTIME_GROUP_START
end

return RunEnemyGroup
