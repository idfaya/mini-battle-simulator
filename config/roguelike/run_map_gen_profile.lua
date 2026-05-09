---@class RunMapGenNodeCountRule
---@field min integer
---@field max integer

---@class RunMapGenTypeWeightEntry
---@field battle_normal integer|nil
---@field battle_elite integer|nil
---@field event integer|nil
---@field shop integer|nil
---@field camp integer|nil
---@field recruit integer|nil

---@class RunMapGenProfileEntry
---@field id integer
---@field chapterId integer
---@field floorCount integer
---@field battleRatioMin number
---@field nodeCountByFloor table<integer, RunMapGenNodeCountRule>
---@field typeWeightsByFloor table<integer, RunMapGenTypeWeightEntry>
---@field recruitFloorRange integer[]
---@field shopFloorRange integer[]
---@field campFloorRange integer[]
---@field eventFloorRange integer[]
---@field eliteFloorRange integer[]
---@field recruitPoolId integer
---@field shopId integer
---@field campId integer
---@field eventIds integer[]
---@field battlePoolIds table<string, integer>

---@class RunMapGenProfileModule
---@field PROFILES table<integer, RunMapGenProfileEntry>
---@field GetProfile fun(profileId: integer): RunMapGenProfileEntry|nil

---@type RunMapGenProfileModule
local RunMapGenProfile = {}

---@type table<integer, RunMapGenProfileEntry>
RunMapGenProfile.PROFILES = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        floorCount = 8,
        battleRatioMin = 0.60,
        nodeCountByFloor = {
            [1] = { min = 1, max = 1 },
            [2] = { min = 2, max = 2 },
            [3] = { min = 2, max = 3 },
            [4] = { min = 2, max = 3 },
            [5] = { min = 2, max = 3 },
            [6] = { min = 2, max = 2 },
            [7] = { min = 1, max = 1 },
            [8] = { min = 1, max = 1 },
        },
        typeWeightsByFloor = {
            [2] = { battle_normal = 70, recruit = 30 },
            [3] = { battle_normal = 55, battle_elite = 20, event = 25 },
            [4] = { battle_normal = 45, shop = 20, camp = 20, event = 15 },
            [5] = { battle_normal = 45, battle_elite = 25, event = 20, shop = 10 },
            [6] = { battle_normal = 70, battle_elite = 20, shop = 10 },
            [7] = { battle_normal = 100 },
        },
        recruitFloorRange = { 2, 3, 4, 5 },
        shopFloorRange = { 3, 4, 5, 6 },
        campFloorRange = { 4, 5 },
        eventFloorRange = { 3, 4, 5, 6 },
        eliteFloorRange = { 3, 4, 5, 6 },
        recruitPoolId = 101001,
        shopId = 101001,
        campId = 101001,
        eventIds = { 101001, 101002, 101003 },
        battlePoolIds = {
            battle_normal = 101002,
            battle_normal_early = 101001,
            battle_normal_mid = 101002,
            battle_normal_late = 101003,
            battle_elite = 101101,
            boss = 101201,
            event_battle = 101301,
        },
    },
}

function RunMapGenProfile.GetProfile(profileId)
    return RunMapGenProfile.PROFILES[profileId]
end

return RunMapGenProfile
