-- Roguelike 进度门测试（partyExp + FeatPicker，5e 阈值）
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local FeatPicker = require("roguelike.feat_picker")
local FeatBuildConfig = require("config.tables.feats")
local HeroData = require("config.hero_data")
local Exp5e = require("config.roguelike.exp_5e")

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local LEVEL_EXP_THRESHOLDS = {}
for lv = 1, Exp5e.MAX_CHARACTER_LEVEL do
    LEVEL_EXP_THRESHOLDS[lv] = Exp5e.GetCharacterExpThreshold(lv)
end

local function makeUnit(classId, level, rosterId)
    local unit = HeroData.CreateClassUnit(classId, {
        rosterId = rosterId,
        unitId = string.format("gate_unit_%d_%d", classId, rosterId),
        promotionStage = "low",
        level = level,
        teamState = "active",
        source = "progression_gate_test",
    })
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
        levelCap = 20,
    }
end

do
    math.randomseed(12001)
    local fighter = makeUnit(2, 1, 201)
    local state = makeMockState({ fighter }, Exp5e.GetCharacterExpThreshold(2))
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv1 to Lv2 session should be created")
    assert_true(state.partyLevel == 2, "partyLevel should be 2 at 5e Lv2 threshold")
end

do
    math.randomseed(12002)
    local fighter = makeUnit(2, 2, 202)
    local state = makeMockState({ fighter }, Exp5e.GetCharacterExpThreshold(3))
    state.partyLevel = 2
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv2 to Lv3 session should be created")
    assert_true(state.partyLevel == 3, "partyLevel should be 3")
end

do
    math.randomseed(12003)
    local rogue = makeUnit(1, 4, 203)
    local state = makeMockState({ rogue }, Exp5e.GetCharacterExpThreshold(5))
    state.partyLevel = 4
    local session = FeatPicker.BeginSession(state, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv4 to Lv5 session should be created")
    local hasHighTier = false
    for _, opt in ipairs(session.options) do
        if opt.tier == "high" then
            hasHighTier = true
        end
    end
    assert_true(hasHighTier, "Lv4 to Lv5 should contain high tier feat")
end

print("roguelike progression gate test passed")
