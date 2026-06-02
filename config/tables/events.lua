local ConfigJsonLoader = require("config.json_loader")

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
---| "revive_one"

---@class RunEventSkillCheckResult
---@field resultType RunEventResultType
---@field result RunEventResult

---@class RunEventSkillCheck
---@field ability string
---@field dc integer
---@field results table<string, RunEventSkillCheckResult>

---@class RunEventResult
---@field gold integer|nil
---@field battleId integer|nil
---@field rewardGroupId integer|nil
---@field value number|nil
---@field blessingId integer|nil
---@field equipmentId integer|nil
---@field healPct number|nil

---@class RunEventOption
---@field id integer
---@field label string
---@field kind RunEventKind|nil
---@field costType RunEventCostType|nil
---@field costValue number|nil
---@field resultType RunEventResultType|nil
---@field result RunEventResult|nil
---@field zeroRisk boolean|nil
---@field skillCheck RunEventSkillCheck|nil

---@class RunEventEntry
---@field id integer
---@field chapterId integer
---@field chapterIds integer[]
---@field code string
---@field title string
---@field kind RunEventKind
---@field options RunEventOption[]

---@class EventsModule
---@field GetEvent fun(eventId: integer): RunEventEntry|nil
---@field AllEvents fun(): table<integer, RunEventEntry>
---@field Init fun(): boolean
---@field Reload fun(): boolean

local defs = {}
local loaded = false

local methods = {}

local function normalizeOption(rawOption)
    if type(rawOption) ~= "table" then
        return nil
    end
    local option = {
        id = tonumber(rawOption.id),
        label = rawOption.label,
        kind = rawOption.kind or "choice",
        costType = rawOption.costType,
        costValue = rawOption.costValue,
        resultType = rawOption.resultType,
        result = rawOption.result,
        zeroRisk = rawOption.zeroRisk == true,
        skillCheck = rawOption.skillCheck,
    }
    if not option.id or not option.label then
        return nil
    end
    return option
end

local function normalizeEntry(rawEntry)
    if type(rawEntry) ~= "table" then
        return nil
    end
    local id = tonumber(rawEntry.id)
    if not id then
        return nil
    end

    local chapterIds = rawEntry.chapterIds
    if type(chapterIds) ~= "table" or #chapterIds == 0 then
        local single = tonumber(rawEntry.chapterId)
        chapterIds = single and { single } or { 101 }
    end

    local options = {}
    for _, rawOption in ipairs(rawEntry.options or {}) do
        local option = normalizeOption(rawOption)
        if option then
            options[#options + 1] = option
        end
    end

    return {
        id = id,
        chapterId = tonumber(chapterIds[1]) or 101,
        chapterIds = chapterIds,
        code = rawEntry.code or ("event_" .. tostring(id)),
        title = rawEntry.title or ("Event " .. tostring(id)),
        kind = rawEntry.kind or "choice",
        options = options,
    }
end

local function clearDefs()
    for key in pairs(defs) do
        defs[key] = nil
    end
end

local function ensureLoaded()
    if loaded then
        return
    end
    clearDefs()
    local data = assert(ConfigJsonLoader.Load("data/events.json", { expectedType = "table" }))
    for _, rawEntry in ipairs(data) do
        local entry = normalizeEntry(rawEntry)
        if entry then
            defs[entry.id] = entry
        end
    end
    loaded = true
end

function methods.Init()
    ensureLoaded()
    return true
end

function methods.Reload()
    loaded = false
    ensureLoaded()
    return true
end

function methods.GetEvent(eventId)
    ensureLoaded()
    return defs[tonumber(eventId) or 0]
end

function methods.AllEvents()
    ensureLoaded()
    return defs
end

return setmetatable({}, {
    __index = function(_, key)
        if methods[key] ~= nil then
            return methods[key]
        end
        ensureLoaded()
        return defs[key]
    end,
    __pairs = function()
        ensureLoaded()
        return next, defs, nil
    end,
})
