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
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv1 grants holy spark")
    assert_true(hasSkill(lv1Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv1 grants shelter prayer passive")
    assert_true(not hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv1 does not grant healing word yet")

    local lv3Build = HeroBuild.CompileBuild(6, 3, canonicalSelections(6, 3))
    assert_true(hasSkill(lv3Build.activeSkills, SkillRuntimeConfig.Ids.cleric_turn_undead), "Cleric Lv3 grants turn undead as T1")
    assert_true(hasSkill(lv3Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_radiant_prayer), "Cleric Lv3 T1 grants radiant prayer")

    local lv4Build = HeroBuild.CompileBuild(6, 4, canonicalSelections(6, 4))
    assert_true(hasSkill(lv4Build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv4 grants healing word after T1")

    local lv5Build = HeroBuild.CompileBuild(6, 5, canonicalSelections(6, 5))
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv5 keeps holy spark")
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_turn_undead), "Cleric Lv5 keeps turn undead")
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv5 keeps healing word")
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv5 grants sanctuary prayer as T2")
    assert_true(hasSkill(lv5Build.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv5 keeps shelter prayer passive")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(lv5Build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric runtime exports sanctuary prayer")
end

do
    local shelterBuild = HeroBuild.CompileBuild(6, 2, { FeatBuildConfig.Ids.b_cleric_shelter_plus })
    assert_true(((shelterBuild.skillMods[SkillRuntimeConfig.Ids.cleric_shelter_prayer] or {}).shelterTempHpDice) == "1d4",
        "Cleric shelter plus grants temp hp dice on shelter trigger")

    local healBuild = HeroBuild.CompileBuild(6, 4, {
        FeatBuildConfig.Ids.cleric_healing_word,
        FeatBuildConfig.Ids.b_cleric_turn_undead,
    })
    assert_true(hasSkill(healBuild.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric healing branch grants healing word")

    local revivalBuild = HeroBuild.CompileBuild(6, 6, {
        FeatBuildConfig.Ids.cleric_healing_word,
        FeatBuildConfig.Ids.b_cleric_turn_undead,
        FeatBuildConfig.Ids.b_cleric_heal_plus,
    })
    assert_true(hasSkill(revivalBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_revival_prayer),
        "Cleric healing branch grants revival prayer passive")

    local sanctuaryMasterBuild = HeroBuild.CompileBuild(6, 8, {
        FeatBuildConfig.Ids.cleric_guardian_domain,
        FeatBuildConfig.Ids.b_cleric_shelter_plus,
        FeatBuildConfig.Ids.j_cleric_shelter_master,
    })
    assert_true(hasSkill(sanctuaryMasterBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_mastery),
        "Cleric sanctuary mastery grants sanctuary mastery passive")
    assert_true(((sanctuaryMasterBuild.skillMods[SkillRuntimeConfig.Ids.cleric_shelter_prayer] or {}).shelterPerUnit) == true,
        "Cleric sanctuary mastery upgrades shelter to per-unit")

    local spellMasterBuild = HeroBuild.CompileBuild(6, 8, {
        FeatBuildConfig.Ids.cleric_healing_word,
        FeatBuildConfig.Ids.cleric_guardian_domain,
        FeatBuildConfig.Ids.j_cleric_turn_master,
    })
    assert_true(hasSkill(spellMasterBuild.passiveSkills, SkillRuntimeConfig.Ids.cleric_spell_mastery),
        "Cleric turn mastery grants spell mastery passive")

    local clericHero = HeroData.ConvertToHeroData(900007, 5, 1, {
        buildFeatIds = canonicalSelections(6, 5),
    })
    assert_true(clericHero and clericHero.buildState ~= nil, "HeroData generic build compile works for cleric")
    assert_true(hasSkill(clericHero.skillsConfig, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "HeroData exports cleric sanctuary prayer")
    assert_true((findSkill(clericHero.skillsConfig, SkillRuntimeConfig.Ids.cleric_basic_spell) or {}).skillType == 1,
        "HeroData exports cleric holy spark as basic spell")
end

log("Cleric build pipeline tests passed.")
