local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Runtime = require("runtime.browser_battle_runtime")

local snapshot = Runtime.init({
    level = 3,
    heroCount = 4,
    enemyCount = 6,
    initialEnergy = 100,
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
