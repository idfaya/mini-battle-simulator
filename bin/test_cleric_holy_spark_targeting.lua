--- 神圣火花（80006011）阵营判定与结算回归：
--- 敌人被误治疗通常来自 isLeft 字段漂移；应以 teamLeft/teamRight 为准。
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
local HOLY_SPARK_ID = IDS.cleric_basic_spell or 80006011

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

    local skill = cleric.skillData.skillInstances[HOLY_SPARK_ID]
    assert_true(skill ~= nil, "cleric should have holy spark skill instance")

    return cleric, enemy, skill
end

local function buildHolySparkTimeline(cleric, target, skill)
    return require("config.skill.skill_80006011").BuildTimeline(cleric, { target }, skill)
end

local function runHolySpark(cleric, target, skill)
    local timeline = buildHolySparkTimeline(cleric, target, skill)
    local _, result = SkillTimeline.Execute(cleric, { target }, skill, timeline)
    return result
end

local function captureHolySparkCombatLogs(cleric, enemy, skill)
    local BattleEvent = require("core.battle_event")
    local logs = {}
    BattleEvent.AddListener("CombatLog", function(payload)
        if payload and payload.message then
            logs[#logs + 1] = payload.message
        end
    end, "test_cleric_holy_spark_targeting")
    runHolySpark(cleric, enemy, skill)
    BattleEvent.RemoveListener("CombatLog", "test_cleric_holy_spark_targeting")
    return logs
end

--- 误治疗敌人的判定：结算走治疗或敌人 HP 上升。
local function assert_enemy_not_healed(enemy, enemyHpBefore, result, message)
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
    local result = runHolySpark(cleric, enemy, skill)
    assert_true((result and result.totalDamage or 0) > 0, "holy spark should damage enemy at baseline")
    assert_true((result and result.totalHeal or 0) == 0, "holy spark should not heal enemy at baseline")
    assert_true(enemy.hp < enemyHpBefore, "enemy hp should drop after holy spark")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 2) 目标 isLeft 漂移：仍应对敌造成伤害
do
    local cleric, enemy, skill = setupClericVsScout()
    enemy.isLeft = true
    assert_eq(BattleSkill.IsAlly(cleric, enemy), false, "drifted target.isLeft must not mark enemy as ally")

    local enemyHpBefore = enemy.hp
    local result = runHolySpark(cleric, enemy, skill)
    assert_enemy_not_healed(enemy, enemyHpBefore, result, "holy spark must not heal enemy when target.isLeft drifts")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 3) 施法者 isLeft 漂移：这是误治疗敌人的主要回归点
do
    local cleric, enemy, skill = setupClericVsScout({
        hp = 1000,
        maxHp = 1000,
        saveCon = -20,
    })
    cleric.isLeft = false
    assert_eq(BattleFormation.IsHeroOnLeftTeam(cleric), true, "caster remains on left team despite isLeft drift")
    assert_eq(BattleSkill.IsAlly(cleric, enemy), false, "drifted caster.isLeft must not mark enemy as ally")

    local enemyHpBefore = enemy.hp
    local result = runHolySpark(cleric, enemy, skill)
    assert_enemy_not_healed(enemy, enemyHpBefore, result, "holy spark must not heal enemy when caster.isLeft drifts")
    assert_true(enemy.hp < enemyHpBefore, "holy spark should damage enemy when caster.isLeft drifts")
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
    local result = runHolySpark(cleric, enemy, skill)
    assert_enemy_not_healed(enemy, enemyHpBefore, result, "holy spark must not heal enemy when both isLeft drift")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 5) 对友方目标：仍应治疗（正向用例，防止修过头）
do
    local cleric, enemy, skill = setupClericVsScout()
    local injuredHp = math.max(1, math.floor(cleric.maxHp * 0.5))
    cleric.hp = injuredHp
    local enemyHpBefore = enemy.hp
    assert_true(BattleSkill.IsAlly(cleric, cleric), "self should count as ally")

    local result = runHolySpark(cleric, cleric, skill)
    assert_true(cleric.hp > injuredHp, "holy spark should heal when target is ally")
    assert_true((result and result.totalHeal or 0) == 0, "timeline heal is tracked via hp, not totalHeal field")
    assert_true(enemy.hp == enemyHpBefore, "enemy should be untouched when cleric self-heals")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 6) 战斗日志应包含体质豁免与伤害骰信息
do
    local cleric, enemy, skill = setupClericVsScout({
        hp = 1000,
        maxHp = 1000,
        saveCon = -20,
    })
    local logs = captureHolySparkCombatLogs(cleric, enemy, skill)
    assert_true(#logs > 0, "holy spark should publish combat log")
    local joined = table.concat(logs, "\n")
    assert_true(joined:find("体质豁免") ~= nil, "holy spark combat log should mention con save")
    assert_true(joined:find("vs DC") ~= nil, "holy spark combat log should include save DC")
    assert_true(joined:find("伤害骰") ~= nil, "holy spark combat log should include damage dice")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

-- 7) 实战施法路径：StartSkillCastInSeq + 显式敌目标，施法者 isLeft 漂移
do
    local cleric, enemy, skill = setupClericVsScout({
        hp = 1000,
        maxHp = 1000,
        saveCon = -20,
    })
    cleric.isLeft = false

    local enemyHpBefore = enemy.hp
    local castOk = BattleSkill.CastSkillInSeqWithResult(cleric, enemy, HOLY_SPARK_ID, {
        resolvedTargets = { enemy },
    })
    local castResult = SkillTimeline.GetLastCompletedResult()
    assert_true(castOk, "CastSkillInSeqWithResult should complete holy spark")
    assert_true(castResult and castResult.succeeded, "holy spark cast should succeed")
    assert_enemy_not_healed(enemy, enemyHpBefore, castResult, "cast path must not heal enemy when caster.isLeft drifts")
    assert_true(enemy.hp < enemyHpBefore, "cast path should damage enemy when caster.isLeft drifts")
    BattleFormation.OnFinal()
    BattleSkill.OnFinal()
end

print("cleric holy spark targeting test passed")
