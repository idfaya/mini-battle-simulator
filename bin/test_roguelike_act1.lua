local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RoguelikeTestRoute = dofile(script_dir .. "roguelike_test_route.lua")
local BattleFormation = require("modules.battle_formation")
local RunBattleProfile = require("config.roguelike.run_battle_profile")
local ClassRoleConfig = require("config.tables.classes")

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
    local desc = (ult.skillConfig and ult.skillConfig.description) or ""
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
    for battleId, battleProfile in pairs(RunBattleProfile.BATTLE_PROFILES or {}) do
        assert(battleProfile.playerScale == nil, string.format("battle %s should not define playerScale", tostring(battleId)))
        assert(battleProfile.enemyScale == nil, string.format("battle %s should not define enemyScale", tostring(battleId)))
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
    -- 单场战斗可能跨多档 partyExp；FeatPicker 链式 pendingLevels 需全部 Pick 完。
    while current.phase == "reward" and guard < 32 do
        local reward = current.rewardState
        assert(reward and #(reward.options or {}) > 0,
            "reward phase should expose options (kind=" .. tostring(reward and reward.kind) .. ")")
        local rewardIndex = chooseRewardIndex(current)
        assert(Run.ChooseReward(rewardIndex) == true,
            "reward selection should succeed (kind=" .. tostring(reward.kind) .. ", index=" .. tostring(rewardIndex) .. ")")
        current = autoPromoteBench()
        guard = guard + 1
    end
    assert(current.phase == "map" or current.phase == "chapter_result",
        "reward chain should return to map or chapter_result, got " .. tostring(current.phase))
    return current
end

