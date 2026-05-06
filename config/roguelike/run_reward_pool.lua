---@alias RunRewardGroupKind
---| "normal"
---| "elite"
---| "event"
---| "boss"

---@alias RunRewardType
---| "gold"
---| "equipment"
---| "blessing"
---| "recruit"

---@class RunRewardOption
---@field rewardType RunRewardType
---@field refId integer|nil
---@field value number|nil
---@field weight integer

---@class RunRewardConstraints
---@field requireAtLeastOne RunRewardType[]|nil

---@class RunRewardGroup
---@field id integer
---@field kind RunRewardGroupKind
---@field optionCount integer
---@field options RunRewardOption[]
---@field constraints RunRewardConstraints|nil

---@class RunRewardPoolModule
---@field GROUPS table<integer, RunRewardGroup>
---@field GetGroup fun(groupId: integer): RunRewardGroup|nil

---@type RunRewardPoolModule
local RunRewardPool = {}

-- rewardType:
-- - "gold": +gold
-- - "equipment": grant an equipment id (see run_equipment_config.lua)
-- - "blessing": grant a blessing id (see run_blessing_config.lua)
-- - "recruit": offer a hero id (from res_hero.json)
--
-- Only event reward groups remain on the main roguelike reward path.
---@type table<integer, RunRewardGroup>
RunRewardPool.GROUPS = {
    -- Event reward group: used by events when they say "rewardGroupId".
    [101301] = {
        id = 101301,
        kind = "event",
        optionCount = 1,
        options = {
            { rewardType = "gold", value = 65, weight = 24 },
            { rewardType = "equipment", refId = 101004, weight = 20 },
            { rewardType = "blessing", refId = 101005, weight = 30 },
            { rewardType = "blessing", refId = 101006, weight = 18 },
        },
    },
}

function RunRewardPool.GetGroup(groupId)
    return RunRewardPool.GROUPS[groupId]
end

return RunRewardPool
