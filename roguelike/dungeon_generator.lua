local Floors = require("config.tables.floors")
local Rng = require("roguelike.rng")

---@alias DungeonRoomType
---| "battle_normal"
---| "battle_elite"
---| "equip"
---| "event"
---| "camp"
---| "shop"
---| "empty"
---| "boss"
---| "entrance"
---| "stair_up"
---| "stair_down"

---@class DungeonRoomPayload
---@field battlePoolId integer|nil
---@field eventId integer|nil
---@field shopId integer|nil
---@field campId integer|nil

---@class DungeonRoomEntry
---@field id integer
---@field gridX integer
---@field gridY integer
---@field roomType DungeonRoomType
---@field neighbors integer[]
---@field payload DungeonRoomPayload
---@field title string

---@class DungeonDoorEntry
---@field a integer
---@field b integer

---@class DungeonFloorState
---@field chapterId integer
---@field floorDepth integer
---@field floorIndex integer
---@field templateId integer
---@field isBossFloor boolean
---@field isHidden boolean
---@field rooms table<integer, DungeonRoomEntry>
---@field doors DungeonDoorEntry[]
---@field startRoomId integer
---@field downStairRoomId integer|nil
---@field upStairRoomId integer|nil
---@field roomCount integer

---@class DungeonState
---@field seed integer
---@field chapterId integer
---@field profileId integer|nil
---@field floors table<integer, DungeonFloorState>
---@field currentFloorDepth integer
---@field currentRoomId integer
---@field clearedRoomIds table<integer, boolean>

local DungeonGenerator = {}

local MAX_ATTEMPTS = 24

-- 房间id：floorDepth * 1000 + index（index 1-based）。Hidden floor 用 floorDepth = 9。
local HIDDEN_FLOOR_DEPTH = 9

local function makeRoomId(floorDepth, index)
    return tonumber(floorDepth) * 1000 + tonumber(index)
end

local function buildRoomTitle(roomType, floorDepth)
    if roomType == "battle_normal" then
        return string.format("第%d层战斗", floorDepth)
    end
    if roomType == "battle_elite" then
        return string.format("第%d层精英", floorDepth)
    end
    if roomType == "boss" then
        return "Boss"
    end
    if roomType == "shop" then
        return "商店"
    end
    if roomType == "camp" then
        return "营地"
    end
    if roomType == "event" then
        return string.format("第%d层事件", floorDepth)
    end
    if roomType == "equip" then
        return "宝箱房"
    end
    if roomType == "stair_up" then
        return "上楼梯"
    end
    if roomType == "stair_down" then
        return "下楼梯"
    end
    if roomType == "entrance" then
        return "入口"
    end
    return "空房间"
end

