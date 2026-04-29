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
local BattleSkill = require("modules.battle_skill")
local BattlePassiveSkill = require("modules.battle_passive_skill")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleFormation = require("modules.battle_formation")
local BattleLogic = require("modules.battle_logic")
local FighterBuildPassives = require("skills.fighter_build_passives")
local SkillRuntimeConfig = require("config.skill_runtime_config")
local PassiveDefs = require("config.passive.passive_defs")

BattleEvent.Init()
BattleBuff.Init()
BattleSkill.InitModule()

local function new_unit(id, name)
    return {
        id = id,
        instanceId = id,
        name = name,
        hp = 100,
        maxHp = 100,
        atk = 10,
        def = 0,
        hit = 999,
        ac = 1,
        spellDC = 999,
        saveFort = 0,
        saveRef = 0,
        saveWill = 0,
        proficiencyBonus = 2,
        __ignoreNatRules = true,
        isDead = false,
        isAlive = true,
        attributes = { final = {} },
        skills = {},
        skillData = { skillInstances = {} },
    }
end

do
    local hero = new_unit(9101, "BonusDamageHero")
    local target = new_unit(9102, "BonusDamageDummy")
    local oldResolveScaledDamage = BattleSkill.ResolveScaledDamage
    local oldApplyDamage = BattleDmgHeal.ApplyDamage
    local oldRunSkillOnDefBeforeDmg = BattlePassiveSkill.RunSkillOnDefBeforeDmg
    local oldRunSkillOnDefAfterDmg = BattlePassiveSkill.RunSkillOnDefAfterDmg
    local oldRunSkillOnDmgMakeKill = BattlePassiveSkill.RunSkillOnDmgMakeKill
    local oldTriggerDamageBuffs = BattleSkill.TriggerDamageBuffs
    local callCount = 0

    hero.passiveRuntime = { pendingBasicAttackBonusDice = "1d8" }

    BattleSkill.ResolveScaledDamage = function()
        callCount = callCount + 1
        if callCount == 1 then
            return { damage = 10, hit = { hit = true } }
        end
        return { damage = 4, hit = { hit = true } }
    end
    BattleDmgHeal.ApplyDamage = function() end
    BattlePassiveSkill.RunSkillOnDefBeforeDmg = function(_, ctx) return ctx end
    BattlePassiveSkill.RunSkillOnDefAfterDmg = function() end
    BattlePassiveSkill.RunSkillOnDmgMakeKill = function() end
    BattleSkill.TriggerDamageBuffs = function() end

    local total = BattleSkill.ExecuteDefaultAttackWithPassive(hero, { target }, {
        skillId = SkillRuntimeConfig.Ids.fighter_basic_attack,
        name = "基础武器攻击",
    })
    assert_true(total == 14, "basic attack pending bonus damage is applied through ExecuteDefaultAttackWithPassive")
    assert_true(hero.passiveRuntime.pendingBasicAttackBonusDice == nil, "pending bonus dice clears after basic attack resolve")

    BattleSkill.ResolveScaledDamage = oldResolveScaledDamage
    BattleDmgHeal.ApplyDamage = oldApplyDamage
    BattlePassiveSkill.RunSkillOnDefBeforeDmg = oldRunSkillOnDefBeforeDmg
    BattlePassiveSkill.RunSkillOnDefAfterDmg = oldRunSkillOnDefAfterDmg
    BattlePassiveSkill.RunSkillOnDmgMakeKill = oldRunSkillOnDmgMakeKill
    BattleSkill.TriggerDamageBuffs = oldTriggerDamageBuffs
end

do
    local hero = new_unit(9151, "PreciseHero")
    local passive = FighterBuildPassives.CreatePreciseAttackPassive({ src = hero })

    hero.passiveRuntime = {}
    passive:OnBattleBegin()

    assert_true(hero.passiveRuntime.basicAttackIgnoreAc == 2, "precise attack grants 2 AC ignore to basic attack")
end

