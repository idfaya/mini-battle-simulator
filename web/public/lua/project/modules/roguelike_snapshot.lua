local RoguelikeMap = require("modules.roguelike_map")
local RunRelicConfig = require("config.roguelike.run_relic_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")

local RoguelikeSnapshot = {}

local function shallowCopyArray(input)
    local result = {}
    for i, v in ipairs(input or {}) do
        result[i] = v
    end
    return result
end

local function serializeTeam(roster)
    local result = {}
    for _, hero in ipairs(roster or {}) do
        result[#result + 1] = {
            rosterId = hero.rosterId,
            heroId = hero.heroId,
            name = hero.name,
            classId = hero.classId,
            level = hero.level,
            star = hero.star,
            hp = hero.currentHp,
            maxHp = hero.maxHp,
            isDead = hero.isDead == true,
            ultimateCharges = tonumber(hero.ultimateCharges) or tonumber(hero.ultimateChargesMax) or 1,
            ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1,
        }
    end
    return result
end

local function serializeRelics(relicIds)
    local result = {}
    for _, relicId in ipairs(relicIds or {}) do
        local relic = RunRelicConfig.GetRelic(relicId)
        result[#result + 1] = {
            relicId = relicId,
            name = relic and relic.name or ("Relic " .. tostring(relicId)),
            rarity = relic and relic.rarity or "common",
            code = relic and relic.code or "",
        }
    end
    return result
end

local function serializeBlessings(blessingIds)
    local result = {}
    for _, blessingId in ipairs(blessingIds or {}) do
        local blessing = RunBlessingConfig.GetBlessing(blessingId)
        result[#result + 1] = {
            blessingId = blessingId,
            name = blessing and blessing.name or ("Blessing " .. tostring(blessingId)),
            rarity = blessing and blessing.rarity or "common",
            code = blessing and blessing.code or "",
        }
    end
    return result
end

local function serializeMap(runState)
    local chapterMap = RoguelikeMap.BuildChapterMap(runState.chapterId)
    if not chapterMap then
        return nil
    end

    local visited = runState.visitedNodeIds or {}
    local available = {}
    for _, nodeId in ipairs(runState.availableNextNodeIds or {}) do
        available[nodeId] = true
    end

    local nodes = {}
    for _, node in ipairs(chapterMap.nodes or {}) do
        nodes[#nodes + 1] = {
            id = node.id,
            floor = node.floor,
            lane = node.lane,
            nodeType = node.nodeType,
            title = node.title,
            visited = visited[node.id] == true,
            current = runState.currentNodeId == node.id,
            selectable = available[node.id] == true,
        }
    end

    return {
        chapterId = chapterMap.chapterId,
        floorCount = chapterMap.floorCount,
        nodes = nodes,
        startNodeId = chapterMap.startNodeId,
        bossNodeId = chapterMap.bossNodeId,
    }
end

function RoguelikeSnapshot.Build(runState, battleSnapshot)
    return {
        phase = runState.phase,
        chapterId = runState.chapterId,
        currentNodeId = runState.currentNodeId,
        maxHeroCount = runState.maxHeroCount or 5,
        partyLevel = runState.partyLevel or 1,
        partyExp = runState.partyExp or 0,
        levelProgressExp = runState.levelProgressExp or 0,
        nextLevelExp = runState.nextLevelExp or 0,
        gold = runState.gold or 0,
        food = runState.food or 0,
        lastActionMessage = runState.lastActionMessage or "",
        map = serializeMap(runState),
        team = serializeTeam(runState.teamRoster),
        bench = serializeTeam(runState.benchRoster),
        relics = serializeRelics(runState.relicIds),
        blessings = serializeBlessings(runState.blessingIds),
        eventState = runState.eventState,
        shopState = runState.shopState,
        campState = runState.campState,
        rewardState = runState.rewardState,
        battleSnapshot = battleSnapshot,
        chapterResult = runState.chapterResult,
        debug = {
            availableNextNodeIds = shallowCopyArray(runState.availableNextNodeIds),
        },
    }
end

return RoguelikeSnapshot
