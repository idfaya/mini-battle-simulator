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

local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local FeatPicker = require("roguelike.feat_picker")
local HeroData = require("config.hero_data")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.tables.skill_runtime")

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
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_counter_basic), "Fighter Lv1 has counter")
end

do
    local build = HeroBuild.CompileBuild(2, 2, {})
    assert_true(not hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_extra_attack), "Fighter Lv2 does not grant extra attack in three-tier build")
    assert_true(not hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_action_surge), "Fighter Lv2 does not grant action surge yet")
end

do
    local build = HeroBuild.CompileBuild(2, 3, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv3 fixed tier grants guard stance")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_guard_counter), "Fighter Lv3 fixed tier grants guard counter passive")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_counter_basic), "Fighter Lv3 keeps counter passive")
end

do
    local build = HeroBuild.CompileBuild(2, 5, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv5 keeps guard stance")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_second_wind), "Fighter Lv5 grants indomitable wind")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack), "SkillRuntime exports basic attack config")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_second_wind), "SkillRuntime exports indomitable wind passive config")
end

do
    -- 阶段 3：FeatPicker 升级三选一应能为 Lv2 fighter 暴露 fighter 候选 feat
    -- 设计：character_progression_design.md §3
    local LEVEL_EXP_THRESHOLDS = {
        [1] = 0, [2] = 8, [3] = 20, [4] = 36, [5] = 58, [6] = 86,
        [7] = 120, [8] = 160, [9] = 208, [10] = 264,
    }
    local fighter = HeroData.CreateClassUnit(2, {
        rosterId = 1,
        unitId = "fbp_fighter_lv2",
        promotionStage = "low",
        level = 2,
        teamState = "active",
        source = "fighter_build_pipeline_test",
    })
    -- 重置 feats（CreateClassUnit 默认填充 canonical feats，会让 Lv3 候选差集为空）
    fighter.feats = {}
    if fighter.buildState then
        fighter.buildState.featIds = {}
    end
    local mockState = {
        ownedUnits = { fighter },
        teamRoster = { fighter },
        benchRoster = {},
        partyLevel = 2,
        partyExp = 20,  -- 跨过 Lv3 阈值
        levelCap = 10,
    }
    local session = FeatPicker.BeginSession(mockState, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv2 fighter should get a feat-pick session at partyExp=20")
    local hasFighterOption = false
    for _, opt in ipairs(session.options or {}) do
        if tonumber(opt.classId) == 2 and tonumber(opt.rosterId) == 1 then
            hasFighterOption = true
            break
        end
    end
    assert_true(hasFighterOption, "feat-pick session should expose at least 1 fighter option")
end

do
    -- 阶段 3：手动给 fighter 加 Lv4 feat → CompileBuild 应正确解析为 build pipeline
    local fighterLv4Feats = FeatBuildConfig.GetFeatsByLevel(2, 4) or {}
    assert_true(#fighterLv4Feats > 0, "fixture sanity: fighter Lv4 should have feats")
    local extraFeatId = tonumber(fighterLv4Feats[1].id) or 0
    assert_true(extraFeatId > 0, "fixture sanity: fighter Lv4 feat should have valid id")
    -- 拿 Lv3 build 作为基础（包含 Lv1+Lv3 fixed feats），再追加 Lv4 选中 feat
    local build = HeroBuild.CompileBuild(2, 4, { extraFeatId })
    local seenExtra = false
    for _, fid in ipairs(build.featIds or {}) do
        if tonumber(fid) == extraFeatId then
            seenExtra = true
            break
        end
    end
    assert_true(seenExtra, "manually-added Lv4 feat should appear in compiled BuildState.featIds")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack),
        "Fighter Lv4 build still has basic attack")
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

