-- FeatPicker 纯单元测试
-- 设计文档：design/character_progression_design.md §3.1 / §9
-- 验证：
--   1) 保底机制：存活英雄 ≤ 3 时每人 1 张候选；> 3 时上限扩展到英雄数。
--   2) choiceGroup 同组互斥：同 session 内同 choiceGroup 只入池 1 张。
--   3) 加权抽：isSubclassCore + tier="medium" 权重为 1.5，其余 1.0（分布合理）。
--   4) 跳级：英雄当前等级缺口对应 level 没有 feat 时，FeatPicker 会向上找最近一个有 feat 的级别（不超过 partyLevel）。
--   5) 没有可选项时（已选完同 level 全部 feats）应返回 nil 不阻塞。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local FeatPicker = require("roguelike.feat_picker")
local FeatBuildConfig = require("config.tables.feats")
local HeroData = require("config.hero_data")
local LevelCurve = require("config.roguelike.level_curve")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

-- SSOT：使用 LevelCurve.LEVEL_EXP_THRESHOLDS；保留本地引用是为了向后兼容旧 BeginSession 入参。
local LEVEL_EXP_THRESHOLDS = LevelCurve.LEVEL_EXP_THRESHOLDS

local function makeUnit(classId, level, rosterId)
    local unit = HeroData.CreateClassUnit(classId, {
        rosterId = rosterId,
        unitId = string.format("test_unit_%d_%d", classId, rosterId),
        promotionStage = "low",
        level = level,
        teamState = "active",
        source = "feat_picker_test",
    })
    -- 重置 feats，避免 BuildClassUnit 默认带的 canonical feats 干扰候选差集
    unit.feats = {}
    if unit.buildState then
        unit.buildState.featIds = {}
    end
    return unit
end

local function makeMockState(units, partyExp)
    local state = {
        ownedUnits = units,
        teamRoster = units,
        benchRoster = {},
        partyLevel = 1,
        partyExp = partyExp,
        levelCap = 10,
    }
    return state
end

-- ========== 用例 1：≤ 3 人时，session.options 至少覆盖每个英雄 ==========
do
    math.randomseed(7777)
    local rogue = makeUnit(1, 1, 11)
    local fighter = makeUnit(2, 1, 12)
    local cleric = makeUnit(3, 1, 13)
    local state = makeMockState({ rogue, fighter, cleric }, 8)
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "session should be created")
    assert_true(#session.options <= 3, "options should be capped at 3 when 3 alive heroes")
    -- 保底：3 个 rosterId 都至少出现 1 次
    local seenRosters = {}
    for _, opt in ipairs(session.options) do
        seenRosters[opt.rosterId] = true
    end
    local seenCount = 0
    for _ in pairs(seenRosters) do seenCount = seenCount + 1 end
    assert_true(seenCount == 3,
        "with 3 alive heroes each should appear at least once in options, got " .. seenCount)
end

-- ========== 用例 2：> 3 人时，optionCap 扩展到英雄数（保底每人 1 张）==========
do
    math.randomseed(8888)
    local units = {
        makeUnit(1, 1, 21),  -- rogue
        makeUnit(2, 1, 22),  -- fighter
        makeUnit(3, 1, 23),  -- cleric
        makeUnit(4, 1, 24),  -- wizard / etc
    }
    -- 跳过：检查目标职业是否真的有 Lv2 feat
    local validUnits = {}
    for _, unit in ipairs(units) do
        local feats = FeatBuildConfig.GetFeatsByLevel(unit.classId, 2) or {}
        if #feats > 0 then
            validUnits[#validUnits + 1] = unit
        end
    end
    if #validUnits >= 4 then
        local state = makeMockState(validUnits, 8)
        local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
        assert_true(session ~= nil, "session should be created with 4 alive heroes")
        assert_true(#session.options >= 4,
            "options cap should expand to alive count, got " .. #session.options)
        local seenRosters = {}
        for _, opt in ipairs(session.options) do
            seenRosters[opt.rosterId] = true
        end
        local seenCount = 0
        for _ in pairs(seenRosters) do seenCount = seenCount + 1 end
        assert_true(seenCount == #validUnits,
            "every alive hero should be represented")
    end
end

-- ========== 用例 3：choiceGroup 同组互斥 ==========
-- rogue Lv2 三个 feat 都在 "rogue_lv2_basic" 组；session 应只入池 1 张 rogue Lv2 feat
do
    math.randomseed(9999)
    local rogue = makeUnit(1, 1, 31)
    local state = makeMockState({ rogue }, 8)
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "session should be created")
    local rogueLv2Feats = FeatBuildConfig.GetFeatsByLevel(1, 2) or {}
    -- 收集本 session 中 rogue_lv2_basic 组出现次数
    local groupCount = 0
    for _, opt in ipairs(session.options) do
        if opt.choiceGroup == "rogue_lv2_basic" then
            groupCount = groupCount + 1
        end
    end
    -- 单英雄场景下保底 1 张；choiceGroup 互斥保证不出现第 2 张同组
    assert_true(groupCount <= 1,
        "same choiceGroup should appear at most once per session, got " .. groupCount)
    assert_true(#rogueLv2Feats >= 2,
        "fixture sanity: rogue Lv2 should have >= 2 feats")
end

-- ========== 用例 4：跳级（当前 level 缺 feat 时向上找）==========
-- 以 fighter 为例：若 Lv2 没有 feat 但 Lv3 有，partyLevel=3 时应跳到 Lv3。
-- 此处不假设具体 classId，只验证若英雄 Lv1 + partyLevel=3 → option.level >= 2
do
    math.randomseed(11111)
    local fighter = makeUnit(2, 1, 41)
    local state = makeMockState({ fighter }, 25)  -- 跨过 Lv2(8), Lv3(20)
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "session should be created at partyLevel 3")
    assert_true(state.partyLevel == 3, "partyLevel should compute to 3")
    -- option.level 必须 >= 2 且 <= partyLevel
    for _, opt in ipairs(session.options) do
        assert_true(opt.level >= 2 and opt.level <= 3,
            "option.level should be in (current, partyLevel] range, got " .. tostring(opt.level))
    end
end

-- ========== 用例 5：partyExp 未跨阈值时返回 nil ==========
do
    math.randomseed(22222)
    local rogue = makeUnit(1, 1, 51)
    local state = makeMockState({ rogue }, 0)  -- 未跨 Lv2 阈值
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session == nil, "session should be nil when no level-up is owed")
end

