-- 队伍 EXP 升级三选一闭环测试
-- 设计文档：design/character_progression_design.md §3 / §8
-- 验证：
--   1) 战斗 EXP 全部进入 state.partyExp（不再写 unit.exp）。
--   2) partyExp 跨越阈值后 phase = "reward" 且 rewardState.kind = "feat_levelup"。
--   3) ChooseReward 后选中英雄 +1 级，并把 featId 写入 unit.feats。
--   4) 单次战斗触发多次升级时，session 链式进入下一轮（pendingLevels > 0）。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local FeatPicker = require("roguelike.feat_picker")
local BattleFormation = require("modules.battle_formation")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local function findSelectableNodeByType(snapshot, nodeType)
    for _, node in ipairs((snapshot and snapshot.map and snapshot.map.nodes) or {}) do
        if node.selectable and node.nodeType == nodeType then
            return node.id
        end
    end
    return nil
end

local function getUltimateSkillForUnit(unitId)
    local hero = BattleFormation.FindHeroByInstanceId
        and BattleFormation.FindHeroByInstanceId(tonumber(unitId)) or nil
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

local function isOutputUltimate(unit)
    if not unit or not unit.id or unit.ultimateReady ~= true then
        return false
    end
    local ult = getUltimateSkillForUnit(unit.id)
    if not ult then
        return false
    end
    local desc = (ult.skillConfig and ult.skillConfig.description) or ""
    if desc:find("治疗") or desc:find("复活") then
        return false
    end
    return true
end

local function findReadyHero(snapshot)
    local battleSnapshot = snapshot and snapshot.battleSnapshot or nil
    if not battleSnapshot then
        return nil
    end
    for _, unit in ipairs(battleSnapshot.leftTeam or {}) do
        if isOutputUltimate(unit) then
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
            Run.QueueBattleCommand({ type = "cast_ultimate", heroId = readyHeroId })
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

local function findHeroByRosterId(team, rosterId)
    for _, unit in ipairs(team or {}) do
        if tonumber(unit.rosterId) == tonumber(rosterId) then
            return unit
        end
    end
    return nil
end

local function countFeats(unit)
    if type(unit) ~= "table" then
        return 0
    end
    return #(unit.buildSummary or unit.feats or {})
end

local function unitContainsFeat(unit, featName)
    -- snapshot.team 的 unit 仅暴露 buildSummary（feat 名字数组），不暴露 feats id 列表
    for _, summary in ipairs((unit and unit.buildSummary) or {}) do
        if summary == featName then
            return true
        end
    end
    return false
end

