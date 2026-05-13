---@alias RunCampActionEffectType
---| "revive_full_rest"
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
        name = "营火圣所",
        actions = {
            {
                id = 1,
                label = "救援祈祷",
                effectType = "revive_full_rest",
            },
            {
                id = 2,
                label = "接受祝圣",
                effectType = "grant_blessing",
                params = {
                    blessingId = 101001,
                },
            },
            {
                id = 3,
                label = "复苏祷言",
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
