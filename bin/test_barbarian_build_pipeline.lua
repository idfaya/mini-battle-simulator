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

local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local HeroData = require("config.hero_data")
local BarbarianBuildPassives = require("skills.barbarian_build_passives")
local BattleSkill = require("modules.battle_skill")
local BattleFormula = require("core.battle_formula")
local Ability5e = require("modules.ability_5e")
local ClassWeaponConfig = require("config.tables.classes")
local ClassBuildProgression = require("config.tables.classes")
local FeatBuildConfig = require("config.tables.feats")
local BattleBuff = require("modules.battle_buff")
local BattleFormation = require("modules.battle_formation")
local BuildPassiveCommon = require("skills.build_passive_common")

local function hasSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

local function new_unit(id, name)
    return {
        id = id,
        instanceId = id,
        name = name,
        hp = 100,
        maxHp = 100,
        hit = 7,
        ac = 15,
        isDead = false,
        skills = {},
        passiveRuntime = {},
    }
end

do
    local build = HeroBuild.CompileBuild(10, 1, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.barbarian_basic_attack), "Barbarian Lv1 grants basic attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.barbarian_rage), "Barbarian Lv1 grants rage")
end

do
    -- §5 单轨：野蛮人 Lv5 build 直接选 T1 重击节点；T2 berserk 由 lv1FeatIds + canonical 链路覆盖。
    local build = HeroBuild.CompileBuild(10, 5, { FeatBuildConfig.Ids.barbarian_heavy_strike, FeatBuildConfig.Ids.barbarian_berserk })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.barbarian_basic_attack), "Barbarian Lv5 keeps basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.barbarian_heavy_strike), "Barbarian Lv5 grants heavy strike")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.barbarian_berserk), "Barbarian Lv5 grants berserk")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.barbarian_heavy_strike), "Barbarian runtime exports heavy strike")

    local hero = HeroData.ConvertToHeroData(900010, 5, 1, {
        buildFeatIds = { FeatBuildConfig.Ids.barbarian_heavy_strike, FeatBuildConfig.Ids.barbarian_berserk },
    })
    assert_true(hero and hero.buildState ~= nil, "HeroData compile works for barbarian")
    assert_true(hasSkill(hero.skillsConfig, SkillRuntimeConfig.Ids.barbarian_basic_attack), "HeroData exports barbarian basic attack")
    assert_true(hasSkill(hero.skillsConfig, SkillRuntimeConfig.Ids.barbarian_heavy_strike), "HeroData exports barbarian heavy strike")
end

do
    local hero = new_unit(9691, "BarbarianDamageHero")
    local target = new_unit(9692, "BarbarianDamageTarget")
    hero.class = 10
    hero.hit = 999
    hero.strMod = 4
    hero.dexMod = 2
    hero.conMod = 3
    hero.__ignoreNatRules = true
    target.__ignoreNatRules = true

    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        meta = {
            kind = "physical",
            damageDice = "",
        },
    })

    assert_true(result.damageRoll ~= nil and result.damageRoll.expr == ClassWeaponConfig.GetWeaponDice(10), "barbarian basic attack uses weapon die only under 5e rules")
    assert_true((result.damage or 0) >= 5, "barbarian basic attack still adds strength modifier after weapon die")
    local profile = Ability5e.GetClassProfile(10)
    assert_true(profile ~= nil and profile.primary_ability == "str", "barbarian class profile uses strength as primary ability")
    assert_true(Ability5e.GetClassHitDie(10) == 12, "barbarian class profile uses d12 hit die")
end

do
    local hero = new_unit(9701, "Barbarian")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
    }
    local rage = BarbarianBuildPassives.CreateRagePassive({ src = hero })
    rage:OnNormalAtkFinish({ data = { extraParam = { skillId = SkillRuntimeConfig.Ids.barbarian_basic_attack } } })
    assert_true(hero.passiveRuntime.barbarianBerserkUsed == true, "Berserk activates after basic attack trigger")
    assert_true(BarbarianBuildPassives.IsBerserkActive(hero) == true, "Berserk remains active until next round end")
    local firstUntilRound = hero.passiveRuntime.barbarianBerserkUntilRound
    rage:OnNormalAtkFinish({ data = { extraParam = { skillId = SkillRuntimeConfig.Ids.barbarian_basic_attack } } })
    assert_true(hero.passiveRuntime.barbarianBerserkUntilRound == firstUntilRound, "Base berserk cannot stack or refresh in battle")
end

do
    local hero = new_unit(9711, "Berserker")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
    }
    hero.passiveRuntime.barbarianBerserkUntilRound = 99
    local rage = BarbarianBuildPassives.CreateRagePassive({ src = hero })
    local ctx = { data = { extraParam = { attacker = new_unit(9712, "Enemy"), damage = 7, damageKind = "physical", skillId = SkillRuntimeConfig.Ids.barbarian_basic_attack } } }
    rage:OnDefBeforeDmg(ctx)
    assert_true(ctx.data.extraParam.damage == 5, "Berserk reduces incoming damage by 2")
    assert_true(BarbarianBuildPassives.ApplyBerserkDamageBonus(hero, 8) == 10, "Berserk adds 2 damage to attacks")
