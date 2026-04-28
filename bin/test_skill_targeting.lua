local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleBuff = require("modules.battle_buff")
local SkillTimeline = require("core.skill_timeline")

local function assert_true(condition, message)
    if not condition then
        error(message or "assert failed")
    end
end

local function assert_eq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s (expected=%s actual=%s)", message or "assert_eq failed", tostring(expected), tostring(actual)))
    end
end

local function new_unit(id, name, wpType, isLeft, hp, maxHp)
    return {
        configId = id,
        heroId = id,
        id = id,
        name = name,
        wpType = wpType,
        class = 1,
        hp = hp or 1000,
        maxHp = maxHp or 1000,
        atk = 100,
        def = 10,
        speed = 100,
        skillsConfig = {
            { skillId = 80001001, skillType = E_SKILL_TYPE_NORMAL, name = "刺击", skillCost = 0 },
        },
        isLeft = isLeft,
    }
end

local function has_target_with_wp(targets, wpType)
    for _, target in ipairs(targets or {}) do
        if target.wpType == wpType then
            return true
        end
    end
    return false
end

math.randomseed(123456)

BattleFormation.Init({
    teamLeft = {
        new_unit(1001, "Attacker", 2, true),
    },
    teamRight = {
        new_unit(2001, "FrontA", 1, false, 900, 1000),
        new_unit(2002, "FrontB", 3, false, 800, 1000),
        new_unit(2003, "BackA", 5, false, 100, 1000),
    },
})

local hero = BattleFormation.FindHeroByCampAndPos(true, 2)

