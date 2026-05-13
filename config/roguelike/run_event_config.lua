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
        title = "破损商队",
        kind = "choice",
        options = {
            {
                id = 1,
                label = "搜寻残存货箱",
                resultType = "grant_gold",
                result = {
                    gold = 55,
                },
            },
            {
                id = 2,
                label = "护送随行医者并接受祝福",
                costType = "gold",
                costValue = 25,
                resultType = "grant_blessing",
                result = {
                    blessingId = 101002,
                },
            },
            {
                id = 3,
                label = "追击劫掠者",
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
        title = "余烬圣坛",
        kind = "choice",
        options = {
            {
                id = 1,
                label = "祈求康复",
                resultType = "team_heal_pct",
                result = {
                    value = 0.30,
                },
            },
            {
                id = 2,
                label = "献上鲜血祈求石肤",
                costType = "current_hp_pct",
                costValue = 0.15,
                resultType = "grant_blessing",
                result = {
                    blessingId = 101005,
                },
            },
            {
                id = 3,
                label = "开启封印祭室",
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
        title = "封印军械库",
        kind = "choice",
        options = {
            {
                id = 1,
                label = "向守卫缴纳金币",
                costType = "gold",
                costValue = 60,
                resultType = "grant_equipment",
                result = {
                    equipmentId = 101004,
                },
            },
            {
                id = 2,
                label = "强行破除封印",
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
