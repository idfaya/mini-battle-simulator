-- 章节结算成功路径回归：StartRun 后由 ForceBossChapterResultForTest 写入终局，
-- 断言 chapter_result.success / reason / 统计字段契约（全三章 E2E 见 act1 + balance）。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")

local SEED = 1
math.randomseed(SEED)

local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = SEED,
})
assert(snapshot.phase == "map", "run should start on map")
assert(Run.ForceBossChapterResultForTest() == true, "test hook should enter chapter_result")
snapshot = Run.GetSnapshot()
assert(snapshot.phase == "chapter_result", string.format("seed %d should be chapter_result, got %s", SEED, tostring(snapshot.phase)))
local result = snapshot.chapterResult
assert(result, "chapter_result snapshot should expose chapterResult payload")
assert(result.success == true, "chapter_result.success should be true on boss defeat path")
assert(result.reason == "boss_defeated", string.format("chapter_result.reason should be boss_defeated, got %s", tostring(result.reason)))
assert(snapshot.chapterId == 103, string.format("should clear all 3 chapters and end on chapterId=103, got %s", tostring(snapshot.chapterId)))
assert(type(result.gold) == "number", "chapter_result.gold should be a number")
assert(type(result.equipmentCount) == "number", "chapter_result.equipmentCount should be a number")
assert(type(result.blessingCount) == "number", "chapter_result.blessingCount should be a number")

print("roguelike chapter_result success path passed")
