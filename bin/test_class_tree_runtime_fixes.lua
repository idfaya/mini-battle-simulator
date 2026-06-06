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

require("core.battle_enum")
local BattleEvent = require("core.battle_event")
local BattleBuff = require("modules.battle_buff")
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local PassiveHandlers = require("modules.passive_handlers")
local BuildPassiveCommon = require("skills.build_passive_common")
local MonkBuildPassives = require("skills.monk_build_passives")
local RogueBuildPassives = require("skills.rogue_build_passives")
local RangerBuildPassives = require("skills.ranger_build_passives")
local PaladinBuildPassives = require("skills.paladin_build_passives")
local SkillEffectRegistry = require("skills.skill_effect_registry")
local BattleSkillStatus = require("skills.battle_skill_status")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local ClassesTable = require("config.tables.classes")
local FeatBuildConfig = require("config.tables.feats")
local HeroBuild = require("modules.hero_build")
local skill_80009003 = require("config.skill.skill_80009003")
local BattleLogic = require("modules.battle_logic")

local IDS = SkillRuntimeConfig.Ids

local function new_unit(id, name, isLeft, wpType)
    return {
        id = id,
        instanceId = id,
        name = name,
        level = 5,
        class = 1,
        classId = 1,
        isDead = false,
        isAlive = true,
        isLeft = isLeft ~= false,
        hp = 100,
        maxHp = 100,
        ac = 14,
        hit = 6,
        spellAttack = 6,
        spellDC = 14,
        wpType = wpType or 1,
        skills = {},
        skillData = { skillInstances = {} },
        passiveRuntime = {},
        buildState = { skillMods = {}, classMods = {} },
    }
end

BattleEvent.Init()
BattleBuff.Init()

do
    BattleFormation.OnFinal()
    local monk = new_unit(101, "RuntimeMonk", true, 4)
    local target = new_unit(102, "BackDummy", false, 4)
    monk.class = 3
    monk.classId = 3
    monk.buildState.skillMods[IDS.monk_martial_arts] = {
        firstHitGuaranteedCombo = true,
    }
    local passive = MonkBuildPassives.CreateMartialArtsPassive({ src = monk })
    local oldRandom = math.random
    local oldCast = BattleSkill.CastSmallSkillWithResult
    local comboCalls = 0
    math.random = function() return 6000 end
    BattleSkill.CastSmallSkillWithResult = function()
        comboCalls = comboCalls + 1
        return true, { totalDamage = 5 }
    end
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                skillId = IDS.monk_basic_attack,
                target = target,
                damageDealt = 5,
            },
        },
    })
    math.random = oldRandom
    BattleSkill.CastSmallSkillWithResult = oldCast
    assert_true(comboCalls == 1, "monk first unarmed strike always triggers flurry")

    local BattleBuff = require("modules.battle_buff")
    local oldHasControlBuff = BattleBuff.HasControlBuff
    monk.buildState.skillMods[IDS.monk_basic_attack] = { sneakAttackImmune = true }
    BattleBuff.HasControlBuff = function() return false end
    assert_true(MonkBuildPassives.HasSneakAttackImmunity(monk) == true, "monk gale step passively grants sneak immunity while not incapacitated")
    BattleBuff.HasControlBuff = function() return true end
    assert_true(MonkBuildPassives.HasSneakAttackImmunity(monk) == false, "monk gale step stops working while incapacitated")
    BattleBuff.HasControlBuff = oldHasControlBuff

    monk.passiveRuntime = {}
    local guaranteedCalls = 0
    math.random = function() return 10000 end
    BattleSkill.CastSmallSkillWithResult = function()
        guaranteedCalls = guaranteedCalls + 1
        return true, { totalDamage = 5 }
    end
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                skillId = IDS.monk_basic_attack,
                target = target,
                damageDealt = 5,
            },
        },
    })
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                skillId = IDS.monk_basic_attack,
                target = target,
                damageDealt = 5,
            },
        },
    })
    assert_true(guaranteedCalls == 1, "monk first hit guaranteed combo bypasses chance only once per round")

    monk.passiveRuntime = {}
    local missGuaranteedCalls = 0
    math.random = function() return 10000 end
    BattleSkill.CastSmallSkillWithResult = function()
        missGuaranteedCalls = missGuaranteedCalls + 1
        return true, { totalDamage = 0 }
    end
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                skillId = IDS.monk_basic_attack,
                target = target,
                damageDealt = 0,
            },
        },
    })
    assert_true(missGuaranteedCalls == 1, "monk first hit guaranteed combo triggers even when unarmed strike misses")

    local nonFirstCalls = 0
    math.random = function() return 1 end
    BattleSkill.CastSmallSkillWithResult = function()
        nonFirstCalls = nonFirstCalls + 1
        return true, { totalDamage = 5 }
    end
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                skillId = IDS.monk_basic_attack,
                target = target,
                damageDealt = 5,
            },
        },
    })
    math.random = oldRandom
    BattleSkill.CastSmallSkillWithResult = oldCast
    assert_true(nonFirstCalls == 0, "monk non-first unarmed strike never triggers flurry")
end