end

do
    local hero = new_unit(9716, "TirelessBerserker")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
        { skillId = SkillRuntimeConfig.Ids.barbarian_berserk },
    }
    hero.passiveRuntime.barbarianBerserkUsed = true
    hero.passiveRuntime.barbarianBerserkUntilRound = -1
    local rage = BarbarianBuildPassives.CreateRagePassive({ src = hero })
    rage:OnNormalAtkFinish({ data = { extraParam = { skillId = SkillRuntimeConfig.Ids.barbarian_basic_attack } } })
    assert_true(BarbarianBuildPassives.IsBerserkActive(hero) == true, "Tireless berserk removes once-per-battle limit")
end

do
    local baseHero = new_unit(9717, "BaseRageDuration")
    baseHero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
    }
    local baseRage = BarbarianBuildPassives.CreateRagePassive({ src = baseHero })
    baseRage:OnNormalAtkFinish({ data = { extraParam = { skillId = SkillRuntimeConfig.Ids.barbarian_basic_attack } } })
    local baseUntil = baseHero.passiveRuntime.barbarianBerserkUntilRound

    local hero = new_unit(9718, "ExtendedRageDuration")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
    }
    hero.buildState = {
        skillMods = {
            [SkillRuntimeConfig.Ids.barbarian_rage] = {
                rageDurationDelta = 1,
            },
        },
    }
    local rage = BarbarianBuildPassives.CreateRagePassive({ src = hero })
    rage:OnNormalAtkFinish({ data = { extraParam = { skillId = SkillRuntimeConfig.Ids.barbarian_basic_attack } } })
    assert_true(hero.passiveRuntime.barbarianBerserkUntilRound == baseUntil + 1, "Rage duration feat extends berserk by 1 round")
end

do
    local hero = new_unit(9719, "BloodrageHero")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
    }
    hero.hp = 40
    hero.maxHp = 100
    hero.passiveRuntime.barbarianBerserkUntilRound = 99
    hero.buildState = {
        skillMods = {
            [SkillRuntimeConfig.Ids.barbarian_rage] = {
                rageLifestealPct = 25,
            },
        },
    }
    local heal = BarbarianBuildPassives.ApplyRageLifesteal(hero, 12, "测试伤害")
    assert_true(heal == 3, "Rage lifesteal restores 25% of damage dealt")
    assert_true(hero.hp == 43, "Rage lifesteal heals the barbarian immediately")
end

do
    local hero = new_unit(9720, "RageShieldHero")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
    }
    hero.buildState = {
        skillMods = {
            [SkillRuntimeConfig.Ids.barbarian_rage] = {
                onRageEnterTempHpDice = "1d6",
            },
        },
    }
    local oldRollDice = BuildPassiveCommon.RollDice
    BuildPassiveCommon.RollDice = function(dice)
        if dice == "1d6" then
            return 6
        end
        return 0
    end
    BarbarianBuildPassives.TryActivateBerserk(hero)
    BuildPassiveCommon.RollDice = oldRollDice
    assert_true((tonumber(hero.tempHp) or 0) == 6, "Rage entry feat grants temporary hp immediately")
end

do
    local hero = new_unit(97205, "KillHealHero")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
    }
    hero.hp = 40
    hero.maxHp = 100
    hero.passiveRuntime.barbarianBerserkUntilRound = 99
    hero.buildState = {
        skillMods = {
            [SkillRuntimeConfig.Ids.barbarian_rage] = {
                onKillHealDice = "1d8",
            },
        },
    }
    local oldRollDice = BuildPassiveCommon.RollDice
    BuildPassiveCommon.RollDice = function(dice)
        if dice == "1d8" then
            return 8
        end
        return 0
    end
    local rage = BarbarianBuildPassives.CreateRagePassive({ src = hero })
    rage:OnDmgMakeKill({})
    BuildPassiveCommon.RollDice = oldRollDice
    assert_true(hero.hp == 48, "Rage kill feat heals on kill while berserk is active")
end

do
    local hero = new_unit(9721, "HeavyStrikeHero")
    local target = new_unit(9722, "HeavyStrikeTarget")
    hero.class = 10
    hero.hit = 8
    hero.strMod = 4
    local oldRollHit = BattleFormula.RollHit
    local oldResolve = BattleSkill.ResolveScaledDamage
    BattleFormula.RollHit = function(_, _, opts)
        return {
            hit = true,
            crit = false,
            total = 19 + (tonumber(opts and opts.attackBonus) or 0),
            roll = 19,
            bonus = tonumber(opts and opts.attackBonus) or 0,
            nat20 = false,
            nat1 = false,
            targetAC = tonumber(opts and opts.targetAC) or 10,
            raw = { 19 },
        }
    end
    BattleSkill.ResolveScaledDamage = function(_, _, opts)
        return {
            hit = { hit = true, crit = false },
            damage = 10,
            damageRoll = { expr = "1d12", total = 6 },
            isCrit = (tonumber(opts and opts.critMin) or 20) <= 19,
            attackBonus = tonumber(opts and opts.attackBonus) or 0,
            critMin = tonumber(opts and opts.critMin) or 20,
        }
    end

    local damage = BarbarianBuildPassives.PerformHeavyStrike(hero, target, {
        skillId = SkillRuntimeConfig.Ids.barbarian_heavy_strike,
        name = "重击",
    })

    BattleSkill.ResolveScaledDamage = oldResolve
    BattleFormula.RollHit = oldRollHit
    assert_true(damage == 14, "Heavy strike doubles strength bonus on top of base damage")
    assert_true(BattleBuff.GetBuffValueBySubType(hero, 880004) == 2, "Heavy strike applies AC -2 self debuff")
