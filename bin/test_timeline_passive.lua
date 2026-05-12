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

local BattleEnum = require("core.battle_enum")
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

-- Test 1: Timeline frames for Fireball (80007001)
do
    local frames = 0
    BattleEvent.AddListener(BattleVisualEvents.SKILL_TIMELINE_FRAME, function(evt)
        frames = frames + 1
    end)
    local hero = new_unit(1001, "Tester_Fire", 10000, 200, 0)
    local target = new_unit(2001, "Dummy_Target", 10000, 0, 0)
    local skillLua = require("config.skill.skill_80007001")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80007001, name = "火球术" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, result = SkillTimeline.Execute(hero, { target }, { skillId = 80007001, name = "火球术" }, timeline)
    assert_true(ok, "Fireball timeline execute ok")
    assert_true(frames == 3, "Fireball frame count == 3 (cast, projectile, damage)")
end

-- Test 2: Ice Arrow applies slow buff (80008001)
do
    local hero = new_unit(1101, "Tester_Ice", 10000, 200, 0)
    local target = new_unit(2101, "Frozen_Target", 10000, 0, 0)
    local skillLua = require("config.skill.skill_80008001")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80008001, name = "冰箭术" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { target }, { skillId = 80008001, name = "冰箭术" }, timeline)
    assert_true(ok, "IceArrow timeline execute ok")
    assert_true(BattleBuff.GetBuffValueBySubType(target, 880001) == 3000, "IceArrow applies slow 3000")
end

-- Test 3: Frost Nova freezes and target skips action (80008003)
do
    local hero = new_unit(1102, "Tester_FrostNova", 10000, 200, 0)
    local target = new_unit(2102, "Nova_Target", 10000, 0, 0)
    local BattleFormation = require("modules.battle_formation")
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    BattleSkill.ApplyFreeze(target, 0, 3000, hero)
    BattleFormation.GetEnemyTeam = function(src)
        if src == hero then
            return { target }
        end
        return oldGetEnemyTeam(src)
    end
    local skillLua = require("config.skill.skill_80008003")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80008003, name = "冰霜新星" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { target }, { skillId = 80008003, name = "冰霜新星" }, timeline)
    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    assert_true(ok, "FrostNova timeline execute ok")
    local canAct = BattleSkill.ProcessTurnStartStatus(target)
    assert_true(canAct == false, "Frozen target skips action on turn start")
end

-- Test 4: Counter Stance triggers on hit (80002003 -> 820002)
do
    local Tank = new_unit(1201, "Tester_Tank", 12000, 150, 50)
    local Attacker = new_unit(2201, "Tester_Orc", 12000, 200, 0)
    local war = PassiveHandlers.Create(80002002, { src = Tank })
    -- Apply Counter Stance via skill API
    BattleSkill.ApplyBuffFromSkill(Tank, Tank, 820002, { skillId = 80002003 })
    -- Simulate being attacked
    local extra = { damage = 2000, attacker = Attacker }
    war:OnDefBeforeDmg({ data = { extraParam = extra } })
    -- Expect counter stance consumed once and attacker took damage
    local BattleBuffMod = require("modules.battle_buff")
    local stance = BattleBuffMod.GetBuffBySubType(Tank, 820002)
    assert_true(stance == nil, "Counter stance consumed after trigger")
    assert_true(Attacker.hp < Attacker.maxHp, "Attacker took counter damage")
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

-- Test 6: Poison Burst consumes poison stacks (80005004)
do
    local hero = new_unit(1401, "Tester_Poison", 10000, 200, 0)
    local target = new_unit(2401, "Poison_Target", 12000, 0, 0)
    local BattleFormation = require("modules.battle_formation")
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    BattleFormation.GetEnemyTeam = function(src)
        if src == hero then
            return { target }
        end
        return oldGetEnemyTeam(src)
    end
    BattleSkill.ApplyPoison(target, 3, hero)
    assert_true(BattleBuff.GetBuffStackNumBySubType(target, 850001) == 3, "Poison applied 3 stacks before burst")
    local skillLua = require("config.skill.skill_80005004")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80005004, name = "毒性爆发" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { target }, { skillId = 80005004, name = "毒性爆发" }, timeline)
    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    assert_true(ok, "PoisonBurst timeline execute ok")
    assert_true(BattleBuff.GetBuffStackNumBySubType(target, 850001) == 0, "PoisonBurst clears poison stacks")
    assert_true(target.hp < target.maxHp, "PoisonBurst deals damage")
