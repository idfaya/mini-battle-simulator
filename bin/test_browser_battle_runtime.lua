package.path = package.path
    .. ";./?.lua"
    .. ";./core/?.lua"
    .. ";./modules/?.lua"
    .. ";./config/?.lua"
    .. ";./utils/?.lua"
    .. ";./ui/?.lua"
    .. ";../?.lua"
    .. ";../core/?.lua"
    .. ";../modules/?.lua"
    .. ";../config/?.lua"
    .. ";../utils/?.lua"
    .. ";../ui/?.lua"

require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")
require("modules.BattleDefaultTypesOpt")

local Runtime = require("modules.browser_battle_runtime")

local snapshot = Runtime.init(nil)
assert(snapshot.phase == "running", "battle should start in running phase")

local sawReady = false
for _ = 1, 160 do
    local events = Runtime.tick(80)
    snapshot = Runtime.getSnapshot()

    for _, event in ipairs(events) do
        if event.type == "ultimate_ready" then
            sawReady = true
            Runtime.queueCommand({
                type = "cast_ultimate",
                heroId = event.payload.heroId,
            })
        end
    end

    if snapshot.result then
        break
    end
end

assert(snapshot.result ~= nil, "battle should complete")
print("browser runtime test passed; saw ultimate ready = " .. tostring(sawReady))
