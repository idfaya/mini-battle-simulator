---@class RunFormationProfileEntry
---@field id integer
---@field code string
---@field name string
---@field frontSlots integer
---@field backSlots integer
---@field waveUnitCap integer
---@field maxSameEnemy integer
---@field requireBoss boolean|nil
---@field guardCountMin integer|nil
---@field guardCountMax integer|nil

---@class RunFormationProfileModule
---@field PROFILES table<integer, RunFormationProfileEntry>
---@field GetProfile fun(profileId: integer): RunFormationProfileEntry|nil

---@type RunFormationProfileModule
local RunFormationProfile = {}

---@type table<integer, RunFormationProfileEntry>
RunFormationProfile.PROFILES = {
    [601001] = {
        id = 601001,
        code = "front2_back1",
        name = "2 Front 1 Back",
        frontSlots = 2,
        backSlots = 2,
        waveUnitCap = 4,
        maxSameEnemy = 2,
    },
    [601002] = {
        id = 601002,
        code = "front2_back2",
        name = "2 Front 2 Back",
        frontSlots = 2,
        backSlots = 2,
        waveUnitCap = 4,
        maxSameEnemy = 2,
    },
    [601003] = {
        id = 601003,
        code = "front3_back1",
        name = "3 Front 1 Back",
        frontSlots = 3,
        backSlots = 1,
        waveUnitCap = 4,
        maxSameEnemy = 2,
    },
    [601101] = {
        id = 601101,
        code = "elite_front2_back2",
        name = "Elite 2 Front 2 Back",
        frontSlots = 2,
        backSlots = 2,
        waveUnitCap = 4,
        maxSameEnemy = 2,
    },
    [601102] = {
        id = 601102,
        code = "elite_front2_back1",
        name = "Elite 2 Front 1 Back",
        frontSlots = 2,
        backSlots = 2,
        waveUnitCap = 4,
        maxSameEnemy = 2,
    },
    [601201] = {
        id = 601201,
        code = "boss_front2_back2",
        name = "Boss 2 Front 2 Back",
        frontSlots = 2,
        backSlots = 2,
        waveUnitCap = 4,
        maxSameEnemy = 2,
        requireBoss = true,
        guardCountMin = 1,
        guardCountMax = 1,
    },
    [601202] = {
        id = 601202,
        code = "boss_front3_back2",
        name = "Boss 3 Front 2 Back",
        frontSlots = 2,
        backSlots = 2,
        waveUnitCap = 4,
        maxSameEnemy = 2,
        requireBoss = true,
        guardCountMin = 1,
        guardCountMax = 1,
    },
}

function RunFormationProfile.GetProfile(profileId)
    return RunFormationProfile.PROFILES[profileId]
end

return RunFormationProfile
