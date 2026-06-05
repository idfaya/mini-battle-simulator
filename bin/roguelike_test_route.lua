--- 回归测试共享寻路（act1 / chapter_success / balance）。
local RoguelikeTestRoute = {}

RoguelikeTestRoute.PREFERENCE = {
    shop = 10,
    camp = 20,
    event = 30,
    equip = 40,
    battle_normal = 60,
    stair_down = 80,
    boss = 90,
    battle_elite = 100,
}

RoguelikeTestRoute.VISITED_SCORE = 200

function RoguelikeTestRoute.findSelectableNodes(snapshot)
    local result = {}
    for _, node in ipairs((snapshot and snapshot.map and snapshot.map.nodes) or {}) do
        if node.selectable then
            result[#result + 1] = node
        end
    end
    table.sort(result, function(a, b)
        if (a.floor or 0) ~= (b.floor or 0) then
            return (a.floor or 0) < (b.floor or 0)
        end
        return (a.lane or 0) < (b.lane or 0)
    end)
    return result
end

---@param opts table|nil { avoidUnvisitedBattle: boolean|nil }
function RoguelikeTestRoute.findPathNextHop(snapshot, predicate, opts)
    opts = opts or {}
    local map = snapshot and snapshot.map
    local nodes = map and map.nodes or {}
    if #nodes == 0 then
        return nil
    end
    local indexById = {}
    for _, n in ipairs(nodes) do
        indexById[n.id] = n
    end
    local current
    for _, n in ipairs(nodes) do
        if n.current then
            current = n
            break
        end
    end
    if not current then
        return nil
    end

    local queue = { current.id }
    local visited = { [current.id] = true }
    local parent = {}
    local target
    while #queue > 0 do
        local id = table.remove(queue, 1)
        local node = indexById[id]
        if node ~= current and predicate(node) then
            target = node
            break
        end
        for _, nxt in ipairs(node.nextNodeIds or {}) do
            local nxtNode = indexById[nxt]
            if nxtNode and not visited[nxt] then
                local skipBattle = opts.avoidUnvisitedBattle
                    and not nxtNode.visited
                    and (nxtNode.nodeType == "battle_normal" or nxtNode.nodeType == "battle_elite")
                    and not predicate(nxtNode)
                if not skipBattle then
                    visited[nxt] = true
                    parent[nxt] = id
                    queue[#queue + 1] = nxt
                end
            end
        end
    end
    if not target then
        return nil
    end
    local cur = target.id
    while parent[cur] and parent[cur] ~= current.id do
        cur = parent[cur]
    end
    return indexById[cur]
end

local function hasUnvisitedBattleOnMap(snapshot)
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if not node.visited and node.nodeType == "battle_normal" then
            return true
        end
    end
    return false
end

local function hasUnvisitedBattleOnFloor(snapshot, floorDepth)
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if not node.visited and node.nodeType == "battle_normal" and (tonumber(node.floor) or 0) == floorDepth then
            return true
        end
    end
    return false
end

local function countVisitedBattlesOnFloor(snapshot, floorDepth)
    local count = 0
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if node.visited and node.nodeType == "battle_normal" and (tonumber(node.floor) or 0) == floorDepth then
            count = count + 1
        end
    end
    return count
end

local function pickHopIfSelectable(selectable, hop)
    if not hop then
        return nil
    end
    for _, node in ipairs(selectable) do
        if node.id == hop.id then
            return hop
        end
    end
    return nil
end

RoguelikeTestRoute.pickHopIfSelectable = pickHopIfSelectable

function RoguelikeTestRoute.chooseUnvisitedInteraction(snapshot, opts)
    opts = opts or {}
    local nodeTypes = opts.nodeTypes or { "shop", "camp", "event", "equip" }
    local floorDepth = opts.floorDepth
    local selectable = RoguelikeTestRoute.findSelectableNodes(snapshot)
    for _, nodeType in ipairs(nodeTypes) do
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            if n.visited or n.nodeType ~= nodeType then
                return false
            end
            if floorDepth ~= nil and (tonumber(n.floor) or 0) ~= floorDepth then
                return false
            end
            return true
        end)
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end
    return nil
end

function RoguelikeTestRoute.chooseStairTowardInteractionFloor(snapshot, nodeTypes)
    nodeTypes = nodeTypes or { "shop", "camp", "equip", "event" }
    local currentFloor = 1
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if node.current then
            currentFloor = tonumber(node.floor) or 1
            break
        end
    end

    local onFloor = RoguelikeTestRoute.chooseUnvisitedInteraction(snapshot, {
        nodeTypes = nodeTypes,
        floorDepth = currentFloor,
    })
    if onFloor then
        return onFloor
    end

    local targetFloor
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if not node.visited then
            for _, nodeType in ipairs(nodeTypes) do
                if node.nodeType == nodeType then
                    local floor = tonumber(node.floor) or 0
                    if floor > currentFloor and (not targetFloor or floor < targetFloor) then
                        targetFloor = floor
                    end
                    break
                end
            end
        end
    end
    if not targetFloor then
        return nil
    end
    local selectable = RoguelikeTestRoute.findSelectableNodes(snapshot)
    if targetFloor > currentFloor then
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor and not n.visited
        end)
        return pickHopIfSelectable(selectable, hop)
    end
    return nil
