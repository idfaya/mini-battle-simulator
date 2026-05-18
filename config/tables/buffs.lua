local ConfigJsonLoader = require("config.json_loader")
local BuffEffectRegistry = require("skills.buff_effect_registry")

local BuffConfig = {}

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

local function loadBuffConfig()
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
            BuffConfig[buffId] = attachHandlers(entry)
        end
    end
end

loadBuffConfig()

return BuffConfig


