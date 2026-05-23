local ConfigJsonLoader = require("config.json_loader")

---@alias RunTrinketEffectType
---| "team_save_delta"
---| "team_damage_resistance"
---| "elite_victory_bonus_gold"
---| "event_skill_check_bonus"
---| "boss_victory_full_heal"
---| "hidden_boss_extra_trinket_roll"

---@class RunTrinketParams
---@field saveDelta integer|nil
---@field damageKind string|nil
---@field gold integer|nil
---@field bonus integer|nil

---@class RunTrinketEntry
---@field id integer
---@field chapterId integer
---@field code string
---@field name string
---@field rarity string
---@field description string
---@field effectType RunTrinketEffectType|nil
---@field params RunTrinketParams|nil
---@field tags string[]

---@class TrinketsModule
---@field GetTrinket fun(trinketId: integer): RunTrinketEntry|nil
---@field AllTrinkets fun(): table<integer, RunTrinketEntry>
---@field GetChapterPool fun(chapterId: integer): RunTrinketEntry[]

local Trinkets = {}
local defs = {}
local loaded = false

local function normalizeEntry(raw)
    if type(raw) ~= "table" then
        return nil
    end
    local id = tonumber(raw.id)
    if not id then
        return nil
    end
    return {
        id = id,
        chapterId = tonumber(raw.chapterId) or 101,
        code = raw.code or ("trinket_" .. tostring(id)),
        name = raw.name or ("Trinket " .. tostring(id)),
        rarity = raw.rarity or "boss",
        description = raw.description or "",
        effectType = raw.effectType,
        params = type(raw.params) == "table" and raw.params or nil,
        tags = raw.tags or { "trinket" },
    }
end

local function ensureLoaded()
    if loaded then
        return
    end
    for key in pairs(defs) do
        defs[key] = nil
    end
    local data = assert(ConfigJsonLoader.Load("data/trinkets.json", { expectedType = "table" }))
    for _, raw in ipairs(data) do
        local entry = normalizeEntry(raw)
        if entry then
            defs[entry.id] = entry
        end
    end
    loaded = true
end

function Trinkets.GetTrinket(trinketId)
    ensureLoaded()
    return defs[tonumber(trinketId) or -1]
end

function Trinkets.AllTrinkets()
    ensureLoaded()
    return defs
end

function Trinkets.GetChapterPool(chapterId)
    ensureLoaded()
    local pool = {}
    local chapter = tonumber(chapterId) or 101
    for _, entry in pairs(defs) do
        if entry.chapterId == chapter then
            pool[#pool + 1] = entry
        end
    end
    table.sort(pool, function(a, b)
        return a.id < b.id
    end)
    return pool
end

return Trinkets