end

local CH101_PATH_OPTS = { avoidUnvisitedBattle = true }

local function isClearedHiddenEntrance(snapshot, node)
    if not snapshot or not node then
        return false
    end
    return snapshot.hiddenFloorCleared == true
        and node.nodeType == "stair_down"
        and tonumber(node.id) == tonumber(snapshot.hiddenFloorStairRoomId)
end

--- 第一章 Boss 触达率（design/dungeon_design.md §8）：首战升级后快下楼，F5 进 Boss。
local function chooseCh101ReachNode(snapshot, routeState, selectable, partyLevel, currentFloor)
    if not routeState.firstBattleResolved then
        for _, node in ipairs(selectable) do
            if not node.visited and node.nodeType == "battle_normal" then
                return node
            end
        end
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return not n.visited and n.nodeType == "battle_normal"
        end)
        return pickHopIfSelectable(selectable, hop)
    end

    if currentFloor >= 5 then
        local campHop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return not n.visited and n.nodeType == "camp" and (tonumber(n.floor) or 0) == currentFloor
        end, CH101_PATH_OPTS)
            or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return not n.visited and n.nodeType == "camp" and (tonumber(n.floor) or 0) == currentFloor
            end)
        local pickedCamp = pickHopIfSelectable(selectable, campHop)
        if pickedCamp then
            return pickedCamp
        end
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "boss" and not n.visited
        end, CH101_PATH_OPTS)
            or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return n.nodeType == "boss" and not n.visited
            end)
        return pickHopIfSelectable(selectable, hop)
    end

    if currentFloor < 5 and routeState.firstBattleResolved then
        if currentFloor >= 4 then
            local campHop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return not n.visited and n.nodeType == "camp" and (tonumber(n.floor) or 0) == currentFloor
            end, CH101_PATH_OPTS)
                or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                    return not n.visited and n.nodeType == "camp" and (tonumber(n.floor) or 0) == currentFloor
                end)
            local pickedCamp = pickHopIfSelectable(selectable, campHop)
            if pickedCamp then
                return pickedCamp
            end
        end
        local stairPred = function(n)
            return n.nodeType == "stair_down"
                and (tonumber(n.floor) or 0) == currentFloor
                and not isClearedHiddenEntrance(snapshot, n)
        end
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, stairPred, CH101_PATH_OPTS)
            or RoguelikeTestRoute.findPathNextHop(snapshot, stairPred)
        if not hop and hasUnvisitedBattleOnFloor(snapshot, currentFloor) then
            hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return not n.visited and n.nodeType == "battle_normal" and (tonumber(n.floor) or 0) == currentFloor
            end)
        end
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end

    for _, node in ipairs(selectable) do
        if not node.visited and node.nodeType == "camp" then
            return node
        end
    end

    return nil
end

