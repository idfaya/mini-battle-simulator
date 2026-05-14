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
local ClassWeaponConfig = require("config.class_weapon_config")
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
    local target = new_unit(9153, "BasicAttackExprTarget")
    for classId = 1, 6 do
        local hero = new_unit(9150 + classId, "BasicAttackExprHero" .. tostring(classId))
        hero.class = classId
        hero.strMod = 3
        hero.dexMod = 3
        hero.conMod = 3
        hero.intMod = 3
        hero.wisMod = 3
        hero.chaMod = 3

        local result = BattleSkill.ResolveScaledDamage(hero, target, {
            meta = {
                kind = "physical",
                damageDice = "",
            },
        })
        local expectedExpr = ClassWeaponConfig.GetWeaponDice(classId)
        assert_true(result.damageRoll ~= nil and result.damageRoll.expr == expectedExpr,
            "class " .. tostring(classId) .. " basic attack uses weapon die only under 5e rules")
        assert_true((result.damage or 0) >= 4,
            "class " .. tostring(classId) .. " basic attack still adds ability modifier after weapon die")
    end
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
    assert_true(passiveEvent and passiveEvent.skillName == "反击", "counter basic publishes passive trigger event when queued")
    assert_true(passiveEvent and passiveEvent.triggerType == "登记反击", "counter basic passive event marks queued reaction")
    FighterBuildPassives.ResolveQueuedReactions(attacker)
    assert_true(castCount == 1, "counter basic resolves after attacker action finishes")

    BattleEvent.RemoveListener("PassiveSkillTriggered", listener)
    BattleSkill.CastSmallSkill = oldCastSmallSkill
    BattleLogic.GetCurRound = oldGetCurRound
    BattleFormation.GetAllHeroes = oldGetAllHeroes
end

do
    local hero = new_unit(9203, "CounterHeroAgainstGuard")
    local attacker = new_unit(9204, "GuardSourceAttacker")
    local passive = FighterBuildPassives.CreateCounterBasicPassive({ src = hero })

    attacker.class = 2
    attacker.passiveRuntime = { __inGuardCounter = true }
    hero.passiveRuntime = {}

    passive:OnDefBeforeDmg({ data = { extraParam = { attacker = attacker, damage = 0 } } })
    assert_true(hero.passiveRuntime.pendingCounterBasicTarget == nil, "counter basic ignores attacks coming from guard reactions")
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
    local defender = new_unit(9304, "GuardDefenderAgainstCounter")
    local guard = new_unit(9305, "GuardFighterAgainstCounter")
    local attacker = new_unit(9306, "CounterSourceAttacker")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam

    attacker.class = 2
    attacker.passiveRuntime = { __inCounterBasic = true }
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

    FighterBuildPassives.TryTriggerGuardCounter(defender, { attacker = attacker })
    assert_true(guard.passiveRuntime.pendingGuardCounterTarget == nil, "guard counter ignores attacks coming from counter reactions")

    BattleFormation.GetFriendTeam = oldGetFriendTeam
end

