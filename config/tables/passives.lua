local ConfigJsonLoader = require("config.json_loader")

if not E_PASSIVE_SKILL_TRIGGER_TIME then
    require("core.battle_enum")
end

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
    local data = assert(ConfigJsonLoader.Load("data/passives.json", { expectedType = "table" }))
    for _, rawEntry in ipairs(data) do
        local skillId = tonumber(rawEntry and rawEntry.id)
        if skillId then
            local triggers = {}
            for _, rawTrigger in ipairs(rawEntry.triggers or {}) do
                local triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME[rawTrigger.triggerTime]
                    or tonumber(rawTrigger.triggerTime)
                assert(triggerTime, "unknown passive trigger time: " .. tostring(rawTrigger.triggerTime))
                triggers[#triggers + 1] = {
                    luaFuncName = rawTrigger.luaFuncName,
                    triggerTime = triggerTime,
                }
            end
            defs[skillId] = {
                triggers = triggers,
            }
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

function methods.Get(skillId)
    ensureLoaded()
    return defs[tonumber(skillId) or 0]
end

function methods.GetAll()
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
