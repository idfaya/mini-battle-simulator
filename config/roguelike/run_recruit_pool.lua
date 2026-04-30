---@class RunRecruitPoolEntry
---@field id integer
---@field optionCount integer
---@field heroIds integer[]

---@class RunRecruitPoolModule
---@field POOLS table<integer, RunRecruitPoolEntry>
---@field GetPool fun(poolId: integer): RunRecruitPoolEntry|nil

---@type RunRecruitPoolModule
local RunRecruitPool = {}

---@type table<integer, RunRecruitPoolEntry>
RunRecruitPool.POOLS = {
    [101001] = {
        id = 101001,
        optionCount = 3,
        heroIds = { 900001, 900006, 900007, 900002, 900003 },
    },
}

function RunRecruitPool.GetPool(poolId)
    return RunRecruitPool.POOLS[poolId]
end

return RunRecruitPool
