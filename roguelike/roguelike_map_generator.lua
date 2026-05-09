local RunMapGenProfile = require("config.roguelike.run_map_gen_profile")

local RoguelikeMapGenerator = {}

local function cloneArray(input)
    local result = {}
    for i, value in ipairs(input or {}) do
        result[i] = value
    end
    return result
end

local function makeRng(seed)
    local state = math.max(1, math.floor(tonumber(seed) or 1) % 2147483647)
    return {
        nextInt = function(self, minValue, maxValue)
            state = (state * 48271) % 2147483647
            local minV = math.floor(tonumber(minValue) or 0)
            local maxV = math.floor(tonumber(maxValue) or minV)
            if maxV < minV then
                minV, maxV = maxV, minV
            end
            local span = maxV - minV + 1
            if span <= 1 then
                return minV
            end
            return minV + (state % span)
        end,
        pick = function(self, list)
            if not list or #list <= 0 then
                return nil
            end
            return list[self:nextInt(1, #list)]
        end,
        weightedPick = function(self, entries, weightKey)
            local total = 0
            for _, entry in ipairs(entries or {}) do
                total = total + math.max(0, tonumber(entry[weightKey or "weight"]) or 0)
            end
            if total <= 0 then
                return entries and entries[1] or nil
            end
            local roll = self:nextInt(1, total)
            local running = 0
            for _, entry in ipairs(entries or {}) do
                running = running + math.max(0, tonumber(entry[weightKey or "weight"]) or 0)
                if roll <= running then
                    return entry
                end
            end
            return entries and entries[#entries] or nil
        end,
    }
end

local function makeNodeId(chapterId, floor, lane)
    return (math.floor(chapterId) * 100000) + floor * 10 + lane
end

local function pickDistinctFloor(rng, candidates, used)
    local pool = {}
    for _, floor in ipairs(candidates or {}) do
        if not used[floor] then
            pool[#pool + 1] = floor
        end
    end
    if #pool <= 0 then
        pool = cloneArray(candidates)
    end
    local picked = rng:pick(pool)
    if picked then
        used[picked] = true
    end
    return picked
end

local function buildNodeTitle(nodeType, floor)
    if nodeType == "battle_normal" then
        return string.format("第%d层战斗", floor)
    end
    if nodeType == "battle_elite" then
        return string.format("第%d层精英", floor)
    end
    if nodeType == "event" then
        return string.format("第%d层事件", floor)
    end
    if nodeType == "shop" then
        return "商店"
    end
    if nodeType == "camp" then
        return "营地"
    end
    if nodeType == "recruit" then
        return "招募"
    end
    if nodeType == "boss" then
        return "Boss"
    end
    return string.format("第%d层节点", floor)
end

local function chooseWeightedType(rng, weights, fallbackType)
    local entries = {}
    for nodeType, weight in pairs(weights or {}) do
        entries[#entries + 1] = {
            nodeType = nodeType,
            weight = tonumber(weight) or 0,
        }
    end
    table.sort(entries, function(a, b)
        return tostring(a.nodeType) < tostring(b.nodeType)
    end)
    local picked = rng:weightedPick(entries, "weight")
    return picked and picked.nodeType or fallbackType or "battle_normal"
end

local function ensureIncomingConnections(currentNodes, nextNodes)
    if #currentNodes <= 0 or #nextNodes <= 0 then
        return
    end
    for index, nextNode in ipairs(nextNodes) do
        local source = currentNodes[math.min(#currentNodes, index)]
        source.nextNodeIds[#source.nextNodeIds + 1] = nextNode.id
    end
end

local function ensureOutgoingConnections(currentNodes, nextNodes)
    if #currentNodes <= 0 or #nextNodes <= 0 then
        return
    end
    for index, node in ipairs(currentNodes) do
        if #(node.nextNodeIds or {}) <= 0 then
            local target = nextNodes[math.min(#nextNodes, index)] or nextNodes[#nextNodes]
            if target then
                node.nextNodeIds[#node.nextNodeIds + 1] = target.id
            end
        end
    end
end

local function addExtraConnections(rng, currentNodes, nextNodes)
    if #currentNodes <= 0 or #nextNodes <= 1 then
        return
    end
    for index, node in ipairs(currentNodes) do
        local neighbor = nextNodes[index] or nextNodes[#nextNodes]
        local alt = nextNodes[math.min(#nextNodes, index + 1)] or nextNodes[1]
        if neighbor and #node.nextNodeIds <= 0 then
            node.nextNodeIds[#node.nextNodeIds + 1] = neighbor.id
        end
        if alt and alt.id ~= node.nextNodeIds[1] and rng:nextInt(1, 100) <= 55 then
            node.nextNodeIds[#node.nextNodeIds + 1] = alt.id
        end
    end
end

local function uniqueList(input)
    local result = {}
    local seen = {}
    for _, value in ipairs(input or {}) do
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end
    return result
end

local function generateOnce(chapterId, seed, profile)
    local rng = makeRng((tonumber(seed) or 1) + chapterId * 7919 + profile.id * 17)
    local floorCount = tonumber(profile.floorCount) or 8
    local usedSpecialFloors = {}
    local recruitFloor = pickDistinctFloor(rng, profile.recruitFloorRange, usedSpecialFloors)
    local campFloor = pickDistinctFloor(rng, profile.campFloorRange, usedSpecialFloors)
    local shopFloor = pickDistinctFloor(rng, profile.shopFloorRange, usedSpecialFloors)
    local eventFloor = pickDistinctFloor(rng, profile.eventFloorRange, usedSpecialFloors)
    local eliteFloorA = pickDistinctFloor(rng, profile.eliteFloorRange, usedSpecialFloors)
    local eliteFloorB = rng:nextInt(1, 100) <= 50 and pickDistinctFloor(rng, profile.eliteFloorRange, usedSpecialFloors) or nil

    local floors = {}
    local nodesById = {}
    local totalNodes = 0
    local battleNodeCount = 0
    local startNodeId = nil
    local bossNodeId = nil

    for floor = 1, floorCount do
        local countRule = profile.nodeCountByFloor[floor] or { min = 1, max = 1 }
        local nodeCount = rng:nextInt(countRule.min or 1, countRule.max or countRule.min or 1)
        local floorNodes = {}
        for lane = 1, nodeCount do
            local nodeType = "battle_normal"
            if floor == 1 then
                nodeType = "battle_normal"
            elseif floor == floorCount then
                nodeType = "boss"
            else
                nodeType = chooseWeightedType(rng, profile.typeWeightsByFloor[floor], "battle_normal")
            end
            floorNodes[#floorNodes + 1] = {
                id = makeNodeId(chapterId, floor, lane),
                chapterId = chapterId,
                floor = floor,
                lane = lane,
                code = string.format("random_%d_%d_%d", chapterId, floor, lane),
                nodeType = nodeType,
                title = buildNodeTitle(nodeType, floor),
                nextNodeIds = {},
            }
        end

        local function overrideFloorType(targetFloor, forcedType)
            if floor ~= targetFloor or #floorNodes <= 0 or not forcedType then
                return
            end
            local pickIndex = rng:nextInt(1, #floorNodes)
            floorNodes[pickIndex].nodeType = forcedType
            floorNodes[pickIndex].title = buildNodeTitle(forcedType, floor)
        end

        overrideFloorType(recruitFloor, "recruit")
        overrideFloorType(shopFloor, "shop")
        overrideFloorType(campFloor, "camp")
        overrideFloorType(eventFloor, "event")
        overrideFloorType(eliteFloorA, "battle_elite")
        overrideFloorType(eliteFloorB, "battle_elite")

        floors[floor] = floorNodes
        for _, node in ipairs(floorNodes) do
            if node.nodeType == "battle_normal" or node.nodeType == "battle_elite" or node.nodeType == "boss" then
                battleNodeCount = battleNodeCount + 1
            end
            totalNodes = totalNodes + 1
            nodesById[node.id] = node
        end
    end

    for floor = 1, floorCount - 1 do
        ensureIncomingConnections(floors[floor], floors[floor + 1])
        addExtraConnections(rng, floors[floor], floors[floor + 1])
        ensureOutgoingConnections(floors[floor], floors[floor + 1])
        for _, node in ipairs(floors[floor]) do
            node.nextNodeIds = uniqueList(node.nextNodeIds)
        end
    end

    for floor = 1, floorCount - 1 do
        for _, node in ipairs(floors[floor]) do
            if node.nodeType == "recruit" then
                node.recruitPoolId = profile.recruitPoolId
            elseif node.nodeType == "shop" then
                node.shopId = profile.shopId
            elseif node.nodeType == "camp" then
                node.campId = profile.campId
            elseif node.nodeType == "event" then
                node.eventId = rng:pick(profile.eventIds)
            elseif node.nodeType == "battle_normal" then
                node.battlePoolId = profile.battlePoolIds.battle_normal
            elseif node.nodeType == "battle_elite" then
                node.battlePoolId = profile.battlePoolIds.battle_elite
            end
        end
    end

    startNodeId = floors[1][1] and floors[1][1].id or nil
    bossNodeId = floors[floorCount][1] and floors[floorCount][1].id or nil
    if bossNodeId then
        floors[floorCount][1].battlePoolId = profile.battlePoolIds.boss
    end

    local orderedNodes = {}
    for floor = 1, floorCount do
        for _, node in ipairs(floors[floor] or {}) do
            orderedNodes[#orderedNodes + 1] = node
        end
    end

    return {
        seed = tonumber(seed) or 0,
        profileId = profile.id,
        chapterId = chapterId,
        floorCount = floorCount,
        startNodeId = startNodeId,
        bossNodeId = bossNodeId,
        battleRatio = totalNodes > 0 and (battleNodeCount / totalNodes) or 0,
        nodes = orderedNodes,
        nodesById = nodesById,
    }
end

function RoguelikeMapGenerator.Generate(chapterId, seed, profileId)
    local profile = RunMapGenProfile.GetProfile(profileId)
    if not profile then
        return nil, "map_profile_not_found"
    end

    local minBattleRatio = tonumber(profile.battleRatioMin) or 0
    local bestMap = nil
    local bestRatio = -1
    local baseSeed = tonumber(seed) or 0
    for attempt = 1, 24 do
        local candidate = generateOnce(chapterId, baseSeed + attempt * 9973, profile)
        if candidate and (candidate.battleRatio or 0) > bestRatio then
            bestMap = candidate
            bestRatio = candidate.battleRatio or 0
        end
        if candidate and (candidate.battleRatio or 0) >= minBattleRatio then
            candidate.seed = baseSeed
            return candidate
        end
    end

    if bestMap and bestRatio >= minBattleRatio then
        bestMap.seed = baseSeed
        return bestMap
    end
    return nil, string.format("battle_ratio_below_min: %.3f < %.3f", bestRatio, minBattleRatio)
end

return RoguelikeMapGenerator
