local ConfigJsonLoader = require("config.json_loader")

---@alias FloorRoomTypeKey
---| "battle_normal"
---| "battle_elite"
---| "equip"
---| "event"
---| "camp"
---| "shop"
---| "empty"
---| "boss"

---@class FloorRoomCountRule
---@field min integer
---@field max integer

---@class FloorConstraints
---@field maxCamp integer|nil
---@field maxShop integer|nil
---@field maxElite integer|nil

---@class FloorBattlePoolIds
---@field battle_normal integer|nil
---@field battle_elite integer|nil
---@field boss integer|nil

---@class FloorTemplateEntry
---@field id integer
---@field code string
---@field chapterId integer
---@field floorIndex integer
---@field gridW integer
---@field gridH integer
---@field roomCount FloorRoomCountRule
---@field extraDoorRatio number
---@field typeWeights table<FloorRoomTypeKey, number>
---@field constraints FloorConstraints
---@field battlePoolIds FloorBattlePoolIds
---@field eventPoolIds integer[]
---@field shopId integer|nil
---@field campId integer|nil
---@field fixedRooms FloorRoomTypeKey[]|nil
---@field isBoss boolean
---@field isHidden boolean

---@class FloorsModule
---@field GetTemplate fun(id: integer): FloorTemplateEntry|nil
---@field AllTemplates fun(): table<integer, FloorTemplateEntry>
---@field Init fun(): boolean
---@field Reload fun(): boolean

local defs = {}
local loaded = false

local methods = {}

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
    local data = assert(ConfigJsonLoader.Load("data/floors.json", { expectedType = "table" }))
    for _, rawEntry in ipairs(data) do
        local id = tonumber(rawEntry and rawEntry.id)
        if id then
            defs[id] = rawEntry
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

function methods.GetTemplate(id)
    ensureLoaded()
    return defs[tonumber(id) or 0]
end

function methods.AllTemplates()
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
