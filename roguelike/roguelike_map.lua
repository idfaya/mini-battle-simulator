local RunChapterConfig = require("config.roguelike.run_chapter_config")
local RunMapGenProfile = require("config.roguelike.run_map_gen_profile")
local DungeonGenerator = require("roguelike.dungeon_generator")

local RoguelikeMap = {}

---Augment a dungeon room into the legacy "node" view used across the rest of the runtime.
---@param room DungeonRoomEntry|nil
---@param floor DungeonFloorState|nil
---@param chapterId integer
---@return table|nil
local function buildNodeView(room, floor, chapterId)
    if not room or not floor then
        return nil
    end
    local payload = room.payload or {}
    local nextNodeIds = {}
    for _, neighborId in ipairs(room.neighbors or {}) do
        nextNodeIds[#nextNodeIds + 1] = neighborId
    end
    -- stair_down: 提供下一层 startRoomId 作为可选 next node（兼容老 selectable 流）。
    -- stair_up:   提供上一层 downStairRoomId（落点）。
    if room.roomType == "stair_down" then
        nextNodeIds[#nextNodeIds + 1] = floor.downStairLandingHint or 0
        nextNodeIds[#nextNodeIds] = nil
    end
    return {
        id = room.id,
        chapterId = chapterId,
        floor = floor.floorDepth,
        lane = (function()
            local idx = (room.id % 1000)
            return idx
        end)(),
        gridX = room.gridX,
        gridY = room.gridY,
        floorGridW = floor.gridW,
        floorGridH = floor.gridH,
        nodeType = room.roomType,
        title = room.title or "",
        nextNodeIds = nextNodeIds,
        battlePoolId = payload.battlePoolId,
        eventId = payload.eventId,
        shopId = payload.shopId,
        campId = payload.campId,
    }
end

local function findRoom(dungeonState, roomId)
    if not dungeonState or not dungeonState.floors then
        return nil, nil
    end
    for _, floor in pairs(dungeonState.floors) do
        local room = floor.rooms and floor.rooms[roomId]
        if room then
            return room, floor
        end
    end
    return nil, nil
end

local function pickBossRoomId(dungeonState)
    if not dungeonState or not dungeonState.floors then
        return nil
    end
    for _, floor in pairs(dungeonState.floors) do
        if floor.isBossFloor then
            for id, room in pairs(floor.rooms or {}) do
                if room.roomType == "boss" then
                    return id
                end
            end
        end
    end
    return nil
end

local function sortFloors(state)
    local depths = {}
    for depth, _ in pairs(state.floors or {}) do
        depths[#depths + 1] = depth
    end
    table.sort(depths)
    return depths
end

function RoguelikeMap.GetChapter(chapterId)
    return RunChapterConfig.GetChapter(chapterId)
end

function RoguelikeMap.GetNode(nodeId, dungeonState)
    if not nodeId then
        return nil
    end
    if not dungeonState then
        return nil
    end
    local room, floor = findRoom(dungeonState, nodeId)
    if not room then
        return nil
    end
    return buildNodeView(room, floor, dungeonState.chapterId)
end

function RoguelikeMap.GetChapterNodes(chapterId, dungeonState)
    local result = {}
    if not dungeonState or not dungeonState.floors then
        return result
    end
    local depths = sortFloors(dungeonState)
    for _, depth in ipairs(depths) do
        local floor = dungeonState.floors[depth]
        local roomIds = {}
        for id, _ in pairs(floor.rooms or {}) do
            roomIds[#roomIds + 1] = id
        end
        table.sort(roomIds)
        for _, id in ipairs(roomIds) do
            local room = floor.rooms[id]
            local node = buildNodeView(room, floor, chapterId)
            if node then
                result[#result + 1] = node
            end
        end
    end
    return result
end

function RoguelikeMap.BuildChapterMap(chapterId, dungeonState)
    local chapter = RoguelikeMap.GetChapter(chapterId)
    if not chapter then
        return nil
    end
    if not dungeonState then
        return {
            chapterId = chapterId,
            startNodeId = nil,
            bossNodeId = nil,
            floorCount = chapter.floorCount or 0,
            nodes = {},
        }
    end
    local floor1 = dungeonState.floors and dungeonState.floors[1]
    return {
        chapterId = dungeonState.chapterId or chapterId,
        startNodeId = floor1 and floor1.startRoomId or nil,
        bossNodeId = pickBossRoomId(dungeonState),
        floorCount = (function()
            local n = 0
            for _ in pairs(dungeonState.floors or {}) do
                n = n + 1
            end
            return n
        end)(),
        nodes = RoguelikeMap.GetChapterNodes(chapterId, dungeonState),
    }
end

---@param currentRoomId integer|nil
---@param visitedRoomIds table<integer, boolean>|nil
---@param chapterId integer
---@param dungeonState DungeonState|nil
---@return integer[]
function RoguelikeMap.GetAvailableNextNodeIds(currentRoomId, visitedRoomIds, chapterId, dungeonState)
    if not dungeonState then
        return {}
    end
    if not currentRoomId then
        local floor1 = dungeonState.floors and dungeonState.floors[1]
        if not floor1 or not floor1.startRoomId then
            return {}
        end
        return { floor1.startRoomId }
    end
    local room, _ = findRoom(dungeonState, currentRoomId)
    if not room then
        return {}
    end
    -- dungeon §4.2：cleared 房间仅作通路；neighbors 全部可达，由 chooseNextNode 偏好优先未访问。
    local result = {}
    for _, neighborId in ipairs(room.neighbors or {}) do
        result[#result + 1] = neighborId
    end
    return result
end

---@param chapterId integer
---@param seed integer|nil
---@return DungeonState|nil, string|nil
function RoguelikeMap.GenerateChapterMap(chapterId, seed)
    local chapter = RoguelikeMap.GetChapter(chapterId)
    if not chapter then
        return nil, "chapter_not_found"
    end
    local profile = chapter.mapGenProfileId and RunMapGenProfile.GetProfile(chapter.mapGenProfileId) or nil
    return DungeonGenerator.Generate(seed, chapterId, profile)
end

return RoguelikeMap
