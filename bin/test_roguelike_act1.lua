local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local BattleFormation = require("modules.battle_formation")
local RunEncounterGroup = require("config.roguelike.run_encounter_group")
local ClassRoleConfig = require("config.class_role_config")
local HeroData = require("config.hero_data")

local function getUltimateSkillForUnit(unitId)
    local hero = BattleFormation.FindHeroByInstanceId and BattleFormation.FindHeroByInstanceId(tonumber(unitId)) or nil
    local instances = hero and hero.skillData and hero.skillData.skillInstances or nil
    if not instances then
        return nil
    end
    for _, skill in pairs(instances) do
        if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then
            return skill
        end
    end
    return nil
end

local function isEnemyOrOutputUltimate(unit)
    if not unit or not unit.id or unit.ultimateReady ~= true then
        return false
    end

    local ult = getUltimateSkillForUnit(unit.id)
    if not ult then
        return false
    end

    local ts = ult.targetsSelections or (ult.config and ult.config.targetsSelections) or nil
    local castTarget = ts and ts.castTarget or ult.castTarget
    if castTarget == E_CAST_TARGET.Enemy or castTarget == E_CAST_TARGET.EnemyPos then
        return true
    end

    -- "输出型"：用技能描述里的骰子/伤害关键词做保守判断；治疗/复活类不自动点。
    local desc = (ult.skillConfig and ult.skillConfig.Description) or ""
    if desc:find("治疗") or desc:find("复活") then
        return false
    end
    if desc:find("伤害骰") or desc:find("%dd%d+") or desc:find("d%d+") then
        return true
    end
    return false
end

local function findReadyHero(snapshot)
    local battleSnapshot = snapshot and snapshot.battleSnapshot or nil
    if not battleSnapshot then
        return nil
    end
    for _, unit in ipairs(battleSnapshot.leftTeam or {}) do
        if isEnemyOrOutputUltimate(unit) then
            return unit.id
        end
    end
    return nil
end

local function runBattleUntilResolved(maxSteps)
    local snapshot = Run.GetSnapshot()
    for _ = 1, maxSteps do
        -- If any unit can cast an offensive limited-use skill, do it immediately to reduce wipe risk.
        local heroId = findReadyHero(snapshot)
        if heroId then
            Run.QueueBattleCommand({ type = "cast_ultimate", heroId = heroId })
        end
        Run.Tick(800)
        snapshot = Run.GetSnapshot()
        if snapshot.phase ~= "battle" then
            return snapshot
        end
    end
    error("battle did not resolve in time")
end

local function choosePathAndEnter(nodeId)
    local ok, reason = Run.ChoosePath(nodeId)
    assert(ok, "choose path failed: " .. tostring(reason))
    ok, reason = Run.EnterCurrentNode()
    assert(ok, "enter node failed: " .. tostring(reason))
end

local function assertEncounterScalesRemoved()
    for encounterId, encounter in pairs(RunEncounterGroup.ENCOUNTERS or {}) do
        assert(encounter.playerScale == nil, string.format("encounter %s should not define playerScale", tostring(encounterId)))
        assert(encounter.enemyScale == nil, string.format("encounter %s should not define enemyScale", tostring(encounterId)))
    end
end

local function autoPromoteBench()
    local snapshot = Run.GetSnapshot()
    while #(snapshot.bench or {}) > 0 and #(snapshot.team or {}) < (snapshot.maxHeroCount or 5) do
        local benchHero = snapshot.bench[1]
        assert(benchHero and benchHero.rosterId, "bench hero should exist when promoting")
        assert(Run.PromoteBenchHero(benchHero.rosterId) == true, "bench promote should succeed")
        snapshot = Run.GetSnapshot()
    end
    return snapshot
end

local function acceptRewardIfPresent()
    local current = Run.GetSnapshot()
    local guard = 0
    while current.phase == "reward" and guard < 4 do
        local rewardIndex = chooseRewardIndex(current)
        assert(Run.ChooseReward(rewardIndex) == true, "reward selection should succeed")
        current = autoPromoteBench()
        guard = guard + 1
    end
    assert(current.phase == "map" or current.phase == "chapter_result", "reward chain should return to map or chapter_result")
    return current
end

function chooseRewardIndex(snapshot)
    local reward = snapshot and snapshot.rewardState
    if not reward or not reward.options then
        return 1
    end

    if reward.kind == "node_recruit" then
        local existing = {}
        for _, hero in ipairs(snapshot.team or {}) do
            existing[hero.heroId] = true
        end
        for _, hero in ipairs(snapshot.bench or {}) do
            existing[hero.heroId] = true
        end
        local bestIndex, bestQuality
        for index, option in ipairs(reward.options) do
            local heroId = tonumber(option.refId)
            if heroId and not existing[heroId] then
                local heroInfo = HeroData.GetHeroInfo(heroId) or {}
                local quality = tonumber(heroInfo.BaseQuality or heroInfo.Quality) or 1
                if not bestQuality or quality > bestQuality then
                    bestIndex = index
                    bestQuality = quality
                end
            end
        end
        if bestIndex then
            return bestIndex
        end
    end

    local priority = {
        recruit = 1,
        equipment = 2,
        blessing = 3,
        gold = 4,
    }
    local bestIndex, bestScore
    for index, option in ipairs(reward.options) do
        local score = priority[option.rewardType] or 99
        if not bestScore or score < bestScore then
            bestIndex = index
            bestScore = score
        end
    end
    return bestIndex or 1
