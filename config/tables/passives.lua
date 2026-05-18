local ConfigJsonLoader = require("config.json_loader")

local function loadPassiveDefs()
    local data = assert(ConfigJsonLoader.Load("data/passives.json", { expectedType = "table" }))
    local defs = {}
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
    return defs
end

return loadPassiveDefs()
