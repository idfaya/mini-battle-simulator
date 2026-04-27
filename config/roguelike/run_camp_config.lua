---@alias RunCampActionEffectType
---| "team_heal_pct"
---| "grant_blessing"
---| "revive_one"

---@class RunCampActionParams
---@field value number|nil
---@field blessingId integer|nil
---@field healPct number|nil

---@class RunCampActionRequirements
---@field hasDeadHero boolean|nil

---@class RunCampAction
---@field id integer
---@field label string
---@field effectType RunCampActionEffectType
---@field params RunCampActionParams
---@field requirements RunCampActionRequirements|nil

---@class RunCampEntry
---@field id integer
---@field chapterId integer
---@field code string
---@field name string
---@field actions RunCampAction[]

---@class RunCampConfigModule
---@field CAMPS table<integer, RunCampEntry>
---@field GetCamp fun(campId: integer): RunCampEntry|nil

---@type RunCampConfigModule
local RunCampConfig = {}

---@type table<integer, RunCampEntry>
RunCampConfig.CAMPS = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        code = "campfire_shrine",
        name = "Campfire Shrine",
        actions = {
            {
                id = 1,
                label = "Rest",
                effectType = "team_heal_pct",
                params = {
                    value = 0.16,
                },
            },
            {
                id = 2,
                label = "Sharpen",
                effectType = "grant_blessing",
                params = {
                    blessingId = 101002,
                },
            },
            {
                id = 3,
                label = "Revive",
                effectType = "revive_one",
                params = {
                    healPct = 0.25,
                },
                requirements = {
                    hasDeadHero = true,
                },
            },
        },
    },
}

function RunCampConfig.GetCamp(campId)
    return RunCampConfig.CAMPS[campId]
end

return RunCampConfig
