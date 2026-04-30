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
local RoguelikeReward = require("roguelike.roguelike_reward")
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

local function hasRewardFeat(options, featIds)
    local expected = {}
    for _, featId in ipairs(featIds or {}) do
        expected[tonumber(featId) or 0] = true
    end
    for _, option in ipairs(options or {}) do
        if expected[tonumber(option.featId) or 0] then
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
    local build = HeroBuild.CompileBuild(2, 2, {})
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_extra_attack), "Fighter Lv2 fixed feat grants extra attack")
    assert_true(not hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_action_surge), "Fighter Lv2 does not grant action surge yet")
end

do
    local build = HeroBuild.CompileBuild(2, 3, {
        FeatBuildConfig.Ids.fighter_action_surge,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_action_surge), "Fighter Lv3 action surge route grants action surge")
    assert_true(not hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv3 action surge route does not also grant guard stance")
end

do
    local build = HeroBuild.CompileBuild(2, 4, {
        FeatBuildConfig.Ids.fighter_guard,
        FeatBuildConfig.Ids.fighter_counter_basic,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv4 guard route grants guard stance")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_guard_counter), "Fighter Lv4 guard route grants guard counter passive")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_counter_basic), "Fighter Lv4 guard route can add counter basic passive")
end

do
    local build = HeroBuild.CompileBuild(2, 5, {
        FeatBuildConfig.Ids.fighter_action_surge,
        FeatBuildConfig.Ids.fighter_precise_attack,
        FeatBuildConfig.Ids.fighter_sweeping_attack,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_action_surge), "Fighter Lv5 offensive route keeps action surge active")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_extra_attack), "Fighter Lv5 offensive route grants extra attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_sweeping_attack), "Fighter Lv5 offensive route grants sweeping attack")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack), "SkillRuntime exports basic attack config")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_action_surge), "SkillRuntime exports action surge config")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_sweeping_attack), "SkillRuntime exports sweeping attack passive config")
end

do
    local build = HeroBuild.CompileBuild(2, 5, {
        FeatBuildConfig.Ids.fighter_guard,
        FeatBuildConfig.Ids.fighter_counter_basic,
        FeatBuildConfig.Ids.fighter_second_wind_mastery,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv5 defensive route keeps guard stance active")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_counter_basic), "Fighter Lv5 defensive route keeps counter basic passive")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_second_wind_mastery), "Fighter Lv5 defensive route grants second wind mastery")
end

do
    local level2Entry = ClassBuildProgression.GetLevelEntry(2, 2)
    local rewardState = RoguelikeReward.GenerateLevelUpRewardState({
        levelCap = 20,
        teamRoster = {
            {
                rosterId = 1,
                heroId = 900005,
                classId = 2,
                name = "Fighter",
                level = 1,
                currentHp = 100,
                isDead = false,
                feats = {},
            },
        },
    })
    assert_true(rewardState ~= nil, "Roguelike level-up state exists for fighter fixed node")
    assert_true(hasRewardFeat(rewardState.options, level2Entry and level2Entry.fixed or {}),
        "Roguelike level-up includes fighter fixed feat cards")
end

do
    local level3Entry = ClassBuildProgression.GetLevelEntry(2, 3)
    local rewardState = RoguelikeReward.GenerateLevelUpRewardState({
        levelCap = 20,
        teamRoster = {
            {
                rosterId = 1,
                heroId = 900005,
                classId = 2,
                name = "Fighter",
                level = 2,
                currentHp = 100,
                isDead = false,
                feats = ClassBuildProgression.CollectFixedFeatIds(2, 2),
            },
        },
    })
    local expectedChoices = FeatBuildConfig.GetFeatsByLevel(2, 3, level3Entry and level3Entry.choiceGroup or nil)
    local expectedChoiceIds = {}
    for _, def in ipairs(expectedChoices) do
        expectedChoiceIds[#expectedChoiceIds + 1] = def.id
    end
    assert_true(rewardState ~= nil, "Roguelike level-up state exists for fighter choice node")
    assert_true(hasRewardFeat(rewardState.options, expectedChoiceIds),
        "Roguelike level-up includes fighter choice-group feat cards")
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
