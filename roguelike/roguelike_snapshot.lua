local RoguelikeMap = require("roguelike.roguelike_map")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local RoguelikeRoster = require("roguelike.roguelike_roster")

local RoguelikeSnapshot = {}
-- 注：等级曲线统一来自 config.roguelike.level_curve；本文件不再维护本地阈值表。

local function getNextLevelExp(hero)
    -- 个人下一级 EXP 已不再有意义（队伍共享 partyExp），保留 0 占位以兼容旧客户端字段。
    return 0
end

local function shallowCopyArray(input)
    local result = {}
    for i, v in ipairs(input or {}) do
        result[i] = v
    end
    return result
end

local function addUnique(list, value)
    if not value or value == "" then
        return
    end
    for _, existing in ipairs(list) do
        if existing == value then
            return
        end
    end
    list[#list + 1] = value
end

local function buildFeatSummary(hero)
    local result = {}
    local classId = tonumber(hero and hero.classId) or 0
    local level = tonumber(hero and hero.level) or 1
    for _, featId in ipairs(ClassBuildProgression.CollectFixedFeatIds(classId, level)) do
        local feat = FeatBuildConfig.GetFeat(featId)
        addUnique(result, feat and feat.name or nil)
    end
    for _, featId in ipairs(hero and hero.feats or {}) do
        local feat = FeatBuildConfig.GetFeat(featId)
        addUnique(result, feat and feat.name or nil)
    end
    return result
end

local function serializeTeam(roster)
    local result = {}
    for _, hero in ipairs(roster or {}) do
        result[#result + 1] = {
            rosterId = hero.rosterId,
            unitId = hero.unitId,
            heroId = hero.heroId,
            name = hero.name,
            classId = hero.classId,
            className = hero.className,
            characterGroup = hero.characterGroup,
            level = hero.level,
            nextLevelExp = getNextLevelExp(hero),
            star = hero.star,
            hp = hero.currentHp,
            maxHp = hero.maxHp,
            isDead = hero.isDead == true,
            teamState = hero.teamState,
            promotionStage = hero.promotionStage,
            skillPackageId = hero.skillPackageId,
            ultimateCharges = tonumber(hero.ultimateCharges) or tonumber(hero.ultimateChargesMax) or 1,
            ultimateChargesMax = tonumber(hero.ultimateChargesMax) or 1,
            buildSummary = buildFeatSummary(hero),
        }
    end
    return result
end

local function serializeEquipments(equipmentIds)
    local result = {}
    for _, equipmentId in ipairs(equipmentIds or {}) do
        local equipment = RunEquipmentConfig.GetEquipment(equipmentId)
        result[#result + 1] = {
            equipmentId = equipmentId,
            name = equipment and equipment.name or ("装备 " .. tostring(equipmentId)),
            rarity = equipment and equipment.rarity or "common",
            code = equipment and equipment.code or "",
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
            name = blessing and blessing.name or ("祝福 " .. tostring(blessingId)),
            rarity = blessing and blessing.rarity or "common",
            code = blessing and blessing.code or "",
            description = blessing and blessing.description or "",
        }
    end
    return result
end

local function serializeMap(runState)
    local chapterMap = RoguelikeMap.BuildChapterMap(runState.chapterId, runState.dungeonState)
    if not chapterMap then
        return nil
    end

    local visited = runState.visitedNodeIds or {}
    local available = {}
    for _, nodeId in ipairs(runState.availableNextNodeIds or {}) do
        available[nodeId] = true
    end
    local chapter = RoguelikeMap.GetChapter(runState.chapterId) or {}
    local hideNodeTitles = chapter.mapVision == "node_type_only"
    local edges = {}

    local nodes = {}
    for _, node in ipairs(chapterMap.nodes or {}) do
        local visible = visited[node.id] == true or runState.currentNodeId == node.id or available[node.id] == true or node.id == chapterMap.startNodeId
        local titleVisible = (not hideNodeTitles) or visible
        nodes[#nodes + 1] = {
            id = node.id,
            floor = node.floor,
            lane = node.lane,
            nodeType = node.nodeType,
            title = titleVisible and node.title or "",
            visited = visited[node.id] == true,
            current = runState.currentNodeId == node.id,
            selectable = available[node.id] == true,
            revealed = visible,
            titleVisible = titleVisible,
            nextNodeIds = shallowCopyArray(node.nextNodeIds),
        }
        for _, nextNodeId in ipairs(node.nextNodeIds or {}) do
            edges[#edges + 1] = {
                fromNodeId = node.id,
                toNodeId = nextNodeId,
            }
        end
    end

    return {
        chapterId = chapterMap.chapterId,
        floorCount = chapterMap.floorCount,
        nodes = nodes,
        edges = edges,
        startNodeId = chapterMap.startNodeId,
        bossNodeId = chapterMap.bossNodeId,
    }
end

function RoguelikeSnapshot.Build(runState, battleSnapshot)
    local ownedUnits = serializeTeam(RoguelikeRoster.GetOwnedUnits(runState))
    local teamRoster = serializeTeam(RoguelikeRoster.GetTeamUnits(runState))
    local benchRoster = serializeTeam(RoguelikeRoster.GetBenchUnits(runState))
    return {
        phase = runState.phase,
        chapterId = runState.chapterId,
        currentFloorDepth = runState.dungeonState and runState.dungeonState.currentFloorDepth or nil,
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
        ownedUnits = ownedUnits,
        team = teamRoster,
        bench = benchRoster,
        equipments = serializeEquipments(runState.equipmentIds),
        blessings = serializeBlessings(runState.blessingIds),
        eventState = runState.eventState,
        shopState = runState.shopState,
        campState = runState.campState,
        rewardState = runState.rewardState,
        lastBattleSummary = runState.lastBattleSummary,
        battleSnapshot = battleSnapshot,
        currentBattleBudget = runState.currentBattleBudget,
        chapterResult = runState.chapterResult,
        debug = {
            availableNextNodeIds = shallowCopyArray(runState.availableNextNodeIds),
        },
    }
end

return RoguelikeSnapshot

