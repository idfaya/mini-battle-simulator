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
    local build = HeroBuild.CompileBuild(3, 5, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_open_hand), "Monk Lv5 keeps open hand")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_harmonize), "Monk Lv5 grants still mind")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.monk_martial_arts), "Monk Lv5 keeps combo")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk runtime exports basic attack")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_open_hand), "Monk runtime exports mid-tier active skill")
end

do
    local build = HeroBuild.CompileBuild(4, 5, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_basic_attack), "Paladin Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "Paladin Lv5 keeps smite evil")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.paladin_lay_on_hands), "Paladin Lv5 grants lay on hands")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.paladin_shelter_prayer), "Paladin Lv5 keeps holy shelter")
end

do
    local build = HeroBuild.CompileBuild(5, 5, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_basic_attack), "Ranger Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_hunter_shot), "Ranger Lv5 grants hunting guide")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_hunter_mark), "Ranger Lv5 keeps hunter mark")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_extra_attack), "Ranger Lv5 grants extra attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_hunter_mastery), "Ranger Lv5 grants arrow rain")
end

do
    local monkHero = HeroData.ConvertToHeroData(900001, 5, 1, {
        buildFeatIds = {},
    })
    assert_true(monkHero and monkHero.buildState ~= nil, "HeroData generic build compile works for monk")
    assert_true(hasSkill(monkHero.skillsConfig, SkillRuntimeConfig.Ids.monk_basic_attack), "HeroData exports monk build basic attack")

    local paladinHero = HeroData.ConvertToHeroData(900009, 5, 1, {
        buildFeatIds = {},
    })
    assert_true(paladinHero and paladinHero.buildState ~= nil, "HeroData generic build compile works for paladin")
    assert_true(hasSkill(paladinHero.skillsConfig, SkillRuntimeConfig.Ids.paladin_vengeance_smite), "HeroData exports paladin mid-tier active")

    local rangerHero = HeroData.ConvertToHeroData(900008, 5, 1, {
        buildFeatIds = {},
    })
    assert_true(rangerHero and rangerHero.buildState ~= nil, "HeroData generic build compile works for ranger")
    assert_true(hasSkill(rangerHero.skillsConfig, SkillRuntimeConfig.Ids.ranger_hunter_shot), "HeroData exports ranger build active")
end

log("Three-class build pipeline tests passed.")
