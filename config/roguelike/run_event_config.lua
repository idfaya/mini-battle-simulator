---@alias RunEventKind
---| "choice"

---@alias RunEventCostType
---| "gold"
---| "current_hp_pct"
---| "hp_pct"

---@alias RunEventResultType
---| "grant_gold"
---| "trigger_battle"
---| "team_heal_pct"
---| "grant_blessing"
---| "grant_equipment"

---@class RunEventResult
---@field gold integer|nil
---@field battleId integer|nil
---@field rewardGroupId integer|nil
---@field value number|nil
---@field blessingId integer|nil
---@field equipmentId integer|nil

---@class RunEventOption
---@field id integer
---@field label string
---@field costType RunEventCostType|nil
---@field costValue number|nil
---@field resultType RunEventResultType
---@field result RunEventResult

---@class RunEventEntry
---@field id integer
---@field chapterId integer
---@field code string
---@field title string
---@field kind RunEventKind
---@field options RunEventOption[]

---@class RunEventConfigModule
---@field EVENTS table<integer, RunEventEntry>
---@field GetEvent fun(eventId: integer): RunEventEntry|nil

---@type RunEventConfigModule
local RunEventConfig = {}

---@type table<integer, RunEventEntry>
RunEventConfig.EVENTS = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        code = "broken_caravan",
        title = "Broken Caravan",
        kind = "choice",
        options = {
            {
                id = 1,
                label = "Salvage the crates",
                resultType = "grant_gold",
                result = {
                    gold = 55,
                },
            },
            {
                id = 2,
                label = "Escort the medic",
                costType = "gold",
                costValue = 25,
                resultType = "grant_blessing",
                result = {
                    blessingId = 101002,
                },
            },
            {
                id = 3,
                label = "Chase the raiders",
                resultType = "trigger_battle",
                result = {
                    battleId = 101103,
                    rewardGroupId = 101301,
                },
            },
        },
    },
    [101002] = {
        id = 101002,
        chapterId = 101,
        code = "ember_shrine",
        title = "Ember Shrine",
        kind = "choice",
        options = {
            {
                id = 1,
                label = "Pray for recovery",
                resultType = "team_heal_pct",
                result = {
                    value = 0.30,
                },
            },
            {
                id = 2,
                label = "Offer blood for strength",
                costType = "current_hp_pct",
                costValue = 0.15,
                resultType = "grant_blessing",
                result = {
                    blessingId = 101005,
                },
            },
            {
                id = 3,
                label = "Open the sealed vault",
                resultType = "trigger_battle",
                result = {
                    battleId = 101104,
                    rewardGroupId = 101301,
                },
            },
        },
    },
    [101003] = {
        id = 101003,
        chapterId = 101,
        code = "sealed_armory",
        title = "Sealed Armory",
        kind = "choice",
        options = {
            {
                id = 1,
                label = "Pay the wardens",
                costType = "gold",
                costValue = 60,
                resultType = "grant_equipment",
                result = {
                    equipmentId = 101004,
                },
            },
            {
                id = 2,
                label = "Break the seals",
                costType = "hp_pct",
                costValue = 0.20,
                resultType = "grant_equipment",
                result = {
                    equipmentId = 101003,
                },
            },
        },
    },
}

function RunEventConfig.GetEvent(eventId)
    return RunEventConfig.EVENTS[eventId]
end

return RunEventConfig
