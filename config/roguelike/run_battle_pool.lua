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
            { battleTemplateId = 201001, weight = 100 },
        },
    },
    [101002] = {
        id = 101002,
        chapterId = 101,
        kind = "normal",
        entries = {
            { battleTemplateId = 201001, weight = 55 },
            { battleTemplateId = 201002, weight = 45 },
        },
    },
    [101003] = {
        id = 101003,
        chapterId = 101,
        kind = "normal",
        entries = {
            { battleTemplateId = 201003, weight = 100 },
        },
    },
    [101004] = {
        id = 101004,
        chapterId = 101,
        kind = "normal",
        entries = {
            { battleTemplateId = 201004, weight = 100 },
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
    [101102] = {
        id = 101102,
        chapterId = 101,
        kind = "elite",
        entries = {
            { battleTemplateId = 201101, weight = 20 },
            { battleTemplateId = 201102, weight = 80 },
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
    [102001] = {
        id = 102001,
        chapterId = 102,
        kind = "normal",
        entries = {
            { battleTemplateId = 202001, weight = 100 },
        },
    },
    [102002] = {
        id = 102002,
        chapterId = 102,
        kind = "normal",
        entries = {
            { battleTemplateId = 202002, weight = 100 },
        },
    },
    [102003] = {
        id = 102003,
        chapterId = 102,
        kind = "normal",
        entries = {
            { battleTemplateId = 202002, weight = 25 },
            { battleTemplateId = 202003, weight = 75 },
        },
    },
    [102101] = {
        id = 102101,
        chapterId = 102,
        kind = "elite",
        entries = {
            { battleTemplateId = 202101, weight = 55 },
            { battleTemplateId = 202102, weight = 45 },
        },
    },
    [102102] = {
        id = 102102,
        chapterId = 102,
        kind = "elite",
        entries = {
            { battleTemplateId = 202101, weight = 20 },
            { battleTemplateId = 202102, weight = 80 },
        },
    },
    [102201] = {
        id = 102201,
        chapterId = 102,
        kind = "boss",
        entries = {
            { battleTemplateId = 202201, weight = 100 },
        },
    },
    [103001] = {
        id = 103001,
        chapterId = 103,
        kind = "normal",
        entries = {
            { battleTemplateId = 203001, weight = 100 },
        },
    },
    [103002] = {
        id = 103002,
        chapterId = 103,
        kind = "normal",
        entries = {
            { battleTemplateId = 203002, weight = 60 },
            { battleTemplateId = 203003, weight = 40 },
        },
    },
    [103003] = {
        id = 103003,
        chapterId = 103,
        kind = "normal",
        entries = {
            { battleTemplateId = 203002, weight = 20 },
            { battleTemplateId = 203003, weight = 80 },
        },
    },
    [103101] = {
        id = 103101,
        chapterId = 103,
        kind = "elite",
        entries = {
            { battleTemplateId = 203101, weight = 45 },
            { battleTemplateId = 203102, weight = 55 },
        },
    },
    [103102] = {
        id = 103102,
        chapterId = 103,
        kind = "elite",
        entries = {
            { battleTemplateId = 203101, weight = 20 },
            { battleTemplateId = 203102, weight = 80 },
        },
    },
    [103201] = {
        id = 103201,
        chapterId = 103,
        kind = "boss",
        entries = {
            { battleTemplateId = 203201, weight = 100 },
        },
    },
}

function RunBattlePool.GetPool(poolId)
    return RunBattlePool.POOLS[poolId]
end

return RunBattlePool
