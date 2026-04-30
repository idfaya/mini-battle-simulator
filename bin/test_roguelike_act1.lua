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

local function isEnemyOrOutputUltimate(unit)
    if not unit or not unit.id or unit.ultimateReady ~= true then
        return false
    end

    local ult = getUltimateSkillForUnit(unit.id)
    if not ult then
        return false
    end

    local ts = ult.targetsSelections or (ult.config and ult.config.targetsSelections) or nil
    local castTarget = ts and ts.castTarget or ult.castTarget
    if castTarget == E_CAST_TARGET.Enemy or castTarget == E_CAST_TARGET.EnemyPos then
        return true
    end

    -- "输出型"：用技能描述里的骰子/伤害关键词做保守判断；治疗/复活类不自动点。
    local desc = (ult.skillConfig and ult.skillConfig.Description) or ""
    if desc:find("治疗") or desc:find("复活") then
        return false
    end
    if desc:find("伤害骰") or desc:find("%dd%d+") or desc:find("d%d+") then
        return true
    end
    return false
end

local function runBattleUntilResolved(maxSteps)
    local snapshot = Run.GetSnapshot()
    local castedUltimate = false
    for _ = 1, maxSteps do
        if not castedUltimate and snapshot.battleSnapshot and snapshot.battleSnapshot.pendingCommands == 0 then
            for _, unit in ipairs(snapshot.battleSnapshot.leftTeam or {}) do
                if isEnemyOrOutputUltimate(unit) then
                    Run.QueueBattleCommand({
                        type = "cast_ultimate",
                        heroId = unit.id,
                    })
                    castedUltimate = true
                    break
                end
            end
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
    assert(ok, "choose path failed: " .. tostring(reason))
    ok, reason = Run.EnterCurrentNode()
    assert(ok, "enter node failed: " .. tostring(reason))
end

local snapshot = Run.StartRun({
    chapterId = 101,
    starterHeroIds = { 900005, 900007, 900002 },
})

assert(snapshot.phase == "map", "run should start on map")
assert(#(snapshot.debug.availableNextNodeIds or {}) == 1, "start map should expose one node")

choosePathAndEnter(101001)
assert(Run.GetSnapshot().phase == "battle", "first node should be battle")
snapshot = runBattleUntilResolved(600)
assert(snapshot.phase == "reward", "first battle should open reward")
assert(Run.ChooseReward(1) == true, "reward selection should succeed")

choosePathAndEnter(101002)
assert(Run.GetSnapshot().phase == "reward", "second path should open recruit reward")
assert(Run.ChooseReward(1) == true, "recruit selection should resolve")
assert(Run.GetSnapshot().phase == "map", "recruit node should return to map")

choosePathAndEnter(101004)
assert(Run.GetSnapshot().phase == "shop", "shop node should open shop")
local shopSnapshot = Run.GetSnapshot()
assert(Run.ShopBuy(101001) == true, "shop equipment should succeed")
shopSnapshot = Run.GetSnapshot()
assert(#(shopSnapshot.equipments or {}) >= 1, "equipment should be added to run inventory")
assert(Run.ShopLeave() == true, "should be able to leave shop")

choosePathAndEnter(101006)
assert(Run.GetSnapshot().phase == "camp", "camp node should open camp")
assert(Run.CampChoose(2) == true, "camp empower should work")

choosePathAndEnter(101008)
assert(Run.GetSnapshot().phase == "event", "ember shrine should open event")
assert(Run.ChooseEventOption(1) == true, "healing event option should resolve")

choosePathAndEnter(101010)
assert(Run.GetSnapshot().phase == "shop", "last stop should open shop")
assert(Run.ShopLeave() == true, "should leave final shop")

choosePathAndEnter(101011)
assert(Run.GetSnapshot().phase == "battle", "boss node should be battle")
snapshot = runBattleUntilResolved(900)
assert(snapshot.phase == "reward" or snapshot.phase == "chapter_result", "boss should resolve to reward or chapter result")
if snapshot.phase == "reward" then
    assert(Run.ChooseReward(1) == true, "boss reward selection should succeed")
    snapshot = Run.GetSnapshot()
end

assert(snapshot.phase == "chapter_result", "run should end at chapter result")
assert(snapshot.chapterResult and snapshot.chapterResult.success == true, "chapter should clear successfully")
print("roguelike act1 test passed")