function chooseRewardIndex(snapshot)
    local reward = snapshot and snapshot.rewardState
    if not reward or not reward.options then
        return 1
    end

    -- 升级三选一：优先选当前等级最低的英雄，让全队等级尽量均衡，避免敌人按 partyLevel 缩放后某些英雄拖后腿。
    if reward.kind == "feat_levelup" then
        local levelByRoster = {}
        for _, hero in ipairs(snapshot.team or {}) do
            levelByRoster[tonumber(hero.rosterId) or 0] = tonumber(hero.level) or 1
        end
        local bestIndex, bestLevel
        for index, option in ipairs(reward.options) do
            local rosterId = tonumber(option.rosterId) or 0
            local lv = levelByRoster[rosterId] or 99
            if not bestLevel or lv < bestLevel then
                bestLevel = lv
                bestIndex = index
            end
        end
        if bestIndex then
            return bestIndex
        end
    end

    local priority = {
        equipment = 1,
        blessing = 2,
        gold = 3,
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

local chooseNextNode = RoguelikeTestRoute.chooseNextNode

assertEncounterScalesRemoved()

-- 全章 3 章通关回归计算量大：主种子 + 抽样（10101/10102 见计划 §2.3 单独跟踪）。
local SEEDS = { 1 }

local function runOnce(seed)
    math.randomseed(seed)

    local snapshot = Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = seed,
    })

    assert(snapshot.phase == "map", "run should start on map")
    assert(#(snapshot.debug.availableNextNodeIds or {}) >= 1, "start map should expose at least one node")
    assert(#(snapshot.team or {}) == 4, "run should start with 4 heroes")
    assertOwnedUnitViews(snapshot)
    local frontCount, backCount = countRows(snapshot.team)
    assert(frontCount == 2 and backCount == 2, "starter team should be 2 front and 2 back")
    local routeState = {
        campSeen = false,
        shopSeen = false,
        eventSeen = false,
        firstBattleResolved = false,
        lastNodeId = nil,
        recentNodeIds = {},
    }
    local goldBeforeFirstBattle = nil
    local guard = 0

    while guard < 800 do
        guard = guard + 1
        snapshot = Run.GetSnapshot()
        assertOwnedUnitViews(snapshot)

        if snapshot.phase == "chapter_result" then
            break
        end
        assert(snapshot.phase ~= "failed", "run should not fail during act1 regression (seed=" .. tostring(seed) .. ")")

        if snapshot.phase == "map" then
            local nextNode = chooseNextNode(snapshot, routeState)
            assert(nextNode and nextNode.id, "should choose a valid next node")
            choosePathAndEnter(nextNode.id)
            routeState.recentNodeIds[2] = routeState.recentNodeIds[1]
            routeState.recentNodeIds[1] = routeState.lastNodeId
            routeState.lastNodeId = nextNode.id
            local afterEnter = Run.GetSnapshot()
            if nextNode.nodeType == "battle_normal" or nextNode.nodeType == "battle_elite" or nextNode.nodeType == "boss" then
                if afterEnter.phase == "battle" then
                    if goldBeforeFirstBattle == nil then
                        goldBeforeFirstBattle = afterEnter.gold or 0
                    end
                else
                    assert(afterEnter.phase == "map", "cleared battle should pass through (dungeon §4.2)")
                end
            elseif nextNode.nodeType == "camp" then
                assert(afterEnter.phase == "map", "camp node should auto-settle and return to map")
                routeState.campSeen = true
            elseif nextNode.nodeType == "shop" then
                assert(afterEnter.phase == "shop", "shop node should open shop")
                routeState.shopSeen = true
            elseif nextNode.nodeType == "event" then
                if afterEnter.phase == "event" then
                    routeState.eventSeen = true
                else
                    assert(afterEnter.phase == "map", "cleared event node should pass through (dungeon §4.2)")
                end
            elseif nextNode.nodeType == "stair_down" or nextNode.nodeType == "stair_up" then
                if nextNode.visited then
                    assert(
                        afterEnter.phase == "map" or afterEnter.phase == "stair",
                        "visited stair may pass through or reopen stair UI before cleared"
                    )
                else
                    assert(afterEnter.phase == "stair", "stair node should open stair phase")
                end
            end
            -- equip / empty 等其他 nodeType 由 roguelike_run 直接处理（回 map 或 reward）。
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
            snapshot = acceptRewardIfPresent()
            assertOwnedUnitViews(snapshot)
        elseif snapshot.phase == "camp" then
            -- 营地动作可能因重复祝福（duplicate_blessing）等约束失败，按可用列表逐个 fallback；
            -- dungeon §4.2 cleared camp 全 unavailable 时直接 CampLeave。
            local primary = chooseCampAction(snapshot)
            local resolved = false
            if Run.CampChoose(primary) == true then
                resolved = true
            else
                for _, action in ipairs((snapshot.campState and snapshot.campState.actions) or {}) do
                    if action.available ~= false and tonumber(action.id) ~= primary then
                        if Run.CampChoose(tonumber(action.id)) == true then
                            resolved = true
                            break
                        end
                    end
                end
            end
            if not resolved then
                assert(Run.CampLeave() == true, "camp leave should succeed when no action available")
            end
        elseif snapshot.phase == "shop" then
            assert(Run.ShopLeave() == true, "shop leave should succeed")
        elseif snapshot.phase == "event" then
            assert(RoguelikeTestRoute.resolveEvent(Run, snapshot) == true, "event option should resolve")
        elseif snapshot.phase == "stair" then
            -- 楼梯房：partyLevel 高于本层阈值时使用楼梯推进；否则路过当通路探索本层。
            local stair = snapshot.stairState or {}
            local depth = tonumber(stair.currentFloorDepth) or 1
            local pl = tonumber(snapshot.partyLevel) or 1
            if stair.direction == "down" then
                assert(Run.StairUse() == true, "stair down use should succeed")
            elseif stair.direction == "up" and pl < depth * 2 then
                assert(Run.StairUse() == true, "stair up use should succeed")
            else
                assert(Run.StairLeave() == true, "stair leave should succeed")
            end
        else
            error("unsupported phase in act1 regression: " .. tostring(snapshot.phase))
        end
    end

    snapshot = Run.GetSnapshot()
    assert(snapshot.phase ~= "failed", "run should not fail during act1 regression (seed=" .. tostring(seed) .. ")")
    assert(routeState.firstBattleResolved, "act1 flow should include at least one battle (seed=" .. tostring(seed) .. ")")
    assert(routeState.campSeen or routeState.shopSeen or routeState.eventSeen,
        "act1 flow should include at least one room interaction (seed=" .. tostring(seed) .. ")")
    if snapshot.phase == "chapter_result" then
        local chapterResult = snapshot.chapterResult or {}
        assert(chapterResult.reason == "boss_defeated", "final reason should be boss_defeated (seed=" .. tostring(seed) .. ")")
        assert(snapshot.chapterId == 103, "should clear all 3 chapters and end on chapterId=103 (seed=" .. tostring(seed) .. ")")
    end
    assertOwnedUnitViews(snapshot)
end

for _, seed in ipairs(SEEDS) do
    runOnce(seed)
end

print("roguelike act1 flow test passed")
