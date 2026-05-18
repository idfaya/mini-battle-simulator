local json = require("utils.json")
local BuffEffectRegistry = require("config.buff.buff_effect_registry")

local BuffConfig = {}

local function getConfigFilePath(fileName)
    local paths = {
        "config/" .. fileName,
        "../config/" .. fileName,
    }

    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            return path
        end
    end

    return nil
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

local function loadBuffConfig()
    local path = getConfigFilePath("res_buff.json")
    assert(path, "cannot find config/res_buff.json")

    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()

    local data = json.JsonDecode(content)
    assert(type(data) == "table", "res_buff.json must decode to a table")

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
