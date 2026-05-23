local RunTrinketConfig = require("config.roguelike.run_trinket_config")

local RoguelikeTrinket = {}

local function hasTrinket(runState, trinketId)
    for _, id in ipairs(runState.trinketIds or {}) do
        if id == trinketId then
            return true
        end
    end
    return false
end

function RoguelikeTrinket.Grant(runState, trinketId)
    if type(runState) ~= "table" then
        return false, "invalid_run_state"
    end
    local id = tonumber(trinketId)
    if not id then
        return false, "invalid_trinket_id"
    end
    local entry = RunTrinketConfig.GetTrinket(id)
    if not entry then
        return false, "trinket_not_found"
    end
    if hasTrinket(runState, id) then
        return false, "duplicate_trinket"
    end
    runState.trinketIds = runState.trinketIds or {}
    runState.trinketIds[#runState.trinketIds + 1] = id
    runState.lastActionMessage = string.format("获得章节 trinket：%s", entry.name or tostring(id))
    return true
end

function RoguelikeTrinket.GrantChapterBoss(runState, chapterId, isHidden)
    if type(runState) ~= "table" then
        return false, "invalid_run_state"
    end
    local seedOffset = (runState.seed or 0) + #(runState.trinketIds or {}) * 31
    if isHidden then
        seedOffset = seedOffset + 9001
    end
    local trinketId = RunTrinketConfig.RollChapterTrinket(chapterId, seedOffset)
    if not trinketId then
        return false, "empty_trinket_pool"
    end
    local ok, reason = RoguelikeTrinket.Grant(runState, trinketId)
    if ok and isHidden then
        local entry = RunTrinketConfig.GetTrinket(trinketId)
        runState.lastActionMessage = string.format("隐藏层双倍 trinket：%s", entry and entry.name or trinketId)
        local secondId = RunTrinketConfig.RollChapterTrinket(chapterId, seedOffset + 7)
        if secondId and secondId ~= trinketId then
            RoguelikeTrinket.Grant(runState, secondId)
        end
    end
    return ok, reason
end

function RoguelikeTrinket.Serialize(runState)
    local result = {}
    for _, trinketId in ipairs(runState and runState.trinketIds or {}) do
        local entry = RunTrinketConfig.GetTrinket(trinketId)
        result[#result + 1] = {
            trinketId = trinketId,
            name = entry and entry.name or ("Trinket " .. tostring(trinketId)),
            rarity = entry and entry.rarity or "boss",
            code = entry and entry.code or "",
            description = entry and entry.description or "",
        }
    end
    return result
end

return RoguelikeTrinket