end

-- Test 7: Cleric ultimate revives latest dead ally with penalty (80006004)
do
    local hero = new_unit(1501, "Tester_Holy", 10000, 200, 0)
    hero.isLeft = true
    local ally = new_unit(1502, "Holy_Ally", 10000, 0, 0)
    ally.isLeft = true
    local BattleAttribute = require("modules.battle_attribute")
    BattleAttribute.SetHpByVal(ally, 0)
    local BattleFormation = require("modules.battle_formation")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function(src)
        if src == hero then
            return { hero, ally }
        end
        return oldGetFriendTeam(src)
    end
    BattleSkill.ApplyPoison(ally, 2, hero)
    BattleSkill.ApplyFreeze(ally, 2, 3000, hero)
    assert_true(BattleBuff.GetBuffStackNumBySubType(ally, 850001) > 0, "Holy target has poison before cleanse")
    local skillLua = require("config.skill.skill_80006004")
    local timeline = skillLua.BuildTimeline(hero, { ally }, { skillId = 80006004, name = "复苏祷言" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { ally }, { skillId = 80006004, name = "复苏祷言" }, timeline)
    BattleFormation.GetFriendTeam = oldGetFriendTeam
    assert_true(ok, "RevivePrayer timeline execute ok")
    assert_true(ally.isAlive and not ally.isDead, "RevivePrayer revives ally")
    assert_true(ally.hp == 2000, "RevivePrayer restores ally to 20% max hp")
    assert_true(BattleBuff.GetBuffStackNumBySubType(ally, 850001) > 0, "RevivePrayer does not auto-cleanse poison")
    assert_true(BattleBuff.IsHeroUnderControl(ally) == true, "RevivePrayer does not auto-remove control")
    assert_true(BattleSkill.ProcessTurnStartStatus(ally) == false, "Revived ally skips next action")
end

-- Test 8: Combo slash triggers extra small skill when combo effect returns 1 (80003001)
do
    local hero = new_unit(1601, "Tester_Combo", 10000, 200, 0)
    local target = new_unit(2601, "Combo_Target", 10000, 0, 0)
    local comboPassive = PassiveHandlers.Create(80003002, { src = hero })
    comboPassive:OnBattleBegin({})
    assert_true((hero.passiveRuntime or {}).comboMasterMinRate == 5000, "ComboMaster writes passive runtime state")
    local oldProcessComboEffect = BattleSkill.ProcessComboEffect
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local comboExtra = 0
    BattleSkill.ProcessComboEffect = function(src, targets, skill)
        return 1
    end
    BattleSkill.CastSmallSkill = function(src, dst)
        comboExtra = comboExtra + 1
        return true
    end
    local skillLua = require("config.skill.skill_80003001")
    local timeline = skillLua.BuildTimeline(hero, { target }, { skillId = 80003001, name = "连斩", skillParam = {10000, 2500} })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { target }, { skillId = 80003001, name = "连斩", skillParam = {10000, 2500} }, timeline)
    BattleSkill.ProcessComboEffect = oldProcessComboEffect
    BattleSkill.CastSmallSkill = oldCastSmallSkill
    assert_true(ok, "ComboSlash timeline execute ok")
    assert_true(comboExtra == 1, "ComboSlash triggers one extra small skill")
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