local defaultTargets = BattleSkill.SelectEnemyTargets(hero, {}, {
    castTarget = E_CAST_TARGET.Enemy,
})
assert_eq(#defaultTargets, 1, "default enemy select should return single target")
assert_true(defaultTargets[1].wpType == 1 or defaultTargets[1].wpType == 3, "default enemy select should stay in front row")

local multiTargets = BattleSkill.SelectEnemyTargets(hero, {}, {
    castTarget = E_CAST_TARGET.Enemy,
    measureType = E_MEASURE_TYPE.Muti,
    count = 2,
})
assert_eq(#multiTargets, 2, "multi target selection should return requested count from selectable pool")
assert_true(has_target_with_wp(multiTargets, 1), "multi target selection should include front row target 1")
assert_true(has_target_with_wp(multiTargets, 3), "multi target selection should include front row target 3")

local ignoreFrontTargets = BattleSkill.SelectEnemyTargets(hero, {}, {
    castTarget = E_CAST_TARGET.Enemy,
    measureType = E_MEASURE_TYPE.Muti,
    count = 3,
    ignoreFrontProtection = true,
})
assert_eq(#ignoreFrontTargets, 3, "ignoreFrontProtection should open full alive enemy pool")
assert_true(has_target_with_wp(ignoreFrontTargets, 5), "ignoreFrontProtection should allow selecting back row")

local rowTargets = BattleSkill.SelectEnemyTargets(hero, {}, {
    castTarget = E_CAST_TARGET.Enemy,
    measureType = E_MEASURE_TYPE.Row,
    row = 2,
    ignoreFrontProtection = true,
})
assert_eq(#rowTargets, 1, "row selection should return only the requested row")
assert_eq(rowTargets[1].wpType, 5, "row selection should hit back row target")

local enemyPosTargets = BattleSkill.SelectTarget(hero, {
    targetsSelections = {
        castTarget = E_CAST_TARGET.EnemyPos,
        targetWpType = 5,
    },
})
assert_eq(#enemyPosTargets, 1, "EnemyPos should resolve explicit enemy position")
assert_eq(enemyPosTargets[1].wpType, 5, "EnemyPos should select target wpType 5")

local lowestHpTarget = BattleSkill.SelectLowestHpEnemy(hero)
assert_true(lowestHpTarget ~= nil, "lowest hp target should exist")
assert_eq(lowestHpTarget.wpType, 3, "lowest hp enemy should still respect front protection")

BattleFormation.OnFinal()

BattleFormation.Init({
    teamLeft = {
        new_unit(5001, "HolyCaster", 2, true, 1000, 1000),
        new_unit(5002, "InjuredAlly", 4, true, 300, 1000),
    },
    teamRight = {
        new_unit(6001, "EnemyAnchor", 2, false, 1000, 1000),
        new_unit(6002, "EnemyRowTop", 1, false, 1000, 1000),
        new_unit(6003, "EnemyRowBottom", 3, false, 1000, 1000),
        new_unit(6004, "EnemyColumnBack", 5, false, 1000, 1000),
        new_unit(6005, "EnemyOtherBack", 6, false, 1000, 1000),
    },
})

local holyCaster = BattleFormation.FindHeroByCampAndPos(true, 2)
local holyLightSkill = BattleSkill.CreateSkillInstance(80006001, {})
local holyTargets = BattleSkill.SelectTarget(holyCaster, holyLightSkill)
assert_eq(#holyTargets, 1, "cleric basic attack should choose one target")
assert_eq(holyTargets[1].isLeft, false, "cleric basic attack should target an enemy")

local areaTargets = BattleSkill.ExpandAreaTargets(BattleFormation.FindHeroByCampAndPos(false, 2), {
    includeRow = true,
    includeColumn = true,
})
assert_eq(#areaTargets, 4, "cross area should include row and column without duplicates")
assert_true(has_target_with_wp(areaTargets, 1), "cross area should include same row left target")
assert_true(has_target_with_wp(areaTargets, 2), "cross area should include anchor target")
assert_true(has_target_with_wp(areaTargets, 3), "cross area should include same row right target")
assert_true(has_target_with_wp(areaTargets, 5), "cross area should include same column back target")

local chainTargets = BattleSkill.GetChainTargets(holyCaster, BattleFormation.FindHeroByCampAndPos(false, 2), 4)
assert_eq(#chainTargets, 4, "chain lightning should produce unique chain targets up to requested count")
assert_eq(chainTargets[1].wpType, 2, "chain lightning should start from selected primary target")

local injuredAlly = BattleFormation.FindHeroByCampAndPos(true, 4)
injuredAlly.hp = injuredAlly.maxHp
local holyEnemyTargets = BattleSkill.SelectTarget(holyCaster, holyLightSkill)
assert_eq(#holyEnemyTargets, 1, "cleric basic attack should resolve one enemy target")
assert_eq(holyEnemyTargets[1].isLeft, false, "cleric basic attack should always target enemies")

BattleFormation.OnFinal()

BattleFormation.Init({
    teamLeft = {
        new_unit(7001, "SupportCaster", 2, true, 1000, 1000),
        new_unit(7002, "SupportAlly", 4, true, 200, 1000),
    },
    teamRight = {
        new_unit(8001, "PoisonEnemy", 2, false, 1000, 1000),
    },
})

local supportCaster = BattleFormation.FindHeroByCampAndPos(true, 2)
local supportAlly = BattleFormation.FindHeroByCampAndPos(true, 4)
local poisonEnemy = BattleFormation.FindHeroByCampAndPos(false, 2)

local holySpecial = BattleSkill.CreateSkillInstance(80006001, {})
assert_eq(holySpecial.specialEffectTag, nil, "cleric basic attack should not infer holy_light special effect tag")
local holyTimeline = require("config.skill.skill_80006001").BuildTimeline(supportCaster, { poisonEnemy }, holySpecial)
local _, holyResult = SkillTimeline.Execute(supportCaster, { poisonEnemy }, holySpecial, holyTimeline)
assert_true((holyResult and holyResult.totalDamage or 0) > 0, "cleric basic attack timeline should resolve enemy damage")

local buffSkill = BattleSkill.CreateSkillInstance(80004003, {})
assert_eq(buffSkill.specialEffectTag, "battle_intent_buff", "battle intent skill should infer special effect tag")
local buffTimeline = require("config.skill.skill_80004003").BuildTimeline(supportCaster, { supportCaster, supportAlly }, buffSkill)
SkillTimeline.Execute(supportCaster, { supportCaster, supportAlly }, buffSkill, buffTimeline)
assert_true(BattleBuff.GetBuff(supportCaster, 840002) ~= nil, "battle intent buff should be applied to caster")
assert_true(BattleBuff.GetBuff(supportAlly, 840002) ~= nil, "battle intent buff should be applied to ally")

BattleSkill.ApplyPoison(poisonEnemy, 2, supportCaster)
local poisonBurstSkill = BattleSkill.CreateSkillInstance(80005004, {})
assert_eq(poisonBurstSkill.specialEffectTag, "poison_burst", "poison burst should infer special effect tag")
local poisonBurstTimeline = require("config.skill.skill_80005004").BuildTimeline(supportCaster, { poisonEnemy }, poisonBurstSkill)
local _, poisonBurstResult = SkillTimeline.Execute(supportCaster, { poisonEnemy }, poisonBurstSkill, poisonBurstTimeline)
assert_true((poisonBurstResult and poisonBurstResult.totalDamage or 0) > 0, "poison burst timeline should detonate poison damage")
assert_true(BattleBuff.GetBuff(poisonEnemy, 850001) == nil, "poison burst should clear poison buff")

BattleFormation.OnFinal()

BattleFormation.Init({
    teamLeft = {
        new_unit(3001, "Caster", 2, true, 1000, 1000),
        new_unit(3002, "LowHpAlly", 4, true, 100, 1000),
        new_unit(3003, "MidHpAlly", 5, true, 500, 1000),
    },
    teamRight = {
        new_unit(4001, "EnemyFront", 1, false, 1000, 1000),
    },
})

local caster = BattleFormation.FindHeroByCampAndPos(true, 2)
local healSkill = BattleSkill.CreateSkillInstance(80006003, {})
local healTargets = BattleSkill.SelectTarget(caster, healSkill)
assert_eq(#healTargets, 1, "healing word should pick one lowest hp ally by inferred config")
assert_eq(healTargets[1].name, "LowHpAlly", "group heal should pick lowest hp ally first")

local slashSkill = BattleSkill.CreateSkillInstance(80001003, {})
assert_true(slashSkill.targetsSelections.preferLowestHp == true, "slash skill should infer lowest hp targeting")

local meteorSkill = BattleSkill.CreateSkillInstance(80007004, {})
assert_eq(meteorSkill.targetsSelections.measureType, E_MEASURE_TYPE.AOE, "meteor should infer aoe targeting")
assert_true(meteorSkill.targetsSelections.ignoreFrontProtection == true, "meteor should ignore front protection")

local warGodSkill = BattleSkill.CreateSkillInstance(80004004, {})
assert_eq(warGodSkill.targetsSelections.castTarget, E_CAST_TARGET.Alias, "war god should target allies")
assert_true(warGodSkill.targetsSelections.includeSelf == true, "war god should include self")

BattleFormation.OnFinal()
BattleSkill.OnFinal()

print("skill targeting test passed")
