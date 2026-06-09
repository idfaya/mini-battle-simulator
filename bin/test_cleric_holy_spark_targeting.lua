--- 圣火术（80006011）阵营判定与结算回归：
--- 敌人被误判为友方通常来自 isLeft 字段漂移；应以 teamLeft/teamRight 为准。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleAttribute = require("modules.battle_attribute")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local SkillTimeline = require("core.skill_timeline")
local SkillRuntimeConfig = require("config.tables.skill_runtime")

local IDS = SkillRuntimeConfig.Ids
local SACRED_FLAME_ID = IDS.cleric_basic_spell or 80006011

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

local function setupClericVsScout(enemyOverrides)
    local clericData = HeroData.ConvertToHeroData(900007, 5, 5, nil)
    local enemyData = EnemyData.ConvertToHeroData(910008, 5)
    assert_true(clericData ~= nil and enemyData ~= nil, "hero/enemy data should load")
    clericData.wpType = 2
    enemyData.wpType = 1
    for key, value in pairs(enemyOverrides or {}) do
        enemyData[key] = value
    end

    BattleFormation.Init({
        teamLeft = { clericData },
        teamRight = { enemyData },
    })

    local cleric = BattleFormation.FindHeroByCampAndPos(true, 2)
    local enemy = BattleFormation.FindHeroByCampAndPos(false, 1)
    assert_true(cleric ~= nil and enemy ~= nil, "formation should place cleric and scout")

    BattleAttribute.Init(cleric, {})
    BattleAttribute.Init(enemy, {})
    BattleSkill.Init(cleric, cleric.skillsConfig or cleric.skills)

    local skill = cleric.skillData.skillInstances[SACRED_FLAME_ID]
    assert_true(skill ~= nil, "cleric should have sacred flame skill instance")

    return cleric, enemy, skill
end

local function buildSacredFlameTimeline(cleric, target, skill)
    return require("config.skill.skill_80006011").BuildTimeline(cleric, { target }, skill)
end

local function runSacredFlame(cleric, target, skill)
    local timeline = buildSacredFlameTimeline(cleric, target, skill)
    local _, result = SkillTimeline.Execute(cleric, { target }, skill, timeline)
    return result
end

local function captureSacredFlameCombatLogs(cleric, enemy, skill)
    local BattleEvent = require("core.battle_event")
    local logs = {}
    local listener = function(payload)
        if payload and payload.message then
            logs[#logs + 1] = payload.message
        end
    end
    BattleEvent.AddListener("CombatLog", listener, "test_cleric_holy_spark_targeting")
    runSacredFlame(cleric, enemy, skill)
    BattleEvent.RemoveListener("CombatLog", listener)
    return logs
end

--- 敌方不应被治疗或获得任何正向生命收益。
local function assert_enemy_not_helped(enemy, enemyHpBefore, result, message)
    assert_true((result and result.totalHeal or 0) == 0, message .. " (totalHeal)")
    assert_true(enemy.hp <= enemyHpBefore, message .. " (hp increased)")
end

math.randomseed(424242)

-- 1) 基线：IsAlly 与正常对敌伤害
do
    local cleric, enemy, skill = setupClericVsScout()
    assert_eq(BattleFormation.IsHeroOnLeftTeam(cleric), true, "cleric should be on left team")
    assert_eq(BattleFormation.IsHeroOnLeftTeam(enemy), false, "scout should be on right team")
    assert_eq(BattleSkill.IsAlly(cleric, enemy), false, "cleric vs enemy should not be ally")
    assert_eq(BattleSkill.IsAlly(cleric, cleric), true, "cleric vs self should be ally")

    local enemyHpBefore = enemy.hp
    local result = runSacredFlame(cleric, enemy, skill)
    assert_true((result and result.totalDamage or 0) > 0, "sacred flame should damage enemy at baseline")
    assert_true((result and result.totalHeal or 0) == 0, "sacred flame should not heal enemy at baseline")
    assert_true(enemy.hp < enemyHpBefore, "enemy hp should drop after sacred flame")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 2) 目标 isLeft 漂移：仍应对敌造成伤害
