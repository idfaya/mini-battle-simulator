--- 回归用 Run 自动推进（与 test_roguelike_act1 同策略）。
local BattleFormation = require("modules.battle_formation")
local ClassRoleConfig = require("config.tables.classes")

local RoguelikeRunDriver = {}

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

function RoguelikeRunDriver.chooseRewardIndex(snapshot)
    local reward = snapshot and snapshot.rewardState
    if not reward or not reward.options then
        return 1
    end
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
    local priority = { equipment = 1, blessing = 2, gold = 3 }
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

local function autoPromoteBench(Run)
    local snapshot = Run.GetSnapshot()
    while #(snapshot.bench or {}) > 0 and #(snapshot.team or {}) < (snapshot.maxHeroCount or 5) do
        local benchHero = snapshot.bench[1]
        if not benchHero or not benchHero.rosterId then
            break
        end
        if Run.PromoteBenchHero(benchHero.rosterId) ~= true then
            break
        end
        snapshot = Run.GetSnapshot()
    end
    return snapshot
end

function RoguelikeRunDriver.acceptRewardIfPresent(Run)
    local current = Run.GetSnapshot()
    local guard = 0
    while current.phase == "reward" and guard < 32 do
        local reward = current.rewardState
        if not reward or #(reward.options or {}) == 0 then
            break
        end
        local rewardIndex = RoguelikeRunDriver.chooseRewardIndex(current)
        if Run.ChooseReward(rewardIndex) ~= true then
            break
        end
        current = autoPromoteBench(Run)
        guard = guard + 1
    end
    return current
end

function RoguelikeRunDriver.runBattleUntilResolved(Run, maxSteps, tickMs)
    tickMs = tickMs or 800
    local snapshot = Run.GetSnapshot()
    for _ = 1, maxSteps or 900 do
        local heroId = findReadyHero(snapshot)
        if heroId then
            Run.QueueBattleCommand({ type = "cast_ultimate", heroId = heroId })
        end
        Run.Tick(tickMs)
        snapshot = Run.GetSnapshot()
        if snapshot.phase ~= "battle" then
            return snapshot
        end
    end
    return snapshot
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

---@param Run table
---@param RoguelikeTestRoute table
---@param config table|nil { seed, chapterId, starterHeroIds, maxGuard, tickMs, maxBattleTicks }
---@return table
function RoguelikeRunDriver.simulate(Run, RoguelikeTestRoute, config)
    config = config or {}
    local seed = tonumber(config.seed) or 1
    math.randomseed(seed)

    Run.StartRun({
        chapterId = tonumber(config.chapterId) or 101,
        starterHeroIds = config.starterHeroIds or { 900005, 900001, 900007, 900002 },
        seed = seed,
    })

    local routeState = {
        campSeen = false,
        shopSeen = false,
        eventSeen = false,
        firstBattleResolved = false,
        lastNodeId = nil,
        recentNodeIds = {},
        progressionMode = config.progressionMode,
    }
    local report = {
        seed = seed,
        phase = "map",
        chapterId = 101,
        failed = false,
        ch101BossReached = false,
        ch101BossCleared = false,
        chapterResult = false,
        guardSteps = 0,
        lastNodeType = nil,
    }

    local maxGuard = math.floor(tonumber(config.maxGuard) or 800)
    for guard = 1, maxGuard do
        report.guardSteps = guard
        local snapshot = Run.GetSnapshot()
        report.phase = snapshot.phase
        report.chapterId = tonumber(snapshot.chapterId) or 101

        if snapshot.phase == "failed" then
            report.failed = true
            break
        end
        if snapshot.phase == "chapter_result" then
            report.chapterResult = true
            report.ch101BossReached = true
            report.ch101BossCleared = true
            break
        end
        if (tonumber(snapshot.chapterId) or 101) > 101 then
            report.ch101BossReached = true
            report.ch101BossCleared = true
        end

        if snapshot.phase == "map" then
            local nextNode = RoguelikeTestRoute.chooseNextNode(snapshot, routeState)
            if not nextNode then
                break
            end
            report.lastNodeType = nextNode.nodeType
            Run.ChoosePath(nextNode.id)
            Run.EnterCurrentNode()
            routeState.recentNodeIds[2] = routeState.recentNodeIds[1]
            routeState.recentNodeIds[1] = routeState.lastNodeId
            routeState.lastNodeId = nextNode.id
            if nextNode.nodeType == "camp" then
                routeState.campSeen = true
            elseif nextNode.nodeType == "shop" then
                routeState.shopSeen = true
            elseif nextNode.nodeType == "event" then
                routeState.eventSeen = true
            elseif nextNode.nodeType == "boss" and (tonumber(snapshot.chapterId) or 101) == 101 then
                report.ch101BossReached = true
            end
        elseif snapshot.phase == "battle" then
            routeState.firstBattleResolved = true
            if config.autoWinBattles == true then
                if Run.TestForceCurrentBattleVictory() ~= true then
                    snapshot = Run.GetSnapshot()
                    if snapshot.phase == "failed" then
                        report.failed = true
                        break
                    end
                end
                snapshot = Run.GetSnapshot()
                if snapshot.phase == "reward" then
                    snapshot = RoguelikeRunDriver.acceptRewardIfPresent(Run)
                end
            else
                snapshot = RoguelikeRunDriver.runBattleUntilResolved(Run, config.maxBattleTicks, config.tickMs)
            end
            if snapshot.phase == "failed" then
                report.failed = true
                break
            end
            if snapshot.phase == "reward" then
                snapshot = RoguelikeRunDriver.acceptRewardIfPresent(Run)
            end
        elseif snapshot.phase == "reward" then
            snapshot = RoguelikeRunDriver.acceptRewardIfPresent(Run)
        elseif snapshot.phase == "camp" then
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
                Run.CampLeave()
            end
        elseif snapshot.phase == "shop" then
            Run.ShopLeave()
        elseif snapshot.phase == "event" then
            RoguelikeTestRoute.resolveEvent(Run, snapshot)
        elseif snapshot.phase == "stair" then
            local stair = snapshot.stairState or {}
            local depth = tonumber(stair.currentFloorDepth) or 1
            local pl = tonumber(snapshot.partyLevel) or 1
            if stair.direction == "down" then
                Run.StairUse()
            elseif stair.direction == "up" and pl < depth * 2 then
                Run.StairUse()
            else
                Run.StairLeave()
            end
        end
    end

    local final = Run.GetSnapshot()
    report.phase = final.phase
    report.chapterId = tonumber(final.chapterId) or report.chapterId
    if (report.chapterId or 101) > 101 then
        report.ch101BossReached = true
        report.ch101BossCleared = true
    end
    return report
end

return RoguelikeRunDriver
