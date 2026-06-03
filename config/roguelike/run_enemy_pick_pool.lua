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
            { enemyId = 910001, weight = 55 },
            { enemyId = 910002, weight = 25 },
            { enemyId = 910014, weight = 15 },
            { enemyId = 910004, weight = 5 },
        },
    },
    [701002] = {
        id = 701002,
        entries = {
            { enemyId = 910001, weight = 52 },
            { enemyId = 910002, weight = 18 },
            { enemyId = 910012, weight = 15 },
            { enemyId = 910013, weight = 12 },
            { enemyId = 910004, weight = 3 },
        },
    },
    [701003] = {
        id = 701003,
        entries = {
            { enemyId = 910001, weight = 25 },
            { enemyId = 910002, weight = 25 },
            { enemyId = 910003, weight = 25 },
            { enemyId = 910012, weight = 10 },
            { enemyId = 910014, weight = 15 },
        },
    },
    [701004] = {
        id = 701004,
        entries = {
            { enemyId = 910003, weight = 30 },
            { enemyId = 910004, weight = 25 },
            { enemyId = 910002, weight = 15 },
            { enemyId = 910014, weight = 20 },
            { enemyId = 910015, weight = 10 },
        },
    },
    [701005] = {
        id = 701005,
        entries = {
            { enemyId = 910002, weight = 15 },
            { enemyId = 910003, weight = 25 },
            { enemyId = 910004, weight = 20 },
            { enemyId = 910012, weight = 10 },
            { enemyId = 910013, weight = 10 },
            { enemyId = 910014, weight = 20 },
        },
    },
    [701006] = {
        id = 701006,
        entries = {
            { enemyId = 910005, weight = 60 },
            { enemyId = 910016, weight = 40 },
        },
    },
    [701007] = {
        id = 701007,
        entries = {
            { enemyId = 910001, weight = 92 },
            { enemyId = 910002, weight = 8 },
        },
    },
    [701008] = {
        id = 701008,
        entries = {
            { enemyId = 910001, weight = 88 },
            { enemyId = 910002, weight = 12 },
        },
    },
    [701201] = {
        id = 701201,
        entries = {
            { enemyId = 910006, weight = 45 },
            { enemyId = 910007, weight = 55 },
        },
    },
    [701202] = {
        id = 701202,
        entries = {
            { enemyId = 910002, weight = 20 },
            { enemyId = 910003, weight = 25 },
            { enemyId = 910004, weight = 20 },
            { enemyId = 910014, weight = 20 },
            { enemyId = 910015, weight = 15 },
        },
    },
    [701203] = {
        id = 701203,
        entries = {
            { enemyId = 910002, weight = 35 },
            { enemyId = 910003, weight = 25 },
            { enemyId = 910004, weight = 10 },
            { enemyId = 910014, weight = 20 },
            { enemyId = 910015, weight = 10 },
        },
    },
    [701204] = {
        id = 701204,
        entries = {
            { enemyId = 910002, weight = 35 },
            { enemyId = 910004, weight = 20 },
            { enemyId = 910012, weight = 15 },
            { enemyId = 910013, weight = 15 },
            { enemyId = 910016, weight = 15 },
        },
    },
    [702001] = {
        id = 702001,
        entries = {
            { enemyId = 910003, weight = 25 },
            { enemyId = 910004, weight = 20 },
            { enemyId = 910010, weight = 20 },
            { enemyId = 910014, weight = 20 },
            { enemyId = 910015, weight = 15 },
        },
    },
    [702002] = {
        id = 702002,
        entries = {
            { enemyId = 910008, weight = 20 },
            { enemyId = 910009, weight = 15 },
            { enemyId = 910012, weight = 15 },
            { enemyId = 910013, weight = 20 },
            { enemyId = 910005, weight = 15 },
            { enemyId = 910016, weight = 15 },
        },
    },
    [702003] = {
        id = 702003,
        entries = {
            { enemyId = 910015, weight = 35 },
            { enemyId = 910010, weight = 20 },
            { enemyId = 910014, weight = 20 },
            { enemyId = 910011, weight = 25 },
        },
    },
    [702004] = {
        id = 702004,
        entries = {
            { enemyId = 910005, weight = 35 },
            { enemyId = 910016, weight = 35 },
            { enemyId = 910013, weight = 15 },
            { enemyId = 910009, weight = 15 },
        },
    },
    [702201] = {
        id = 702201,
        entries = {
            { enemyId = 910006, weight = 40 },
            { enemyId = 910007, weight = 60 },
        },
    },
    [702202] = {
        id = 702202,
        entries = {
            { enemyId = 910015, weight = 30 },
            { enemyId = 910011, weight = 25 },
            { enemyId = 910010, weight = 20 },
            { enemyId = 910014, weight = 25 },
        },
    },
    [702203] = {
        id = 702203,
        entries = {
            { enemyId = 910016, weight = 35 },
            { enemyId = 910005, weight = 25 },
            { enemyId = 910013, weight = 20 },
            { enemyId = 910012, weight = 20 },
        },
    },
    [703001] = {
        id = 703001,
        entries = {
            { enemyId = 910015, weight = 25 },
            { enemyId = 910011, weight = 25 },
            { enemyId = 910010, weight = 20 },
            { enemyId = 910014, weight = 15 },
            { enemyId = 910003, weight = 15 },
        },
    },
    [703002] = {
        id = 703002,
        entries = {
            { enemyId = 910016, weight = 30 },
            { enemyId = 910005, weight = 25 },
            { enemyId = 910013, weight = 15 },
            { enemyId = 910012, weight = 10 },
            { enemyId = 910008, weight = 10 },
            { enemyId = 910009, weight = 10 },
        },
    },
    [703003] = {
        id = 703003,
        entries = {
            { enemyId = 910015, weight = 35 },
            { enemyId = 910011, weight = 30 },
            { enemyId = 910016, weight = 20 },
            { enemyId = 910005, weight = 15 },
        },
    },
    [703004] = {
        id = 703004,
        entries = {
            { enemyId = 910016, weight = 40 },
            { enemyId = 910005, weight = 30 },
            { enemyId = 910013, weight = 15 },
            { enemyId = 910012, weight = 15 },
        },
    },
    [703201] = {
        id = 703201,
        entries = {
            { enemyId = 910007, weight = 75 },
            { enemyId = 910006, weight = 25 },
        },
    },
    [703202] = {
        id = 703202,
        entries = {
            { enemyId = 910015, weight = 25 },
            { enemyId = 910011, weight = 30 },
            { enemyId = 910010, weight = 20 },
            { enemyId = 910014, weight = 25 },
        },
    },
    [703203] = {
        id = 703203,
        entries = {
            { enemyId = 910016, weight = 40 },
            { enemyId = 910005, weight = 25 },
            { enemyId = 910013, weight = 20 },
            { enemyId = 910012, weight = 15 },
        },
    },
}

function RunEnemyPickPool.GetPool(poolId)
    return RunEnemyPickPool.POOLS[poolId]
end

return RunEnemyPickPool
