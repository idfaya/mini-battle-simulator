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
local ClassBuildProgression = require("config.class_build_progression")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.skill_runtime_config")

local function hasSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

do
    local build = HeroBuild.CompileBuild(2, 1, {})
    assert_true(#build.featIds == 2, "Fighter Lv1 auto-grants 2 fixed feats")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack), "Fighter Lv1 has basic attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_second_wind), "Fighter Lv1 has second wind")
end

do
    local build = HeroBuild.CompileBuild(2, 2, {
        FeatBuildConfig.Ids.fighter_pressure_style,
    })
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_pressure_style), "Fighter Lv2 pressure route grants pressure style")
    assert_true(not hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_counter_basic), "Fighter Lv2 pressure route does not also grant counter style")
end

do
    local build = HeroBuild.CompileBuild(2, 3, {
        FeatBuildConfig.Ids.fighter_second_wind_followup,
        FeatBuildConfig.Ids.fighter_guard,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv3 guard route grants guard stance")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_guard_counter), "Fighter Lv3 guard route grants guard counter passive")
end

do
    local build = HeroBuild.CompileBuild(2, 5, {
        FeatBuildConfig.Ids.fighter_pressure_style,
        FeatBuildConfig.Ids.fighter_battle_master,
        FeatBuildConfig.Ids.fighter_signature_mastery,
        FeatBuildConfig.Ids.fighter_extra_attack_pressure,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_pressure_strike), "Fighter Lv5 pressure route keeps battle master active")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_extra_attack), "Fighter Lv5 pressure route grants extra attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_extra_attack_pressure), "Fighter Lv5 pressure route grants pressure modifier passive")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack), "SkillRuntime exports basic attack config")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_pressure_strike), "SkillRuntime exports pressure strike config")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_extra_attack_pressure), "SkillRuntime exports hidden pressure passive config")
end

do
    local oldCollectFixedFeatIds = ClassBuildProgression.CollectFixedFeatIds
    local oldCollectChoiceGroups = ClassBuildProgression.CollectChoiceGroups
    local oldGetFeat = FeatBuildConfig.GetFeat
    local oldRuntimeGet = SkillRuntimeConfig.Get

    ClassBuildProgression.CollectFixedFeatIds = function(classId, toLevel)
        if classId == 999 and toLevel == 1 then
            return { 990001, 990002, 990003 }
        end
        return oldCollectFixedFeatIds(classId, toLevel)
    end
    ClassBuildProgression.CollectChoiceGroups = function(classId, toLevel)
        if classId == 999 and toLevel == 1 then
            return {}
        end
        return oldCollectChoiceGroups(classId, toLevel)
    end
    FeatBuildConfig.GetFeat = function(featId)
        if featId == 990001 then
            return {
                id = featId,
                classId = 999,
                level = 1,
                effects = {
                    { type = "grant_skill", skill = 990101 },
                },
            }
        elseif featId == 990002 then
            return {
                id = featId,
                classId = 999,
                level = 1,
                effects = {
                    { type = "modify_skill", skill = 990101, add = { cooldown = 7, statMods = { maxHp = 25 } } },
                },
            }
        elseif featId == 990003 then
            return {
                id = featId,
                classId = 999,
                level = 1,
                effects = {
                    { type = "replace_skill", oldSkill = 990101, newSkill = 990102 },
                },
            }
        end
        return oldGetFeat(featId)
    end
    SkillRuntimeConfig.Get = function(skillId)
        if skillId == 990101 then
            return { id = 990101, runtimeKind = "active", classId = 999, name = "OldSkill", cooldown = 0, tags = {} }
        elseif skillId == 990102 then
            return { id = 990102, runtimeKind = "active", classId = 999, name = "NewSkill", cooldown = 0, tags = {} }
        end
        return oldRuntimeGet(skillId)
    end

    local build = HeroBuild.CompileBuild(999, 1, {})
    assert_true(hasSkill(build.activeSkills, 990102), "modify+replace pipeline keeps replaced skill")
    assert_true(not hasSkill(build.activeSkills, 990101), "replace removes old skill from final active list")
    assert_true((build.skillMods[990102] or {}).cooldown == 7, "replace migrates accumulated skill mods")
    assert_true((build.statMods.maxHp or 0) == 25, "modify_skill statMods are merged into BuildState")

    ClassBuildProgression.CollectFixedFeatIds = oldCollectFixedFeatIds
    ClassBuildProgression.CollectChoiceGroups = oldCollectChoiceGroups
    FeatBuildConfig.GetFeat = oldGetFeat
    SkillRuntimeConfig.Get = oldRuntimeGet
end

log("Fighter build pipeline tests passed.")
