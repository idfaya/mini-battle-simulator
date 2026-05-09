local RunChapterConfig = require("config.roguelike.run_chapter_config")
local RunNodePool = require("config.roguelike.run_node_pool")
local RoguelikeMapGenerator = require("roguelike.roguelike_map_generator")

local RoguelikeMap = {}

local function sortNodes(a, b)
    if (a.floor or 0) ~= (b.floor or 0) then
        return (a.floor or 0) < (b.floor or 0)
    end
    return (a.lane or 0) < (b.lane or 0)
end

function RoguelikeMap.GetNode(nodeId, mapState)
    if mapState and mapState.nodesById then
        return mapState.nodesById[nodeId]
    end
    return RunNodePool.GetNode(nodeId)
end

function RoguelikeMap.GetChapter(chapterId)
    return RunChapterConfig.GetChapter(chapterId)
end

function RoguelikeMap.GetChapterNodes(chapterId, mapState)
    if mapState and mapState.nodes then
        local nodes = {}
        for _, node in ipairs(mapState.nodes or {}) do
            nodes[#nodes + 1] = node
        end
        table.sort(nodes, sortNodes)
        return nodes
    end
    local result = {}
    for _, node in pairs(RunNodePool.NODES or {}) do
        if node.chapterId == chapterId then
            result[#result + 1] = node
        end
    end
    table.sort(result, sortNodes)
    return result
end

function RoguelikeMap.BuildChapterMap(chapterId, mapState)
    local chapter = RoguelikeMap.GetChapter(chapterId)
    if not chapter then
        return nil
    end

    local activeMapState = mapState
    if not activeMapState and chapter.mapGenProfileId then
        activeMapState = RoguelikeMapGenerator.Generate(chapterId, 0, chapter.mapGenProfileId)
    end
    local startNodeId = activeMapState and activeMapState.startNodeId or chapter.startNodeId
    local bossNodeId = activeMapState and activeMapState.bossNodeId or chapter.bossNodeId
    local floorCount = activeMapState and activeMapState.floorCount or chapter.floorCount
    return {
        chapterId = chapterId,
        startNodeId = startNodeId,
        bossNodeId = bossNodeId,
        floorCount = floorCount,
        nodes = RoguelikeMap.GetChapterNodes(chapterId, activeMapState),
    }
end

function RoguelikeMap.GetAvailableNextNodeIds(currentNodeId, visitedNodeIds, chapterId, mapState)
    local visited = visitedNodeIds or {}
    if not currentNodeId then
        local chapterMap = RoguelikeMap.BuildChapterMap(chapterId, mapState)
        if not chapterMap or not chapterMap.startNodeId then
            return {}
        end
        if visited[chapterMap.startNodeId] then
            return {}
        end
        return { chapterMap.startNodeId }
    end

    local node = RoguelikeMap.GetNode(currentNodeId, mapState)
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

function RoguelikeMap.GenerateChapterMap(chapterId, seed)
    local chapter = RoguelikeMap.GetChapter(chapterId)
    if not chapter or not chapter.mapGenProfileId then
        return nil, "chapter_or_profile_not_found"
    end
    return RoguelikeMapGenerator.Generate(chapterId, seed, chapter.mapGenProfileId)
end

return RoguelikeMap