do
    local trigger = PassiveDefs[SkillRuntimeConfig.Ids.fighter_counter_basic].triggers[1]
    assert_true(trigger.luaFuncName == "OnDefBeforeDmg", "counter basic passive def binds OnDefBeforeDmg")
    assert_true(trigger.triggerTime == E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg, "counter basic passive def uses DefBeforeDmg trigger time")
end

do
    local guardLua = BattleSkill.LoadSkillLua(SkillRuntimeConfig.Ids.fighter_guard_stance)
    assert_true(type(guardLua) == "table" and type(guardLua.BuildTimeline) == "function", "guard stance loads runtime lua timeline")
end

do
    local hero = new_unit(9201, "CounterHero")
    local attacker = new_unit(9202, "CounterAttacker")
    attacker.class = 2
    local passive = FighterBuildPassives.CreateCounterBasicPassive({ src = hero })
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local oldGetCurRound = BattleLogic.GetCurRound
    local oldGetAllHeroes = BattleFormation.GetAllHeroes
    local castCount = 0
    local passiveEvent = nil

    BattleLogic.GetCurRound = function() return 1 end
    BattleFormation.GetAllHeroes = function()
        return { hero, attacker }
    end
    BattleSkill.CastSmallSkill = function()
        castCount = castCount + 1
        return true
    end
    local listener = function(payload)
        passiveEvent = payload
    end
    BattleEvent.AddListener("PassiveSkillTriggered", listener)

    attacker.passiveRuntime = { __inCounterBasic = true }
    passive:OnDefBeforeDmg({ data = { extraParam = { attacker = attacker, damage = 0 } } })
    assert_true(castCount == 0, "counter basic ignores attacks coming from another counter")

    attacker.passiveRuntime.__inCounterBasic = false
    hero.passiveRuntime = {}
    passive:OnDefBeforeDmg({ data = { extraParam = { attacker = attacker, damage = 0 } } })
    assert_true(castCount == 0, "counter basic is queued until attacker animation resolves")
    assert_true(passiveEvent and passiveEvent.skillName == "反击战法", "counter basic publishes passive trigger event when queued")
    assert_true(passiveEvent and passiveEvent.triggerType == "登记反击", "counter basic passive event marks queued reaction")
    FighterBuildPassives.ResolveQueuedReactions(attacker)
    assert_true(castCount == 1, "counter basic resolves after attacker action finishes")

    BattleEvent.RemoveListener("PassiveSkillTriggered", listener)
    BattleSkill.CastSmallSkill = oldCastSmallSkill
    BattleLogic.GetCurRound = oldGetCurRound
    BattleFormation.GetAllHeroes = oldGetAllHeroes
end

do
    local defender = new_unit(9301, "GuardDefender")
    local guard = new_unit(9302, "GuardFighter")
    local attacker = new_unit(9303, "GuardAttacker")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local oldGetAllHeroes = BattleFormation.GetAllHeroes
    local castCount = 0

    attacker.class = 2

    guard.skills = {
        { skillId = SkillRuntimeConfig.Ids.fighter_guard_counter },
    }
    guard.passiveRuntime = {
        guardStanceActive = true,
        guardCounterUsed = false,
    }

    BattleFormation.GetFriendTeam = function(unit)
        if unit == defender then
            return { defender, guard }
        end
        return { guard, defender }
    end
    BattleFormation.GetAllHeroes = function()
        return { defender, guard, attacker }
    end
    BattleSkill.CastSmallSkill = function()
        castCount = castCount + 1
        return true
    end

    FighterBuildPassives.TryTriggerGuardCounter(defender, { attacker = attacker })
    FighterBuildPassives.TryTriggerGuardCounter(defender, { attacker = attacker })
    assert_true(castCount == 0, "guard counter is queued until attacker animation resolves")
    FighterBuildPassives.ResolveQueuedReactions(attacker)
    assert_true(castCount == 1, "guard counter resolves once after ally attack animation finishes")

    BattleFormation.GetFriendTeam = oldGetFriendTeam
    BattleSkill.CastSmallSkill = oldCastSmallSkill
    BattleFormation.GetAllHeroes = oldGetAllHeroes