-- ========== 用例 1：战斗胜利 → partyExp 增长 → feat_levelup 弹出 ==========
do
    math.randomseed(20260520)
    local snapshot = Run.StartRun({
        chapterId = 101,
        starterHeroIds = { 900005, 900001, 900007, 900002 },
        seed = 20260520,
    })
    assert_true(snapshot.partyLevel == 1, "starter party level should be 1")
    assert_true((snapshot.partyExp or 0) == 0, "starter partyExp should be 0")

    -- 个人 unit.exp 应当不再被写入（彻底废弃），全部经验只进 partyExp
    for _, unit in ipairs(snapshot.team or {}) do
        assert_true(unit.exp == nil or unit.exp == 0,
            "starter unit.exp should be nil or 0, got " .. tostring(unit.exp))
    end

    -- 进入第一个普通战
    local battleNodeId = findSelectableNodeByType(snapshot, "battle_normal")
        or findSelectableNodeByType(snapshot, "battle_elite")
    assert_true(battleNodeId ~= nil, "opening map should expose at least one battle node")
    choosePathAndEnter(battleNodeId)
    snapshot = runBattleUntilResolved(600)

    -- 战斗后必然产生 partyExp 增长，且达到 Lv2 阈值（Lv2=6 EXP，普通战奖励高于此值）
    assert_true((snapshot.partyExp or 0) > 0, "battle should grant partyExp")
    assert_true(snapshot.phase == "reward",
        "battle level-up should open feat_levelup reward, got phase " .. tostring(snapshot.phase))
    assert_true(snapshot.rewardState ~= nil and snapshot.rewardState.kind == "feat_levelup",
        "reward kind should be feat_levelup, got " .. tostring(snapshot.rewardState and snapshot.rewardState.kind))
    assert_true(#(snapshot.rewardState.options or {}) > 0, "feat_levelup should provide >0 options")

    -- 校验 option payload 字段完备
    local firstOption = snapshot.rewardState.options[1]
    assert_true(firstOption.featId and firstOption.featId > 0, "option should carry featId")
    assert_true(firstOption.heroId and firstOption.heroId > 0, "option should carry heroId")
    assert_true(firstOption.rosterId and firstOption.rosterId > 0, "option should carry rosterId")
    assert_true(firstOption.tier == "small" or firstOption.tier == "medium" or firstOption.tier == "high",
        "option.tier should be one of small/medium/high")
    assert_true(type(firstOption.heroName) == "string" and #firstOption.heroName > 0, "option.heroName should be set")
    assert_true(firstOption.level >= 2,
        "first level-up should target Lv>=2 (Lv2 跳级时可能直接到 Lv3), got " .. tostring(firstOption.level))

    -- 选中第一项：对应英雄 +1 级，feat 写入
    local targetRosterId = firstOption.rosterId
    local beforeUnit = findHeroByRosterId(snapshot.team, targetRosterId)
    assert_true(beforeUnit ~= nil, "target rosterId should exist in team")
    local beforeLevel = tonumber(beforeUnit.level) or 1
    local beforeFeatCount = countFeats(beforeUnit)

    assert_true(Run.ChooseReward(1) == true, "ChooseReward should accept feat_levelup index 1")
    snapshot = Run.GetSnapshot()
    local afterUnit = findHeroByRosterId(snapshot.team, targetRosterId)
    assert_true(afterUnit ~= nil, "target rosterId should still exist after pick")
    local afterLevel = tonumber(afterUnit.level) or 1
    assert_true(afterLevel == beforeLevel + 1,
        string.format("hero level should +1: before=%d after=%d", beforeLevel, afterLevel))
    assert_true(unitContainsFeat(afterUnit, firstOption.featName),
        "selected feat (" .. tostring(firstOption.featName) .. ") should appear in unit.buildSummary")
    assert_true(countFeats(afterUnit) >= beforeFeatCount + 1,
        "unit.buildSummary length should grow after pick")
end

-- ========== 用例 2：人为塞高 partyExp 跨多级，链式 session ==========
do
    math.randomseed(99887)
    -- 直接调用 BeginSession 验证 pendingLevels
    -- 通过模拟的 state（隔离的本地 state）测试 FeatPicker 的纯逻辑
    local LevelCurve = require("config.roguelike.level_curve")
    -- 直接复用 SSOT 阈值表，避免本地散写。
    local LEVEL_EXP_THRESHOLDS = LevelCurve.LEVEL_EXP_THRESHOLDS
    local HeroData = require("config.hero_data")
    local heroA = HeroData.CreateClassUnit(1, {
        rosterId = 101, unitId = "test_a", promotionStage = "low",
        level = 1, teamState = "active", source = "test",
    })
    local heroB = HeroData.CreateClassUnit(2, {
        rosterId = 102, unitId = "test_b", promotionStage = "low",
        level = 1, teamState = "active", source = "test",
    })
    -- 清空 default canonical feats，确保 Lv2/Lv3 升级有候选可选
    heroA.feats = {}
    heroB.feats = {}
    if heroA.buildState then heroA.buildState.featIds = {} end
    if heroB.buildState then heroB.buildState.featIds = {} end

    local mockState = {
        ownedUnits = { heroA, heroB },
        teamRoster = { heroA, heroB },
        benchRoster = {},
        partyLevel = 1,
        partyExp = 25,  -- 跨过 Lv2(10) 与 Lv3(20)，到达 partyLevel 3
        levelCap = 32,
    }
    local session = FeatPicker.BeginSession(mockState, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "session should be created when partyExp crosses thresholds")
    assert_true(session.kind == "feat_levelup", "session kind should be feat_levelup")
    -- 设计 §3：队伍每升 1 级 = 1 次三选一 = 升 1 个英雄；与队员人数无关。
    -- 队伍 partyLevel 1 → 3 = 2 次会话。
    assert_true(session.pendingLevels == 2,
        "pendingLevels should be 2 (party Lv1→Lv3), got " .. tostring(session.pendingLevels))
    assert_true(#session.options > 0, "session should expose options")

    -- 选第一项后 pendingLevels -= 1，且自动开启下一轮 session
    local ok, result = FeatPicker.Pick(mockState, 1)
    assert_true(ok, "Pick should succeed")
    assert_true(result.sessionExhausted == false, "session should not be exhausted yet")
    assert_true(result.nextSession ~= nil, "next session should auto-launch when pendingLevels > 0")
    assert_true(result.nextSession.pendingLevels == 1,
        "next session.pendingLevels should be 1 after consuming 1")
end

print("party EXP level-up test passed")
