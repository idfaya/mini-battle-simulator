-- D2-T2：事件房 5e 检定 4 档 + 零风险跳骰
local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EventResolver = require("roguelike.event_resolver")
local RoguelikeEvent = require("roguelike.roguelike_event")
local HeroData = require("config.hero_data")
local RoguelikeRoster = require("roguelike.roguelike_roster")

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", msg or "assert_eq", tostring(expected), tostring(actual)))
    end
end

-- 4 档边界（不依赖随机）
assert_eq(EventResolver.ClassifyTier(20, 25, 12), "critSuccess", "nat20 -> critSuccess")
assert_eq(EventResolver.ClassifyTier(1, 6, 12), "critFailure", "nat1 -> critFailure")
assert_eq(EventResolver.ClassifyTier(10, 15, 12), "success", "total>=dc -> success")
assert_eq(EventResolver.ClassifyTier(6, 11, 12), "failure", "total<dc -> failure")

local wizard = HeroData.CreateClassUnit(8, { level = 5, rosterId = 9001 })
local fighter = HeroData.CreateClassUnit(2, { level = 5, rosterId = 9002 })
assert(wizard.int and wizard.int >= 10, "wizard class should have INT for arcana checks")

local modWizard = EventResolver.GetSkillModifier(wizard, "arcana")
local modFighter = EventResolver.GetSkillModifier(fighter, "arcana")
assert(modWizard > modFighter, "wizard should beat fighter on arcana modifier")

local runState = {
    gold = 100,
    eventState = {},
}
wizard.teamState = "active"
fighter.teamState = "active"
runState.ownedUnits = { wizard, fighter }

local skillOption = {
    skillCheck = {
        ability = "arcana",
        dc = 12,
        results = {
            critSuccess = { resultType = "grant_gold", result = { gold = 100 } },
            success = { resultType = "grant_gold", result = { gold = 50 } },
            failure = { resultType = "grant_gold", result = { gold = 5 } },
            critFailure = { resultType = "grant_gold", result = { gold = 0 } },
        },
    },
}

local zeroOption = {
    zeroRisk = true,
    resultType = "grant_gold",
    result = { gold = 77 },
}

local rt, res, outcome = EventResolver.ResolveOptionOutcome(runState, nil, zeroOption)
assert_eq(rt, "grant_gold", "zeroRisk resultType")
assert_eq(res.gold, 77, "zeroRisk gold")
assert(outcome == nil, "zeroRisk should not produce skillCheck outcome")

-- 10000 次分布：modifier 固定为 +5，dc=12
math.randomseed(424242)
local counts = { critSuccess = 0, success = 0, failure = 0, critFailure = 0 }
local fakeHero = { str = 10, dex = 10, con = 10, int = 10, wis = 10, cha = 10, level = 1, rosterId = 1, name = "Tester" }
local fixedCheck = {
    ability = "investigation",
    dc = 12,
    results = {
        critSuccess = { resultType = "grant_gold", result = { gold = 4 } },
        success = { resultType = "grant_gold", result = { gold = 3 } },
        failure = { resultType = "grant_gold", result = { gold = 2 } },
        critFailure = { resultType = "grant_gold", result = { gold = 1 } },
    },
}

fakeHero.int = 16
fakeHero.level = 1
assert_eq(EventResolver.GetSkillModifier(fakeHero, "investigation"), 5, "fixed +5 modifier for distribution test")

for _ = 1, 10000 do
    local o = EventResolver.ResolveSkillCheck(fakeHero, fixedCheck)
    counts[o.tier] = (counts[o.tier] or 0) + 1
end

assert(counts.critSuccess >= 400 and counts.critSuccess <= 600, "nat20 ~5%")
assert(counts.critFailure >= 400 and counts.critFailure <= 600, "nat1 ~5%")
assert(counts.success + counts.failure >= 8500, "non-extreme tiers should dominate")

-- 集成：101004 检定选项应写入 lastSkillCheck
runState.gold = 0
runState.eventState = {}
local ok = RoguelikeEvent.ResolveOption(runState, 101004, 2)
assert(ok == true, "101004 skill option should resolve")
assert(runState.eventState.lastSkillCheck and runState.eventState.lastSkillCheck.tier, "lastSkillCheck should persist")
assert(runState.gold > 0 or runState.eventState.lastSkillCheck.tier == "critFailure",
    "non-critFailure tiers grant gold from 101004")

ok = RoguelikeEvent.ResolveOption(runState, 101004, 1)
assert(ok == true, "101004 zeroRisk leave should resolve")
assert(runState.gold >= 15, "zeroRisk leave grants at least 15 gold")

print(string.format(
    "event skill check test passed (10k tiers: crit+=%d success=%d failure=%d crit-=%d)",
    counts.critSuccess,
    counts.success,
    counts.failure,
    counts.critFailure
))
