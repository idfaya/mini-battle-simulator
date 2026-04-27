local RunChapterConfig = require("config.roguelike.run_chapter_config")
local RunNodePool = require("config.roguelike.run_node_pool")

local RoguelikeMap = {}

local function sortNodes(a, b)
    if (a.floor or 0) ~= (b.floor or 0) then
        return (a.floor or 0) < (b.floor or 0)
    end
    return (a.lane or 0) < (b.lane or 0)
end

function RoguelikeMap.GetNode(nodeId)
    return RunNodePool.GetNode(nodeId)
end

function RoguelikeMap.GetChapter(chapterId)
    return RunChapterConfig.GetChapter(chapterId)
end

function RoguelikeMap.GetChapterNodes(chapterId)
    local result = {}
    for _, node in pairs(RunNodePool.NODES or {}) do
        if node.chapterId == chapterId then
            result[#result + 1] = node
        end
    end
    table.sort(result, sortNodes)
    return result
end

function RoguelikeMap.BuildChapterMap(chapterId)
    local chapter = RoguelikeMap.GetChapter(chapterId)
    if not chapter then
        return nil
    end

    return {
        chapterId = chapterId,
        startNodeId = chapter.startNodeId,
        bossNodeId = chapter.bossNodeId,
        floorCount = chapter.floorCount,
        nodes = RoguelikeMap.GetChapterNodes(chapterId),
    }
end

function RoguelikeMap.GetAvailableNextNodeIds(currentNodeId, visitedNodeIds, chapterId)
    local visited = visitedNodeIds or {}
    if not currentNodeId then
        local chapter = RoguelikeMap.GetChapter(chapterId)
        if not chapter or not chapter.startNodeId then
            return {}
        end
        if visited[chapter.startNodeId] then
            return {}
        end
        return { chapter.startNodeId }
    end

    local node = RoguelikeMap.GetNode(currentNodeId)
    if not node then
        return {}
    end

    local result = {}
    for _, nextNodeId in ipairs(node.nextNodeIds or {}) do
        if not visited[nextNodeId] then
            result[#result + 1] = nextNodeId
        end
    end
    return result
end

return RoguelikeMap
