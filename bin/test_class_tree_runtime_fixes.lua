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
local RangerBuildPassives = require("skills.ranger_build_passives")
local PaladinBuildPassives = require("skills.paladin_build_passives")
local SkillEffectRegistry = require("skills.skill_effect_registry")
local BattleSkillStatus = require("skills.battle_skill_status")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local skill_80009003 = require("config.skill.skill_80009003")

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
        comboTriggerChanceDelta = 15,
    }
    monk.buildState.skillMods[IDS.monk_basic_attack] = {
        hitAcDelta = 1,
        bonusHit = 1,
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
    assert_true(comboCalls == 1, "monk combo chance delta lets 60% roll trigger")
    assert_true(MonkBuildPassives.GetShadowStepAcBonus(monk, nil) == 1, "shadow step grants temporary AC")
    local basicOpts = BuildPassiveCommon.BuildBasicAttackResolveOpts(monk, target, { skillId = IDS.monk_basic_attack })
    assert_true(basicOpts.attackBonus == 1, "shadow step queues next basic attack hit bonus")

    monk.passiveRuntime = {}
    monk.buildState.skillMods[IDS.monk_martial_arts].firstHitGuaranteedCombo = true
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
    monk.buildState.skillMods[IDS.monk_martial_arts].comboReentryOnce = 1
    local reentryCalls = 0
    math.random = function() return 1 end
    BattleSkill.CastSmallSkillWithResult = function()
        reentryCalls = reentryCalls + 1
        if reentryCalls == 1 then
            passive:OnNormalAtkFinish({
                data = {
                    extraParam = {
                        skillId = IDS.monk_basic_attack,
                        target = target,
                        damageDealt = 5,
                    },
                },
            })
        end
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
    assert_true(reentryCalls == 2, "monk combo reentry once accepts numeric feat mod and triggers one extra reentry")
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
    local passive = RangerBuildPassives.CreateHunterMarkPassive({ src = ranger })
    local oldApply = BuildPassiveCommon.ApplyDirectBonusDamage
    local applyCalls = {}
    BuildPassiveCommon.ApplyDirectBonusDamage = function(_, _, diceExpr)
        applyCalls[#applyCalls + 1] = diceExpr
        return 3
    end
    passive:OnNormalAtkFinish({
        data = { extraParam = { skillId = IDS.ranger_basic_attack, target = enemyA, damageDealt = 5 } },
    })
    passive:OnNormalAtkFinish({
        data = { extraParam = { skillId = IDS.ranger_basic_attack, target = enemyA, damageDealt = 5 } },
    })
    RangerBuildPassives.ApplyHunterMark(ranger, enemyB)
    passive:OnNormalAtkFinish({
        data = { extraParam = { skillId = IDS.ranger_basic_attack, target = enemyB, damageDealt = 5 } },
    })
    BuildPassiveCommon.ApplyDirectBonusDamage = oldApply
    assert_true(#applyCalls == 2, "ranger mark payout can trigger twice per round but not on same target")
    assert_true(applyCalls[1] == "1d4;1d4", "ranger mark bonus dice merges extra feat dice")
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