function RoguelikeTestRoute.chooseNextNode(snapshot, routeState)
    local selectable = RoguelikeTestRoute.findSelectableNodes(snapshot)
    assert(#selectable > 0, "map should always expose at least one selectable node before completion")

    local partyLevel = tonumber(snapshot and snapshot.partyLevel) or 1
    local currentFloor = 1
    for _, node in ipairs((snapshot.map and snapshot.map.nodes) or {}) do
        if node.current then
            currentFloor = tonumber(node.floor) or 1
            break
        end
    end

    if routeState and routeState.requireRoomInteraction and routeState.firstBattleResolved then
        if not (routeState.campSeen or routeState.shopSeen or routeState.eventSeen) then
            local interaction = RoguelikeTestRoute.chooseStairTowardInteractionFloor(snapshot, { "shop", "camp" })
            if interaction then
                return interaction
            end
        end
    end

    if routeState and routeState.progressionMode == "ch101_reach" then
        local rushed = chooseCh101ReachNode(snapshot, routeState, selectable, partyLevel, currentFloor)
        if rushed then
            return rushed
        end
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "stair_down" or n.nodeType == "camp" or n.nodeType == "empty"
                or n.nodeType == "event" or n.nodeType == "equip"
        end, CH101_PATH_OPTS)
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
        for _, node in ipairs(selectable) do
            if node.nodeType ~= "battle_elite" and node.nodeType ~= "battle_normal" then
                return node
            end
        end
    end

    if routeState and routeState.firstBattleResolved and not hasUnvisitedBattleOnMap(snapshot) then
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor
        end) or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "boss" and not n.visited
        end)
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end

    if routeState and routeState.firstBattleResolved and partyLevel < 3 then
        for _, node in ipairs(selectable) do
            if not node.visited and node.nodeType == "battle_normal" then
                return node
            end
        end
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return not n.visited and n.nodeType == "battle_normal"
        end)
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end

    if routeState and not routeState.firstBattleResolved then
        for _, node in ipairs(selectable) do
            if not node.visited and node.nodeType == "battle_normal" then
                return node
            end
        end
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return not n.visited and n.nodeType == "battle_normal"
        end)
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end

    if partyLevel >= currentFloor * 4 and partyLevel >= 3 then
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "boss" and not n.visited
        end) or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor
        end)
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end

    local allVisitedSelectable = true
    for _, node in ipairs(selectable) do
        if not node.visited then
            allVisitedSelectable = false
            break
        end
    end
    if allVisitedSelectable then
        local hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
            return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor
        end)
            or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return n.nodeType == "boss" and not n.visited
            end)
            or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return not n.visited and n.nodeType ~= "stair_up" and n.nodeType ~= "empty"
            end)
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end

    local hasUnvisited = false
    for _, n in ipairs(selectable) do
        if not n.visited and n.nodeType ~= "stair_up" then
            hasUnvisited = true
            break
        end
    end
    if not hasUnvisited then
        local hop
        if partyLevel >= 5 then
            hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return n.nodeType == "boss" and not n.visited
            end)
                or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                    return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor
                end)
        else
            hop = RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                return not n.visited and n.nodeType ~= "stair_up" and n.nodeType ~= "empty"
            end)
                or RoguelikeTestRoute.findPathNextHop(snapshot, function(n)
                    return n.nodeType == "stair_down" and (tonumber(n.floor) or 0) == currentFloor
                end)
        end
        local picked = pickHopIfSelectable(selectable, hop)
        if picked then
            return picked
        end
    end

    local best, bestScore
    local pref = RoguelikeTestRoute.PREFERENCE
    local visitedScore = RoguelikeTestRoute.VISITED_SCORE
    for _, node in ipairs(selectable) do
        local score
        local floorDepth = tonumber(node.floor) or 1
        if node.visited then
            if node.nodeType == "empty" or node.nodeType == "equip" then
                score = 999
            elseif node.nodeType == "stair_down" and partyLevel >= 2 then
                score = 45
            else
                score = visitedScore
            end
        else
            score = pref[node.nodeType] or 99
            if node.nodeType == "battle_elite" then
                if partyLevel < 6 or partyLevel < floorDepth * 4 + 2 then
                    score = 999
                else
                    score = 60
                end
            elseif node.nodeType == "battle_normal" then
                if partyLevel < 3 then
                    score = 5
                elseif partyLevel >= floorDepth * 6 then
                    score = 70
                end
            elseif node.nodeType == "stair_down" then
                if partyLevel < 3 then
                    score = 150
                elseif partyLevel >= floorDepth * 4 then
                    score = 25
                end
            elseif node.nodeType == "boss" then
                if partyLevel >= 5 then
                    score = 15
                end
            elseif node.nodeType == "stair_up" then
                score = 220
            end
        end
        if routeState then
            if routeState.lastNodeId == node.id then
                score = score + 500
            end
            local recent = routeState.recentNodeIds or {}
            if recent[1] == node.id or recent[2] == node.id then
                score = score + 800
            end
        end
        if not bestScore or score < bestScore then
            best = node
            bestScore = score
        end
    end
    return best or selectable[1]
end

--- 回归用：优先零风险选项，再试检定选项（遍历队员），最后倒序尝试其余选项。
function RoguelikeTestRoute.resolveEvent(runModule, snapshot)
    local options = (snapshot and snapshot.eventState and snapshot.eventState.options) or {}
    assert(#options > 0, "event should expose options")

    local function tryOption(optionId, rosterHeroId)
        if runModule.ChooseEventOption(optionId, rosterHeroId) ~= true then
            return false
        end
        if runModule.ContinueEvent and runModule.ContinueEvent() == true then
            return true
        end
        local phase = runModule.GetSnapshot and runModule.GetSnapshot().phase or nil
        return phase ~= "event"
    end

    for _, opt in ipairs(options) do
        if opt.zeroRisk == true and tryOption(opt.id) then
            return true
        end
    end

    local team = (snapshot and snapshot.team) or {}
    for _, opt in ipairs(options) do
        if opt.skillCheck then
            for _, hero in ipairs(team) do
                if tryOption(opt.id, hero.rosterId) then
                    return true
                end
            end
        end
    end

    for i = #options, 1, -1 do
        if tryOption(options[i].id) then
            return true
        end
    end
    for _, opt in ipairs(options) do
        if tryOption(opt.id) then
            return true
        end
    end
    return false
end

return RoguelikeTestRoute
