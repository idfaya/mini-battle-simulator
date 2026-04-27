local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Logger = require("utils.logger")
local Run = require("roguelike.roguelike_run")

Logger.SetLogLevel(Logger.LOG_LEVELS.ERROR)

local ROUTE = { 101001, 101003, 101005, 101007, 101009, 101010, 101011 }
local STARTER = { 900005, 900007, 900002 }

local function teamStats(snapshot)
    local totalHp, totalMaxHp, alive, dead = 0, 0, 0, 0
    for _, hero in ipairs(snapshot.team or {}) do
        totalHp = totalHp + (hero.hp or 0)
        totalMaxHp = totalMaxHp + (hero.maxHp or 0)
        if hero.isDead or (hero.hp or 0) <= 0 then
            dead = dead + 1
        else
            alive = alive + 1
        end
    end
    local pct = totalMaxHp > 0 and ((totalHp / totalMaxHp) * 100) or 0
    return pct, alive, dead, totalHp, totalMaxHp
end

local function battleTeamStats(snapshot)
    local totalHp, totalMaxHp, alive, dead = 0, 0, 0, 0
    local battle = snapshot and snapshot.battleSnapshot or nil
    for _, hero in ipairs(battle and battle.leftTeam or {}) do
        totalHp = totalHp + (hero.hp or 0)
        totalMaxHp = totalMaxHp + (hero.maxHp or 0)
        if hero.isDead or not hero.isAlive or (hero.hp or 0) <= 0 then
            dead = dead + 1
        else
            alive = alive + 1
        end
    end
    local pct = totalMaxHp > 0 and ((totalHp / totalMaxHp) * 100) or 0
    return pct, alive, dead, totalHp, totalMaxHp
end

local function consumeNonBattle(snapshot)
    if snapshot.phase == "reward" then
        Run.ChooseReward(1)
    elseif snapshot.phase == "shop" then
        Run.ShopLeave()
    elseif snapshot.phase == "camp" then
        Run.CampChoose(1)
    elseif snapshot.phase == "event" then
        Run.ChooseEventOption(1)
    end
end

Run.StartRun({
    chapterId = 101,
    starterHeroIds = STARTER,
})

print("Act1 Combat Route Simulation")
print("starter=900005,900007,900002 route=101001,101003,101005,101007,101009,101010,101011")
print(string.rep("=", 72))

for _, nodeId in ipairs(ROUTE) do
    Run.ChoosePath(nodeId)
    local ok, err = Run.EnterCurrentNode()
    if not ok then
        print(string.format("node=%d enter_failed=%s", nodeId, tostring(err)))
        break
    end

    local snapshot = Run.GetSnapshot()
    local ticks = 0
    local battleRound = 0
    local startPct, startAlive, startDead, startHp, startMaxHp = battleTeamStats(snapshot)
    local endPct, endAlive, endDead, endHp, endMaxHp = startPct, startAlive, startDead, startHp, startMaxHp
    while snapshot.phase == "battle" and ticks < 2000 do
        if snapshot.battleSnapshot then
            battleRound = tonumber(snapshot.battleSnapshot.round) or battleRound
            endPct, endAlive, endDead, endHp, endMaxHp = battleTeamStats(snapshot)
        end
        Run.Tick(800)
        ticks = ticks + 1
        snapshot = Run.GetSnapshot()
    end
    local hpPct, alive, dead, totalHp, totalMaxHp = teamStats(snapshot)
    local budget = snapshot.currentEncounterBudget or {}
    print(string.format(
        "node=%d phase=%s ticks=%d round=%d battleHp=%.1f%% (%d/%d) -> %.1f%% (%d/%d) rosterHp=%.1f%% (%d/%d) alive=%d dead=%d budget=%s x%.2f adj=%s/%s",
        nodeId,
        tostring(snapshot.phase),
        ticks,
        battleRound,
        startPct,
        startHp,
        startMaxHp,
        endPct,
        endHp,
        endMaxHp,
        hpPct,
        totalHp,
        totalMaxHp,
        alive,
        dead,
        tostring(budget.targetDifficulty or "-"),
        tonumber(budget.pressureFactor) or 0,
        tostring(budget.adjustedXp or "-"),
        tostring(budget.targetAdjustedXp or "-")
    ))

    if snapshot.phase == "chapter_result" then
        local result = snapshot.chapterResult or {}
        print(string.format("terminal=%s", tostring(result.reason)))
        break
    end

    consumeNonBattle(snapshot)
end

local final = Run.GetSnapshot()
local hpPct, alive, dead, totalHp, totalMaxHp = teamStats(final)
print(string.rep("=", 72))
print(string.format(
    "final phase=%s partyLv=%d hp=%.1f%% (%d/%d) alive=%d dead=%d",
    tostring(final.phase),
    tonumber(final.partyLevel) or 0,
    hpPct,
    totalHp,
    totalMaxHp,
    alive,
    dead
))