end

do
    local guard = new_unit(9311, "GuardOwner")
    local ally = new_unit(9312, "GuardAlly")
    local meleeAttacker = new_unit(9313, "GuardMelee")
    local rangedAttacker = new_unit(9314, "GuardRanged")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam

    guard.skills = {
        { skillId = SkillRuntimeConfig.Ids.fighter_guard_counter },
    }
    guard.passiveRuntime = {
        guardStanceActive = true,
        guardCounterUsed = false,
    }
    meleeAttacker.class = 2
    rangedAttacker.class = 7

    BattleFormation.GetFriendTeam = function()
        return { guard, ally }
    end

    assert_true(FighterBuildPassives.GetGuardStanceAcBonus(guard, meleeAttacker) == 2, "guard stance grants AC bonus to self")
    assert_true(FighterBuildPassives.GetGuardStanceAcBonus(ally, meleeAttacker) == 2, "guard stance grants AC bonus to allies")

    local rangedDamageContext = { damage = 7 }
    FighterBuildPassives.ApplyGuardStanceProtection(ally, {
        attacker = rangedAttacker,
        damageContext = rangedDamageContext,
    })
    assert_true(rangedDamageContext.damage == 5, "guard stance reduces incoming damage by proficiency bonus")
    assert_true(guard.passiveRuntime.pendingGuardCounterTarget == nil, "guard counter ignores ranged attackers")

    local meleeDamageContext = { damage = 7 }
    FighterBuildPassives.ApplyGuardStanceProtection(guard, {
        attacker = meleeAttacker,
        damageContext = meleeDamageContext,
    })
    assert_true(meleeDamageContext.damage == 5, "guard stance reduction also protects self")
    assert_true(guard.passiveRuntime.pendingGuardCounterTarget == meleeAttacker, "guard counter queues for melee attackers after protection")

    BattleFormation.GetFriendTeam = oldGetFriendTeam
end

do
    local hero = new_unit(9501, "ActionSurgeHero")
    local target = new_unit(9502, "ActionSurgeDummy")
    local oldCastSmallSkillWithResult = BattleSkill.CastSmallSkillWithResult
    local calls = 0

    BattleSkill.CastSmallSkillWithResult = function()
        calls = calls + 1
        return true, { totalDamage = 7 }
    end

    local total = FighterBuildPassives.CastBasicAttackRepeated(hero, target, 2)
    assert_true(total == 14 and calls == 2, "repeat basic attack helper sums actual cast result damage instead of hp delta")

    BattleSkill.CastSmallSkillWithResult = oldCastSmallSkillWithResult
end

do
    local hero = new_unit(9551, "ExtraAttackHero")
    local fallenTarget = new_unit(9552, "FallenDummy")
    local retarget = new_unit(9553, "RetargetDummy")
    local passive = FighterBuildPassives.CreateExtraAttackPassive({ src = hero })
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local oldSelectRandomAliveEnemies = BattleSkill.SelectRandomAliveEnemies
    local castTarget = nil

    fallenTarget.isDead = true
    fallenTarget.isAlive = false

    BattleSkill.SelectRandomAliveEnemies = function()
        return { retarget }
    end
    BattleSkill.CastSmallSkill = function(_, target)
        castTarget = target
        return true
    end

    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                target = fallenTarget,
                skillId = SkillRuntimeConfig.Ids.fighter_basic_attack,
                damageDealt = 6,
            },
        },
    })

    assert_true(castTarget == retarget, "extra attack retargets when the original target is already dead")

    BattleSkill.CastSmallSkill = oldCastSmallSkill
    BattleSkill.SelectRandomAliveEnemies = oldSelectRandomAliveEnemies
end

