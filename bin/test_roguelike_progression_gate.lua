local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RoguelikeReward = require("roguelike.roguelike_reward")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local HeroData = require("config.hero_data")
local BattleFormation = require("modules.battle_formation")

local function assert_true(condition, message)
    if not condition then
        error(message or "assert_true failed")
    end
end

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
    local desc = (ult.skillConfig and ult.skillConfig.Description) or ""
    if desc:find("治疗") or desc:find("复活") then
        return false
    end
    return desc:find("伤害骰") ~= nil or desc:find("%dd%d+") ~= nil or desc:find("d%d+") ~= nil
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
    local castedUltimate = false
    for _ = 1, maxSteps do
        local readyHeroId = (not castedUltimate) and findReadyHero(snapshot) or nil
        if readyHeroId and snapshot.battleSnapshot and snapshot.battleSnapshot.pendingCommands == 0 then
            Run.QueueBattleCommand({
                type = "cast_ultimate",
                heroId = readyHeroId,
            })
            castedUltimate = true
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
    assert_true(ok, "choose path failed: " .. tostring(reason))
    ok, reason = Run.EnterCurrentNode()
    assert_true(ok, "enter node failed: " .. tostring(reason))
end

local function chooseFirstReward()
    local snapshot = Run.GetSnapshot()
    assert_true(snapshot.phase == "reward", "expected reward phase")
    assert_true(Run.ChooseReward(1) == true, "reward selection should succeed")
    return Run.GetSnapshot()
end

local function findClassCardOption(rewardState, classId)
    for _, option in ipairs((rewardState and rewardState.options) or {}) do
        if tonumber(option.classId) == tonumber(classId) then
            return option
        end
    end
    return nil
end

do
    local runState = {
        ownedUnits = {},
        teamRoster = {},
        benchRoster = {},
        equipmentIds = {},
        blessingIds = {},
        maxHeroCount = 5,
        nextRosterId = 2,
    }
    local fighter = HeroData.CreateClassUnit(2, {
        rosterId = 1,
        unitId = "test_fighter",
        promotionStage = "low",
        level = 2,
        exp = 8,
        teamState = "active",
        source = "test",
    })
    RoguelikeRoster.AddOwnedUnit(runState, fighter, "active")

    local rewardState = RoguelikeReward.GenerateLevelUpRewardState(runState)
    local lowToMidOption = findClassCardOption(rewardState, 2)
    assert_true(lowToMidOption ~= nil, "low-stage fighter should appear in class card reward")
    assert_true(lowToMidOption.resultType == "promotion_pending", "level 2 duplicate class card should become pending promotion")
    assert_true(lowToMidOption.requiredLevel == 3, "low to mid promotion should require level 3")
    assert_true(RoguelikeReward.ApplyLevelUpReward(runState, lowToMidOption) == true, "pending promotion reward should apply")
    assert_true(fighter.promotionStage == "low", "pending promotion should not change stage immediately")
    assert_true(fighter.promotionPendingTarget == "mid", "pending promotion should store target stage")

    local hiddenState = RoguelikeReward.GenerateLevelUpRewardState(runState)
    assert_true(findClassCardOption(hiddenState, 2) == nil, "pending class should leave class-card pool until level gate is met")

    HeroData.RefreshClassUnit(fighter, {
        level = 3,
        exp = 20,
        teamState = "active",
        currentHp = fighter.currentHp,
        promotionPendingTarget = fighter.promotionPendingTarget,
        source = "test_level",
    })
    assert_true(RoguelikeReward.ResolvePendingPromotion(runState, fighter, "test_level") == true,
        "reaching level 3 should auto-resolve pending low to mid promotion")
    assert_true(fighter.promotionStage == "mid", "fighter should promote to mid at level 3")
    assert_true(fighter.promotionPendingTarget == nil, "resolved promotion should clear pending target")

    HeroData.RefreshClassUnit(fighter, {
        level = 5,
        exp = 58,
        teamState = "active",
        currentHp = fighter.currentHp,
        source = "test_level",
    })
    local midState = RoguelikeReward.GenerateLevelUpRewardState(runState)
    local midToHighOption = findClassCardOption(midState, 2)
    assert_true(midToHighOption ~= nil, "mid-stage fighter should remain in class card reward")
    assert_true(midToHighOption.resultType == "promotion_pending", "level 5 duplicate class card should still pend high promotion")
    assert_true(midToHighOption.requiredLevel == 6, "mid to high promotion should require level 6")
    assert_true(RoguelikeReward.ApplyLevelUpReward(runState, midToHighOption) == true, "mid to high pending reward should apply")
    assert_true(fighter.promotionStage == "mid", "pending high promotion should not change stage immediately")
    assert_true(fighter.promotionPendingTarget == "high", "pending high promotion should store target stage")

    HeroData.RefreshClassUnit(fighter, {
        level = 6,
        exp = 86,
        teamState = "active",
        currentHp = fighter.currentHp,
        promotionPendingTarget = fighter.promotionPendingTarget,
        source = "test_level",
    })
    assert_true(RoguelikeReward.ResolvePendingPromotion(runState, fighter, "test_level") == true,
        "reaching level 6 should auto-resolve pending mid to high promotion")
    assert_true(fighter.promotionStage == "high", "fighter should promote to high at level 6")
    assert_true(fighter.promotionPendingTarget == nil, "high promotion should clear pending target")
end

do
    math.randomseed(10102)
    local snapshot = Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = 10102,
    })
    local startingGold = snapshot.gold or 0

    choosePathAndEnter(101001)
    snapshot = runBattleUntilResolved(600)
    assert_true(snapshot.phase == "map", "normal battle should return to map instead of opening class-card reward")
    assert_true((snapshot.gold or 0) > startingGold, "normal battle should still grant gold")

    choosePathAndEnter(101002)
    snapshot = chooseFirstReward()
    assert_true(snapshot.phase == "map", "recruit node should return to map after choosing a class card")

    local rewardState = RoguelikeReward.GenerateLevelUpRewardState({
        ownedUnits = snapshot.ownedUnits,
        teamRoster = snapshot.team,
        benchRoster = snapshot.bench,
        maxHeroCount = snapshot.maxHeroCount,
    })
    assert_true(rewardState ~= nil and rewardState.kind == "battle_levelup", "class-card reward state should still be available after recruit expansion")
    for _, option in ipairs(rewardState.options or {}) do
        assert_true(option.rewardType == "levelup", "class-card reward options should stay in levelup payload format")
    end
end

print("roguelike progression gate test passed")
