-- 第一章 Boss 触达率（design/dungeon_design.md §8）：多种子自动推图，目标 ≥60% 选路进入 Boss 房。
-- 战斗用 TestForceCurrentBattleVictory 跳过（测地图可达 + 推图策略）；战斗数值见 act1 / progression_pacing。
local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local RoguelikeTestRoute = dofile(script_dir .. "roguelike_test_route.lua")
local Driver = dofile(script_dir .. "roguelike_run_driver.lua")

local TARGET_RATE = 0.60
local SEED_START = 1
local SEED_COUNT = 30

local cleared = 0
local failed = 0
local chapterResult = 0

for offset = 0, SEED_COUNT - 1 do
    local seed = SEED_START + offset
    local report = Driver.simulate(Run, RoguelikeTestRoute, {
        seed = seed,
        maxGuard = 2500,
        progressionMode = "ch101_reach",
        autoWinBattles = true,
    })
    if report.ch101BossReached or report.ch101BossCleared or (report.chapterId or 101) > 101 or report.chapterResult then
        cleared = cleared + 1
    end
    if report.failed then
        failed = failed + 1
    end
    if report.chapterResult then
        chapterResult = chapterResult + 1
    end
end

local rate = cleared / SEED_COUNT
print(string.format(
    "[ch101 reach] seeds=%d..%d bossClear=%d/%d (%.1f%%) failed=%d chapter_result=%d (target %.0f%%)",
    SEED_START,
    SEED_START + SEED_COUNT - 1,
    cleared,
    SEED_COUNT,
    rate * 100,
    failed,
    chapterResult,
    TARGET_RATE * 100
))

assert(rate >= TARGET_RATE, string.format(
    "ch101 boss reach rate %.1f%% below target %.0f%% (seeds %d..%d)",
    rate * 100,
    TARGET_RATE * 100,
    SEED_START,
    SEED_START + SEED_COUNT - 1
))
