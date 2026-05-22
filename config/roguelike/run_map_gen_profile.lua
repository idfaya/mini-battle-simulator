---@class RunMapGenProfileEntry
---@field id integer
---@field chapterId integer

---@class RunMapGenProfileModule
---@field PROFILES table<integer, RunMapGenProfileEntry>
---@field GetProfile fun(profileId: integer): RunMapGenProfileEntry|nil

---@type RunMapGenProfileModule
local RunMapGenProfile = {}

---@type table<integer, RunMapGenProfileEntry>
RunMapGenProfile.PROFILES = {
    [101001] = { id = 101001, chapterId = 101 },
    [102001] = { id = 102001, chapterId = 102 },
    [103001] = { id = 103001, chapterId = 103 },
}

function RunMapGenProfile.GetProfile(profileId)
    return RunMapGenProfile.PROFILES[profileId]
end

return RunMapGenProfile