end

do
    BattleFormation.OnFinal()
    local hero = new_unit(9724, "SplitStrikeHero")
    local targetA = new_unit(9725, "FrontA")
    local targetB = new_unit(9726, "FrontB")
    local targetC = new_unit(9727, "BackC")
    hero.class = 10
    hero.hit = 8
    hero.strMod = 4
    hero.isLeft = true
    hero.wpType = 4
    hero.passiveRuntime.barbarianBerserkUntilRound = 99
    hero.buildState = {
        skillMods = {
            [SkillRuntimeConfig.Ids.barbarian_heavy_strike] = {
                bonusDamageDice = "1d6",
                splashAdjacentDice = "1d6",
                frontRowSplitTargets = 2,
                rageCritThresholdDelta = -1,
            },
        },
    }
    targetA.isLeft = false
    targetA.wpType = 1
    targetB.isLeft = false
    targetB.wpType = 2
    targetC.isLeft = false
    targetC.wpType = 5
    BattleFormation.Init({
        teamLeft = { hero },
        teamRight = { targetA, targetB, targetC },
    })
    local battleHero = BattleFormation.GetFriendTeam(hero)[1]
    local enemyTeam = BattleFormation.GetEnemyTeam(battleHero) or {}
    targetA = enemyTeam[1] or targetA
    targetB = enemyTeam[2] or targetB
    local oldResolve = BattleSkill.ResolveScaledDamage
    local oldApplyDamage = require("modules.battle_dmg_heal").ApplyDamage
    local oldBonus = BuildPassiveCommon.ApplyDirectBonusDamage
    local resolveCalls = {}
    local splashCalls = {}
    BattleSkill.ResolveScaledDamage = function(_, target, opts)
        resolveCalls[#resolveCalls + 1] = {
            targetId = target and target.instanceId or 0,
            damageDice = opts and opts.damageDice or "",
            critMin = opts and opts.critMin or 20,
        }
        return {
            hit = { hit = true, crit = false },
            damage = 10,
            damageRoll = { expr = opts and opts.damageDice or "", total = 6 },
            isCrit = false,
        }
    end
    require("modules.battle_dmg_heal").ApplyDamage = function() end
    BuildPassiveCommon.ApplyDirectBonusDamage = function(_, target, diceExpr)
        splashCalls[#splashCalls + 1] = {
            targetId = target and target.instanceId or 0,
            diceExpr = diceExpr,
        }
        return 4
    end
    BarbarianBuildPassives.PerformHeavyStrike(battleHero, targetA, {
        skillId = SkillRuntimeConfig.Ids.barbarian_heavy_strike,
        name = "重击",
    })
    BattleSkill.ResolveScaledDamage = oldResolve
    require("modules.battle_dmg_heal").ApplyDamage = oldApplyDamage
    BuildPassiveCommon.ApplyDirectBonusDamage = oldBonus
    assert_true(#resolveCalls == 2, "Heavy strike grandmaster splits onto a second front-row target")
    assert_true(resolveCalls[1].damageDice == "1d6", "Heavy strike consumes bonus damage dice")
    assert_true(resolveCalls[1].critMin == 18, "Heavy strike lowers crit threshold while berserk is active")
    assert_true(resolveCalls[2].targetId == targetB.instanceId, "Heavy strike split targets the second front-row enemy")
    assert_true(#splashCalls == 1 and splashCalls[1].targetId == targetB.instanceId and splashCalls[1].diceExpr == "1d6",
        "Heavy strike mastery splashes adjacent target with configured dice")
end

do
    local hero = new_unit(9728, "CritHero")
    local target = new_unit(9729, "CritTarget")
    hero.class = 10
    hero.hit = 8
    local oldRollHit = BattleFormula.RollHit
    BattleFormula.RollHit = function(_, _, opts)
        return {
            hit = true,
            crit = false,
            total = 19 + (tonumber(opts and opts.attackBonus) or 0),
            roll = 19,
            bonus = tonumber(opts and opts.attackBonus) or 0,
            nat20 = false,
            nat1 = false,
            targetAC = tonumber(opts and opts.targetAC) or 10,
            raw = { 19 },
        }
    end
    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        meta = {
            kind = "physical",
            damageDice = "",
        },
        attackBonus = hero.hit,
        critMin = 19,
    })
    BattleFormula.RollHit = oldRollHit
    assert_true(result ~= nil and result.isCrit == true, "Heavy strike doubles crit range to 19-20")
end

log("Barbarian build pipeline tests passed.")