do
    local defender = new_unit(9312, "CounterDefender")
    local guard = new_unit(9313, "GuardFighter")
    local attacker = new_unit(9314, "SharedAttacker")
    local counterPassive = FighterBuildPassives.CreateCounterBasicPassive({ src = defender })
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local oldGetCurRound = BattleLogic.GetCurRound
    local oldGetAllHeroes = BattleFormation.GetAllHeroes
    local castOrder = {}

    attacker.class = 2
    defender.passiveRuntime = {}
    guard.skills = {
        { skillId = SkillRuntimeConfig.Ids.fighter_guard_counter },
    }
    guard.passiveRuntime = {
        guardStanceActive = true,
        guardCounterUsed = false,
    }

    BattleLogic.GetCurRound = function() return 1 end
    BattleFormation.GetFriendTeam = function(unit)
        if unit == defender then
            return { defender, guard }
        end
        return { guard, defender }
    end
    BattleFormation.GetAllHeroes = function()
        return { guard, defender, attacker }
    end
    BattleSkill.CastSmallSkill = function(hero)
        table.insert(castOrder, hero.name)
        return true
    end

    counterPassive:OnDefBeforeDmg({ data = { extraParam = { attacker = attacker, damage = 0 } } })
    FighterBuildPassives.TryTriggerGuardCounter(defender, { attacker = attacker })
    FighterBuildPassives.ResolveQueuedReactions(attacker)

    assert_true(#castOrder == 2, "shared attacker resolves both counter and guard reactions")
    assert_true(castOrder[1] == "CounterDefender", "shared attacker resolves counter reaction before guard reaction")
    assert_true(castOrder[2] == "GuardFighter", "shared attacker resolves guard reaction after counter reaction")

    BattleFormation.GetFriendTeam = oldGetFriendTeam
    BattleSkill.CastSmallSkill = oldCastSmallSkill
    BattleLogic.GetCurRound = oldGetCurRound
    BattleFormation.GetAllHeroes = oldGetAllHeroes
end

do
    local firstDefender = new_unit(9315, "FirstProtected")
    local secondDefender = new_unit(9316, "SecondProtected")
    local firstGuard = new_unit(9317, "FirstGuard")
    local secondGuard = new_unit(9318, "SecondGuard")
    local attacker = new_unit(9319, "SharedGuardAttacker")
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local oldGetAllHeroes = BattleFormation.GetAllHeroes
    local castOrder = {}

    attacker.class = 2
    firstGuard.skills = {
        { skillId = SkillRuntimeConfig.Ids.fighter_guard_counter },
    }
    secondGuard.skills = {
        { skillId = SkillRuntimeConfig.Ids.fighter_guard_counter },
    }
    firstGuard.passiveRuntime = {
        guardStanceActive = true,
        guardCounterUsed = false,
    }
    secondGuard.passiveRuntime = {
        guardStanceActive = true,
        guardCounterUsed = false,
    }

    BattleFormation.GetFriendTeam = function()
        return { firstDefender, secondDefender, firstGuard, secondGuard }
    end
    BattleFormation.GetAllHeroes = function()
        return { firstDefender, secondDefender, firstGuard, secondGuard, attacker }
    end
    BattleSkill.CastSmallSkill = function(hero)
        table.insert(castOrder, hero.name)
        return true
    end

    FighterBuildPassives.TryTriggerGuardCounter(firstDefender, { attacker = attacker })
    FighterBuildPassives.TryTriggerGuardCounter(secondDefender, { attacker = attacker })
    FighterBuildPassives.ResolveQueuedReactions(attacker)

    assert_true(#castOrder == 1, "one attack can queue at most one guard reaction")

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

    assert_true(FighterBuildPassives.GetGuardStanceAcBonus(guard, meleeAttacker) == 0, "guard stance does not grant AC bonus to self")
    assert_true(FighterBuildPassives.GetGuardStanceAcBonus(ally, meleeAttacker) == 2, "guard stance grants AC bonus to allies")

    local rangedDamageContext = { damage = 7 }
    FighterBuildPassives.ApplyGuardStanceProtection(ally, {
        attacker = rangedAttacker,
        damageContext = rangedDamageContext,
    })
    assert_true(rangedDamageContext.damage == 7, "guard stance no longer reduces incoming damage")
    assert_true(guard.passiveRuntime.pendingGuardCounterTarget == nil, "guard counter ignores ranged attackers")

    local meleeDamageContext = { damage = 7 }
    FighterBuildPassives.ApplyGuardStanceProtection(guard, {
        attacker = meleeAttacker,
        damageContext = meleeDamageContext,
    })
    assert_true(meleeDamageContext.damage == 7, "guard stance does not modify self damage directly")
    assert_true(guard.passiveRuntime.pendingGuardCounterTarget == nil, "guard stance does not guard the owner themself")

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
    local firstTarget = new_unit(9552, "FirstDummy")
    local secondTarget = new_unit(9553, "SecondDummy")
    local fallenTarget = new_unit(9554, "FallenDummy")
    local passive = FighterBuildPassives.CreateExtraAttackPassive({ src = hero })
    local oldCastSmallSkill = BattleSkill.CastSmallSkill
    local castCalls = {}

    fallenTarget.isDead = true
    fallenTarget.isAlive = false

    BattleSkill.CastSmallSkill = function(_, target, opts)
        castCalls[#castCalls + 1] = { target = target, opts = opts }
        return true
    end

    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                target = firstTarget,
                skillId = SkillRuntimeConfig.Ids.fighter_basic_attack,
                damageDealt = 6,
                basicAttackActionToken = 101,
                basicAttackActionSource = "normal_action",
            },
        },
    })
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                target = firstTarget,
                skillId = SkillRuntimeConfig.Ids.fighter_basic_attack,
                damageDealt = 6,
                basicAttackActionToken = 101,
                basicAttackActionSource = "normal_action",
            },
        },
    })
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                target = secondTarget,
                skillId = SkillRuntimeConfig.Ids.fighter_basic_attack,
                damageDealt = 6,
                basicAttackActionToken = 102,
                basicAttackActionSource = "action_surge",
            },
        },
    })
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                target = fallenTarget,
                skillId = SkillRuntimeConfig.Ids.fighter_basic_attack,
                damageDealt = 6,
                basicAttackActionToken = 103,
                basicAttackActionSource = "action_surge",
            },
        },
    })

    assert_true(#castCalls == 2, "extra attack triggers once per basic attack action token, including action surge extra action")
    assert_true(castCalls[1].target == firstTarget, "extra attack keeps the same target within the same action")
    assert_true(castCalls[1].opts and castCalls[1].opts.basicAttackActionToken == 101, "extra attack follow-up keeps the original action token")
    assert_true(castCalls[1].opts and castCalls[1].opts.basicAttackIsFollowUp == true, "extra attack follow-up is marked to avoid recursive triggers")
    assert_true(castCalls[2].target == secondTarget, "action surge opened action can independently trigger extra attack on its chosen target")

    BattleSkill.CastSmallSkill = oldCastSmallSkill
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
    assert_true(hitTarget ~= nil and hitTarget.diceExpr == "1d6", "sweeping attack uses fighter weapon damage die under 5e rules")

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
    hero.hp = 20
    hero.maxHp = 100
    hero.passiveRuntime = {}

    BattleDmgHeal.ApplyHeal = function(_, amount)
        healed = amount
    end

    local listener = function(payload)
        passiveEvent = payload
    end
    BattleEvent.AddListener("PassiveSkillTriggered", listener)

    local ctx = { data = { extraParam = { attacker = new_unit(9602, "Enemy"), damage = 25 } } }
    passive:OnDefBeforeDmg(ctx)

    BattleEvent.RemoveListener("PassiveSkillTriggered", listener)
    BattleDmgHeal.ApplyHeal = oldApplyHeal

    assert_true(healed == 30, "indomitable wind heals to half max hp before lethal damage")
    assert_true(ctx.data.extraParam.damage == 0, "indomitable wind prevents lethal damage")
    assert_true(passiveEvent ~= nil, "second wind publishes passive trigger event")
    assert_true(passiveEvent.skillName == "不屈之风", "indomitable wind passive trigger event exposes skill name")
end

do
    local hero = new_unit(9611, "SecondWindMasterHero")
    local passive = FighterBuildPassives.CreateSecondWindPassive({ src = hero })
    local oldApplyHeal = BattleDmgHeal.ApplyHeal
    local healed = 0

    hero.level = 5
    hero.hp = 10
    hero.maxHp = 100
    hero.passiveRuntime = {}

    BattleDmgHeal.ApplyHeal = function(_, amount)
        healed = amount
    end

    passive:OnDefBeforeDmg({ data = { extraParam = { attacker = new_unit(9612, "Enemy"), damage = 12 } } })

    BattleDmgHeal.ApplyHeal = oldApplyHeal

    assert_true(healed == 40, "indomitable wind restores hero to half max hp")
end

log("Fighter build runtime tests passed.")
