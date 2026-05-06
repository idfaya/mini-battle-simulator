local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local BattleFormation = require("modules.battle_formation")
local RunEncounterGroup = require("config.roguelike.run_encounter_group")
local ClassRoleConfig = require("config.class_role_config")

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

local function runBattleUntilResolved(maxSteps)
    local snapshot = Run.GetSnapshot()
    local castedUltimate = false
    for _ = 1, maxSteps do
        if not castedUltimate and snapshot.battleSnapshot and snapshot.battleSnapshot.pendingCommands == 0 then
            for _, unit in ipairs(snapshot.battleSnapshot.leftTeam or {}) do
                if isEnemyOrOutputUltimate(unit) then
                    Run.QueueBattleCommand({
                        type = "cast_ultimate",
                        heroId = unit.id,
                    })
                    castedUltimate = true
                    break
                end
            end
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

local function assertEncounterScalesStay5eStyle()
    for encounterId, encounter in pairs(RunEncounterGroup.ENCOUNTERS or {}) do
        local scale = encounter.enemyScale or {}
        for _, key in ipairs({ "hp", "atk", "def" }) do
            local value = tonumber(scale[key]) or 1
            assert(value >= 0.90 and value <= 1.10, string.format("encounter %s enemyScale.%s should stay within 5e-style bounds", tostring(encounterId), key))
        end
        local hitDelta = math.abs(tonumber(scale.hitDelta) or 0)
        local spellDCDelta = math.abs(tonumber(scale.spellDCDelta) or 0)
        assert(hitDelta <= 1, string.format("encounter %s hitDelta should be a light modifier", tostring(encounterId)))
        assert(spellDCDelta <= 1, string.format("encounter %s spellDCDelta should be a light modifier", tostring(encounterId)))
    end
end

local function acceptRewardIfPresent()
    local current = Run.GetSnapshot()
    local guard = 0
    while current.phase == "reward" and guard < 4 do
        local rewardIndex = chooseRewardIndex(current)
        assert(Run.ChooseReward(rewardIndex) == true, "reward selection should succeed")
        current = Run.GetSnapshot()
        guard = guard + 1
    end
    assert(current.phase == "map", "reward chain should return to map")
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
            existing[hero.name] = true
        end
        for _, hero in ipairs(snapshot.bench or {}) do
            existing[hero.name] = true
        end
        for index, option in ipairs(reward.options) do
            local heroName = option.heroName or string.gsub(option.label or "", "^招募%s+", "")
            if heroName and not existing[heroName] then
                return index
            end
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

assertEncounterScalesStay5eStyle()

local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = 10102,
})

assert(snapshot.phase == "map", "run should start on map")
assert(#(snapshot.debug.availableNextNodeIds or {}) == 1, "start map should expose one node")
assert(#(snapshot.team or {}) == 4, "run should start with 4 heroes")
local frontCount, backCount = countRows(snapshot.team)
assert(frontCount == 2 and backCount == 2, "starter team should be 2 front and 2 back")

choosePathAndEnter(101001)
assert(Run.GetSnapshot().phase == "battle", "first node should be battle")
snapshot = runBattleUntilResolved(600)
assert(snapshot.phase == "reward", "first battle should open reward")
snapshot = acceptRewardIfPresent()

choosePathAndEnter(101002)
assert(Run.GetSnapshot().phase == "reward", "second path should open recruit reward")
assert(Run.ChooseReward(chooseRewardIndex(Run.GetSnapshot())) == true, "recruit selection should resolve")
assert(Run.GetSnapshot().phase == "map", "recruit node should return to map")

choosePathAndEnter(101004)
assert(Run.GetSnapshot().phase == "battle", "third path should be battle")
snapshot = runBattleUntilResolved(700)
assert(snapshot.phase == "reward" or snapshot.phase == "map", "third battle should resolve")
snapshot = acceptRewardIfPresent()

choosePathAndEnter(101006)
assert(Run.GetSnapshot().phase == "camp", "camp node should open camp")
assert(Run.CampChoose(2) == true, "camp empower should work")

choosePathAndEnter(101008)
assert(Run.GetSnapshot().phase == "battle", "ember ambush should be battle")
snapshot = runBattleUntilResolved(700)
assert(snapshot.phase == "reward" or snapshot.phase == "map", "ember ambush should resolve")
snapshot = acceptRewardIfPresent()

choosePathAndEnter(101010)
assert(Run.GetSnapshot().phase == "reward", "last stop should open second recruit reward")
assert(Run.ChooseReward(chooseRewardIndex(Run.GetSnapshot())) == true, "second recruit selection should resolve")
local recruitSnapshot = Run.GetSnapshot()
assert(recruitSnapshot.phase == "map", "second recruit should return to map")
assert((#(recruitSnapshot.team or {}) + #(recruitSnapshot.bench or {})) >= 4, "second recruit should keep boss roster viable")

choosePathAndEnter(101011)
assert(Run.GetSnapshot().phase == "battle", "boss node should be battle")
snapshot = runBattleUntilResolved(900)
assert(snapshot.phase == "reward" or snapshot.phase == "chapter_result", "boss should resolve to reward or chapter result")
local bossRewardGuard = 0
while snapshot.phase == "reward" and bossRewardGuard < 4 do
    assert(Run.ChooseReward(1) == true, "boss reward selection should succeed")
    snapshot = Run.GetSnapshot()
    bossRewardGuard = bossRewardGuard + 1
end

assert(snapshot.phase == "chapter_result", "run should end at chapter result")
assert(snapshot.chapterResult and snapshot.chapterResult.success == true, "chapter should clear successfully")
print("roguelike act1 test passed")
