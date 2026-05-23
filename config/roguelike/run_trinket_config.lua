local Trinkets = require("config.tables.trinkets")

---@class RunTrinketConfigModule
---@field GetTrinket fun(trinketId: integer): table|nil
---@field GetChapterPool fun(chapterId: integer): table[]
---@field RollChapterTrinket fun(chapterId: integer, seedOffset: integer|nil): integer|nil

local RunTrinketConfig = {}

function RunTrinketConfig.GetTrinket(trinketId)
    return Trinkets.GetTrinket(trinketId)
end

function RunTrinketConfig.GetChapterPool(chapterId)
    return Trinkets.GetChapterPool(chapterId)
end

function RunTrinketConfig.RollChapterTrinket(chapterId, seedOffset)
    local pool = RunTrinketConfig.GetChapterPool(chapterId)
    if #pool == 0 then
        return nil
    end
    local seed = (tonumber(seedOffset) or 0) + (tonumber(chapterId) or 0) * 17
    math.randomseed(seed)
    local pick = pool[math.random(1, #pool)]
    return pick and pick.id or nil
end

return RunTrinketConfig