-- Recursive Backtracker on grid: return list of cells {gridX,gridY,index} and edges (cellIndex pairs)
-- followed by extra random doors based on extraDoorRatio.
local function generateMaze(rng, gridW, gridH, roomCount, extraDoorRatio)
    -- Pick a random connected sub-region of size roomCount
    local startX = rng:nextInt(1, gridW)
    local startY = rng:nextInt(1, gridH)
    local cellMap = {} -- key="x,y" -> cellIndex (1..roomCount)
    local cells = {}
    local edges = {}

    local function key(x, y)
        return x .. "," .. y
    end

    local function inBounds(x, y)
        return x >= 1 and x <= gridW and y >= 1 and y <= gridH
    end

    local frontier = {} -- cells visited but maybe with unvisited neighbors
    local function addCell(x, y, fromIdx)
        local idx = #cells + 1
        cells[idx] = { gridX = x, gridY = y, index = idx }
        cellMap[key(x, y)] = idx
        if fromIdx then
            edges[#edges + 1] = { a = fromIdx, b = idx }
        end
        frontier[#frontier + 1] = idx
        return idx
    end

    addCell(startX, startY, nil)

    -- Recursive backtracker style: keep extending from a random frontier cell
    local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
    while #cells < roomCount and #frontier > 0 do
        local pickIndex = rng:nextInt(1, #frontier)
        local cellIdx = frontier[pickIndex]
        local cell = cells[cellIdx]
        -- shuffle dirs
        local dirOrder = { 1, 2, 3, 4 }
        for i = #dirOrder, 2, -1 do
            local j = rng:nextInt(1, i)
            dirOrder[i], dirOrder[j] = dirOrder[j], dirOrder[i]
        end
        local extended = false
        for _, dirIdx in ipairs(dirOrder) do
            local dx = DIRS[dirIdx][1]
            local dy = DIRS[dirIdx][2]
            local nx = cell.gridX + dx
            local ny = cell.gridY + dy
            if inBounds(nx, ny) and not cellMap[key(nx, ny)] then
                addCell(nx, ny, cellIdx)
                extended = true
                break
            end
        end
        if not extended then
            -- remove from frontier
            table.remove(frontier, pickIndex)
        end
    end

    if #cells < roomCount then
        return nil, "cells_not_enough"
    end

    -- Add extra doors among adjacent cells (回路)
    -- Find all adjacent pairs not yet connected.
    local edgeKeySet = {}
    local function edgeKey(a, b)
        if a < b then
            return a .. "_" .. b
        end
        return b .. "_" .. a
    end
    for _, edge in ipairs(edges) do
        edgeKeySet[edgeKey(edge.a, edge.b)] = true
    end

    local extraCandidates = {}
    for _, cell in ipairs(cells) do
        for _, dir in ipairs(DIRS) do
            local nx = cell.gridX + dir[1]
            local ny = cell.gridY + dir[2]
            local nIdx = cellMap[key(nx, ny)]
            if nIdx and nIdx > cell.index then
                local k = edgeKey(cell.index, nIdx)
                if not edgeKeySet[k] then
                    extraCandidates[#extraCandidates + 1] = { a = cell.index, b = nIdx, key = k }
                end
            end
        end
    end

    local extraTarget = math.floor(#edges * (tonumber(extraDoorRatio) or 0))
    local extraAdded = 0
    while extraAdded < extraTarget and #extraCandidates > 0 do
        local pickIdx = rng:nextInt(1, #extraCandidates)
        local candidate = extraCandidates[pickIdx]
        edges[#edges + 1] = { a = candidate.a, b = candidate.b }
        edgeKeySet[candidate.key] = true
        table.remove(extraCandidates, pickIdx)
        extraAdded = extraAdded + 1
    end

    return cells, edges
end

local function buildAdjacency(cells, edges)
    local adj = {}
    for i = 1, #cells do
        adj[i] = {}
    end
    for _, edge in ipairs(edges) do
        adj[edge.a][#adj[edge.a] + 1] = edge.b
        adj[edge.b][#adj[edge.b] + 1] = edge.a
    end
    return adj
end

local function bfsDistances(adj, startIdx)
    local dist = {}
    dist[startIdx] = 0
    local queue = { startIdx }
    local head = 1
    while head <= #queue do
        local node = queue[head]
        head = head + 1
        for _, neighbor in ipairs(adj[node]) do
            if dist[neighbor] == nil then
                dist[neighbor] = dist[node] + 1
                queue[#queue + 1] = neighbor
            end
        end
    end
    return dist
end

local function isFullyConnected(adj, totalCells)
    if totalCells <= 0 then
        return false
    end
    local dist = bfsDistances(adj, 1)
    local count = 0
    for _ in pairs(dist) do
        count = count + 1
    end
    return count == totalCells
end

local function findFarthestCell(adj, startIdx, excludeIdx)
    local dist = bfsDistances(adj, startIdx)
    local bestIdx = nil
    local bestDist = -1
    for idx, d in pairs(dist) do
        if idx ~= excludeIdx and d > bestDist then
            bestDist = d
            bestIdx = idx
        end
    end
    return bestIdx, bestDist
end

local function pickRoomType(rng, template, counts)
    local weights = template.typeWeights or {}
    local entries = {}
    for typeKey, weight in pairs(weights) do
        local effectiveWeight = tonumber(weight) or 0
        if typeKey == "camp" and (template.constraints and template.constraints.maxCamp) and
            (counts.camp or 0) >= (template.constraints.maxCamp or 0) then
            effectiveWeight = 0
        elseif typeKey == "shop" and (template.constraints and template.constraints.maxShop) and
            (counts.shop or 0) >= (template.constraints.maxShop or 0) then
            effectiveWeight = 0
        elseif typeKey == "battle_elite" and (template.constraints and template.constraints.maxElite) and
            (counts.battle_elite or 0) >= (template.constraints.maxElite or 0) then
            effectiveWeight = 0
        end
        if effectiveWeight > 0 then
            entries[#entries + 1] = { type = typeKey, weight = effectiveWeight }
        end
    end
    table.sort(entries, function(a, b)
        return a.type < b.type
    end)
    if #entries <= 0 then
        return "empty"
    end
    local picked = rng:weightedPick(entries, "weight")
    return (picked and picked.type) or "empty"
end

local function buildPayload(template, roomType, rng)
    local payload = {}
    if roomType == "battle_normal" or roomType == "battle_elite" or roomType == "boss" then
        local battlePoolIds = template.battlePoolIds or {}
        payload.battlePoolId = tonumber(battlePoolIds[roomType])
    elseif roomType == "event" then
        local eventIds = template.eventPoolIds or {}
        if #eventIds > 0 then
            payload.eventId = tonumber(rng:pick(eventIds))
        end
    elseif roomType == "shop" then
        payload.shopId = tonumber(template.shopId)
    elseif roomType == "camp" then
        payload.campId = tonumber(template.campId)
    end
    return payload
end

---Generate one floor; returns FloorState or nil, err.
---@param seed integer
---@param floorDepth integer       -- 1..N within dungeon (or HIDDEN_FLOOR_DEPTH for hidden)
---@param chapterId integer
---@param template FloorTemplateEntry
---@param options table|nil  -- { hasUpStair=bool, hasDownStair=bool }
---@return DungeonFloorState|nil, string|nil
function DungeonGenerator.GenerateFloor(seed, floorDepth, chapterId, template, options)
    if not template then
        return nil, "template_not_found"
    end
    options = options or {}
    local hasUpStair = options.hasUpStair ~= false
    local hasDownStair = options.hasDownStair ~= false

    local baseSeed = (tonumber(seed) or 1) + floorDepth * 7919 + (tonumber(template.id) or 0) * 17

    for attempt = 1, MAX_ATTEMPTS do
        local rng = Rng.New(baseSeed + attempt * 9973)
        local roomCountMin = math.max(1, math.floor((template.roomCount and template.roomCount.min) or 3))
        local roomCountMax = math.max(roomCountMin, math.floor((template.roomCount and template.roomCount.max) or roomCountMin))
        local roomCount = rng:nextInt(roomCountMin, roomCountMax)
        local maxByGrid = math.floor((template.gridW or 4) * (template.gridH or 4))
        if roomCount > maxByGrid then
            roomCount = maxByGrid
        end

        local cells, edges = generateMaze(rng, template.gridW or 4, template.gridH or 4, roomCount, template.extraDoorRatio or 0)
        if cells then
            local adj = buildAdjacency(cells, edges)
            if isFullyConnected(adj, #cells) then
                -- 起点房 = 上楼梯落点（stair_up），不承担战斗/事件等其他功能。
                -- 下楼梯放在距起点最远的房，保证玩家穿越足够多房间。
                local startCellIdx = 1
                local downStairIdx = nil
                local upStairIdx = nil
                if hasDownStair and #cells >= 2 then
                    downStairIdx = findFarthestCell(adj, startCellIdx, nil)
                end
                if hasUpStair then
                    -- 强制：起点房 == 上楼梯落点，类型为 stair_up（楼梯房单独，不混杂战斗）。
                    upStairIdx = startCellIdx
                end

                -- Determine room types per cell
                local rooms = {}
                local doorList = {}
                local counts = { camp = 0, shop = 0, battle_elite = 0 }

                -- For boss floor: pick a non-stair cell to be boss
                local bossCellIdx = nil
                if template.isBoss then
                    -- pick a cell that is not start (start = up stair landing) and not (if any) downStair
                    local bossCandidates = {}
                    for i = 1, #cells do
                        if i ~= startCellIdx and i ~= downStairIdx and i ~= upStairIdx then
                            bossCandidates[#bossCandidates + 1] = i
                        end
                    end
                    if #bossCandidates == 0 then
                        for i = 1, #cells do
                            if i ~= startCellIdx then
                                bossCandidates[#bossCandidates + 1] = i
                            end
                        end
                    end
                    if #bossCandidates == 0 then
                        bossCandidates = { startCellIdx }
                    end
                    bossCellIdx = bossCandidates[rng:nextInt(1, #bossCandidates)]
                end

                for i, cell in ipairs(cells) do
                    local roomType
                    local payload
                    local roomId = makeRoomId(floorDepth, i)
                    if i == upStairIdx and hasUpStair and i ~= downStairIdx then
                        roomType = "stair_up"
                        payload = buildPayload(template, roomType, rng)
                    elseif i == downStairIdx and hasDownStair then
                        roomType = "stair_down"
                        payload = buildPayload(template, roomType, rng)
                    elseif template.isBoss and i == bossCellIdx then
                        roomType = "boss"
                        payload = buildPayload(template, roomType, rng)
                    else
                        roomType = pickRoomType(rng, template, counts)
                        if roomType == "camp" then counts.camp = counts.camp + 1 end
                        if roomType == "shop" then counts.shop = counts.shop + 1 end
                        if roomType == "battle_elite" then counts.battle_elite = counts.battle_elite + 1 end
                        -- 始终用原始 pickRoomType 结果计算 payload，以维持 RNG 稳定。
                        payload = buildPayload(template, roomType, rng)
                        -- 首层（无 stair_up）起点房改为 entrance：仅作通路，不混杂战斗/事件。
                        -- 注：保留前序 pickRoomType + buildPayload 调用以维持 RNG 与 counts 稳定，仅覆盖结果类型。
                        if i == startCellIdx and not hasUpStair then
                            roomType = "entrance"
                            payload = {}
                        end
                    end
                    rooms[roomId] = {
                        id = roomId,
                        gridX = cell.gridX,
                        gridY = cell.gridY,
                        roomType = roomType,
                        neighbors = {},
                        payload = payload,
                        title = buildRoomTitle(roomType, floorDepth),
                    }
                end

                -- Build neighbors and doors using cell indices -> roomIds
                for _, edge in ipairs(edges) do
                    local idA = makeRoomId(floorDepth, edge.a)
                    local idB = makeRoomId(floorDepth, edge.b)
                    rooms[idA].neighbors[#rooms[idA].neighbors + 1] = idB
                    rooms[idB].neighbors[#rooms[idB].neighbors + 1] = idA
                    doorList[#doorList + 1] = { a = idA, b = idB }
                end

                local startRoomId = makeRoomId(floorDepth, startCellIdx)
                local downStairRoomId = downStairIdx and makeRoomId(floorDepth, downStairIdx) or nil
                local upStairRoomId = (hasUpStair and upStairIdx) and makeRoomId(floorDepth, upStairIdx) or nil

                local floorState = {
                    chapterId = chapterId,
                    floorDepth = floorDepth,
                    floorIndex = template.floorIndex or floorDepth,
                    templateId = template.id,
                    isBossFloor = template.isBoss == true,
                    isHidden = template.isHidden == true,
                    gridW = template.gridW or 4,
                    gridH = template.gridH or 4,
                    rooms = rooms,
                    doors = doorList,
                    startRoomId = startRoomId,
                    downStairRoomId = downStairRoomId,
                    upStairRoomId = upStairRoomId,
                    roomCount = #cells,
                }
                return floorState
            end
        end
    end

    return nil, "floor_generation_failed"
end

---@param state DungeonState
---@return boolean, string|nil
function DungeonGenerator.Validate(state)
    if not state or not state.floors then
        return false, "no_floors"
    end
    for depth, floor in pairs(state.floors) do
        local ids = {}
        for id, _ in pairs(floor.rooms or {}) do
            ids[#ids + 1] = id
        end
        if #ids ~= floor.roomCount then
            return false, string.format("floor %d roomCount mismatch", depth)
        end
        -- BFS connectivity
        local visited = {}
        local queue = { ids[1] }
        visited[ids[1]] = true
        local head = 1
        while head <= #queue do
            local cur = queue[head]
            head = head + 1
            local room = floor.rooms[cur]
            for _, nb in ipairs(room.neighbors or {}) do
                if not visited[nb] then
                    visited[nb] = true
                    queue[#queue + 1] = nb
                end
            end
        end
        local visitedCount = 0
        for _ in pairs(visited) do
            visitedCount = visitedCount + 1
        end
        if visitedCount ~= #ids then
            return false, string.format("floor %d not fully connected", depth)
        end
    end
    return true
end

---@param seed integer
---@param chapterId integer
---@param profile table  -- { id, chapterId, ... }
---@return DungeonState|nil, string|nil
function DungeonGenerator.Generate(seed, chapterId, profile)
    local RunChapterConfig = require("config.roguelike.run_chapter_config")
    local chapter = RunChapterConfig.GetChapter(chapterId)
    if not chapter then
        return nil, "chapter_not_found"
    end
    local floorTemplateIds = chapter.floorTemplateIds or {}
    if #floorTemplateIds <= 0 then
        return nil, "no_floor_templates"
    end

    local state = {
        seed = tonumber(seed) or 0,
        chapterId = chapterId,
        profileId = profile and profile.id or nil,
        floors = {},
        currentFloorDepth = 1,
        currentRoomId = nil,
        clearedRoomIds = {},
    }

    for depth, templateId in ipairs(floorTemplateIds) do
        local template = Floors.GetTemplate(templateId)
        if not template then
            return nil, string.format("floor template %d not found", templateId)
        end
        -- 每章第 1 层没有上一层，统一无 stair_up（起点房改为 entrance）
        local hasUpStair = depth > 1
        local hasDownStair = depth < #floorTemplateIds and not template.isBoss
        local floorState, err = DungeonGenerator.GenerateFloor(
            state.seed,
            depth,
            chapterId,
            template,
            { hasUpStair = hasUpStair, hasDownStair = hasDownStair }
        )
        if not floorState then
            return nil, err or "floor_failed"
        end
        state.floors[depth] = floorState
    end

    state.currentFloorDepth = 1
    state.currentRoomId = state.floors[1] and state.floors[1].startRoomId or nil

    local ok, err = DungeonGenerator.Validate(state)
    if not ok then
        return nil, err
    end

    return state
end

---@param chapterId integer
---@param seed integer
---@param profile table|nil
---@return DungeonFloorState|nil, string|nil
function DungeonGenerator.GenerateHiddenFloor(chapterId, seed, profile)
    local RunChapterConfig = require("config.roguelike.run_chapter_config")
    local chapter = RunChapterConfig.GetChapter(chapterId)
    local hiddenId = chapter and chapter.hiddenFloorTemplateId
    if not hiddenId then
        return nil, "no_hidden_floor_template"
    end
    local template = Floors.GetTemplate(hiddenId)
    if not template then
        return nil, "hidden_template_not_found"
    end
    return DungeonGenerator.GenerateFloor(seed, HIDDEN_FLOOR_DEPTH, chapterId, template, {
        hasUpStair = true,
        hasDownStair = false,
    })
end

DungeonGenerator.HIDDEN_FLOOR_DEPTH = HIDDEN_FLOOR_DEPTH

return DungeonGenerator
