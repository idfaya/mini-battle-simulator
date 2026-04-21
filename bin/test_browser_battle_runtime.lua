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

local snapshot = Runtime.init({
    level = 20,
    heroCount = 3,
    enemyCount = 4,
    initialEnergy = 80,
})
assert(snapshot.phase == "running", "battle should start in running phase")

local sawReady = false
for _ = 1, 5000 do
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
assert(sawReady == true, "battle should expose at least one ultimate-ready event in browser runtime")
print("browser runtime test passed; saw ultimate ready = " .. tostring(sawReady))
