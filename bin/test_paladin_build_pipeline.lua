local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local Common = dofile(script_dir .. "test_helpers/class_build_test_common.lua")
Common.bootstrapFromCaller(script_source)
local assert_true, log = Common.makeAssert()

local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local HeroData = require("config.hero_data")
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleMain = require("modules.battle_main")
local PaladinBuildPassives = require("skills.paladin_build_passives")

local canonicalSelections = function(classId, toLevel)
    return Common.canonicalSelections(ClassBuildProgression, classId, toLevel)
end
local hasSkill = Common.hasSkill
local findSkill = Common.findSkill
local new_unit = Common.newUnit

do
    local lv1Build = HeroBuild.CompileBuild(4, 1, {})
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.paladin_basic_attack), "Paladin Lv1 grants basic attack")
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.paladin_lay_on_hands), "Paladin Lv1 grants lay on hands as root skill")
    assert_true(not hasSkill(lv1Build.passiveSkills, SkillRuntimeConfig.Ids.paladin_shelter_prayer), "Paladin Lv1 no longer starts with holy shelter")

    local lv2Build = HeroBuild.CompileBuild(4, 2, canonicalSelections(4, 2))
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).cleanseDebuffs) == true,
        "Paladin Lv2 first child enables lay on hands cleanse")
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).cooldownDelta) == nil,
        "Paladin Lv2 lay on hands mastery does not reduce cooldown on a per-battle limited skill")

    local comboBuild = HeroBuild.CompileBuild(4, 2, { FeatBuildConfig.Ids.b_paladin_combo_basic })
    assert_true(hasSkill(comboBuild.passiveSkills, SkillRuntimeConfig.Ids.paladin_extra_attack),
        "Paladin combo basic grants extra attack passive")
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).bonusHealDice) == nil,
        "Paladin Lv2 first child no longer adds extra heal dice")
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.paladin_lay_on_hands] or {}).postHealShield) == nil,
        "Paladin Lv2 first child no longer grants post-heal shield")

    local lv3Build = HeroBuild.CompileBuild(4, 3, canonicalSelections(4, 3))
    assert_true(hasSkill(lv3Build.activeSkills, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "Paladin Lv3 grants smite evil as T1")

    local lv4Build = HeroBuild.CompileBuild(4, 4, canonicalSelections(4, 4))
    assert_true(((lv4Build.skillMods[SkillRuntimeConfig.Ids.paladin_vengeance_smite] or {}).bonusDamageDice) == "1d8",
        "Paladin Lv4 first post-T1 child upgrades smite evil")

    local sel = canonicalSelections(4, 5)
    local build = HeroBuild.CompileBuild(4, 5, sel)
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_basic_attack), "Paladin Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "Paladin Lv5 keeps smite evil")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_lay_on_hands), "Paladin Lv5 grants lay on hands")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.paladin_shelter_prayer), "Paladin Lv5 grants holy shelter as T2")
    assert_true(not hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_guardian_aura), "Paladin Lv5 does not auto-grant guardian aura active")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true((findSkill(runtimeSkills, SkillRuntimeConfig.Ids.paladin_lay_on_hands) or {}).skillType == 3,
        "Paladin runtime exports lay on hands as LIMITED")
end

do
    local paladin = new_unit(9051, "AuraPaladin", 4, 2)
    local ally = new_unit(9052, "AuraAlly", 2, 1)
    paladin.buildState = { skillMods = {}, classMods = { paladinAuraSaveBonus = 1 } }
    paladin.skills = {
        { skillId = SkillRuntimeConfig.Ids.paladin_shelter_prayer },
    }
    local oldGetFriendTeam = BattleFormation.GetFriendTeam
    BattleFormation.GetFriendTeam = function()
        return { paladin, ally }
    end
    assert_true(PaladinBuildPassives.GetAuraAcBonus(ally, nil) >= 1, "paladin aura grants AC bonus to ally")
    assert_true(PaladinBuildPassives.GetAuraSaveBonus(ally, "will") >= 1, "paladin aura grants saving throw bonus after aura mastery mods")
    BattleFormation.GetFriendTeam = oldGetFriendTeam
end

do
    local paladinHero = HeroData.ConvertToHeroData(900009, 5, 1, {
        buildFeatIds = canonicalSelections(4, 5),
    })
    assert_true(paladinHero and paladinHero.buildState ~= nil, "HeroData generic build compile works for paladin")
    assert_true(hasSkill(paladinHero.skillsConfig, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "HeroData exports paladin mid-tier active")
end

do
    BattleFormation.OnFinal()

    local paladin = new_unit(9301, "DecisionPaladin", 4, 1)
    local ally = new_unit(9302, "PaladinAlly", 2, 1)
    local enemy = new_unit(9303, "PaladinEnemy", 2, 1)
    enemy.isLeft = false
    paladin.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(4, 5, canonicalSelections(4, 5)))

    BattleFormation.Init({
        teamLeft = { paladin, ally },
        teamRight = { enemy },
    })

    local teamLeft = BattleFormation.GetTeams()
    local battlePaladin = teamLeft[1]
    local battleAlly = teamLeft[2]
    BattleSkill.Init(battlePaladin, battlePaladin.skillsConfig)
    battlePaladin.hp = 99
    battlePaladin.maxHp = 100
    battleAlly.hp = 100
    battleAlly.maxHp = 100
    local minorInjurySkill = BattleMain.DebugSelectAvailableSkill(battlePaladin)
    assert_true(minorInjurySkill and minorInjurySkill.skillId ~= SkillRuntimeConfig.Ids.paladin_lay_on_hands,
        "Paladin does not spend lay on hands when only 1 HP is missing")

    battlePaladin.hp = 51
    battlePaladin.maxHp = 100
    battleAlly.hp = 100
    battleAlly.maxHp = 100
    local aboveHalfSkill = BattleMain.DebugSelectAvailableSkill(battlePaladin)
    assert_true(aboveHalfSkill and aboveHalfSkill.skillId ~= SkillRuntimeConfig.Ids.paladin_lay_on_hands,
        "Paladin does not spend lay on hands above half HP")

    battlePaladin.hp = 50
    battlePaladin.maxHp = 100
    battleAlly.hp = 28
    battleAlly.maxHp = 100
    local emergencySkill, emergencyTargets = BattleMain.DebugSelectAvailableSkill(battlePaladin)
    assert_true(emergencySkill and emergencySkill.skillId == SkillRuntimeConfig.Ids.paladin_lay_on_hands,
        "Paladin uses lay on hands automatically at half HP")
    assert_true(#(emergencyTargets or {}) == 1 and emergencyTargets[1] == battlePaladin,
        "Paladin targets self with lay on hands when self is at half HP")

    BattleFormation.OnFinal()
end

log("Paladin build pipeline tests passed.")
