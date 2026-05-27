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

-- §5 单轨：直接用 GetCanonicalFeatChain 拓扑链路，去掉 Lv1 fixed。
local function canonicalSelections(classId, toLevel)
    local lv1Set = {}
    for _, fid in ipairs(ClassBuildProgression.GetLv1FeatIds(classId)) do
        lv1Set[tonumber(fid) or 0] = true
    end
    local selections = {}
    for _, fid in ipairs(ClassBuildProgression.GetCanonicalFeatChain(classId, toLevel)) do
        if not lv1Set[tonumber(fid) or 0] then
            selections[#selections + 1] = fid
        end
    end
    return selections
end

do
    -- §5 SSOT：fighter Lv1 自动获得 fighter_training + fighter_counter_basic。
    local build = HeroBuild.CompileBuild(2, 1, {})
    assert_true(#build.featIds == 2, "Fighter Lv1 auto-grants 2 lv1FeatIds")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack), "Fighter Lv1 has basic attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_counter_basic), "Fighter Lv1 has counter")
end

do
    -- §5 单轨：Lv3 取 trunk T1 = fighter_guard，验证 guard stance + counter。
    local build = HeroBuild.CompileBuild(2, 3, { FeatBuildConfig.Ids.fighter_guard })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv3 guard choice grants guard stance")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_guard_counter), "Fighter Lv3 guard choice grants guard counter passive")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.fighter_counter_basic), "Fighter Lv3 keeps Lv1 counter passive")
end

do
    -- §5 单轨：Lv5 走 canonical 拓扑链路（自动包括 fighter_guard T1 + fighter_second_wind T2）。
    local build = HeroBuild.CompileBuild(2, 5, canonicalSelections(2, 5))
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_guard_stance), "Fighter Lv5 keeps guard stance")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_second_wind_action), "Fighter Lv5 grants second wind action")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack), "SkillRuntime exports basic attack config")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.fighter_second_wind_action), "SkillRuntime exports second wind action config")
end

do
    -- 阶段 3：FeatPicker 升级三选一应能为 Lv2 fighter 暴露 fighter 候选 feat。
    local LevelCurve = require("config.roguelike.level_curve")
    local LEVEL_EXP_THRESHOLDS = LevelCurve.LEVEL_EXP_THRESHOLDS
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
        partyLevel = 1,
        partyExp = LevelCurve.GetExpThreshold(2) + 1,
        levelCap = 10,
    }
    local session = FeatPicker.BeginSession(mockState, LEVEL_EXP_THRESHOLDS)
    assert_true(session ~= nil, "Lv2 fighter should get a feat-pick session past Lv2 threshold")
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
    -- §5 SSOT：classes.json 已为 fighter 注入 treePool；验证 loader 正确读到。
    local pool = ClassBuildProgression.GetTreePool(2) or {}
    assert_true(#pool >= 12, "fighter treePool should contain at least 12 tree feat ids, got "..#pool)
    -- treePool 同时包含 §5 树节点（≥2300000 新 namespace）和 trunk T1/T2 旧 entry id。
    local treeFeatCount = 0
    for _, fid in ipairs(pool) do
        local feat = FeatBuildConfig.GetFeat(fid)
        assert_true(feat ~= nil, "treePool id "..tostring(fid).." should resolve to a feat in FeatBuildConfig")
        assert_true(feat.classId == 2, "treePool id "..tostring(fid).." should belong to classId=2")
        if fid >= 2300000 then
            treeFeatCount = treeFeatCount + 1
        end
    end
    assert_true(treeFeatCount >= 12, "treePool should contain at least 12 §5 tree-namespace feats, got "..treeFeatCount)
end

do
    -- §5 单轨：手动给 fighter 加 Lv2 B 节点 → CompileBuild 应正确解析并校验 prereq。
    local fighterLv2Feats = FeatBuildConfig.GetFeatsByLevel(2, 2) or {}
    assert_true(#fighterLv2Feats > 0, "fixture sanity: fighter Lv2 should have B feats in §5 tree")
    local extraFeatId = tonumber(fighterLv2Feats[1].id) or 0
    assert_true(extraFeatId > 0, "fixture sanity: fighter Lv2 feat should have valid id")
    local build = HeroBuild.CompileBuild(2, 4, { extraFeatId, FeatBuildConfig.Ids.fighter_guard })
    local seenExtra = false
    for _, fid in ipairs(build.featIds or {}) do
        if tonumber(fid) == extraFeatId then
            seenExtra = true
            break
        end
    end
    assert_true(seenExtra, "manually-added Lv2 feat should appear in compiled BuildState.featIds")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.fighter_basic_attack),
        "Fighter Lv4 build still has basic attack")
end

do
    -- §5 单轨：modify_skill / replace_skill pipeline 仍正确。
    -- 用 mock class 999 + 自定义 feat 验证 build 管线本身。
    local oldGetLv1 = ClassBuildProgression.GetLv1FeatIds
    local oldGetTreePool = ClassBuildProgression.GetTreePool
    local oldHasClass = ClassBuildProgression.HasClass
    local oldGetFeat = FeatBuildConfig.GetFeat
    local oldRuntimeGet = SkillRuntimeConfig.Get

    ClassBuildProgression.GetLv1FeatIds = function(classId)
        if classId == 999 then return { 990001, 990002, 990003 } end
        return oldGetLv1(classId)
    end
    ClassBuildProgression.GetTreePool = function(classId)
        if classId == 999 then return {} end
        return oldGetTreePool(classId)
    end
    ClassBuildProgression.HasClass = function(classId)
        if classId == 999 then return true end
        return oldHasClass(classId)
    end
    FeatBuildConfig.GetFeat = function(featId)
        if featId == 990001 then
            return {
                id = featId, classId = 999, level = 1,
                effects = { { type = "grant_skill", skill = 990101 } },
            }
        elseif featId == 990002 then
            return {
                id = featId, classId = 999, level = 1,
                effects = { { type = "modify_skill", skill = 990101, add = { cooldown = 7, statMods = { maxHp = 25 } } } },
            }
        elseif featId == 990003 then
            return {
                id = featId, classId = 999, level = 1,
                effects = { { type = "replace_skill", oldSkill = 990101, newSkill = 990102 } },
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

    ClassBuildProgression.GetLv1FeatIds = oldGetLv1
    ClassBuildProgression.GetTreePool = oldGetTreePool
    ClassBuildProgression.HasClass = oldHasClass
    FeatBuildConfig.GetFeat = oldGetFeat
    SkillRuntimeConfig.Get = oldRuntimeGet
end

log("Fighter build pipeline tests passed.")
