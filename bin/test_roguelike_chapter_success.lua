-- 章节结算成功路径回归：用已验证可通关的种子 10101 跑一遍 act1，
-- 断言最终落到 chapter_result.success=true 且 reason=boss_defeated，
-- 锁定 RoguelikeRun.chapterResult 字段契约。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local Run = require("roguelike.roguelike_run")
local BattleFormation = require("modules.battle_formation")

local function getUltimateSkillForUnit(unitId)
    local hero = BattleFormation.FindHeroByInstanceId and BattleFormation.FindHeroByInstanceId(tonumber(unitId)) or nil
    local instances = hero and hero.skillData and hero.skillData.skillInstances or nil
    if not instances then return nil end
    for _, skill in pairs(instances) do
        if skill and skill.skillType == E_SKILL_TYPE_ULTIMATE then return skill end
    end
    return nil
end

local function isOutputUlt(unit)
    if not unit or not unit.id or unit.ultimateReady ~= true then return false end
    local ult = getUltimateSkillForUnit(unit.id)
    if not ult then return false end
    local ts = ult.targetsSelections or (ult.config and ult.config.targetsSelections)
    local ct = ts and ts.castTarget or ult.castTarget
    if ct == E_CAST_TARGET.Enemy or ct == E_CAST_TARGET.EnemyPos then return true end
    local desc = (ult.skillConfig and ult.skillConfig.Description) or ""
    if desc:find("治疗") or desc:find("复活") then return false end
    return desc:find("d%d+") ~= nil
end

local function findReadyHero(s)
    local b = s and s.battleSnapshot
    if not b then return nil end
    for _, u in ipairs(b.leftTeam or {}) do
        if isOutputUlt(u) then return u.id end
    end
    return nil
end

local function runBattle(maxSteps)
    local s
    for _ = 1, maxSteps do
        Run.Tick(800)
        s = Run.GetSnapshot()
        if s.phase ~= "battle" then return s end
        local heroId = findReadyHero(s)
        if heroId then
            Run.QueueBattleCommand({ type = "cast_ultimate", heroId = heroId })
        end
    end
    return s
end

local function chooseRewardIndex(s)
    local r = s and s.rewardState
    if not r or not r.options then return 1 end
    local priority = { recruit = 1, equipment = 2, blessing = 3, gold = 4 }
    local bestIdx, bestScore = 1, 99
    for i, opt in ipairs(r.options) do
        local sc = priority[opt.rewardType] or 99
        if sc < bestScore then bestIdx, bestScore = i, sc end
    end
    return bestIdx
end

local function pickAggressiveNode(s)
    local sel = {}
    for _, n in ipairs((s.map and s.map.nodes) or {}) do
        if n.selectable then sel[#sel + 1] = n end
    end
    if #sel == 0 then return nil end
    local prio = { boss = 1, camp = 2, shop = 3, recruit = 4, event = 5, battle_normal = 6, battle_elite = 7 }
    table.sort(sel, function(a, b) return (prio[a.nodeType] or 99) < (prio[b.nodeType] or 99) end)
    return sel[1]
end

local SEED = 10101
math.randomseed(SEED)

local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900001, 900007, 900002 },
    seed = SEED,
})
assert(snapshot.phase == "map", "run should start on map")

local guard = 0
while guard < 30 do
    guard = guard + 1
    snapshot = Run.GetSnapshot()
    if snapshot.phase == "chapter_result" then break end
    assert(snapshot.phase ~= "failed", string.format("seed %d should not fail before chapter result", SEED))

    if snapshot.phase == "map" then
        local n = pickAggressiveNode(snapshot)
        assert(n, "should always have a selectable node before chapter result")
        assert(Run.ChoosePath(n.id) == true, "choose path should succeed")
        assert(Run.EnterCurrentNode() == true, "enter node should succeed")
    elseif snapshot.phase == "battle" then
        snapshot = runBattle(900)
        if snapshot.phase == "reward" then
            assert(Run.ChooseReward(chooseRewardIndex(snapshot)) == true, "reward should resolve")
        end
    elseif snapshot.phase == "reward" then
        assert(Run.ChooseReward(chooseRewardIndex(snapshot)) == true, "reward should resolve")
    elseif snapshot.phase == "camp" then
        assert(Run.CampChoose(2) == true, "camp short rest should succeed")
    elseif snapshot.phase == "shop" then
        assert(Run.ShopLeave() == true, "shop leave should succeed")
    elseif snapshot.phase == "event" then
        local opts = snapshot.eventState and snapshot.eventState.options or {}
        assert(opts[1], "event should have at least one option")
        assert(Run.ChooseEventOption(opts[1].id) == true, "event option should resolve")
    else
        error("unsupported phase: " .. tostring(snapshot.phase))
    end
end

assert(snapshot.phase == "chapter_result", string.format("seed %d should converge to chapter_result, got %s", SEED, tostring(snapshot.phase)))
local result = snapshot.chapterResult
assert(result, "chapter_result snapshot should expose chapterResult payload")
assert(result.success == true, "chapter_result.success should be true on boss defeat path")
assert(result.reason == "boss_defeated", string.format("chapter_result.reason should be boss_defeated, got %s", tostring(result.reason)))
assert(type(result.gold) == "number", "chapter_result.gold should be a number")
assert(type(result.equipmentCount) == "number", "chapter_result.equipmentCount should be a number")
assert(type(result.blessingCount) == "number", "chapter_result.blessingCount should be a number")

print("roguelike chapter_result success path passed")
