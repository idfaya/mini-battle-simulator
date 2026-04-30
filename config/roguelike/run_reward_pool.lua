---@alias RunRewardGroupKind
---| "normal"
---| "elite"
---| "event"
---| "boss"

---@alias RunRewardType
---| "gold"
---| "heal_pct"
---| "equipment"
---| "blessing"
---| "recruit"
---| "shop_discount"

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
-- - "heal_pct": heal each alive hero by % max hp
-- - "equipment": grant an equipment id (see run_equipment_config.lua)
-- - "blessing": grant a blessing id (see run_blessing_config.lua)
-- - "recruit": offer a hero id (from res_hero.json)
-- - "shop_discount": adjust shop price for current run (optional)
--
-- NOTE: This is a vertical-slice config. The runtime can evolve the schema later.
---@type table<integer, RunRewardGroup>
RunRewardPool.GROUPS = {
    -- Normal battle reward: 3 options, typically blessing / recruit / small heal.
    [101001] = {
        id = 101001,
        kind = "normal",
        optionCount = 3,
        options = {
            { rewardType = "blessing", refId = 101001, weight = 42 },
            { rewardType = "blessing", refId = 101002, weight = 42 },
            { rewardType = "heal_pct", value = 0.15, weight = 32 },
            { rewardType = "gold", value = 55, weight = 24 },
            { rewardType = "blessing", refId = 101003, weight = 20 },
        },
    },

    -- Elite reward: 3 options with guaranteed relic appearance.
    [101101] = {
        id = 101101,
        kind = "elite",
        optionCount = 3,
        options = {
            { rewardType = "equipment", refId = 101001, weight = 30 },
            { rewardType = "equipment", refId = 101002, weight = 30 },
            { rewardType = "equipment", refId = 101003, weight = 25 },
            { rewardType = "blessing", refId = 101003, weight = 25 },
            { rewardType = "blessing", refId = 101004, weight = 20 },
            { rewardType = "heal_pct", value = 0.18, weight = 22 },
        },
        constraints = {
            requireAtLeastOne = { "equipment" },
        },
    },

    -- Event reward group: used by events when they say "rewardGroupId".
    [101301] = {
        id = 101301,
        kind = "event",
        optionCount = 1,
        options = {
            { rewardType = "gold", value = 65, weight = 24 },
            { rewardType = "equipment", refId = 101004, weight = 20 },
            { rewardType = "blessing", refId = 101005, weight = 30 },
            { rewardType = "heal_pct", value = 0.18, weight = 26 },
        },
    },

    -- Boss reward: 3 options, should feel like a power spike.
    [101201] = {
        id = 101201,
        kind = "boss",
        optionCount = 3,
        options = {
            { rewardType = "equipment", refId = 101005, weight = 40 },
            { rewardType = "equipment", refId = 101006, weight = 35 },
            { rewardType = "blessing", refId = 101006, weight = 30 },
            { rewardType = "blessing", refId = 101007, weight = 25 },
            { rewardType = "heal_pct", value = 0.18, weight = 18 },
        },
        constraints = {
            requireAtLeastOne = { "equipment" },
        },
    },
}

function RunRewardPool.GetGroup(groupId)
    return RunRewardPool.GROUPS[groupId]
end

return RunRewardPool