do
    local monk = new_unit(106, "UnarmedMonk", true, 4)
    local target = new_unit(107, "DiceDummy", false, 1)
    monk.class = 3
    monk.classId = 3
    monk.hit = 99
    target.ac = 0
    assert_true(ClassesTable.GetWeaponDice(3) == "1d6", "monk baseline unarmed strike is 1d6")

    local baseResult = BattleSkill.ResolveScaledDamage(monk, target, {
        skill = { skillId = IDS.monk_basic_attack },
        meta = { kind = "physical" },
    })
    assert_true(baseResult.damageRoll and baseResult.damageRoll.expr == "1d6", "monk basic attack rolls baseline 1d6")

    local adeptBuild = HeroBuild.CompileBuild(3, 5, { FeatBuildConfig.Ids.b_monk_combo_plus })
    monk.buildState = adeptBuild
    local adeptResult = BattleSkill.ResolveScaledDamage(monk, target, {
        skill = { skillId = IDS.monk_basic_attack },
        meta = { kind = "physical" },
    })
    assert_true(adeptResult.damageRoll and adeptResult.damageRoll.expr == "1d8", "monk Lv5 unarmed feat upgrades strike to 1d8")

    local masterBuild = HeroBuild.CompileBuild(3, 10, {
        FeatBuildConfig.Ids.b_monk_combo_plus,
        FeatBuildConfig.Ids.j_monk_combo_master,
    })
    monk.buildState = masterBuild
    local masterResult = BattleSkill.ResolveScaledDamage(monk, target, {
        skill = { skillId = IDS.monk_basic_attack },
        meta = { kind = "physical" },
    })
    assert_true(masterResult.damageRoll and masterResult.damageRoll.expr == "1d10", "monk Lv10 unarmed feat upgrades strike to 1d10")

    local coreBuild = HeroBuild.CompileBuild(3, 1, {})
    assert_true(coreBuild.skillMods[IDS.monk_martial_arts]
        and coreBuild.skillMods[IDS.monk_martial_arts].firstHitGuaranteedCombo == true,
        "monk starts with first-hit guaranteed flurry")
end

do
    local monk = new_unit(111, "DefenseMonk", true, 4)
    monk.class = 3
    monk.classId = 3
    monk.buildState.skillMods[IDS.monk_martial_arts] = {
        deflectAttackFlat = 3,
        deflectSpellFlat = 4,
        flawlessFirstHitImmune = true,
    }
    local passive = MonkBuildPassives.CreateMartialArtsPassive({ src = monk })
    local oldGetCurRound = BattleLogic.GetCurRound
    BattleLogic.GetCurRound = function() return 1 end
    local hitOne = { damage = 12, damageKind = "fire" }
    passive:OnDefBeforeDmg({ data = { extraParam = hitOne } })
    assert_true(hitOne.damage == 0, "monk flawless defense negates first damage each round")
    local hitTwo = { damage = 12, damageKind = "fire" }
    passive:OnDefBeforeDmg({ data = { extraParam = hitTwo } })
    assert_true(hitTwo.damage == 8, "monk deflect energy reduces spell damage")
    local hitThree = { damage = 12, damageKind = "physical" }
    passive:OnDefBeforeDmg({ data = { extraParam = hitThree } })
    assert_true(hitThree.damage == 9, "monk deflect attack reduces physical damage")
    BattleLogic.GetCurRound = function() return 2 end
    local hitFour = { damage = 7, damageKind = "physical" }
    passive:OnDefBeforeDmg({ data = { extraParam = hitFour } })
    assert_true(hitFour.damage == 0, "monk flawless defense refreshes next round")
    BattleLogic.GetCurRound = oldGetCurRound
end

do
    local monk = new_unit(118, "HarmonizeMonk", true, 4)
    monk.class = 3
    monk.classId = 3
    monk.hp = 40
    monk.maxHp = 100
    local oldRollDice = BuildPassiveCommon.RollDice
    local oldDelBuffBySubType = BattleBuff.DelBuffBySubType
    local cleared = 0
    BuildPassiveCommon.RollDice = function() return 11 end
    BattleBuff.DelBuffBySubType = function()
        cleared = cleared + 1
        return 1
    end
    monk.buildState.skillMods[IDS.monk_harmonize] = {
        healDiceOverride = "2d8+3",
    }
    local healed = MonkBuildPassives.PerformHarmonize(monk, { skillId = IDS.monk_harmonize })
    assert_true(healed == 11 and monk.hp == 51, "monk base harmonize only heals")
    assert_true(cleared == 0, "monk base harmonize does not clear debuffs")
    monk.buildState.skillMods[IDS.monk_harmonize].clearDebuffs = true
    MonkBuildPassives.PerformHarmonize(monk, { skillId = IDS.monk_harmonize })
    assert_true(cleared == 3, "monk harmonize training clears three control debuffs")
    BuildPassiveCommon.RollDice = oldRollDice
    BattleBuff.DelBuffBySubType = oldDelBuffBySubType
end

do
    local rogue = new_unit(119, "SneakRogue", true, 1)
    local monk = new_unit(120, "GuardMonk", false, 1)
    rogue.class = 1
    rogue.classId = 1
    monk.class = 3
    monk.classId = 3
    rogue.buildState.skillMods[IDS.rogue_sneak_attack] = {}
    monk.buildState.skillMods[IDS.monk_basic_attack] = { sneakAttackImmune = true }
    local passive = RogueBuildPassives.CreateSneakAttackPassive({ src = rogue })
    local oldApply = BuildPassiveCommon.ApplyDirectBonusDamage
    local calls = 0
    BuildPassiveCommon.ApplyDirectBonusDamage = function()
        calls = calls + 1
        return 6
    end
    local oldHasControlBuff = BattleBuff.HasControlBuff
    BattleBuff.HasControlBuff = function(unit)
        return unit == monk and false or oldHasControlBuff(unit)
    end
    passive:OnNormalAtkFinish({
        data = { extraParam = { skillId = IDS.rogue_basic_attack, target = monk, damageDealt = 5 } },
    })
    assert_true(calls == 0, "rogue sneak attack is blocked by monk gale step immunity")
    BuildPassiveCommon.ApplyDirectBonusDamage = oldApply
    BattleBuff.HasControlBuff = oldHasControlBuff
