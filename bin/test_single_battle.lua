local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local SingleBattleTest = require("runtime.single_battle_test")

local function parseIds(raw)
    local result = {}
    for part in string.gmatch(raw or "", "[^,%s]+") do
        local id = tonumber(part)
        if id then
            result[#result + 1] = id
        end
    end
    return result
end

local level = tonumber(arg[1])
local heroIds = parseIds(arg[2])
local enemyIds = parseIds(arg[3])
local seed = tonumber(arg[4])

SingleBattleTest.Run({
    level = level,
    heroIds = #heroIds > 0 and heroIds or nil,
    enemyIds = #enemyIds > 0 and enemyIds or nil,
    seed = seed,
})