-- Test 8c: Ice affinity writes unified passive runtime and boosts freeze chance/damage (80008002)
do
    local hero = new_unit(1603, "Tester_IcePassive", 10000, 200, 0)
    local target = new_unit(2603, "Ice_Target", 10000, 0, 0)
    local icePassive = PassiveHandlers.Create(80008002, { src = hero })
    icePassive:OnBattleBegin({})
    assert_true((hero.passiveRuntime or {}).iceDamageBonusPct == 1000, "IceAffinity writes damage bonus runtime state")
    assert_true((hero.passiveRuntime or {}).iceFreezeChanceBonus == 1000, "IceAffinity writes freeze chance runtime state")
    assert_true(BattleSkill.GetPassiveAdjustedChance(hero, 5000, "iceFreezeChanceBonus") == 6000, "IceAffinity increases freeze chance by 10%")

    local oldRandom = math.random
    local oldApplyFreeze = BattleSkill.ApplyFreeze
    local oldSelectAllAliveTargets = BattleSkill.SelectAllAliveTargets
    local freezeTriggered = false
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
    BattleSkill.ApplyFreeze = function(dst, turns, slowPct, caster)
        freezeTriggered = true
    end
    local blizzard = require("config.skill.skill_80008004")
    local blizzardTimeline = blizzard.BuildTimeline(hero, { target }, { skillId = 80008004, name = "暴风雪" })
    local SkillTimeline = require("core.skill_timeline")
    SkillTimeline.Execute(hero, { target }, { skillId = 80008004, name = "暴风雪" }, blizzardTimeline)
    BattleSkill.SelectAllAliveTargets = oldSelectAllAliveTargets
    BattleSkill.ApplyFreeze = oldApplyFreeze
    math.random = oldRandom
    assert_true(freezeTriggered == true, "IceAffinity makes 44% roll trigger Blizzard freeze")
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

-- Test 9: Pursuit attacks a second target after kill (80001003)
do
    local hero = new_unit(1701, "Tester_Pursuit", 10000, 300, 0)
    hero.skills = {
        { skillType = E_SKILL_TYPE_NORMAL, skillId = 80001001, name = "刺击" },
        { skillType = E_SKILL_TYPE_PASSIVE, skillId = 80001002, name = "追击" },
    }
    local low = new_unit(2701, "Low_Target", 10000, 0, 0)
    low.hp = 1
    local nextTarget = new_unit(2702, "Next_Target", 10000, 0, 0)
    local BattleFormation = require("modules.battle_formation")
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local pursuitTarget = nil
    BattleFormation.GetEnemyTeam = function(src)
        if src == hero then
            return { low, nextTarget }
        end
        return oldGetEnemyTeam(src)
    end
    BattleSkill.CastSmallSkill = function(src, dst)
        pursuitTarget = dst
        dst.hp = math.max(0, dst.hp - 1)
        return true
    end
    local skillLua = require("config.skill.skill_80001003")
    local timeline = skillLua.BuildTimeline(hero, { low }, { skillId = 80001003, name = "斩杀" })
    local SkillTimeline = require("core.skill_timeline")
    local ok, _ = SkillTimeline.Execute(hero, { low }, { skillId = 80001003, name = "斩杀" }, timeline)
    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    BattleSkill.CastSmallSkill = oldCastSmallSkill
    assert_true(ok, "Pursuit timeline execute ok")
    assert_true(low.isDead == true, "Pursuit primary target is killed")
    assert_true(pursuitTarget == nextTarget, "Pursuit selects second target")
    assert_true(nextTarget.hp < nextTarget.maxHp, "Pursuit triggers follow-up attack")
end

-- Test 10: Fighter rebuilt skills keep single-target semantics (80002001/80002004)
do
    local tank = new_unit(1801, "Tester_Tankwall", 12000, 200, 50)
    local attacker = new_unit(2801, "Taunted_Enemy", 12000, 200, 0)
    local extraEnemy1 = new_unit(2802, "Whirlwind_Target_1", 12000, 150, 0)
    local extraEnemy2 = new_unit(2803, "Whirlwind_Target_2", 12000, 150, 0)
    local otherAlly = new_unit(1802, "Other_Ally", 12000, 100, 0)
    tank.isLeft = true
    otherAlly.isLeft = true
    attacker.isLeft = false
    extraEnemy1.isLeft = false
    extraEnemy2.isLeft = false
    local BattleFormation = require("modules.battle_formation")
    local oldSelectRandomAliveEnemies = BattleSkill.SelectRandomAliveEnemies
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    BattleFormation.GetEnemyTeam = function(src)
        if src == attacker then
            return { tank, otherAlly }
        elseif src == tank then
            return { attacker, extraEnemy1, extraEnemy2 }
        end
        return oldGetEnemyTeam(src)
    end
    local tauntSkill = require("config.skill.skill_80002001")
    local SkillTimeline = require("core.skill_timeline")
    local okTaunt, _ = SkillTimeline.Execute(tank, { attacker }, { skillId = 80002001, name = "基础武器攻击" }, tauntSkill.BuildTimeline(tank, { attacker }, { skillId = 80002001, name = "基础武器攻击" }))
    assert_true(okTaunt, "Basic attack timeline execute ok")
    assert_true(attacker.hp < attacker.maxHp, "Basic attack damages selected enemy")

    local wallSkill = require("config.skill.skill_80002004")
    BattleSkill.SelectRandomAliveEnemies = function(src, count)
        return { attacker, extraEnemy1, extraEnemy2 }
    end
    local beforePrimary = attacker.hp
    local okWall, _ = SkillTimeline.Execute(tank, { attacker }, { skillId = 80002004, name = "压制打击" }, wallSkill.BuildTimeline(tank, { attacker }, { skillId = 80002004, name = "压制打击" }))
    BattleSkill.SelectRandomAliveEnemies = oldSelectRandomAliveEnemies
    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    assert_true(okWall, "Pressure strike timeline execute ok")
    assert_true(attacker.hp < beforePrimary, "Pressure strike damages primary enemy")
    assert_true(extraEnemy1.hp == extraEnemy1.maxHp, "Pressure strike does not splash extra enemy 1")
    assert_true(extraEnemy2.hp == extraEnemy2.maxHp, "Pressure strike does not splash extra enemy 2")
