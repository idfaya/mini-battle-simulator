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

---@type RunEnemyGroupModule
local RunEnemyGroup = {}

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
        back = {},
        elite = {},
        boss = nil,
        guards = {},
    },
    [101003] = {
        id = 101003,
        code = "collapsed_bridge_opening",
        name = "Collapsed Bridge Opening",
        front = { 910004, 910003, 910002 },
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
        back = { 910001 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101102] = {
        id = 101102,
        code = "dark_cabal_opening",
        name = "Dark Cabal Opening",
        front = { 910004, 910003, 910002 },
        back = { 910005 },
        elite = {},
        boss = nil,
        guards = {},
    },
    [101103] = {
        id = 101103,
        code = "frostbite_raid_opening",
        name = "Frostbite Raid Opening",
        front = { 910003, 910002, 910001 },
        back = {},
        elite = {},
        boss = nil,
        guards = {},
    },
    [101104] = {
        id = 101104,
        code = "ember_ambush_opening",
        name = "Ember Ambush Opening",
        front = { 910003, 910002, 910001 },
        back = {},
        elite = {},
        boss = nil,
        guards = {},
    },
    [101201] = {
        id = 101201,
        code = "frozen_gate_opening",
        name = "Frozen Gate Opening",
        front = { 910005, 910006, 910004 },
        back = {},
        elite = {},
        boss = nil,
        guards = {},
    },
}

function RunEnemyGroup.GetGroup(groupId)
    return RunEnemyGroup.GROUPS[groupId]
end

return RunEnemyGroup
