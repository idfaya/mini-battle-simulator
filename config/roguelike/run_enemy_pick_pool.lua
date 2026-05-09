---@class RunEnemyPickEntry
---@field enemyId integer
---@field weight integer

---@class RunEnemyPickPoolConfig
---@field id integer
---@field entries RunEnemyPickEntry[]

---@class RunEnemyPickPoolModule
---@field POOLS table<integer, RunEnemyPickPoolConfig>
---@field GetPool fun(poolId: integer): RunEnemyPickPoolConfig|nil

---@type RunEnemyPickPoolModule
local RunEnemyPickPool = {}

---@type table<integer, RunEnemyPickPoolConfig>
RunEnemyPickPool.POOLS = {
    [701001] = {
        id = 701001,
        entries = {
            { enemyId = 910001, weight = 40 },
            { enemyId = 910002, weight = 45 },
            { enemyId = 910004, weight = 15 },
        },
    },
    [701002] = {
        id = 701002,
        entries = {
            { enemyId = 910001, weight = 45 },
            { enemyId = 910002, weight = 40 },
            { enemyId = 910005, weight = 15 },
        },
    },
    [701003] = {
        id = 701003,
        entries = {
            { enemyId = 910001, weight = 30 },
            { enemyId = 910002, weight = 45 },
            { enemyId = 910003, weight = 25 },
        },
    },
    [701004] = {
        id = 701004,
        entries = {
            { enemyId = 910003, weight = 45 },
            { enemyId = 910004, weight = 35 },
            { enemyId = 910002, weight = 20 },
        },
    },
    [701005] = {
        id = 701005,
        entries = {
            { enemyId = 910002, weight = 20 },
            { enemyId = 910003, weight = 45 },
            { enemyId = 910004, weight = 35 },
        },
    },
    [701006] = {
        id = 701006,
        entries = {
            { enemyId = 910005, weight = 55 },
            { enemyId = 910006, weight = 45 },
        },
    },
    [701201] = {
        id = 701201,
        entries = {
            { enemyId = 910006, weight = 100 },
        },
    },
    [701202] = {
        id = 701202,
        entries = {
            { enemyId = 910003, weight = 35 },
            { enemyId = 910004, weight = 35 },
            { enemyId = 910006, weight = 30 },
        },
    },
}

function RunEnemyPickPool.GetPool(poolId)
    return RunEnemyPickPool.POOLS[poolId]
end

return RunEnemyPickPool