end

-- Test 11: War Spirit stacks and Aura increases damage/heal (80004003/80004004)
do
    local hero = new_unit(1901, "Tester_War", 10000, 300, 100)
    local ally = new_unit(1902, "War_Ally", 10000, 150, 80)
    local enemy = new_unit(2901, "War_Dummy", 10000, 0, 0)
    hero.isLeft = true
    ally.isLeft = true
    enemy.isLeft = false
    local war = PassiveHandlers.Create(80004002, { src = hero })
    war:OnDmgMakeKill({})
    assert_true(BattleBuff.GetBuffStackNumBySubType(hero, 840001) == 1, "WarSpirit gains one stack after kill")

    local BattleFormation = require("modules.battle_formation")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function(src)
        if src == hero then
            return { hero, ally }
        end
        return oldGetFriendTeam(src)
    end

    math.randomseed(12345)
    local baseDamage = (BattleSkill.ResolveScaledDamage(hero, enemy, { meta = { kind = "physical", damageDice = "2d6+4" } }).damage) or 0
    local aura3 = require("config.skill.skill_80004003")
    local SkillTimeline = require("core.skill_timeline")
    SkillTimeline.Execute(hero, { ally }, { skillId = 80004003, name = "全军突击" }, aura3.BuildTimeline(hero, { ally }, { skillId = 80004003, name = "全军突击" }))
    assert_true(BattleBuff.GetBuffBySubType(hero, 840002) ~= nil, "WarCharge applies 840002 aura")
    assert_true(hero.__concentrationSkillId == 80004003, "WarCharge enters concentration")
    math.randomseed(12345)
    local auraDamage = (BattleSkill.ResolveScaledDamage(hero, enemy, { meta = { kind = "physical", damageDice = "2d6+4" } }).damage) or 0
    assert_true(auraDamage > baseDamage, "WarCharge increases damage")
    BattleSkill.OnDamagedInterrupt(hero, 999)
    assert_true(hero.__concentrationSkillId == nil, "Damage can break concentration")
    assert_true(BattleBuff.GetBuffBySubType(hero, 840002) == nil, "Concentration break removes WarCharge aura from caster")
    assert_true(BattleBuff.GetBuffBySubType(ally, 840002) == nil, "Concentration break removes WarCharge aura from ally")

    local aura4 = require("config.skill.skill_80004004")
    SkillTimeline.Execute(hero, { ally }, { skillId = 80004004, name = "战神降临" }, aura4.BuildTimeline(hero, { ally }, { skillId = 80004004, name = "战神降临" }))
    assert_true(BattleBuff.GetBuffBySubType(hero, 840003) ~= nil, "WarGod applies 840003 aura")
    assert_true(hero.__concentrationSkillId == 80004004, "WarGod refreshes concentration source")
    math.randomseed(54321)
    local baseHealHero = new_unit(1903, "Heal_NoAura", 10000, 300, 0)
    local healTarget = new_unit(1904, "Heal_Target", 10000, 0, 0)
    local baseHeal = BattleSkill.CalculateHealDice(baseHealHero, healTarget, "100d6+100")
    math.randomseed(54321)
    local auraHeal = BattleSkill.CalculateHealDice(hero, healTarget, "100d6+100")
    BattleFormation.GetFriendTeam = oldGetFriendTeam
    assert_true(auraHeal > baseHeal, "WarGod increases heal through aura and war spirit")