-- ========== 用例 6：subclass core 加权（采样验证概率上偏）==========
-- 选 rogue Lv3：3 个候选都是 rogue_lv3_subclass 组的 isSubclassCore = true
-- 同组互斥意味着只能出 1 张，无法直接验证权重；改为针对 rogue Lv4（mastery，medium 但都不是 subclassCore）
-- 这里只做基础检查：option.tier 是否被正确传递。
do
    math.randomseed(33333)
    local rogue = makeUnit(1, 4, 61)  -- 升到 Lv5 触发 capstone（高阶 + isSubclassCore）
    local state = makeMockState({ rogue }, 58)  -- partyLevel = 5
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv4→Lv5 session should be created")
    local hasSubclassCore = false
    for _, opt in ipairs(session.options) do
        if opt.tier == "high" then
            assert_true(opt.isSubclassCore == true,
                "Lv5 capstone should be flagged isSubclassCore=true")
            hasSubclassCore = true
        end
    end
    assert_true(hasSubclassCore,
        "Lv5 candidate pool should contain at least one subclass core option")
end

-- ========== 用例 7：加权抽样频率断言（×1.5 权重）==========
-- 构造 medium tier 池：1 张 isSubclassCore=true + 4 张 isSubclassCore=false
-- 期望 isSubclassCore=true 频率 = 1.5 / (1.5 + 4) = 1.5/5.5 ≈ 0.273
-- 不加权基线 = 1/5 = 0.20。断言实际 > 0.24（明显高于不加权基线）。
do
    math.randomseed(1357924680)
    local subclassItem = { feat = { tier = "medium", isSubclassCore = true, name = "subclass_core" } }
    local plainItems = {}
    for i = 1, 4 do
        plainItems[i] = { feat = { tier = "medium", isSubclassCore = false, name = "plain_" .. i } }
    end
    local pool = { subclassItem, plainItems[1], plainItems[2], plainItems[3], plainItems[4] }

    local N = 2000
    local hits = 0
    for _ = 1, N do
        local picked = FeatPicker._weightedPickForTest(pool)
        if picked == subclassItem then
            hits = hits + 1
        end
    end
    local freq = hits / N
    -- 期望理论频率 ≈ 0.273；考虑随机波动，断言 > 0.24（高于不加权 0.20 的中点附近）
    assert_true(freq > 0.24,
        string.format("subclass core weighted freq should exceed 0.24, got %.4f (N=%d, hits=%d)",
            freq, N, hits))
    -- 上限保底：避免 weight 实现错把 ×N 放大
    assert_true(freq < 0.40,
        string.format("subclass core weighted freq sanity upper bound 0.40, got %.4f", freq))
end

print("feat picker test passed")
