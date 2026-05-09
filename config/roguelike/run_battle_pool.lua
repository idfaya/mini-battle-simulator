---@class RunBattlePoolEntry
---@field battleTemplateId integer
---@field weight integer

---@class RunBattlePoolConfig
---@field id integer
---@field chapterId integer
---@field kind string
---@field entries RunBattlePoolEntry[]

---@class RunBattlePoolModule
---@field POOLS table<integer, RunBattlePoolConfig>
---@field GetPool fun(poolId: integer): RunBattlePoolConfig|nil

---@type RunBattlePoolModule
local RunBattlePool = {}

---@type table<integer, RunBattlePoolConfig>
RunBattlePool.POOLS = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        kind = "normal",
        entries = {
            { battleTemplateId = 201001, weight = 40 },
            { battleTemplateId = 201002, weight = 35 },
            { battleTemplateId = 201003, weight = 25 },
        },
    },
    [101101] = {
        id = 101101,
        chapterId = 101,
        kind = "elite",
        entries = {
            { battleTemplateId = 201101, weight = 45 },
            { battleTemplateId = 201102, weight = 55 },
        },
    },
    [101201] = {
        id = 101201,
        chapterId = 101,
        kind = "boss",
        entries = {
            { battleTemplateId = 201201, weight = 100 },
        },
    },
    [101301] = {
        id = 101301,
        chapterId = 101,
        kind = "event_battle",
        entries = {
            { battleTemplateId = 201301, weight = 50 },
            { battleTemplateId = 201302, weight = 50 },
        },
    },
}

function RunBattlePool.GetPool(poolId)
    return RunBattlePool.POOLS[poolId]
end

return RunBattlePool
