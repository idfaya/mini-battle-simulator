local ConfigJsonLoader = require("config.json_loader")
local BuffEffectRegistry = require("skills.buff_effect_registry")

local entries = {}
local loaded = false

local methods = {}

local function clearEntries()
    for key in pairs(entries) do
        entries[key] = nil
    end
end

local function attachHandlers(entry)
    local effects = {}
    for index, effect in ipairs(entry.effects or {}) do
        local mapped = {}
        for key, value in pairs(effect) do
            if key ~= "handlerId" then
                mapped[key] = value
            end
        end

        if effect.handlerId then
            local handler = BuffEffectRegistry[effect.handlerId]
            assert(type(handler) == "function", string.format("missing buff effect handler: %s (buffId=%s effect=%d)", tostring(effect.handlerId), tostring(entry.buffId), index))
            mapped.func = handler
        end
        effects[index] = mapped
    end
    entry.effects = effects
    return entry
end

local function ensureLoaded()
    if loaded then
        return
    end

    clearEntries()
    local data, err = ConfigJsonLoader.Load("data/buffs.json", { expectedType = "table" })
    assert(data, err)

    for _, rawEntry in ipairs(data) do
        local buffId = tonumber(rawEntry and rawEntry.buffId)
        if buffId then
            local entry = {}
            for key, value in pairs(rawEntry) do
                entry[key] = value
            end
            entry.buffId = buffId
            entries[buffId] = attachHandlers(entry)
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

function methods.Get(buffId)
    ensureLoaded()
    return entries[tonumber(buffId) or 0]
end

function methods.GetAll()
    ensureLoaded()
    return entries
end

return setmetatable({}, {
    __index = function(_, key)
        if methods[key] ~= nil then
            return methods[key]
        end
        ensureLoaded()
        return entries[key]
    end,
    __pairs = function()
        ensureLoaded()
        return next, entries, nil
    end,
})


