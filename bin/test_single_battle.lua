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

local SingleBattleTest = require("modules.single_battle_test")

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