end

local function countRows(team)
    local front = 0
    local back = 0
    for _, hero in ipairs(team or {}) do
        if ClassRoleConfig.PreferFrontRow(hero.classId) then
            front = front + 1
        else
            back = back + 1
        end
    end
    return front, back
end

local function assertOwnedUnitViews(snapshot)
    local ownedUnits = snapshot and snapshot.ownedUnits or {}
    local teamCount = 0
    local benchCount = 0
    for _, hero in ipairs(ownedUnits) do
        if hero.teamState == "bench" then
            benchCount = benchCount + 1
        else
            teamCount = teamCount + 1
        end
    end
    assert(teamCount == #(snapshot.team or {}), "team view should match ownedUnits non-bench partition")
    assert(benchCount == #(snapshot.bench or {}), "bench view should match ownedUnits bench partition")
    assert(#ownedUnits == teamCount + benchCount, "ownedUnits should be fully partitioned into team/bench views")
end

local function chooseCampAction(snapshot)
    local hasDeadHero = false
    for _, hero in ipairs((snapshot and snapshot.team) or {}) do
        if hero.isDead or (hero.hp or 0) <= 0 then
            hasDeadHero = true
            break
        end
    end

    local campState = snapshot and snapshot.campState or {}
    if hasDeadHero then
        for _, action in ipairs(campState.actions or {}) do
            if tonumber(action.id) == 1 and action.available ~= false then
                return 1
            end
        end
    end
    for _, action in ipairs(campState.actions or {}) do
        if tonumber(action.id) == 2 and action.available ~= false then
            return 2
        end
    end
    for _, action in ipairs(campState.actions or {}) do
        if action.available ~= false then
            return tonumber(action.id)
        end
    end
    return 1
end

local function findSelectableNodes(snapshot)
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

local function chooseNextNode(snapshot, routeState)
    local selectable = findSelectableNodes(snapshot)
    assert(#selectable > 0, "map should always expose at least one selectable node before completion")
    local nodesById = {}
    for _, node in ipairs((snapshot and snapshot.map and snapshot.map.nodes) or {}) do
        nodesById[node.id] = node
    end

    local function pathCanReachType(startNodeId, wantedType, visited)
        visited = visited or {}
        if visited[startNodeId] then
            return false
        end
        visited[startNodeId] = true
        local node = nodesById[startNodeId]
        if not node then
            return false
        end
        if node.nodeType == wantedType then
            return true
        end
        for _, nextNodeId in ipairs(node.nextNodeIds or {}) do
            if pathCanReachType(nextNodeId, wantedType, visited) then
                return true
            end
        end
        return false
    end

    local function pickByTypes(types)
        for _, wanted in ipairs(types) do
            for _, node in ipairs(selectable) do
                if node.nodeType == wanted then
                    return node
                end
            end
        end
        return nil
    end

    local function pickByReachableType(wantedType)
        for _, node in ipairs(selectable) do
            if pathCanReachType(node.id, wantedType) then
                return node
            end
        end
        return nil
    end

    local function scoreNodeForPendingGoals(node)
        local score = 0
        if node.nodeType == "recruit" then
            score = score + (routeState.recruitSeen and 0 or 1000)
        end
        if node.nodeType == "camp" then
            score = score + (routeState.campSeen and 0 or 900)
        end
        if node.nodeType == "shop" then
            score = score + (routeState.shopSeen and 0 or 700)
        end
        if node.nodeType == "event" then
            score = score + (routeState.eventSeen and 0 or 500)
        end
        if not routeState.recruitSeen and pathCanReachType(node.id, "recruit") then
            score = score + 400
        end
        if not routeState.campSeen and pathCanReachType(node.id, "camp") then
            score = score + 320
        end
        if not routeState.shopSeen and pathCanReachType(node.id, "shop") then
            score = score + 240
        end
        if not routeState.eventSeen and pathCanReachType(node.id, "event") then
            score = score + 180
        end
        if node.nodeType == "battle_normal" then
            score = score + 100
        elseif node.nodeType == "battle_elite" then
            score = score + 80
        elseif node.nodeType == "boss" then
            score = score + 20
        end
        return score
    end

    local bestNode = selectable[1]
    local bestScore = -1
    for _, node in ipairs(selectable) do
        local score = scoreNodeForPendingGoals(node)
        if score > bestScore then
            bestScore = score
            bestNode = node
        end
    end

    if not routeState.shopSeen then
        return pickByTypes({ "shop" })
            or pickByReachableType("shop")
            or pickByTypes({ "battle_normal", "event", "camp", "recruit", "battle_elite", "boss" })
            or bestNode
    end
    if not routeState.campSeen then
        return pickByTypes({ "camp" })
            or pickByReachableType("camp")
            or pickByTypes({ "battle_normal", "event", "battle_elite", "recruit", "boss" })
            or bestNode
    end
    if not routeState.recruitSeen then
        return pickByTypes({ "recruit" })
            or pickByReachableType("recruit")
            or pickByTypes({ "event", "battle_normal", "battle_elite", "shop", "boss" })
            or bestNode
    end
    if not routeState.eventSeen then
        return pickByTypes({ "event" })
            or pickByReachableType("event")
            or pickByTypes({ "battle_normal", "battle_elite", "shop", "recruit", "boss" })
            or bestNode
    end
    return pickByTypes({ "event", "shop", "battle_normal", "battle_elite", "recruit", "boss" }) or bestNode
end

assertEncounterScalesRemoved()

math.randomseed(10102)

local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = 10102,
})

assert(snapshot.phase == "map", "run should start on map")
assert(#(snapshot.debug.availableNextNodeIds or {}) == 1, "start map should expose one node")
assert(#(snapshot.team or {}) == 4, "run should start with 4 heroes")
assertOwnedUnitViews(snapshot)
local frontCount, backCount = countRows(snapshot.team)
assert(frontCount == 2 and backCount == 2, "starter team should be 2 front and 2 back")
local routeState = {
    recruitSeen = false,
    campSeen = false,
    shopSeen = false,
    eventSeen = false,
    firstBattleResolved = false,
}
local goldBeforeFirstBattle = nil
local guard = 0

while guard < 24 do
    guard = guard + 1
    snapshot = Run.GetSnapshot()
    assertOwnedUnitViews(snapshot)

    if snapshot.phase == "chapter_result" then
        break
    end
    assert(snapshot.phase ~= "failed", "run should not fail during act1 regression")

    if snapshot.phase == "map" then
        local nextNode = chooseNextNode(snapshot, routeState)
        assert(nextNode and nextNode.id, "should choose a valid next node")
        choosePathAndEnter(nextNode.id)
        local afterEnter = Run.GetSnapshot()
        if nextNode.nodeType == "battle_normal" or nextNode.nodeType == "battle_elite" or nextNode.nodeType == "boss" then
            assert(afterEnter.phase == "battle", "battle node should enter battle")
            if goldBeforeFirstBattle == nil then
                goldBeforeFirstBattle = afterEnter.gold or 0
            end
        elseif nextNode.nodeType == "recruit" then
            assert(afterEnter.phase == "reward", "recruit node should open reward")
            routeState.recruitSeen = true
        elseif nextNode.nodeType == "camp" then
            assert(afterEnter.phase == "camp", "camp node should open camp")
            routeState.campSeen = true
        elseif nextNode.nodeType == "shop" then
            assert(afterEnter.phase == "shop", "shop node should open shop")
            routeState.shopSeen = true
        elseif nextNode.nodeType == "event" then
            assert(afterEnter.phase == "event", "event node should open event")
            routeState.eventSeen = true
        end
    elseif snapshot.phase == "battle" then
        snapshot = runBattleUntilResolved(900)
        if not routeState.firstBattleResolved then
            routeState.firstBattleResolved = true
            assert(goldBeforeFirstBattle ~= nil, "first battle gold baseline should be captured")
            assert((snapshot.gold or 0) > goldBeforeFirstBattle, "first battle should still grant gold")
        end
        if snapshot.phase == "reward" then
            snapshot = acceptRewardIfPresent()
        end
    elseif snapshot.phase == "reward" then
        assert(Run.ChooseReward(chooseRewardIndex(snapshot)) == true, "reward selection should resolve")
        snapshot = autoPromoteBench()
        assertOwnedUnitViews(snapshot)
    elseif snapshot.phase == "camp" then
        assert(Run.CampChoose(chooseCampAction(snapshot)) == true, "camp action should work")
    elseif snapshot.phase == "shop" then
        assert(Run.ShopLeave() == true, "shop leave should succeed")
    elseif snapshot.phase == "event" then
        local options = snapshot.eventState and snapshot.eventState.options or {}
        assert(#options > 0, "event should expose options")
        assert(Run.ChooseEventOption(options[1].id) == true, "event option should resolve")
    else
        error("unsupported phase in act1 regression: " .. tostring(snapshot.phase))
    end
end

snapshot = Run.GetSnapshot()
assert(guard < 24, "act1 flow should resolve within guard limit")
assert(routeState.firstBattleResolved, "act1 flow should include at least one battle")
assert(routeState.shopSeen, "act1 flow should include at least one shop")
assert(routeState.campSeen, "act1 flow should include at least one camp")
assert(snapshot.phase == "chapter_result", "act1 random route should eventually clear the chapter")
assertOwnedUnitViews(snapshot)
print("roguelike act1 flow test passed")
