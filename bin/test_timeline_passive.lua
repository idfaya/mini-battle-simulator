-- Minimal timeline + passive assertions for config-driven skills
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local function log(msg) print(msg) end
local function assert_true(cond, name)
    if not cond then
        io.stderr:write("ASSERT FAIL: " .. name .. "\n")
        os.exit(1)
    else
        log("ASSERT OK  : " .. name)
    end
end

local BattleEvent = require("core.battle_event")
local BattleBuff = require("modules.battle_buff")
local BattleSkill = require("modules.battle_skill")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleVisualEvents = require("ui.battle_visual_events")
local PassiveHandlers = require("modules.passive_handlers")

-- Init subsystems
BattleEvent.Init()
BattleBuff.Init()
BattleSkill.InitModule()

-- Helpers
local function new_unit(id, name, hp, atk, def)
    return {
        id = id, instanceId = id, name = name,
        hp = hp or 10000, maxHp = hp or 10000,
        atk = atk or 100, def = def or 0,
        -- 5e-style fields (keep tests deterministic)
        hit = 999,
        spellAttack = 999,
        ac = 1,
        spellDC = 999,
        saveFort = 0,
        saveRef = 0,
        saveWill = 0,
        __ignoreNatRules = true,
        isDead = false, isAlive = true,
        attributes = { final = {} },
    }
end

-- Test 0: Timeline async progression should respect frame spacing
do
    local SkillTimeline = require("core.skill_timeline")
    local frameEvents = 0
    local completed = false
    local handler = function()
        frameEvents = frameEvents + 1
    end
    local completedHandler = function()
        completed = true
    end

    BattleEvent.AddListener(BattleVisualEvents.SKILL_TIMELINE_FRAME, handler)
    BattleEvent.AddListener(BattleVisualEvents.SKILL_TIMELINE_COMPLETED, completedHandler)

    local hero = new_unit(9001, "Async_Tester", 10000, 200, 0)
    local target = new_unit(9002, "Async_Target", 10000, 0, 0)
    local skillLua = require("config.skill.skill_80007001")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80007001, name = "火球术" })

    local started = SkillTimeline.Start(hero, { target }, { skillId = 80007001, name = "火球术" }, timeline)
    assert_true(started, "Async timeline start ok")
    assert_true(frameEvents == 1, "Async timeline only executes frame 0 immediately")
    assert_true(not completed, "Async timeline not completed immediately")

    SkillTimeline.Update(11 * (1000 / 30))
    assert_true(frameEvents == 1, "Async timeline still waiting before frame 12")

    SkillTimeline.Update(1 * (1000 / 30))
    assert_true(frameEvents == 2, "Async timeline reaches projectile frame at 12")

    SkillTimeline.Update(12 * (1000 / 30))
    assert_true(frameEvents == 3, "Async timeline reaches damage frame at 24")
    assert_true(completed, "Async timeline completes after final frame")

    BattleEvent.RemoveListener(BattleVisualEvents.SKILL_TIMELINE_FRAME, handler)
    BattleEvent.RemoveListener(BattleVisualEvents.SKILL_TIMELINE_COMPLETED, completedHandler)
end

-- Test 1: Timeline frames for Fire Bolt (80007001)
do
    local frames = 0
    local damageEvent = nil
    local damageListener = function(evt)
        if evt and evt.skillId == 80007001 then
            damageEvent = evt
        end
    end
    BattleEvent.AddListener(BattleVisualEvents.SKILL_TIMELINE_FRAME, function(evt)
        frames = frames + 1
    end)
    BattleEvent.AddListener(BattleVisualEvents.DAMAGE_DEALT, damageListener)
    local hero = new_unit(1001, "Tester_Fire", 10000, 200, 0)
    local target = new_unit(2001, "Dummy_Target", 10000, 0, 0)
    local skillLua = require("config.skill.skill_80007001")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80007001, name = "火焰弹" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, result = SkillTimeline.Execute(hero, { target }, { skillId = 80007001, name = "火焰弹" }, timeline)
    assert_true(ok, "Fire Bolt timeline execute ok")
    assert_true(frames == 3, "Fire Bolt frame count == 3 (cast, projectile, damage)")
    assert_true(target.hp < target.maxHp, "Fire Bolt timeline applies damage")
    assert_true((result and result.totalDamage or 0) > 0, "Fire Bolt timeline accumulates total damage")
    assert_true(damageEvent ~= nil, "Fire Bolt publishes damage event")
    assert_true(damageEvent.preferSkillColor == true, "Fire Bolt damage event prefers skill color")
    assert_true(damageEvent.attackRoll ~= nil, "Fire Bolt damage event carries attack roll")
    assert_true(damageEvent.saveRoll == nil, "Fire Bolt damage event omits save roll")
    assert_true(damageEvent.damageRoll ~= nil, "Fire Bolt damage event carries damage roll")
    BattleEvent.RemoveListener(BattleVisualEvents.DAMAGE_DEALT, damageListener)