end

do
    local function runSneakFinish(passive, target, damageDealt)
        local calls = 0
        local oldApply = BuildPassiveCommon.ApplyDirectBonusDamage
        BuildPassiveCommon.ApplyDirectBonusDamage = function()
            calls = calls + 1
            return 4
        end
        passive:OnNormalAtkFinish({
            data = {
                extraParam = {
                    skillId = IDS.rogue_basic_attack,
                    target = target,
                    damageDealt = damageDealt or 5,
                },
            },
        })
        BuildPassiveCommon.ApplyDirectBonusDamage = oldApply
        return calls
    end

    local function initRogueSneakHero(wpType, classMods)
        local hero = new_unit(301, "FlankRogue", true, wpType or 2)
        hero.class = 1
        hero.classId = 1
        hero.buildState.skillMods[IDS.rogue_sneak_attack] = classMods or {}
        return hero
    end

    BattleFormation.OnFinal()
    local rogue = initRogueSneakHero()
    local farAlly = new_unit(302, "FarAlly", true, 1)
    local farEnemy = new_unit(304, "FarEnemy", false, 3)
    BattleFormation.Init({
        teamLeft = { rogue, farAlly },
        teamRight = { farEnemy },
    })
    rogue = BattleFormation.FindHeroByCampAndPos(true, 2)
    farEnemy = BattleFormation.FindHeroByCampAndPos(false, 3)

    local passive = RogueBuildPassives.CreateSneakAttackPassive({ src = rogue })
    local oldGetCurRound = BattleLogic.GetCurRound
    BattleLogic.GetCurRound = function() return 2 end

    assert_true(
        runSneakFinish(passive, farEnemy) == 0,
        "rogue sneak flank requires an adjacent ally, not just two front-row allies")

    BattleFormation.OnFinal()
    rogue = initRogueSneakHero(3)
    local nearAlly = new_unit(303, "NearAlly", true, 1)
    local centerEnemy = new_unit(305, "CenterEnemy", false, 2)
    BattleFormation.Init({
        teamLeft = { rogue, nearAlly },
        teamRight = { centerEnemy },
    })
    rogue = BattleFormation.FindHeroByCampAndPos(true, 3)
    centerEnemy = BattleFormation.FindHeroByCampAndPos(false, 2)
    passive = RogueBuildPassives.CreateSneakAttackPassive({ src = rogue })
    assert_true(
        runSneakFinish(passive, centerEnemy) == 1,
        "rogue sneak flank triggers when another ally is adjacent to the target")

    BattleFormation.OnFinal()
    rogue = initRogueSneakHero()
    local distractVictim = new_unit(307, "DistractVictim", true, 4)
    local distractedEnemy = new_unit(306, "DistractedEnemy", false, 2)
    BattleFormation.Init({
        teamLeft = { rogue, distractVictim },
        teamRight = { distractedEnemy },
    })
    rogue = BattleFormation.FindHeroByCampAndPos(true, 2)
    distractedEnemy = BattleFormation.FindHeroByCampAndPos(false, 2)
    passive = RogueBuildPassives.CreateSneakAttackPassive({ src = rogue })
    distractedEnemy.passiveRuntime = distractedEnemy.passiveRuntime or {}
    distractedEnemy.passiveRuntime.lastAttackVictimId = distractVictim.instanceId
    distractedEnemy.passiveRuntime.lastAttackRound = 1
    assert_true(
        runSneakFinish(passive, distractedEnemy) == 0,
        "rogue sneak distracted only counts attacks from the current round")

    distractedEnemy.passiveRuntime.lastAttackRound = 2
    assert_true(
        runSneakFinish(passive, distractedEnemy) == 1,
        "rogue sneak distracted triggers when target attacked another unit this round")

    BattleLogic.GetCurRound = oldGetCurRound
end

