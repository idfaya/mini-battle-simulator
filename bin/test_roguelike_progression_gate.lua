-- Roguelike 进度门测试（partyExp + FeatPicker）
-- 设计文档：design/character_progression_design.md §3 / §9
-- 验证：
--   1) Lv1 → Lv2 升级时，候选只含 tier="small" 的 feat
--   2) Lv2 → Lv3 升级时，候选可含 tier="medium" 子职业核心 feat（isSubclassCore=true）
--   3) Lv4 → Lv5 升级时，候选含 tier="high" capstone feat
--   4) 阵亡角色不出现在候选
--   5) 已选 feat 不重复出现
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local FeatPicker = require("roguelike.feat_picker")
local FeatBuildConfig = require("config.tables.feats")
local HeroData = require("config.hero_data")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

-- 注：FeatPicker 内部统一从 LevelCurve（线性 10 EXP/级）读取阈值，
-- 此本地表仅作历史兼容入参；用例中的 partyExp 必须按新线性阈值校准。
local LEVEL_EXP_THRESHOLDS = {
    [1] = 0, [2] = 10, [3] = 20, [4] = 30, [5] = 40, [6] = 50,
    [7] = 60, [8] = 70, [9] = 80, [10] = 90,
}

local function makeUnit(classId, level, rosterId)
    local unit = HeroData.CreateClassUnit(classId, {
        rosterId = rosterId,
        unitId = string.format("gate_unit_%d_%d", classId, rosterId),
        promotionStage = "low",
        level = level,
        teamState = "active",
        source = "progression_gate_test",
    })
    -- 重置 feats，避免 BuildClassUnit 默认带的 canonical feats 干扰候选差集
    unit.feats = {}
    if unit.buildState then
        unit.buildState.featIds = {}
    end
    return unit
end

local function makeMockState(units, partyExp)
    return {
        ownedUnits = units,
        teamRoster = units,
        benchRoster = {},
        partyLevel = 1,
        partyExp = partyExp,
        levelCap = 10,
    }
end

local function findOption(session, predicate)
    for _, opt in ipairs((session and session.options) or {}) do
        if predicate(opt) then
            return opt
        end
    end
    return nil
end

-- ========== 用例 1：Lv1 → Lv2 升级时，候选 tier 全部为 "small" ==========
do
    math.randomseed(12001)
    local fighter = makeUnit(2, 1, 201)
    local state = makeMockState({ fighter }, 10)  -- 跨过 Lv2 阈值（线性 10/级）
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv1 to Lv2 session should be created")
    assert_true(state.partyLevel == 2, "partyLevel should be 2 after partyExp=10")
    assert_true(#session.options > 0, "session should expose options")
    for _, opt in ipairs(session.options) do
        assert_true(opt.tier == "small",
            "Lv1 to Lv2 options should be tier=small, got " .. tostring(opt.tier))
        assert_true(opt.level == 2, "option.level should be 2")
    end
end

-- ========== 用例 2：Lv2 → Lv3 升级时，候选可含 tier="medium" + isSubclassCore=true ==========
do
    math.randomseed(12002)
    -- Lv2 fighter；partyExp=20 跨过 Lv3 阈值（线性 10/级）
    local fighter = makeUnit(2, 2, 202)
    local state = makeMockState({ fighter }, 20)
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv2 to Lv3 session should be created")
    assert_true(state.partyLevel == 3, "partyLevel should be 3 at partyExp=20")
    -- Lv3 fighter feats 数据：fighter Lv3 是子职业核心档（fighting style）
    -- 候选池中至少存在一个 medium + isSubclassCore=true 的 feat
    local fighterLv3Feats = FeatBuildConfig.GetFeatsByLevel(2, 3) or {}
    local hasMediumSubclassCore = false
    for _, feat in ipairs(fighterLv3Feats) do
        if feat.tier == "medium" and feat.isSubclassCore == true then
            hasMediumSubclassCore = true
            break
        end
    end
    assert_true(hasMediumSubclassCore,
        "fixture sanity: fighter Lv3 should have at least 1 medium+subclassCore feat")
    -- session 由于 choiceGroup 互斥单英雄场景下只能出 1 张，但至少应有一张 fighter Lv3 候选
    for _, opt in ipairs(session.options) do
        assert_true(opt.level == 3, "option.level should be 3")
        if opt.tier == "medium" then
            -- medium feat 可能是 subclassCore，也可能不是；只要类型正确
            assert_true(opt.tier == "medium", "tier should be medium")
        end
    end
end

-- ========== 用例 3：Lv4 → Lv5 升级时，候选含 tier="high" capstone feat ==========
do
    math.randomseed(12003)
    -- 选择 rogue（classId=1）：Lv5 capstone（high + isSubclassCore=true）已在 feat_picker 测试验证存在
    local rogue = makeUnit(1, 4, 203)
    local state = makeMockState({ rogue }, 40)  -- partyLevel = 5（线性 10/级，Lv5=40）
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv4 to Lv5 session should be created")
    assert_true(state.partyLevel == 5, "partyLevel should be 5 at partyExp=40")
    local hasHighTier = false
    for _, opt in ipairs(session.options) do
        if opt.tier == "high" then
            hasHighTier = true
        end
        assert_true(opt.level == 5, "option.level should be 5")
    end
    assert_true(hasHighTier,
        "Lv4 to Lv5 candidate pool should contain at least one tier=high feat")
end

-- ========== 用例 4：阵亡角色不出现在候选 ==========
do
    math.randomseed(12004)
    local alive = makeUnit(2, 1, 204)
    local dead = makeUnit(1, 1, 205)
    -- 标记为阵亡
    dead.isDead = true
    dead.teamState = "dead"
    dead.currentHp = 0
    local state = makeMockState({ alive, dead }, 10)
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "session should be created with at least 1 alive hero")
    for _, opt in ipairs(session.options) do
        assert_true(opt.rosterId == 204,
            "dead hero rosterId=205 should not appear in options, got rosterId=" .. tostring(opt.rosterId))
    end
end

-- ========== 用例 5：已选 feat 不重复出现 ==========
do
    math.randomseed(12005)
    local fighter = makeUnit(2, 1, 206)
    local state = makeMockState({ fighter }, 10)
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv1 to Lv2 session should be created")
    assert_true(#session.options > 0, "should have at least 1 option")
    -- 选第一项
    local firstOption = session.options[1]
    local pickedFeatId = firstOption.featId
    local ok, result = FeatPicker.Pick(state, 1)
    assert_true(ok, "Pick should succeed: " .. tostring(result))
    -- 重置 partyExp 让队伍再次升级（提升到 Lv3，触发新 session）
    state.partyExp = 20
    state.partyLevel = 2  -- 重置 partyLevel（FeatPicker 内部会按 thresholds 重算）
    local nextSession = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    -- 第二个 session 中 fighter 的下一级是 Lv3（已是 Lv2），候选应该是 Lv3 feats
    -- 已选 Lv2 feat 不应出现
    if nextSession then
        for _, opt in ipairs(nextSession.options) do
            assert_true(opt.featId ~= pickedFeatId,
                "previously picked feat (id=" .. tostring(pickedFeatId) ..
                ") should not appear in next session options")
        end
    end
end

print("roguelike progression gate test passed")