end

-- Test 12: Healing Word heals lowest ally only at tier 1 (80006003)
do
    local hero = new_unit(2001, "Tester_GroupHeal", 10000, 200, 0)
    local a1 = new_unit(2002, "Heal_A1", 10000, 0, 0)
    local a2 = new_unit(2003, "Heal_A2", 10000, 0, 0)
    local a3 = new_unit(2004, "Heal_A3", 10000, 0, 0)
    local a4 = new_unit(2005, "Heal_A4", 10000, 0, 0)
    a1.hp = 1000
    a2.hp = 2000
    a3.hp = 3000
    a4.hp = 9000
    local BattleFormation = require("modules.battle_formation")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function(src)
        if src == hero then
            return { hero, a1, a2, a3, a4 }
        end
        return oldGetFriendTeam(src)
    end
    local beforeA1, beforeA2, beforeA3, beforeA4 = a1.hp, a2.hp, a3.hp, a4.hp
    local skillLua = require("config.skill.skill_80006003")
    local SkillTimeline = require("core.skill_timeline")
    local skill = { skillId = 80006003, name = "Healing Word", level = 1 }
    local ok, _ = SkillTimeline.Execute(hero, { a1, a2, a3, a4 }, skill, skillLua.BuildTimeline(hero, { a1, a2, a3, a4 }, skill))
    BattleFormation.GetFriendTeam = oldGetFriendTeam
    assert_true(ok, "HealingWord timeline execute ok")
    assert_true(a1.hp > beforeA1, "HealingWord heals the lowest ally")
    assert_true(a2.hp == beforeA2, "HealingWord tier1 does not heal the second-lowest ally")
    assert_true(a3.hp == beforeA3, "HealingWord tier1 does not heal the third-lowest ally")
    assert_true(a4.hp == beforeA4, "HealingWord tier1 does not heal the healthiest ally")
end

-- Test 12b: Cleric passive empowers Healing Word and tier3 cleanses poison/burn (80006002 + 80006003)
do
    local hero = new_unit(2006, "Tester_Cleric", 10000, 200, 0)
    local a1 = new_unit(2007, "Heal_C1", 10000, 0, 0)
    local a2 = new_unit(2008, "Heal_C2", 10000, 0, 0)
    a1.hp = 1000
    a2.hp = 2000
    local passive = PassiveHandlers.Create(80006002, { src = hero })
    passive:OnBattleBegin({})
    assert_true((hero.passiveRuntime or {}).clericChannelReady == true, "Cleric passive writes channel-ready state at battle begin")
    BattleSkill.ApplyPoison(a1, 2, hero)
    BattleSkill.ApplyBurn(a1, 1, 2, hero)
    local BattleFormation = require("modules.battle_formation")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function(src)
        if src == hero then
            return { hero, a1, a2 }
        end
        return oldGetFriendTeam(src)
    end
    local beforeA1, beforeA2 = a1.hp, a2.hp
    local skillLua = require("config.skill.skill_80006003")
    local SkillTimeline = require("core.skill_timeline")
    local skill = { skillId = 80006003, name = "Healing Word", level = 3 }
    local ok, _ = SkillTimeline.Execute(hero, { a1, a2 }, skill, skillLua.BuildTimeline(hero, { a1, a2 }, skill))
    BattleFormation.GetFriendTeam = oldGetFriendTeam
    assert_true(ok, "HealingWord tier3 timeline execute ok")
    assert_true(a1.hp > beforeA1 and a2.hp > beforeA2, "HealingWord tier3 heals two allies")
    assert_true(BattleBuff.GetBuffStackNumBySubType(a1, 850001) == 0, "HealingWord tier3 cleanses poison")
    assert_true(BattleBuff.GetBuffStackNumBySubType(a1, 870001) == 0, "HealingWord tier3 cleanses burn")
    assert_true((hero.passiveRuntime or {}).clericChannelReady == false, "HealingWord consumes channel-ready state")
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