end

-- Test 1a: Ranger basic attack projectile frame should carry target info
do
    local projectileFrame = nil
    local listener = function(evt)
        if evt and evt.skillId == 80005011 and evt.op == "projectile" then
            projectileFrame = evt
        end
    end
    BattleEvent.AddListener(BattleVisualEvents.SKILL_TIMELINE_FRAME, listener)
    local hero = new_unit(1011, "Tester_Ranger", 10000, 200, 0)
    hero.classId = 5
    local target = new_unit(2011, "Ranger_Target", 10000, 0, 0)
    local skillLua = require("config.skill.skill_80005011")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80005011, name = "远程基础攻击" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { target }, { skillId = 80005011, name = "远程基础攻击", skillType = 1 }, timeline)
    assert_true(ok, "Ranger basic attack timeline execute ok")
    assert_true(projectileFrame ~= nil, "Ranger basic attack publishes projectile frame")
    assert_true(projectileFrame.targets ~= nil and #projectileFrame.targets == 1, "Ranger basic attack projectile frame keeps target ids")
    assert_true((projectileFrame.targets[1] and projectileFrame.targets[1].id) == target.instanceId, "Ranger basic attack projectile frame targets the selected enemy")
    BattleEvent.RemoveListener(BattleVisualEvents.SKILL_TIMELINE_FRAME, listener)
end

-- Test 1aa: Timeline frame serialization should prefer actual resolved targets
do
    local hero = new_unit(1012, "TimelineHero", 10000, 200, 0)
    local selectedTarget = new_unit(2012, "SelectedTarget", 10000, 0, 0)
    local actualTarget = new_unit(2013, "ActualTarget", 10000, 0, 0)
    local evt = BattleVisualEvents.BuildSkillTimelineFrame(hero, { skillId = 999001, name = "单体法术" }, {
        frame = 24,
        op = "damage",
        target = selectedTarget,
        targets = { actualTarget, actualTarget },
        buffId = 880001,
    }, 1)
    assert_true(evt.targets ~= nil and #evt.targets == 1, "Timeline frame prefers resolved targets and dedupes ids")
    assert_true((evt.targets[1] and evt.targets[1].id) == actualTarget.instanceId,
        "Timeline frame exposes only the actual affected target")
end

-- Test 1ab: Basic attack finish should track the actual intercepted target
do
    local BuildPassiveCommon = require("skills.build_passive_common")
    local hero = new_unit(1013, "BasicAtkHero", 10000, 200, 0)
    local selectedTarget = new_unit(2014, "SelectedBackline", 10000, 0, 0)
    local guardTarget = new_unit(2015, "GuardFrontline", 10000, 0, 0)
    local originalResolveProtectedDefender = BuildPassiveCommon.ResolveProtectedDefender
    hero.__energyCastStats = { successfulHits = 0, killCount = 0, didCrit = false }
    BuildPassiveCommon.ResolveProtectedDefender = function(defender)
        if defender == selectedTarget then
            return guardTarget, { guard = guardTarget }
        end
        return defender, nil
    end
    local ok, err = pcall(function()
        local totalDamage = BattleSkill.ExecuteDefaultAttackWithPassive(hero, { selectedTarget }, {
            skillId = 80005011,
            name = "远程基础攻击",
            skillType = E_SKILL_TYPE_NORMAL,
        })
        assert_true(totalDamage > 0, "Basic attack still deals damage after interception")
        assert_true(hero.__lastNormalAttackTarget == guardTarget, "Basic attack finish tracks intercepted defender")
    end)
    BuildPassiveCommon.ResolveProtectedDefender = originalResolveProtectedDefender
    if not ok then
        error(err)
    end
end

-- Test 1b: Spell-like multi-hit applies at most one status stack per cast
do
    local hero = new_unit(1003, "Tester_SpellDedupe", 10000, 200, 0)
    local target = new_unit(2003, "SpellDedupe_Target", 10000, 0, 0)
    local SkillTimeline = require("core.skill_timeline")
    local SkillTimelineCompiler = require("skills.skill_timeline_compiler")
    local skill = { skillId = 80007001, name = "火焰弹" }
    local timeline = SkillTimelineCompiler.Build(hero, { target }, skill, {
        id = 990001,
        frames = {
            { frame = 0, op = "cast", target = target },
            {
                frame = 12,
                op = "damage",
                target = target,
                tags = {
                    { tag = "apply_poison", phase = "post", param = { layers = 1 } },
                },
            },
            {
                frame = 24,
                op = "damage",
                target = target,
                tags = {
                    { tag = "apply_poison", phase = "post", param = { layers = 1 } },
                },
            },
        },
    })
    local ok, _ = SkillTimeline.Execute(hero, { target }, skill, timeline)
    assert_true(ok, "Spell multi-hit dedupe timeline execute ok")
    assert_true(BattleBuff.GetBuffStackNumBySubType(target, 850001) == 1,
        "Spell multi-hit adds poison only once per cast")
end

-- Test 1b9: Single-target spell should not spread status when resolvedTargets carries extras
do
    local BattleSkillStatus = require("skills.battle_skill_status")
    local hero = new_unit(1009, "Tester_SpellPrimary", 10000, 200, 0)
    local primaryTarget = new_unit(2009, "SpellPrimary", 10000, 0, 0)
    local extraTarget = new_unit(2010, "SpellExtra", 10000, 0, 0)
    local SkillTimeline = require("core.skill_timeline")
    local skill = { skillId = 80009001, name = "邪能冲击" }
    local skillLua = require("config.skill.skill_80009001")
    local timeline = skillLua.BuildTimeline(hero, { primaryTarget, extraTarget }, skill)
    local executed, _ = SkillTimeline.Execute(hero, { primaryTarget, extraTarget }, skill, timeline)
    assert_true(executed, "Single-target eldritch blast executes with polluted target list")
    assert_true(BattleBuff.GetBuff(primaryTarget, 890001) ~= nil, "Single-target spell applies mark to primary target")
    assert_true(BattleBuff.GetBuff(extraTarget, 890001) == nil, "Single-target spell does not spread mark to extra resolved target")
end

-- Test 1ba: Front protection should not buff the originally selected backline target
do
    local BuildPassiveCommon = require("skills.build_passive_common")
    local BattleSkillStatus = require("skills.battle_skill_status")
    local hero = new_unit(1005, "Tester_SpellProtect", 10000, 200, 0)
    local selectedTarget = new_unit(2005, "SelectedBackline", 10000, 0, 0)
    local guardTarget = new_unit(2006, "GuardFrontline", 10000, 0, 0)
    local originalResolveProtectedDefender = BuildPassiveCommon.ResolveProtectedDefender
    BuildPassiveCommon.ResolveProtectedDefender = function(defender)
        if defender == selectedTarget then
            return guardTarget, { guard = guardTarget }
        end
        return defender, nil
    end
    local ok, err = pcall(function()
        local SkillTimeline = require("core.skill_timeline")
        local skill = { skillId = 80008001, name = "寒霜射线" }
        local skillLua = require("config.skill.skill_80008001")
        local timeline = skillLua.BuildTimeline(hero, { selectedTarget }, skill)
        local executed, _ = SkillTimeline.Execute(hero, { selectedTarget }, skill, timeline)
        assert_true(executed, "Ice spell timeline executes with protection redirect")
        assert_true(BattleSkillStatus.HasSlow(guardTarget), "Protection redirect applies slow to actual defender")
        assert_true(not BattleSkillStatus.HasSlow(selectedTarget), "Protection redirect does not slow selected backline")
    end)
    BuildPassiveCommon.ResolveProtectedDefender = originalResolveProtectedDefender
    if not ok then
        error(err)
    end
end

-- Test 1bb: Multi-target spell frame should only apply status to actually hit enemies
do
    local SkillEffectRegistry = require("skills.skill_effect_registry")
    local BattleSkillStatus = require("skills.battle_skill_status")
    local hero = new_unit(1006, "Tester_SpellMulti", 10000, 200, 0)
    local hitTarget = new_unit(2007, "SpellHitTarget", 10000, 0, 0)
    local missTarget = new_unit(2008, "SpellMissTarget", 10000, 0, 0)
    local burnHandler = SkillEffectRegistry.handlers["apply_burn_refresh_only"]
    local ctx = { hero = hero, skill = { skillId = 80007001, name = "火焰弹" } }
    burnHandler(ctx, {
        targets = { hitTarget, missTarget },
        damage = 8,
        __hitMetaByTarget = {
            [hitTarget.instanceId] = { hit = { hit = true }, damage = 8 },
            [missTarget.instanceId] = { hit = { hit = false }, damage = 0 },
        },
    }, "post", { param = { turns = 2 } })
    assert_true(BattleBuff.GetBuff(hitTarget, 870001) ~= nil, "Multi-target spell applies burn only to hit enemy")
    assert_true(BattleBuff.GetBuff(missTarget, 870001) == nil, "Multi-target spell skips missed enemy even when frame damage > 0")
end

-- Test 1c: Save-success spell with zero damage still publishes MISS + save metadata
do
    local hero = new_unit(1004, "Tester_SpellSave", 10000, 200, 0)
    hero.spellDC = 10
    local target = new_unit(2004, "SpellSave_Target", 10000, 0, 0)
    target.saveWill = 1000
    local SkillTimeline = require("core.skill_timeline")
    local SkillTimelineCompiler = require("skills.skill_timeline_compiler")
    local missEvent = nil
    local missListener = function(evt)
        if evt and evt.skillId == 80006011 then
            missEvent = evt
        end
    end
    BattleEvent.AddListener(BattleVisualEvents.MISS, missListener)
    local skill = { skillId = 80006011, name = "神圣火花" }
    local timeline = SkillTimelineCompiler.Build(hero, { target }, skill, {
        id = 990002,
        frames = {
            { frame = 0, op = "cast", target = target },
            {
                frame = 12,
                op = "damage",
                target = target,
                onSaveSuccess = "none",
            },
        },
    })
    local ok, result = SkillTimeline.Execute(hero, { target }, skill, timeline)
    assert_true(ok, "Spell zero-damage-on-save timeline execute ok")
    assert_true(target.hp == target.maxHp, "Successful save with no damage keeps HP unchanged")
    assert_true((result and result.totalDamage or 0) == 0, "Successful save with no damage keeps totalDamage zero")
    assert_true(missEvent ~= nil, "Successful save with no damage publishes MISS")
    assert_true(missEvent.saveRoll ~= nil and missEvent.saveRoll.success == true,
        "Successful save MISS carries save roll metadata")
    BattleEvent.RemoveListener(BattleVisualEvents.MISS, missListener)
end

-- Test 1d: Fire Bolt tier 3 damage event carries staged dice
do
    local damageEvent = nil
    local damageListener = function(evt)
        if evt and evt.skillId == 80007001 then
            damageEvent = evt
        end
    end
    BattleEvent.AddListener(BattleVisualEvents.DAMAGE_DEALT, damageListener)
    local hero = new_unit(1005, "Tester_Fire_T3", 10000, 200, 0)
    local target = new_unit(2005, "Dummy_Target_T3", 10000, 0, 0)
    local skillLua = require("config.skill.skill_80007001")
    local skill = { skillId = 80007001, name = "火焰弹", level = 3 }
    local timeline = skillLua.BuildTimeline(hero, { target }, skill)
    local SkillTimeline = require("core.skill_timeline")
    local ok = SkillTimeline.Execute(hero, { target }, skill, timeline)
    assert_true(ok, "Fire Bolt tier3 timeline execute ok")
    assert_true(damageEvent ~= nil and damageEvent.damageRoll ~= nil, "Fire Bolt tier3 publishes damage roll")
    assert_true(damageEvent.damageRoll.expr == "1d10+2", "Fire Bolt tier3 damage roll uses staged dice")
    BattleEvent.RemoveListener(BattleVisualEvents.DAMAGE_DEALT, damageListener)
end

-- Test 2: Ice Arrow applies frost buff (80008001)
do
    local hero = new_unit(1101, "Tester_Ice", 10000, 200, 0)
    local target = new_unit(2101, "Frozen_Target", 10000, 0, 0)
    local skillLua = require("config.skill.skill_80008001")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80008001, name = "冰箭术" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { target }, { skillId = 80008001, name = "冰箭术" }, timeline)
    assert_true(ok, "IceArrow timeline execute ok")
    assert_true(BattleBuff.GetBuff(target, 880001) ~= nil, "IceArrow applies slow buff")
end

-- Test 3: Frost Nova freezes slowed targets and slows fresh targets (80008003)
do
    local hero = new_unit(1102, "Tester_FrostNova", 10000, 200, 0)
    local frozenTarget = new_unit(2102, "Nova_FrozenTarget", 10000, 0, 0)
    local BattleSkillStatus = require("skills.battle_skill_status")
    BattleSkillStatus.ApplySlow(frozenTarget, 2, hero)
    local skillLua = require("config.skill.skill_80008003")
    local timeline = skillLua.BuildTimeline(hero, { frozenTarget }, { skillId = 80008003, name = "冰霜新星" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { frozenTarget }, { skillId = 80008003, name = "冰霜新星" }, timeline)
    assert_true(ok, "FrostNova timeline execute ok")
    assert_true(BattleBuff.GetBuffBySubType(frozenTarget, E_BUFF_SPEC_SUBTYPE.Frozen) ~= nil, "FrostNova freezes pre-slowed target")
    local canAct = BattleSkill.ProcessTurnStartStatus(frozenTarget)
    assert_true(canAct == false, "Frozen target skips action on turn start")

    local freshTarget = new_unit(2103, "Nova_FreshTarget", 10000, 0, 0)
    local freshTimeline = skillLua.BuildTimeline(hero, { freshTarget }, { skillId = 80008003, name = "冰霜新星" })
    local freshOk, _ = SkillTimeline.Execute(hero, { freshTarget }, { skillId = 80008003, name = "冰霜新星" }, freshTimeline)
    assert_true(freshOk, "FrostNova fresh-target timeline execute ok")
    assert_true(BattleBuff.GetBuff(freshTarget, 880001) ~= nil, "FrostNova applies slow to fresh target")
end

-- Test 5: Chain Lightning hits current target and one extra target (80009003)
do
    local hero = new_unit(1301, "Tester_Thunder", 10000, 200, 0)
    local e1 = new_unit(2301, "CL_1", 10000, 0, 0)
    local e2 = new_unit(2302, "CL_2", 10000, 0, 0)
    local e3 = new_unit(2303, "CL_3", 10000, 0, 0)
    local e4 = new_unit(2304, "CL_4", 10000, 0, 0)
    local BattleFormation = require("modules.battle_formation")
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    local oldSelectRandomAliveEnemies = BattleSkill.SelectRandomAliveEnemies
    local picks = { e1, e2, e3, e4 }
    local idx = 0
    BattleFormation.GetEnemyTeam = function(src)
        if src == hero then
            return { e1, e2, e3, e4 }
        end
        return oldGetEnemyTeam(src)
    end
    BattleSkill.SelectRandomAliveEnemies = function(src, count)
        idx = idx + 1
        local picked = picks[idx]
        if picked and not picked.isDead then
            return { picked }
        end
        return {}
    end
    local frameHits = 0
    BattleEvent.AddListener(BattleVisualEvents.SKILL_TIMELINE_FRAME, function(evt)
        -- Count chain arcs, not damage numbers (damage may be reduced by save rules).
        if evt.skillId == 80009003 and evt.op == "chain_damage" then
            frameHits = frameHits + 1
        end
    end)
    local skillLua = require("config.skill.skill_80009003")
    local timeline = skillLua.BuildTimeline(hero, { e1, e2, e3, e4 }, { skillId = 80009003, name = "连锁闪电" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { e1, e2, e3, e4 }, { skillId = 80009003, name = "连锁闪电" }, timeline)
    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    BattleSkill.SelectRandomAliveEnemies = oldSelectRandomAliveEnemies
    assert_true(ok, "ChainLightning timeline execute ok")
    assert_true(frameHits == 2, "ChainLightning deals 2 jumps")
end

-- Test 8b: Combo master raises combo rate through unified passive framework (80003002)
do
    local hero = new_unit(1602, "Tester_ComboPassive", 10000, 200, 0)
    local comboPassive = PassiveHandlers.Create(80003002, { src = hero })
    comboPassive:OnBattleBegin({})
    local oldRandom = math.random
    math.random = function(a, b)
        return 4000
    end
    local triggered = BattleSkill.ProcessComboEffect(hero, {}, { skillParam = { 10000, 2500 } })
    math.random = oldRandom
    assert_true(triggered == 1, "ComboMaster upgrades 25% combo rate to 50% in unified passive framework")
end

-- Test 8c: Ice affinity writes unified passive runtime and blizzard can still apply slow (80008002)
do
    local hero = new_unit(1603, "Tester_IcePassive", 10000, 200, 0)
    local target = new_unit(2603, "Ice_Target", 10000, 0, 0)
    local icePassive = PassiveHandlers.Create(80008002, { src = hero })
    icePassive:OnBattleBegin({})
    assert_true((hero.passiveRuntime or {}).iceDamageBonusPct == 1000, "IceAffinity writes damage bonus runtime state")
    assert_true((hero.passiveRuntime or {}).iceFreezeChanceBonus == 1000, "IceAffinity writes freeze chance runtime state")
    assert_true(BattleSkill.GetPassiveAdjustedChance(hero, 5000, "iceFreezeChanceBonus") == 6000, "IceAffinity increases freeze chance by 10%")

    local oldRandom = math.random
    local BattleSkillStatus = require("skills.battle_skill_status")
    local oldApplySlow = BattleSkillStatus.ApplySlow
    local oldSelectAllAliveTargets = BattleSkill.SelectAllAliveTargets
    local slowTriggered = false
    math.random = function(a, b)
        -- Only force the 1..10000 roll used by chance checks. Keep dice rolls sane.
        if b == 10000 then
            return 4400
        end
        return math.floor((a + b) / 2)
    end
    BattleSkill.SelectAllAliveTargets = function(src)
        return { target }
    end
    BattleSkillStatus.ApplySlow = function(dst, turns, caster)
        slowTriggered = true
    end
    local blizzard = require("config.skill.skill_80008004")
    local blizzardTimeline = blizzard.BuildTimeline(hero, { target }, { skillId = 80008004, name = "暴风雪" })
    local SkillTimeline = require("core.skill_timeline")
    SkillTimeline.Execute(hero, { target }, { skillId = 80008004, name = "暴风雪" }, blizzardTimeline)
    BattleSkill.SelectAllAliveTargets = oldSelectAllAliveTargets
    BattleSkillStatus.ApplySlow = oldApplySlow
    math.random = oldRandom
    assert_true(slowTriggered == true, "Blizzard applies slow through settlement")
end

-- Test 8d: Warlock core marks target with static mark (80009002)
do
    local hero = new_unit(1604, "Tester_ThunderPassive", 10000, 200, 0)
    local target = new_unit(2604, "Thunder_Target", 10000, 0, 0)
    local lightningArrow = require("config.skill.skill_80009001")
    local lightningTimeline = lightningArrow.BuildTimeline(hero, { target }, { skillId = 80009001, name = "闪电箭" })
    local SkillTimeline = require("core.skill_timeline")
    SkillTimeline.Execute(hero, { target }, { skillId = 80009001, name = "闪电箭" }, lightningTimeline)
    assert_true(BattleBuff.GetBuff(target, 890001) ~= nil, "Eldritch Blast applies static mark")
end

-- Test 13: Fire Affinity extends Flame Storm burn duration (80007004 + 870002)
do
    local hero = new_unit(2101, "Tester_Meteor", 10000, 250, 0)
    local e1 = new_unit(3101, "Meteor_1", 10000, 0, 0)
    local e2 = new_unit(3102, "Meteor_2", 10000, 0, 0)
    local e3 = new_unit(3103, "Meteor_3", 10000, 0, 0)
    local BattleFormation = require("modules.battle_formation")
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    BattleFormation.GetEnemyTeam = function(src)
        if src == hero then
            return { e1, e2, e3 }
        end
        return oldGetEnemyTeam(src)
    end
    BattleSkill.ApplyBuffFromSkill(hero, hero, 870002, nil)
    local skillLua = require("config.skill.skill_80007004")
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { e1, e2, e3 }, { skillId = 80007004, name = "陨石术" }, skillLua.BuildTimeline(hero, { e1, e2, e3 }, { skillId = 80007004, name = "陨石术" }))
    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    assert_true(ok, "Meteor timeline execute ok")
    for _, enemy in ipairs({ e1, e2, e3 }) do
        local burn = BattleBuff.GetBuff(enemy, 870001)
        assert_true(enemy.hp < enemy.maxHp, "Meteor damages all enemies: " .. enemy.name)
        assert_true(burn and burn.stackCount == 1, "Flame Storm applies one refreshed burn stack: " .. enemy.name)
        assert_true(burn and burn.duration == 4, "FireAffinity extends flame storm burn to 4 turns: " .. enemy.name)
    end
end

log("All timeline & passive assertions passed.")
os.exit(0)
