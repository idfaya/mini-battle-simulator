---@class RunEncounterPoolEntry
---@field encounterId integer
---@field weight integer

---@class RunEncounterPoolConfig
---@field id integer
---@field entries RunEncounterPoolEntry[]

---@class RunEncounterPoolModule
---@field POOLS table<integer, RunEncounterPoolConfig>
---@field GetPool fun(poolId: integer): RunEncounterPoolConfig|nil

---@type RunEncounterPoolModule
local RunEncounterPool = {}

---@type table<integer, RunEncounterPoolConfig>
RunEncounterPool.POOLS = {
    [301001] = {
        id = 301001,
        entries = {
            { encounterId = 101001, weight = 65 },
            { encounterId = 101002, weight = 25 },
            { encounterId = 101103, weight = 10 },
        },
    },
    [301002] = {
        id = 301002,
        entries = {
            { encounterId = 101002, weight = 45 },
            { encounterId = 101003, weight = 30 },
            { encounterId = 101104, weight = 25 },
        },
    },
    [301003] = {
        id = 301003,
        entries = {
            { encounterId = 101003, weight = 60 },
            { encounterId = 101104, weight = 40 },
        },
    },
    [301101] = {
        id = 301101,
        entries = {
            { encounterId = 101101, weight = 100 },
        },
    },
    [301102] = {
        id = 301102,
        entries = {
            { encounterId = 101101, weight = 35 },
            { encounterId = 101102, weight = 65 },
        },
    },
    [301201] = {
        id = 301201,
        entries = {
            { encounterId = 101102, weight = 100 },
        },
    },
}

function RunEncounterPool.GetPool(poolId)
    return RunEncounterPool.POOLS[poolId]
end

return RunEncounterPool
