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
        name = "边境侦察队",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101002] = {
        id = 101002,
        code = "snowfield_ambush_opening",
        name = "雪原伏击",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101003] = {
        id = 101003,
        code = "collapsed_bridge_opening",
        name = "断桥遭遇",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101101] = {
        id = 101101,
        code = "bone_patrol_opening",
        name = "骸骨巡逻队",
        front = { 910003, 910002 },
        back = { 910002, 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101102] = {
        id = 101102,
        code = "dark_cabal_opening",
        name = "暗影秘团",
        front = { 910005, 910004 },
        back = { 910003, 910004 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101103] = {
        id = 101103,
        code = "frostbite_raid_opening",
        name = "霜咬突袭",
        front = { 910003, 910002 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101104] = {
        id = 101104,
        code = "ember_ambush_opening",
        name = "余烬伏兵",
        front = { 910002, 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101201] = {
        id = 101201,
        code = "frozen_gate_opening",
        name = "冰封关隘",
        front = { 910002, 910001 },
        back = { 910001, 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201001] = {
        id = 201001,
        code = "frontier_scouts_wave_2",
        name = "边境侦察队第2波",
        front = { 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201002] = {
        id = 201002,
        code = "snowfield_ambush_wave_2",
        name = "雪原伏击第2波",
        front = { 910001 },
        back = { 910002 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201003] = {
        id = 201003,
        code = "collapsed_bridge_wave_2",
        name = "断桥遭遇第2波",
        front = { 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201004] = {
        id = 201004,
        code = "collapsed_bridge_wave_3",
        name = "断桥遭遇第3波",
        front = { 910001 },
        back = {},
        elite = {},
        boss = nil,
        guards = {},
    },
    [201101] = {
        id = 201101,
        code = "bone_patrol_wave_2",
        name = "骸骨巡逻队第2波",
        front = { 910003 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201102] = {
        id = 201102,
        code = "dark_cabal_wave_2",
        name = "暗影秘团第2波",
        front = { 910003 },
        back = { 910005 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201103] = {
        id = 201103,
        code = "frostbite_raid_wave_2",
        name = "霜咬突袭第2波",
        front = { 910001 },
        back = { 910002 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201104] = {
        id = 201104,
        code = "ember_ambush_wave_2",
        name = "余烬伏兵第2波",
        front = { 910001 },
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [201201] = {
        id = 201201,
        code = "frozen_gate_wave_2",
        name = "冰封关隘第2波",
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
    group.name = group.name or ("运行时敌群 " .. tostring(groupId))
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
