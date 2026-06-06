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

do
    local lv1Build = HeroBuild.CompileBuild(1, 1, {})
    assert_true(hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.rogue_basic_attack), "Rogue Lv1 grants basic attack")
    assert_true(hasSkill(lv1Build.passiveSkills, SkillRuntimeConfig.Ids.rogue_sneak_attack), "Rogue Lv1 grants sneak attack passive")
    assert_true(not hasSkill(lv1Build.activeSkills, SkillRuntimeConfig.Ids.rogue_cunning_strike_build), "Rogue Lv1 does not grant cunning strike yet")

    local lv3Build = HeroBuild.CompileBuild(1, 3, canonicalSelections(1, 3))
    assert_true(hasSkill(lv3Build.passiveSkills, SkillRuntimeConfig.Ids.rogue_uncanny_dodge), "Rogue Lv3 grants uncanny dodge as T1")

    local lv5Build = HeroBuild.CompileBuild(1, 5, canonicalSelections(1, 5))
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.rogue_basic_attack), "Rogue Lv5 keeps basic attack")
    assert_true(hasSkill(lv5Build.activeSkills, SkillRuntimeConfig.Ids.rogue_cunning_strike_build), "Rogue Lv5 grants cunning strike as T2")
    assert_true(hasSkill(lv5Build.passiveSkills, SkillRuntimeConfig.Ids.rogue_sneak_attack), "Rogue Lv5 keeps sneak attack")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(lv5Build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.rogue_cunning_strike_build), "Rogue runtime exports cunning strike")
end

do
    local lv2Build = HeroBuild.CompileBuild(1, 2, { FeatBuildConfig.Ids.b_rogue_sneak_bonus })
    assert_true(((lv2Build.skillMods[SkillRuntimeConfig.Ids.rogue_sneak_attack] or {}).sneakDiceCountDelta) == 1,
        "Rogue sneak bonus adds one extra sneak damage die")

    local rogueHero = HeroData.ConvertToHeroData(900006, 5, 1, {
        buildFeatIds = canonicalSelections(1, 5),
    })
    assert_true(rogueHero and rogueHero.buildState ~= nil, "HeroData generic build compile works for rogue")
    assert_true(hasSkill(rogueHero.skillsConfig, SkillRuntimeConfig.Ids.rogue_cunning_strike_build), "HeroData exports rogue cunning strike")
end

log("Rogue build pipeline tests passed.")
