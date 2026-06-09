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

local canonicalSelections = function(classId, toLevel)
    return Common.canonicalSelections(ClassBuildProgression, classId, toLevel)
end
local hasSkill = Common.hasSkill
local findSkill = Common.findSkill

do
    local lv1Build = HeroBuild.CompileBuild(6, 1, {})
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv1 grants sacred flame")
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv1 grants healing word")
    assert_true(not hasSkill(lv1Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv1 does not grant shelter prayer yet")

    local lv2Build = HeroBuild.CompileBuild(6, 2, canonicalSelections(6, 2))
    assert_true(hasSkill(lv2Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_revival_prayer), "Cleric Lv2 canonical route grants revival prayer")
    assert_true(not hasSkill(lv2Build.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv2 canonical route does not grant blessing prayer yet")
    assert_true(not hasSkill(lv2Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_radiant_prayer), "Cleric Lv2 canonical route does not grant radiant prayer yet")

    local lv3Build = HeroBuild.CompileBuild(6, 3, canonicalSelections(6, 3))
    assert_true(hasSkill(lv3Build.activeSkills, SkillRuntimeConfig.Ids.cleric_turn_undead), "Cleric Lv3 grants turn undead as T1")
    assert_true(not hasSkill(lv3Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_radiant_prayer), "Cleric Lv3 still does not grant radiant prayer")

    local lv4Build = HeroBuild.CompileBuild(6, 4, canonicalSelections(6, 4))
    assert_true(hasSkill(lv4Build.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv4 canonical route grants blessing prayer")
    assert_true(not hasSkill(lv4Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_radiant_prayer), "Cleric Lv4 canonical route does not grant radiant prayer yet")

    local lv5Build = HeroBuild.CompileBuild(6, 5, canonicalSelections(6, 5))
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv5 keeps sacred flame")
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_turn_undead), "Cleric Lv5 keeps turn undead")
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv5 keeps healing word")
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv5 keeps blessing prayer")
    assert_true(not hasSkill(lv5Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv5 still does not grant aid grace passive")
    assert_true(not hasSkill(lv5Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_spell_mastery), "Cleric Lv5 does not grant sacred flame mastery yet")
    assert_true(((lv5Build.skillMods[SkillRuntimeConfig.Ids.cleric_turn_undead] or {}).executeThresholdPct) == 25, "Cleric Lv5 turn mastery upgrades execute threshold")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(lv5Build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv5 runtime exports blessing prayer")

    local lv6Build = HeroBuild.CompileBuild(6, 6, canonicalSelections(6, 6))
    assert_true(hasSkill(lv6Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv6 canonical route grants aid grace")

    local lv7Build = HeroBuild.CompileBuild(6, 7, canonicalSelections(6, 7))
    assert_true(((lv7Build.skillMods[SkillRuntimeConfig.Ids.cleric_turn_undead] or {}).bonusDamageDice) == "1d8", "Cleric Lv7 canonical route grants turn undead bonus damage")

    local lv8Build = HeroBuild.CompileBuild(6, 8, canonicalSelections(6, 8))
    assert_true(hasSkill(lv8Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_mastery), "Cleric Lv8 canonical route grants blessing mastery")

    local lv9Build = HeroBuild.CompileBuild(6, 9, canonicalSelections(6, 9))
    assert_true(hasSkill(lv9Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_healing_mastery), "Cleric Lv9 canonical route grants healing mastery")
end

do
    local revivalBuild = HeroBuild.CompileBuild(6, 2, {
        FeatBuildConfig.Ids.b_cleric_heal_plus,
    })
    assert_true(hasSkill(revivalBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_revival_prayer),
        "Cleric healing branch grants revival prayer passive")

    local turnBuild = HeroBuild.CompileBuild(6, 6, {
        FeatBuildConfig.Ids.cleric_guardian_domain,
        FeatBuildConfig.Ids.j_cleric_turn_master,
        FeatBuildConfig.Ids.b_cleric_turn_undead,
    })
    assert_true(not hasSkill(turnBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_radiant_prayer),
        "Cleric turn branch no longer grants sacred flame passive")
    assert_true(((turnBuild.skillMods[SkillRuntimeConfig.Ids.cleric_turn_undead] or {}).bonusDamageDice) == "1d8",
        "Cleric turn undead branch grants bonus damage dice")
    assert_true(((turnBuild.skillMods[SkillRuntimeConfig.Ids.cleric_turn_undead] or {}).executeThresholdPct) == 25,
        "Cleric turn mastery keeps execute threshold")

    local shelterBuild = HeroBuild.CompileBuild(6, 6, {
        FeatBuildConfig.Ids.cleric_shelter_prayer,
        FeatBuildConfig.Ids.b_cleric_shelter_plus,
    })
    assert_true(hasSkill(shelterBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer),
        "Cleric aid branch grants aid grace passive at skilled node")
    assert_true(((shelterBuild.skillMods[SkillRuntimeConfig.Ids.cleric_sanctuary_prayer] or {}).blessTempHpFlat) == 4,
        "Cleric aid plus upgrades blessing temp hp")

    local sanctuaryMasterBuild = HeroBuild.CompileBuild(6, 8, {
        FeatBuildConfig.Ids.cleric_shelter_prayer,
        FeatBuildConfig.Ids.b_cleric_shelter_plus,
        FeatBuildConfig.Ids.j_cleric_shelter_master,
    })
    assert_true(hasSkill(sanctuaryMasterBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_mastery),
        "Cleric blessing mastery grants blessing mastery passive")
    assert_true(((sanctuaryMasterBuild.skillMods[SkillRuntimeConfig.Ids.cleric_sanctuary_prayer] or {}).blessAcBonus) == 2,
        "Cleric blessing mastery upgrades blessing ac bonus")
    assert_true(((sanctuaryMasterBuild.skillMods[SkillRuntimeConfig.Ids.cleric_sanctuary_prayer] or {}).aidTargetCount) == nil,
        "Cleric blessing mastery no longer upgrades blessing aid target count")

    local basicSpellBuild = HeroBuild.CompileBuild(6, 2, {
        FeatBuildConfig.Ids.b_cleric_basic_spell_plus,
    })
    assert_true(hasSkill(basicSpellBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_radiant_prayer),
        "Cleric sacred flame branch grants radiant prayer passive at lv2")

    local spellMasterBuild = HeroBuild.CompileBuild(6, 4, {
        FeatBuildConfig.Ids.b_cleric_basic_spell_plus,
        FeatBuildConfig.Ids.j_cleric_basic_spell_master,
    })
    assert_true(hasSkill(spellMasterBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_spell_mastery),
        "Cleric sacred flame mastery grants spell mastery passive at lv4")

    local clericHero = HeroData.ConvertToHeroData(900007, 5, 1, {
        buildFeatIds = canonicalSelections(6, 5),
    })
    assert_true(clericHero and clericHero.buildState ~= nil, "HeroData generic build compile works for cleric")
    assert_true(hasSkill(clericHero.skillsConfig, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "HeroData Lv5 canonical cleric exports blessing prayer")
    assert_true((findSkill(clericHero.skillsConfig, SkillRuntimeConfig.Ids.cleric_basic_spell) or {}).skillType == 1,
        "HeroData exports cleric sacred flame as basic spell")
end

log("Cleric build pipeline tests passed.")
