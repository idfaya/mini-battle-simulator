--- 豁免法术伤害事件应携带 saveType / onSaveSuccess，供 Web 与终端统一展示骰子信息。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleAttribute = require("modules.battle_attribute")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")
local SkillTimeline = require("core.skill_timeline")

local function assert_true(condition, message)
    if not condition then
        error(message or "assert failed")
    end
end

local function new_enemy(id, wpType)
    return EnemyData.ConvertToHeroData(id, 5)
end

math.randomseed(515151)

local captured = {}
BattleEvent.AddListener(BattleVisualEvents.DAMAGE_DEALT, function(payload)
    captured[#captured + 1] = payload
end, "test_spell_save_damage_log")

local wizardData = HeroData.ConvertToHeroData(900003, 5, 5, nil)
wizardData.wpType = 2
local enemyData = EnemyData.ConvertToHeroData(910004, 5)
enemyData.wpType = 1
enemyData.saveRef = -10

BattleFormation.Init({
    teamLeft = { wizardData },
    teamRight = { enemyData },
})

local wizard = BattleFormation.FindHeroByCampAndPos(true, 2)
local enemy = BattleFormation.FindHeroByCampAndPos(false, 1)
BattleAttribute.Init(wizard, {})
BattleAttribute.Init(enemy, {})
BattleSkill.Init(wizard, wizard.skillsConfig or wizard.skills)

local skill = wizard.skillData.skillInstances[80008003]
assert_true(skill ~= nil, "wizard should have freezing nova")
local timeline = require("config.skill.skill_80008003").BuildTimeline(wizard, { enemy }, skill)
SkillTimeline.Execute(wizard, { enemy }, skill, timeline)

assert_true(#captured > 0, "freezing nova should publish damage events")
local event = captured[1]
assert_true(event.saveRoll ~= nil, "damage event should include saveRoll")
assert_true(event.saveType == "ref", "freezing nova should expose ref save type")
assert_true(event.onSaveSuccess == "half", "aoe spell save should expose half damage on success")
assert_true(event.damageRoll ~= nil, "damage event should include damageRoll")

BattleFormation.OnFinal()
BattleSkill.OnFinal()

print("spell save damage log test passed")
