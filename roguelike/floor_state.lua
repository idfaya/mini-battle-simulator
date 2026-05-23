---@class FloorStateModule
---@field IsRoomCleared fun(dungeonState: DungeonState, roomId: integer): boolean
---@field MarkRoomCleared fun(dungeonState: DungeonState, roomId: integer)
---@field GetCurrentFloor fun(dungeonState: DungeonState): DungeonFloorState|nil
---@field GetRoom fun(dungeonState: DungeonState, roomId: integer): DungeonRoomEntry|nil
---@field GetAvailableExits fun(dungeonState: DungeonState): integer[]
---@field UseStair fun(dungeonState: DungeonState, direction: string): boolean, string|nil

local DungeonGenerator = require("roguelike.dungeon_generator")

local FloorState = {}

local function getFloor(state, depth)
    if not state or not state.floors then
        return nil
    end
    return state.floors[depth]
end

function FloorState.GetCurrentFloor(state)
    if not state then
        return nil
    end
    return getFloor(state, state.currentFloorDepth)
end

function FloorState.GetRoom(state, roomId)
    if not state or not state.floors then
        return nil
    end
    for _, floor in pairs(state.floors) do
        local room = floor.rooms and floor.rooms[roomId]
        if room then
            return room
        end
    end
    return nil
end

function FloorState.IsRoomCleared(state, roomId)
    if not state or not roomId then
        return false
    end
    return state.clearedRoomIds and state.clearedRoomIds[roomId] == true
end

function FloorState.MarkRoomCleared(state, roomId)
    if not state or not roomId then
        return
    end
    state.clearedRoomIds = state.clearedRoomIds or {}
    state.clearedRoomIds[roomId] = true
end

function FloorState.GetAvailableExits(state)
    if not state then
        return {}
    end
    local floor = FloorState.GetCurrentFloor(state)
    if not floor or not floor.rooms then
        return {}
    end
    local current = floor.rooms[state.currentRoomId]
    if not current then
        return {}
    end
    local result = {}
    for _, neighborId in ipairs(current.neighbors or {}) do
        result[#result + 1] = neighborId
    end
    return result
end

---@param state DungeonState
---@param direction string  -- "up" | "down"
---@return boolean, string|nil
function FloorState.UseStair(state, direction)
    if not state then
        return false, "no_state"
    end
    local floor = FloorState.GetCurrentFloor(state)
    if not floor then
        return false, "no_floor"
    end
    local current = floor.rooms and floor.rooms[state.currentRoomId]
    if not current then
        return false, "no_current_room"
    end

    if direction == "down" then
        if current.roomType ~= "stair_down" then
            return false, "not_on_stair_down"
        end
        local nextDepth
        if current.payload and current.payload.stairTarget == "hidden" then
            nextDepth = DungeonGenerator.HIDDEN_FLOOR_DEPTH
        else
            nextDepth = (state.currentFloorDepth or 1) + 1
        end
        local nextFloor = getFloor(state, nextDepth)
        if not nextFloor then
            return false, "no_next_floor"
        end
        state.currentFloorDepth = nextDepth
        -- 落在下一层 startRoomId（即上楼梯落点）
        state.currentRoomId = nextFloor.startRoomId
        return true
    end

    if direction == "up" then
        if current.roomType ~= "stair_up" then
            return false, "not_on_stair_up"
        end
        if floor.isHidden then
            local retDepth = tonumber(state.hiddenReturnDepth)
            local retRoom = tonumber(state.hiddenReturnRoomId)
            if not retDepth or not retRoom then
                return false, "no_hidden_return"
            end
            local returnFloor = getFloor(state, retDepth)
            if not returnFloor or not returnFloor.rooms[retRoom] then
                return false, "invalid_hidden_return"
            end
            state.currentFloorDepth = retDepth
            state.currentRoomId = retRoom
            return true
        end
        local prevDepth = (state.currentFloorDepth or 1) - 1
        if prevDepth < 1 then
            return false, "no_prev_floor"
        end
        local prevFloor = getFloor(state, prevDepth)
        if not prevFloor then
            return false, "no_prev_floor"
        end
        state.currentFloorDepth = prevDepth
        -- 上楼后落在上一层的下楼梯位置
        state.currentRoomId = prevFloor.downStairRoomId or prevFloor.startRoomId
        return true
    end

    return false, "invalid_direction"
end

return FloorState
