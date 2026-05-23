---@class RunEventConfigModule
---@field EVENTS table<integer, RunEventEntry>
---@field GetEvent fun(eventId: integer): RunEventEntry|nil

local EventsTable = require("config.tables.events")

---@type RunEventConfigModule
local RunEventConfig = {}

function RunEventConfig.GetEvent(eventId)
    return EventsTable.GetEvent(eventId)
end

return setmetatable(RunEventConfig, {
    __index = function(_, key)
        if key == "EVENTS" then
            return EventsTable.AllEvents()
        end
        return EventsTable[key]
    end,
    __pairs = function()
        return pairs(EventsTable.AllEvents())
    end,
})
