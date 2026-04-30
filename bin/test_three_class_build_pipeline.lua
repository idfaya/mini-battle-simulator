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

local FeatBuildConfig = require("config.feat_build_config")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.skill_runtime_config")
local HeroData = require("config.hero_data")

local function hasSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

do
    local build = HeroBuild.CompileBuild(3, 5, {
        FeatBuildConfig.Ids.monk_swift_step,
        FeatBuildConfig.Ids.monk_shadow_combo,
        FeatBuildConfig.Ids.monk_combo_mastery,
        FeatBuildConfig.Ids.monk_disruption_mastery,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_shadow_combo), "Monk Lv5 shadow route grants shadow combo")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.monk_extra_attack), "Monk Lv5 grants extra attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.monk_disruption_mastery), "Monk Lv5 grants disruption mastery")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk runtime exports basic attack")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_shadow_combo), "Monk runtime exports active route skill")
end

do
    local build = HeroBuild.CompileBuild(4, 5, {
        FeatBuildConfig.Ids.paladin_judgement_prayer,
        FeatBuildConfig.Ids.paladin_guardian_aura,
        FeatBuildConfig.Ids.paladin_aura_mastery,
        FeatBuildConfig.Ids.paladin_sanctuary_knight,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_basic_attack), "Paladin Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_guardian_aura), "Paladin Lv5 aura route grants guardian aura")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.paladin_divine_smite), "Paladin Lv5 keeps divine smite")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.paladin_extra_attack), "Paladin Lv5 grants extra attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.paladin_judgement_prayer), "Paladin Lv5 grants judgement prayer")
end

do
    local build = HeroBuild.CompileBuild(5, 5, {
        FeatBuildConfig.Ids.ranger_precise_shot,
        FeatBuildConfig.Ids.ranger_snare_shot,
        FeatBuildConfig.Ids.ranger_mark_mastery,
        FeatBuildConfig.Ids.ranger_snare_mastery,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_basic_attack), "Ranger Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_snare_shot), "Ranger Lv5 snare route grants snare shot")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_hunter_mark), "Ranger Lv5 keeps hunter mark")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_extra_attack), "Ranger Lv5 grants extra attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_snare_mastery), "Ranger Lv5 grants snare mastery")
end

do
    local monkHero = HeroData.ConvertToHeroData(900001, 5, 1, {
        buildFeatIds = {
            FeatBuildConfig.Ids.monk_swift_step,
            FeatBuildConfig.Ids.monk_shadow_combo,
            FeatBuildConfig.Ids.monk_combo_mastery,
            FeatBuildConfig.Ids.monk_disruption_mastery,
        },
    })
    assert_true(monkHero and monkHero.buildState ~= nil, "HeroData generic build compile works for monk")
    assert_true(hasSkill(monkHero.skillsConfig, SkillRuntimeConfig.Ids.monk_basic_attack), "HeroData exports monk build basic attack")

    local paladinHero = HeroData.ConvertToHeroData(900009, 5, 1, {
        buildFeatIds = {
            FeatBuildConfig.Ids.paladin_heavy_armor_prayer,
            FeatBuildConfig.Ids.paladin_vengeance_smite,
            FeatBuildConfig.Ids.paladin_smite_mastery,
            FeatBuildConfig.Ids.paladin_execution_knight,
        },
    })
    assert_true(paladinHero and paladinHero.buildState ~= nil, "HeroData generic build compile works for paladin")
    assert_true(hasSkill(paladinHero.skillsConfig, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "HeroData exports paladin build active")

    local rangerHero = HeroData.ConvertToHeroData(900008, 5, 1, {
        buildFeatIds = {
            FeatBuildConfig.Ids.ranger_precise_shot,
            FeatBuildConfig.Ids.ranger_hunter_shot,
            FeatBuildConfig.Ids.ranger_mark_mastery,
            FeatBuildConfig.Ids.ranger_hunter_mastery,
        },
    })
    assert_true(rangerHero and rangerHero.buildState ~= nil, "HeroData generic build compile works for ranger")
    assert_true(hasSkill(rangerHero.skillsConfig, SkillRuntimeConfig.Ids.ranger_hunter_shot), "HeroData exports ranger build active")
end

log("Three-class build pipeline tests passed.")