do
    local hero = new_unit(9581, "SweepingHero")
    local primaryTarget = new_unit(9582, "PrimaryDummy")
    local secondaryTarget = new_unit(9583, "SecondaryDummy")
    local passive = FighterBuildPassives.CreateSweepingAttackPassive({ src = hero })
    local oldGetEnemyTeam = BattleFormation.GetEnemyTeam
    local oldApplyDirectBonusDamage = FighterBuildPassives.ApplyDirectBonusDamage
    local hitTarget = nil

    BattleFormation.GetEnemyTeam = function()
        return { primaryTarget, secondaryTarget }
    end
    FighterBuildPassives.ApplyDirectBonusDamage = function(_, target, diceExpr)
        hitTarget = { target = target, diceExpr = diceExpr }
        return 6
    end

    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                target = primaryTarget,
                skillId = SkillRuntimeConfig.Ids.fighter_basic_attack,
                damageDealt = 8,
            },
        },
    })

    assert_true(hitTarget ~= nil and hitTarget.target == secondaryTarget, "sweeping attack hits another alive enemy instead of the primary target")
    assert_true(hitTarget ~= nil and hitTarget.diceExpr == "1d8", "sweeping attack uses fighter basic attack damage dice")

    BattleFormation.GetEnemyTeam = oldGetEnemyTeam
    FighterBuildPassives.ApplyDirectBonusDamage = oldApplyDirectBonusDamage
end

do
    local hero = new_unit(9601, "SecondWindHero")
    local passive = FighterBuildPassives.CreateSecondWindPassive({ src = hero })
    local oldApplyHeal = BattleDmgHeal.ApplyHeal
    local passiveEvent = nil
    local healed = 0

    hero.level = 3
    hero.hp = 40
    hero.maxHp = 100
    hero.passiveRuntime = {}

    BattleDmgHeal.ApplyHeal = function(_, amount)
        healed = amount
    end

    local listener = function(payload)
        passiveEvent = payload
    end
    BattleEvent.AddListener("PassiveSkillTriggered", listener)

    passive:OnDefAfterDmg({ data = { extraParam = { attacker = new_unit(9602, "Enemy"), damage = 12 } } })

    BattleEvent.RemoveListener("PassiveSkillTriggered", listener)
    BattleDmgHeal.ApplyHeal = oldApplyHeal

    assert_true(healed > 0, "second wind applies healing when hp falls to half or lower")
    assert_true(passiveEvent ~= nil, "second wind publishes passive trigger event")
    assert_true(passiveEvent.skillName == "二次生命", "second wind passive trigger event exposes skill name")
end

do
    local hero = new_unit(9611, "SecondWindMasterHero")
    local passive = FighterBuildPassives.CreateSecondWindPassive({ src = hero })
    local mastery = FighterBuildPassives.CreateSecondWindMasteryPassive({ src = hero })
    local oldApplyHeal = BattleDmgHeal.ApplyHeal
    local Dice = require("core.dice")
    local oldDiceRoll = Dice.Roll
    local healed = 0
    local rolls = {}

    hero.level = 5
    hero.hp = 40
    hero.maxHp = 100
    hero.passiveRuntime = {}

    mastery:OnBattleBegin()

    Dice.Roll = function(expr)
        rolls[#rolls + 1] = expr
        if expr == "1d10+5" then
            return 9
        end
        if expr == "1d10" then
            return 4
        end
        return oldDiceRoll(expr)
    end
    BattleDmgHeal.ApplyHeal = function(_, amount)
        healed = amount
    end

    passive:OnDefAfterDmg({ data = { extraParam = { attacker = new_unit(9612, "Enemy"), damage = 12 } } })

    BattleDmgHeal.ApplyHeal = oldApplyHeal
    Dice.Roll = oldDiceRoll

    assert_true(healed == 13, "second wind mastery adds an extra 1d10 heal on top of second wind")
    assert_true(#rolls == 2 and rolls[1] == "1d10+5" and rolls[2] == "1d10", "second wind mastery rolls base heal and bonus heal separately")
end

log("Fighter build runtime tests passed.")