do
    BattleFormation.OnFinal()
    local ranger = new_unit(201, "RuntimeRanger", true, 2)
    local enemyA = new_unit(202, "MarkedA", false, 1)
    local enemyB = new_unit(203, "MarkedB", false, 2)
    ranger.class = 5
    ranger.classId = 5
    ranger.buildState.skillMods[IDS.ranger_hunter_mark] = {
        markPayoutPerRound = 2,
        markBonusDice = "1d4",
    }
    BattleFormation.Init({
        teamLeft = { ranger },
        teamRight = { enemyA, enemyB },
    })
    RangerBuildPassives.ApplyHunterMark(ranger, enemyA)
    local markBuff = BattleBuff.GetBuff(enemyA, 890005)
    assert_true(markBuff ~= nil, "hunter mark buff should exist on marked target")
    assert_true((tonumber(markBuff.value) or 0) == 3,
        "hunter mark penalty stacks markBonusDice and markPayoutPerRound")
    assert_true(BuildPassiveCommon.GetDefenderAcBonus(enemyA, ranger) == -3,
        "hunter mark reduces target AC via defender bonus")
    assert_true(BuildPassiveCommon.GetDefenderSaveBonus(enemyA, "ref") == -3,
        "hunter mark reduces target reflex save bonus")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local ranger = new_unit(205, "HitMarkRanger", true, 2)
    local enemy = new_unit(206, "HitMarkEnemy", false, 1)
    ranger.class = 5
    ranger.classId = 5
    BattleFormation.Init({
        teamLeft = { ranger },
        teamRight = { enemy },
    })
    local passive = RangerBuildPassives.CreateHunterMarkPassive({ src = ranger })
    BuildPassiveCommon.AfterBasicAttackResolved(ranger, enemy, 0, { hit = { hit = true } })
    passive:OnNormalAtkFinish({
        data = { extraParam = { skillId = IDS.ranger_basic_attack, target = enemy, damageDealt = 0 } },
    })
    assert_true(BattleBuff.GetBuff(enemy, 890005) ~= nil,
        "hunter mark applies on hit even when final damage is 0")

    BattleBuff.DelBuffByBuffIdAndCaster(enemy, 890005, ranger)
    BuildPassiveCommon.AfterBasicAttackResolved(ranger, enemy, 0, { hit = { hit = false } })
    passive:OnNormalAtkFinish({
        data = { extraParam = { skillId = IDS.ranger_basic_attack, target = enemy, damageDealt = 0 } },
    })
    assert_true(BattleBuff.GetBuff(enemy, 890005) == nil,
        "hunter mark does not apply on miss")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local ranger = new_unit(211, "SlotRanger", true, 2)
    local enemyA = new_unit(212, "SlotA", false, 1)
    local enemyB = new_unit(213, "SlotB", false, 2)
    local enemyC = new_unit(214, "SlotC", false, 4)
    ranger.class = 5
    ranger.classId = 5
    ranger.buildState.skillMods[IDS.ranger_hunter_mark] = {
        markSlotMax = 1,
    }
    BattleFormation.Init({
        teamLeft = { ranger },
        teamRight = { enemyA, enemyB, enemyC },
    })
    local oldGetCurRound = BattleLogic.GetCurRound
    BattleLogic.GetCurRound = function() return 1 end
    RangerBuildPassives.ApplyHunterMark(ranger, enemyB)
    RangerBuildPassives.ApplyHunterMark(ranger, enemyA)
    RangerBuildPassives.ApplyHunterMark(ranger, enemyC)
    BattleLogic.GetCurRound = oldGetCurRound
    assert_true(not RangerBuildPassives.IsTargetMarkedBy(ranger, enemyB), "ranger mark slots evict the oldest applied mark first")
    assert_true(RangerBuildPassives.IsTargetMarkedBy(ranger, enemyA), "ranger mark slots keep newer applied mark when overflowing")
    assert_true(RangerBuildPassives.IsTargetMarkedBy(ranger, enemyC), "ranger mark slots keep the latest applied mark")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local paladin = new_unit(291, "MercyPaladin", true, 2)
    local ally = new_unit(292, "DebuffedAlly", true, 1)
    paladin.class = 4
    paladin.classId = 4
    ally.hp = 20
    ally.maxHp = 100
    BattleFormation.Init({
        teamLeft = { paladin, ally },
        teamRight = {},
    })
    BattleBuff.Add(paladin, ally, {
        buffId = 880005,
        name = "冻结",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = E_BUFF_SPEC_SUBTYPE.Frozen,
        duration = 2,
        canStack = false,
    })
    BattleBuff.Add(paladin, ally, {
        buffId = 850001,
        name = "中毒",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 850001,
        duration = 2,
        canStack = false,
    })
    local oldRollDice = BuildPassiveCommon.RollDice
    BuildPassiveCommon.RollDice = function(expr)
        if expr == "2d8+4" then
            return 9
        end
        return 0
    end
    PaladinBuildPassives.PerformLayOnHands(paladin, ally, { skillId = IDS.paladin_lay_on_hands, name = "圣疗" })
    local healedAlly = BattleFormation.FindHeroByInstanceId(ally.instanceId) or ally
    assert_true(BattleBuff.GetBuffBySubType(healedAlly, E_BUFF_SPEC_SUBTYPE.Frozen) ~= nil, "paladin base lay on hands no longer cleanses frozen")
    assert_true(BattleBuff.GetBuffBySubType(healedAlly, 850001) ~= nil, "paladin base lay on hands no longer cleanses poison")
    local runtimePaladin = BattleFormation.FindHeroByInstanceId(paladin.instanceId) or paladin
    runtimePaladin.buildState = runtimePaladin.buildState or { skillMods = {} }
    runtimePaladin.buildState.skillMods = runtimePaladin.buildState.skillMods or {}
    runtimePaladin.buildState.skillMods[IDS.paladin_lay_on_hands] = {
        cleanseDebuffs = true,
    }
    PaladinBuildPassives.PerformLayOnHands(runtimePaladin, ally, { skillId = IDS.paladin_lay_on_hands, name = "圣疗" })
    healedAlly = BattleFormation.FindHeroByInstanceId(ally.instanceId) or ally
    assert_true(BattleBuff.GetBuffBySubType(healedAlly, E_BUFF_SPEC_SUBTYPE.Frozen) == nil, "paladin lay on hands mastery cleanses frozen")
    assert_true(BattleBuff.GetBuffBySubType(healedAlly, 850001) == nil, "paladin lay on hands mastery cleanses poison")
    assert_true((tonumber(healedAlly.tempHp) or 0) == 0, "paladin lay on hands mastery no longer grants temp hp")
    BuildPassiveCommon.RollDice = oldRollDice
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local paladin = new_unit(301, "RuntimePaladin", true, 2)
    local mainTarget = new_unit(302, "SmiteMain", false, 1)
    local splashTarget = new_unit(303, "SmiteSplash", false, 2)
    paladin.class = 4
    paladin.classId = 4
    paladin.buildState.skillMods[IDS.paladin_vengeance_smite] = {
        onHitVulnerableDelta = 1,
        onHitVulnerableDuration = 1,
        splitAdjacentTargets = 2,
        splitBonusDice = "1d8",
    }
    BattleFormation.Init({
        teamLeft = { paladin },
        teamRight = { mainTarget, splashTarget },
    })
    local oldCast = BattleSkill.CastSmallSkillWithResult
    local oldApply = BuildPassiveCommon.ApplyDirectBonusDamage
    local castCalls = 0
    BattleSkill.CastSmallSkillWithResult = function()
        castCalls = castCalls + 1
        return true, { totalDamage = 6 }
    end
    BuildPassiveCommon.ApplyDirectBonusDamage = function()
        return 4
    end
    local damage = PaladinBuildPassives.PerformVengeanceSmite(paladin, mainTarget, { skillId = IDS.paladin_vengeance_smite, name = "破邪斩" })
    BattleSkill.CastSmallSkillWithResult = oldCast
    BuildPassiveCommon.ApplyDirectBonusDamage = oldApply
    assert_true(castCalls == 2, "paladin smite capstone adds one adjacent weapon strike")
    assert_true(damage == 20, "paladin smite totals main and adjacent split damage")
    local damageContext = { attacker = paladin, damage = 5 }
    PaladinBuildPassives.ApplyPaladinProtections(mainTarget, { damageContext = damageContext })
    assert_true(damageContext.damage == 6, "holy mark adds global vulnerable damage on next hit")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local paladin = new_unit(311, "HolyMarkPaladin", true, 2)
    local allyAttacker = new_unit(312, "OtherAttacker", true, 1)
    local target = new_unit(313, "HolyMarkTarget", false, 1)
    paladin.class = 4
    paladin.classId = 4
    paladin.buildState.skillMods[IDS.paladin_vengeance_smite] = {
        onHitVulnerableDelta = 1,
        onHitVulnerableDuration = 1,
    }
    local oldGetCurRound = BattleLogic.GetCurRound
    BattleLogic.GetCurRound = function() return 1 end
    local oldCast = BattleSkill.CastSmallSkillWithResult
    local oldApply = BuildPassiveCommon.ApplyDirectBonusDamage
    BattleSkill.CastSmallSkillWithResult = function()
        return true, { totalDamage = 6 }
    end
    BuildPassiveCommon.ApplyDirectBonusDamage = function()
        return 4
    end
    PaladinBuildPassives.PerformVengeanceSmite(paladin, target, { skillId = IDS.paladin_vengeance_smite, name = "破邪斩" })
    local otherDamageContext = { attacker = allyAttacker, damage = 5 }
    PaladinBuildPassives.ApplyPaladinProtections(target, { damageContext = otherDamageContext })
    assert_true(otherDamageContext.damage == 5, "holy mark only benefits the paladin who applied it")
    local ownDamageContext = { attacker = paladin, damage = 5 }
    PaladinBuildPassives.ApplyPaladinProtections(target, { damageContext = ownDamageContext })
    assert_true(ownDamageContext.damage == 6, "holy mark applies bonus damage for the original paladin attacker")
    BattleLogic.GetCurRound = function() return 3 end
    local expiredDamageContext = { attacker = paladin, damage = 5 }
    PaladinBuildPassives.ApplyPaladinProtections(target, { damageContext = expiredDamageContext })
    assert_true(expiredDamageContext.damage == 5, "holy mark expires after its configured duration")
    BattleLogic.GetCurRound = oldGetCurRound
    BattleSkill.CastSmallSkillWithResult = oldCast
    BuildPassiveCommon.ApplyDirectBonusDamage = oldApply
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local paladin = new_unit(321, "AuraPaladin", true, 2)
    local nearAlly = new_unit(322, "AuraNear", true, 1)
    local farAlly = new_unit(323, "AuraFar", true, 6)
    paladin.class = 4
    paladin.classId = 4
    paladin.skills = {
        { skillId = IDS.paladin_shelter_prayer },
        { skillId = IDS.paladin_guardian_aura },
    }
    paladin.skillData.skillInstances[IDS.paladin_shelter_prayer] = true
    paladin.skillData.skillInstances[IDS.paladin_guardian_aura] = true
    BattleFormation.Init({
        teamLeft = { paladin, nearAlly, farAlly },
        teamRight = {},
    })
    local friendTeam = BattleFormation.GetFriendTeam(paladin) or {}
    for _, ally in ipairs(friendTeam) do
        if ally.wpType == 2 then
            paladin = ally
        elseif ally.wpType == 1 then
            nearAlly = ally
        elseif ally.wpType == 6 then
            farAlly = ally
        end
    end
    assert_true(PaladinBuildPassives.GetAuraAcBonus(nearAlly, nil) == 1, "paladin aura base range covers adjacent ally")
    assert_true(PaladinBuildPassives.GetAuraAcBonus(farAlly, nil) == 0, "paladin aura base range excludes distant ally")
    paladin.buildState.classMods.paladinAuraRangeDelta = 1
    assert_true(PaladinBuildPassives.GetAuraAcBonus(farAlly, nil) == 1, "paladin aura range delta expands aura distance")
    paladin.buildState.classMods.paladinAuraGlobal = true
    paladin.buildState.classMods.paladinAuraAcBonus = 1
    paladin.buildState.classMods.paladinAuraSaveBonus = 1
    assert_true(PaladinBuildPassives.GetAuraAcBonus(farAlly, nil) == 2, "paladin aura global applies passive AC bonuses to full team")
    assert_true(PaladinBuildPassives.GetAuraSaveBonus(farAlly, "will") == 1, "paladin aura global applies passive save bonuses to full team")
    PaladinBuildPassives.ActivateGuardianAura(paladin)
    assert_true(PaladinBuildPassives.GetAuraAcBonus(farAlly, nil) == 3, "paladin guardian aura respects global aura coverage")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local skill_80007001 = require("config.skill.skill_80007001")
    local sorcerer = new_unit(351, "RuntimeSorcerer", true, 5)
    local burnTarget = new_unit(352, "BurnTarget", false, 1)
    local splashTarget = new_unit(353, "SplashTarget", false, 2)
    sorcerer.class = 7
    sorcerer.classId = 7
    sorcerer.buildState.skillMods[80007001] = {
        projectileCountDelta = 1,
    }
    sorcerer.buildState.skillMods[80007002] = {
        onKillExplodeDice = "1d6",
    }
    BattleFormation.Init({
        teamLeft = { sorcerer },
        teamRight = { burnTarget, splashTarget },
    })
    local enemyTeam = BattleFormation.GetEnemyTeam(sorcerer) or {}
    burnTarget = enemyTeam[1] or burnTarget
    splashTarget = enemyTeam[2] or splashTarget
    local fireBoltTimeline = skill_80007001.BuildTimeline(sorcerer, { burnTarget }, { skillId = 80007001, name = "火焰弹", level = 1 })
    local fireFrames = fireBoltTimeline.frames or fireBoltTimeline
    local fireDamageFrames = {}
    for _, frame in ipairs(fireFrames or {}) do
        if frame.op == "damage" then
            fireDamageFrames[#fireDamageFrames + 1] = frame
        end
    end
    assert_true(#fireDamageFrames == 2, "sorcerer fire bolt projectile delta adds one extra shot")
    BattleBuff.Add(sorcerer, burnTarget, {
        buffId = 870001,
        name = "燃烧",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 870001,
        duration = 2,
        canStack = false,
    })
    local firePassive = PassiveHandlers.Create(80007002, { src = sorcerer })
    local oldApply = BuildPassiveCommon.ApplyDirectBonusDamage
    local explodeCalls = {}
    BuildPassiveCommon.ApplyDirectBonusDamage = function(_, target, diceExpr, meta)
        explodeCalls[#explodeCalls + 1] = {
            targetId = target and target.instanceId,
            diceExpr = diceExpr,
            skillId = meta and meta.skillId or 0,
        }
        return 3
    end
    firePassive:OnDmgMakeKill({ data = { extraParam = { target = burnTarget } } })
    firePassive:OnDmgMakeKill({ data = { extraParam = { target = burnTarget } } })
    BuildPassiveCommon.ApplyDirectBonusDamage = oldApply
    assert_true(#explodeCalls == 1, "sorcerer burn kill explosion triggers at most once per round")
    assert_true(explodeCalls[1].targetId == splashTarget.instanceId, "sorcerer burn kill explosion hits adjacent enemies")
    assert_true(explodeCalls[1].diceExpr == "1d6", "sorcerer burn kill explosion uses configured dice")
    sorcerer.buildState.skillMods[80007002].dotDurationDelta = 1
    BattleSkillStatus.ApplyBurnRefreshOnly(burnTarget, 2, sorcerer)
    local burnBuff = BattleBuff.GetBuff(burnTarget, 870001)
    assert_true((tonumber(burnBuff and burnBuff.duration) or 0) == 3, "sorcerer burn duration delta extends burn refresh")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    SkillEffectRegistry.RegisterBuiltins()
    local wizard = new_unit(381, "RuntimeWizard", true, 5)
    local frozenTarget = new_unit(382, "FrozenTarget", false, 1)
    wizard.class = 8
    wizard.classId = 8
    wizard.buildState.skillMods[80008001] = {
        onCastShield = 4,
        onCastShieldCharges = 2,
        refreshFrostOnFrozenHit = true,
    }
    wizard.buildState.skillMods[80008002] = {
        dotDurationDelta = 1,
    }
    wizard.buildState.skillMods[80008004] = {
        vsFrozenExtendDuration = 1,
        vsFrozenExtendCap = 2,
    }
    BattleBuff.Add(wizard, frozenTarget, {
        buffId = 880002,
        name = "冻结",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 880002,
        duration = 1,
        canStack = false,
    })
    BattleSkillStatus.ApplyFrost(frozenTarget, 2, wizard)
    local frostBuff = BattleBuff.GetBuff(frozenTarget, 880005)
    assert_true((tonumber(frostBuff and frostBuff.duration) or 0) == 3, "wizard frost duration delta extends frost duration")
    local frostHandler = SkillEffectRegistry.handlers["apply_frost"]
    local frostCtx = { hero = wizard, skill = { skillId = 80008001, name = "寒霜射线" } }
    local frostFrame = {
        targets = { frozenTarget },
        __hitMetaByTarget = {
            [frozenTarget.instanceId] = { damage = 4 },
        },
    }
    frostHandler(frostCtx, frostFrame, "post", { param = { turns = 2 } })
    assert_true((tonumber(wizard.tempHp) or 0) == 4, "wizard frost armor grants temp hp on cast")
    frostBuff = BattleBuff.GetBuff(frozenTarget, 880005)
    if frostBuff then
        frostBuff.duration = 1
    end
    frostHandler(frostCtx, frostFrame, "post", { param = { turns = 2 } })
    frostBuff = BattleBuff.GetBuff(frozenTarget, 880005)
    assert_true((tonumber(frostBuff and frostBuff.duration) or 0) == 3, "wizard frost ray refreshes frost on frozen hit")
    local blizzardHandler = SkillEffectRegistry.handlers["wizard_blizzard_settlement"]
    local blizzardFrame = {
        targets = { frozenTarget },
        damage = 0,
        __hitMetaByTarget = {
            [frozenTarget.instanceId] = { damage = 4 },
        },
    }
    blizzardHandler({ hero = wizard, skill = { skillId = 80008004, name = "暴风雪" } }, blizzardFrame, "pre", { param = { bonusDice = "1d8" } })
    blizzardHandler({ hero = wizard, skill = { skillId = 80008004, name = "暴风雪" } }, blizzardFrame, "post", { param = { bonusDice = "1d8" } })
    local frozenBuff = BattleBuff.GetBuff(frozenTarget, 880002)
    assert_true((tonumber(frozenBuff and frozenBuff.duration) or 0) == 2, "wizard blizzard extends frozen duration with cap")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local warlock = new_unit(401, "RuntimeWarlock", true, 5)
    local targetA = new_unit(402, "ChainA", false, 1)
    local targetB = new_unit(403, "ChainB", false, 2)
    local targetC = new_unit(404, "ChainC", false, 4)
    local targetD = new_unit(405, "ChainD", false, 5)
    warlock.class = 9
    warlock.classId = 9
    warlock.buildState.skillMods[80009003] = {
        chainCountDelta = 2,
        firstHopVsMarkBonusDice = "1d8",
        prioritizeMarkedTargets = true,
        onHitMarkDurationDelta = 1,
    }
    BattleFormation.Init({
        teamLeft = { warlock },
        teamRight = { targetA, targetB, targetC, targetD },
    })
    local enemyTeam = BattleFormation.GetEnemyTeam(warlock) or {}
    targetA = enemyTeam[1] or targetA
    targetB = enemyTeam[2] or targetB
    targetC = enemyTeam[3] or targetC
    targetD = enemyTeam[4] or targetD
    BattleBuff.Add(warlock, targetA, {
        buffId = 890001,
        name = "静电印记A",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 890001,
        duration = 2,
        canStack = false,
    })
    BattleBuff.Add(warlock, targetB, {
        buffId = 890001,
        name = "静电印记B",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 890001,
        duration = 2,
        canStack = false,
    })
    local timeline = skill_80009003.BuildTimeline(warlock, { targetA }, { skillId = 80009003, name = "雷链" })
    local chainFrames = {}
    for _, frame in ipairs(timeline.frames or timeline or {}) do
        if frame.op == "chain_damage" then
            chainFrames[#chainFrames + 1] = frame
        end
    end
    assert_true(#chainFrames == 4, "warlock thunder chain consumes chainCountDelta for extra bounces")
    assert_true(type(chainFrames[1].bonusDamageDice) == "string" and string.find(chainFrames[1].bonusDamageDice, "1d8", 1, true) ~= nil,
        "warlock thunder chain first hop gains marked bonus dice")
    local secondTargetId = chainFrames[2].target and chainFrames[2].target.instanceId or 0
    assert_true(secondTargetId == targetB.instanceId,
        "warlock thunder chain prioritizes marked targets before random enemies")
    local extendHandler = SkillEffectRegistry.handlers["extend_static_mark"]
    extendHandler({ hero = warlock, skill = { skillId = 80009003, name = "雷链" } }, {
        targets = { targetB },
        __hitMetaByTarget = {
            [targetB.instanceId] = { damage = 5 },
        },
    }, "post", { param = { turns = 1 } })
    assert_true((BattleBuff.GetBuff(targetB, 890001).duration or 0) == 3, "warlock thunder chain extends mark duration on hit")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local warlock = new_unit(406, "RuntimeWarlockMark", true, 5)
    local targetA = new_unit(407, "MarkLimitA", false, 1)
    local targetB = new_unit(408, "MarkLimitB", false, 2)
    warlock.class = 9
    warlock.classId = 9
    warlock.buildState.skillMods[80009002] = {
        markRecastPerRound = 1,
    }
    local markHandler = SkillEffectRegistry.handlers["apply_static_mark"]
    local markCtx = { hero = warlock, skill = { skillId = 80009001, name = "邪能冲击" } }
    markHandler(markCtx, {
        targets = { targetA },
        __hitMetaByTarget = {
            [targetA.instanceId] = { damage = 4 },
        },
    }, "post", { param = { turns = 2 } })
    markHandler(markCtx, {
        targets = { targetB },
        __hitMetaByTarget = {
            [targetB.instanceId] = { damage = 4 },
        },
    }, "post", { param = { turns = 2 } })
    assert_true(BattleBuff.GetBuff(targetA, 890001) ~= nil, "warlock passive mark recast applies first mark")
    assert_true(BattleBuff.GetBuff(targetB, 890001) == nil, "warlock passive mark recast limit reads 80009002 passive mod")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local warlock = new_unit(409, "RuntimeWarlockPayout", true, 5)
    local targetA = new_unit(410, "PayoutA", false, 1)
    local targetB = new_unit(411, "PayoutB", false, 2)
    local targetC = new_unit(412, "PayoutC", false, 3)
    warlock.class = 9
    warlock.classId = 9
    warlock.buildState.skillMods[80009002] = {
        markBonusDice = "1d4",
        markPayoutPerRound = 2,
    }
    local payoutHandler = SkillEffectRegistry.handlers["warlock_static_mark_payout"]
    local oldResolve = BattleSkill.ResolveScaledDamage
    local oldApplyDamage = BattleDmgHeal.ApplyDamage
    local payoutCalls = {}
    BattleSkill.ResolveScaledDamage = function(_, target, opts)
        payoutCalls[#payoutCalls + 1] = {
            targetId = target and target.instanceId or 0,
            diceExpr = opts and opts.damageDice or "",
        }
        return { damage = 5 }
    end
    BattleDmgHeal.ApplyDamage = function() end
    BattleBuff.Add(warlock, targetA, {
        buffId = 890001,
        name = "静电印记A",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 890001,
        duration = 2,
        canStack = false,
    })
    BattleBuff.Add(warlock, targetB, {
        buffId = 890001,
        name = "静电印记B",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 890001,
        duration = 2,
        canStack = false,
    })
    BattleBuff.Add(warlock, targetC, {
        buffId = 890001,
        name = "静电印记C",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 890001,
        duration = 2,
        canStack = false,
    })
    local payoutCtx = { hero = warlock, skill = { skillId = 80009001, name = "邪能冲击" } }
    payoutHandler(payoutCtx, {
        targets = { targetA },
        __hitMetaByTarget = {
            [targetA.instanceId] = { damage = 5 },
        },
    }, "post")
    payoutHandler(payoutCtx, {
        targets = { targetA },
        __hitMetaByTarget = {
            [targetA.instanceId] = { damage = 5 },
        },
    }, "post")
    payoutHandler(payoutCtx, {
        targets = { targetB },
        __hitMetaByTarget = {
            [targetB.instanceId] = { damage = 5 },
        },
    }, "post")
    payoutHandler(payoutCtx, {
        targets = { targetC },
        __hitMetaByTarget = {
            [targetC.instanceId] = { damage = 5 },
        },
    }, "post")
    BattleSkill.ResolveScaledDamage = oldResolve
    BattleDmgHeal.ApplyDamage = oldApplyDamage
    assert_true(#payoutCalls == 2, "warlock static mark payout uses configured total count and same-target cap")
    assert_true(payoutCalls[1].diceExpr == "1d6;1d4", "warlock static mark payout merges mark bonus dice")
    assert_true(payoutCalls[2].targetId == targetB.instanceId, "warlock static mark payout spends second charge on another marked target")
end

do
    BattleFormation.OnFinal()
    BattleBuff.Init()
    local warlock = new_unit(421, "RuntimeWarlockEcho", true, 5)
    local targetA = new_unit(422, "ChainStart", false, 1)
    local targetB = new_unit(423, "ChainMid", false, 2)
    local targetC = new_unit(424, "ChainEnd", false, 4)
    warlock.class = 9
    warlock.classId = 9
    warlock.buildState.skillMods[80009003] = {
        chainCountDelta = 1,
        lastHopBonusDice = "1d6",
    }
    BattleFormation.Init({
        teamLeft = { warlock },
        teamRight = { targetA, targetB, targetC },
    })
    local enemyTeam = BattleFormation.GetEnemyTeam(warlock) or {}
    targetA = enemyTeam[1] or targetA
    targetB = enemyTeam[2] or targetB
    targetC = enemyTeam[3] or targetC
    BattleBuff.Add(warlock, targetC, {
        buffId = 890001,
        name = "静电印记C",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 890001,
        duration = 2,
        canStack = false,
    })
    local timeline = skill_80009003.BuildTimeline(warlock, { targetA }, { skillId = 80009003, name = "雷链" })
    local chainFrames = {}
    for _, frame in ipairs(timeline.frames or timeline or {}) do
        if frame.op == "chain_damage" then
            chainFrames[#chainFrames + 1] = frame
        end
    end
    local lastFrame = chainFrames[#chainFrames]
    assert_true(lastFrame and lastFrame.op == "chain_damage", "warlock thunder chain last hop frame exists")
    assert_true(type(lastFrame.bonusDamageDice) == "string" and string.find(lastFrame.bonusDamageDice, "1d6", 1, true) ~= nil,
        "warlock thunder chain last hop gains marked bonus dice")
end

BattleFormation.OnFinal()
print("test_class_tree_runtime_fixes ok")
