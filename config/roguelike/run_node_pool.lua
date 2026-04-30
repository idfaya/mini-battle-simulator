---@alias RunNodeType
---| "battle_normal"
---| "battle_elite"
---| "boss"
---| "event"
---| "shop"
---| "camp"
---| "recruit"

---@class RunNodeEntry
---@field id integer
---@field chapterId integer
---@field floor integer
---@field lane integer
---@field code string
---@field nodeType RunNodeType
---@field title string
---@field encounterId integer|nil
---@field rewardGroupId integer|nil
---@field eventId integer|nil
---@field shopId integer|nil
---@field campId integer|nil
---@field recruitPoolId integer|nil
---@field bossPhaseGroupId integer|nil
---@field nextNodeIds integer[]

---@class RunNodePoolModule
---@field NODES table<integer, RunNodeEntry>
---@field GetNode fun(nodeId: integer): RunNodeEntry|nil

---@type RunNodePoolModule
local RunNodePool = {}

---@type table<integer, RunNodeEntry>
RunNodePool.NODES = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        floor = 1,
        lane = 1,
        code = "frontier_scouts",
        nodeType = "battle_normal",
        title = "Frontier Scouts",
        encounterId = 101001,
        rewardGroupId = 101001,
        nextNodeIds = { 101002, 101003 },
    },
    [101002] = {
        id = 101002,
        chapterId = 101,
        floor = 2,
        lane = 1,
        code = "broken_caravan",
        nodeType = "recruit",
        title = "Broken Caravan",
        recruitPoolId = 101001,
        nextNodeIds = { 101004, 101005 },
    },
    [101003] = {
        id = 101003,
        chapterId = 101,
        floor = 2,
        lane = 2,
        code = "snowfield_ambush",
        nodeType = "battle_normal",
        title = "Snowfield Ambush",
        encounterId = 101002,
        rewardGroupId = 101001,
        nextNodeIds = { 101004, 101005 },
    },
    [101004] = {
        id = 101004,
        chapterId = 101,
        floor = 3,
        lane = 1,
        code = "ash_merchant",
        nodeType = "shop",
        title = "Ash Merchant",
        shopId = 101001,
        nextNodeIds = { 101006, 101007 },
    },
    [101005] = {
        id = 101005,
        chapterId = 101,
        floor = 3,
        lane = 2,
        code = "bone_patrol",
        nodeType = "battle_elite",
        title = "Bone Patrol",
        encounterId = 101101,
        rewardGroupId = 101101,
        nextNodeIds = { 101006, 101007 },
    },
    [101006] = {
        id = 101006,
        chapterId = 101,
        floor = 4,
        lane = 1,
        code = "campfire_shrine",
        nodeType = "camp",
        title = "Campfire Shrine",
        campId = 101001,
        nextNodeIds = { 101008, 101009 },
    },
    [101007] = {
        id = 101007,
        chapterId = 101,
        floor = 4,
        lane = 2,
        code = "collapsed_bridge",
        nodeType = "battle_normal",
        title = "Collapsed Bridge",
        encounterId = 101003,
        rewardGroupId = 101001,
        nextNodeIds = { 101008, 101009 },
    },
    [101008] = {
        id = 101008,
        chapterId = 101,
        floor = 5,
        lane = 1,
        code = "ember_shrine",
        nodeType = "event",
        title = "Ember Shrine",
        eventId = 101002,
        nextNodeIds = { 101010 },
    },
    [101009] = {
        id = 101009,
        chapterId = 101,
        floor = 5,
        lane = 2,
        code = "dark_cabal",
        nodeType = "battle_elite",
        title = "Dark Cabal",
        encounterId = 101102,
        rewardGroupId = 101101,
        nextNodeIds = { 101010 },
    },
    [101010] = {
        id = 101010,
        chapterId = 101,
        floor = 6,
        lane = 1,
        code = "quartermaster_halt",
        nodeType = "shop",
        title = "Quartermaster Halt",
        shopId = 101001,
        nextNodeIds = { 101011 },
    },
    [101011] = {
        id = 101011,
        chapterId = 101,
        floor = 7,
        lane = 1,
        code = "frozen_gate",
        nodeType = "boss",
        title = "Frozen Gate",
        encounterId = 101201,
        rewardGroupId = 101201,
        bossPhaseGroupId = 101201,
        nextNodeIds = {},
    },
}

function RunNodePool.GetNode(nodeId)
    return RunNodePool.NODES[nodeId]
end

return RunNodePool
