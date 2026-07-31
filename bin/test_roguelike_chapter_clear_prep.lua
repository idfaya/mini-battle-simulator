local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local ChapterClearPrep = require("roguelike.chapter_clear_prep")
local RoguelikeReward = require("roguelike.roguelike_reward")

local function assert_eq(actual, expected, message)
    assert(actual == expected, string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
end

local runState = {
    nextRosterId = 5,
    partyLevel = 9,
    maxHeroCount = 4,
    ownedUnits = {
        { rosterId = 1, name = "Fighter", classId = 2, teamState = "active", maxHp = 40, currentHp = 12, isDead = false },
        { rosterId = 2, name = "Cleric", classId = 6, teamState = "active", maxHp = 30, currentHp = 0, isDead = true },
        { rosterId = 3, name = "Wizard", classId = 8, teamState = "active", maxHp = 20, currentHp = 0, isDead = true },
        { rosterId = 4, name = "Bench", classId = 1, teamState = "bench", maxHp = 25, currentHp = 1, isDead = true },
    },
    teamRoster = {
        { rosterId = 1, name = "Fighter", teamState = "active", maxHp = 40, currentHp = 12, isDead = false },
        { rosterId = 2, name = "Cleric", teamState = "active", maxHp = 30, currentHp = 0, isDead = true },
        { rosterId = 3, name = "Wizard", teamState = "active", maxHp = 20, currentHp = 0, isDead = true },
    },
    benchRoster = {
        { rosterId = 4, name = "Bench", teamState = "bench", maxHp = 25, currentHp = 1, isDead = true },
    },
}

local changed = ChapterClearPrep.Apply(runState, {
    healPct = 1.00,
    reviveCount = 1,
    revivePct = 0.50,
    targetTeamSize = 4,
    recruitClassIds = { 2, 6, 8, 4, 5 },
})

assert_eq(changed, true, "chapter clear prep should change state")
assert_eq(runState.teamRoster[1].currentHp, 40, "living hero should heal to full")
assert_eq(runState.teamRoster[2].isDead, false, "one dead team member should revive")
assert_eq(runState.teamRoster[2].currentHp, 15, "revived hero should return at 50% max HP")
assert_eq(runState.teamRoster[3].isDead, true, "only one dead team member should revive")
assert_eq(runState.benchRoster[1].isDead, true, "bench unit should not be affected")
assert_eq(#runState.teamRoster, 3, "chapter clear prep should not auto recruit")
assert_eq(runState.maxHeroCount, 4, "chapter clear prep should raise max team size")

local recruitState = ChapterClearPrep.BuildRecruitRewardState(runState, {
    targetTeamSize = 4,
    recruitClassIds = { 2, 6, 8, 4, 5 },
})
assert_eq(recruitState.kind, "node_recruit", "chapter clear prep should open recruit reward")
assert_eq(recruitState.options[1].classId, 4, "first recruit option should skip owned classes")

local rewardOk, rewardReason = RoguelikeReward.ApplyReward(runState, recruitState, 1)
assert_eq(rewardOk, true, "recruit reward should apply: " .. tostring(rewardReason))
assert_eq(#runState.teamRoster, 4, "recruit reward should fill one team slot")
assert_eq(runState.teamRoster[4].classId, 4, "recruit reward should create selected class")
assert_eq(runState.teamRoster[4].level, 9, "recruit should use current party level")
assert_eq(runState.nextRosterId, 6, "recruit should allocate roster id")

print("[OK] roguelike chapter clear prep")