do
    local cleric, enemy, skill = setupClericVsScout()
    enemy.isLeft = true
    assert_eq(BattleSkill.IsAlly(cleric, enemy), false, "drifted target.isLeft must not mark enemy as ally")

    local enemyHpBefore = enemy.hp
    local result = runSacredFlame(cleric, enemy, skill)
    assert_enemy_not_helped(enemy, enemyHpBefore, result, "sacred flame must not heal enemy when target.isLeft drifts")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 3) 施法者 isLeft 漂移：这是误治疗敌人的主要回归点
do
    local cleric, enemy, skill = setupClericVsScout({
        hp = 1000,
        maxHp = 1000,
        saveDex = -20,
    })
    cleric.isLeft = false
    assert_eq(BattleFormation.IsHeroOnLeftTeam(cleric), true, "caster remains on left team despite isLeft drift")
    assert_eq(BattleSkill.IsAlly(cleric, enemy), false, "drifted caster.isLeft must not mark enemy as ally")

    local enemyHpBefore = enemy.hp
    local result = runSacredFlame(cleric, enemy, skill)
    assert_enemy_not_helped(enemy, enemyHpBefore, result, "sacred flame must not heal enemy when caster.isLeft drifts")
    assert_true(enemy.hp < enemyHpBefore, "sacred flame should damage enemy when caster.isLeft drifts")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 4) 双方 isLeft 同时漂移为同侧字段值：仍应对敌造成伤害
do
    local cleric, enemy, skill = setupClericVsScout()
    cleric.isLeft = false
    enemy.isLeft = false
    assert_eq(BattleSkill.IsAlly(cleric, enemy), false, "same wrong isLeft on both sides must not imply ally")

    local enemyHpBefore = enemy.hp
    local result = runSacredFlame(cleric, enemy, skill)
    assert_enemy_not_helped(enemy, enemyHpBefore, result, "sacred flame must not heal enemy when both isLeft drift")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 5) 对友方目标：不再治疗（圣火术只负责对敌伤害）
do
    local cleric, enemy, skill = setupClericVsScout()
    local injuredHp = math.max(1, math.floor(cleric.maxHp * 0.5))
    cleric.hp = injuredHp
    local enemyHpBefore = enemy.hp
    assert_true(BattleSkill.IsAlly(cleric, cleric), "self should count as ally")

    local result = runSacredFlame(cleric, cleric, skill)
    assert_true(cleric.hp == injuredHp, "sacred flame should not heal ally")
    assert_true((result and result.totalHeal or 0) == 0, "sacred flame should not emit heal on ally target")
    assert_true(enemy.hp == enemyHpBefore, "enemy should be untouched when cleric self-targets sacred flame")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 6) 战斗日志应包含敏捷豁免与伤害骰信息
do
    local cleric, enemy, skill = setupClericVsScout({
        hp = 1000,
        maxHp = 1000,
        saveDex = -20,
    })
    local logs = captureSacredFlameCombatLogs(cleric, enemy, skill)
    assert_true(#logs > 0, "sacred flame should publish combat log")
    local joined = table.concat(logs, "\n")
    assert_true(joined:find("敏捷豁免") ~= nil, "sacred flame combat log should mention dex save")
    assert_true(joined:find("vs DC") ~= nil, "sacred flame combat log should include save DC")
    assert_true(joined:find("伤害骰") ~= nil, "sacred flame combat log should include damage dice")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 7) 实战施法路径：StartSkillCastInSeq + 显式敌目标，施法者 isLeft 漂移
do
    local cleric, enemy, skill = setupClericVsScout({
        hp = 1000,
        maxHp = 1000,
        saveDex = -20,
    })
    cleric.isLeft = false

    local enemyHpBefore = enemy.hp
    local castOk = BattleSkill.CastSkillInSeqWithResult(cleric, enemy, SACRED_FLAME_ID, {
        resolvedTargets = { enemy },
    })
    local castResult = SkillTimeline.GetLastCompletedResult()
    assert_true(castOk, "CastSkillInSeqWithResult should complete sacred flame")
    assert_true(castResult and castResult.succeeded, "sacred flame cast should succeed")
    assert_enemy_not_helped(enemy, enemyHpBefore, castResult, "cast path must not heal enemy when caster.isLeft drifts")
    assert_true(enemy.hp < enemyHpBefore, "cast path should damage enemy when caster.isLeft drifts")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

print("cleric sacred flame targeting test passed")
