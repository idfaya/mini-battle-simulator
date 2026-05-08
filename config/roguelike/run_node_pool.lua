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
---@field battleId integer|nil
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
        battleId = 101001,
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
        battleId = 101002,
        nextNodeIds = { 101004, 101005 },
    },
    [101004] = {
        id = 101004,
        chapterId = 101,
        floor = 3,
        lane = 1,
        code = "frostbite_raid",
        nodeType = "battle_normal",
        title = "Frostbite Raid",
        battleId = 101103,
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
        battleId = 101101,
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
        battleId = 101003,
        nextNodeIds = { 101008, 101009 },
    },
    [101008] = {
        id = 101008,
        chapterId = 101,
        floor = 5,
        lane = 1,
        code = "ember_ambush",
        nodeType = "battle_normal",
        title = "Ember Ambush",
        battleId = 101104,
        nextNodeIds = { 101012, 101013 },
    },
    [101009] = {
        id = 101009,
        chapterId = 101,
        floor = 5,
        lane = 2,
        code = "dark_cabal",
        nodeType = "battle_elite",
        title = "Dark Cabal",
        battleId = 101102,
        nextNodeIds = { 101012, 101013 },
    },
    [101012] = {
        id = 101012,
        chapterId = 101,
        floor = 6,
        lane = 1,
        code = "icebound_crossing",
        nodeType = "battle_normal",
        title = "Icebound Crossing",
        battleId = 101003,
        nextNodeIds = { 101010 },
    },
    [101013] = {
        id = 101013,
        chapterId = 101,
        floor = 6,
        lane = 2,
        code = "ashen_pursuit",
        nodeType = "battle_normal",
        title = "Ashen Pursuit",
        battleId = 101104,
        nextNodeIds = { 101010 },
    },
    [101010] = {
        id = 101010,
        chapterId = 101,
        floor = 7,
        lane = 1,
        code = "stranded_allies",
        nodeType = "recruit",
        title = "Stranded Allies",
        recruitPoolId = 101001,
        nextNodeIds = { 101011 },
    },
    [101011] = {
        id = 101011,
        chapterId = 101,
        floor = 8,
        lane = 1,
        code = "frozen_gate",
        nodeType = "boss",
        title = "Frozen Gate",
        battleId = 101201,
        bossPhaseGroupId = 101201,
        nextNodeIds = {},
    },
}

function RunNodePool.GetNode(nodeId)
    return RunNodePool.NODES[nodeId]
end

return RunNodePool
