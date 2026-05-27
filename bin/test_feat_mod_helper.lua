-- FeatModHelper 单元测试
-- 设计文档：design/roguelike_feat_skill_fill_sheet.md §6
-- 验证 helper 对 hero.buildState.skillMods / classMods 的容错读取行为。
local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true, preload = false })

local FeatModHelper = require("skills.feat_mod_helper")

local function assert_true(cond, msg)
    if not cond then
        io.stderr:write("ASSERT FAIL: " .. tostring(msg or "assert_true failed") .. "\n")
        os.exit(1)
    end
end

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        io.stderr:write(string.format("ASSERT FAIL: %s (expected=%s, actual=%s)\n",
            tostring(msg or "assert_eq failed"),
            tostring(expected),
            tostring(actual)))
        os.exit(1)
    end
end

-- 用例 1：hero 为 nil → GetSkillMod 返回 default
do
    assert_eq(FeatModHelper.GetSkillMod(nil, 100, "cooldownDelta", -1), -1,
        "hero=nil should return default")
    assert_eq(FeatModHelper.GetClassMod(nil, "markSlotMax", 7), 7,
        "hero=nil GetClassMod should return default")
end

-- 用例 2：hero 没有 buildState → 返回 default
do
    local hero = { name = "ghost" }
    assert_eq(FeatModHelper.GetSkillMod(hero, 100, "cooldownDelta", -2), -2,
        "missing buildState should return default")
    assert_eq(FeatModHelper.GetClassMod(hero, "markSlotMax", 5), 5,
        "missing buildState GetClassMod should return default")
end

-- 用例 3：buildState.skillMods[skillId][key] 是数字 → 返回该数字
do
    local hero = {
        buildState = {
            skillMods = {
                [100] = { cooldownDelta = -1, bonusHit = 1 },
            },
        },
    }
    assert_eq(FeatModHelper.GetSkillMod(hero, 100, "cooldownDelta", 0), -1,
        "skillMods numeric value should be returned")
    assert_eq(FeatModHelper.GetSkillMod(hero, 100, "bonusHit", 0), 1,
        "skillMods bonusHit value should be returned")
end

-- 用例 4：buildState.skillMods[skillId][key] 不存在 → 返回 default
do
    local hero = {
        buildState = {
            skillMods = {
                [100] = { cooldownDelta = -1 },
            },
        },
    }
    assert_eq(FeatModHelper.GetSkillMod(hero, 100, "bonusHit", 3), 3,
        "missing key should return default")
    assert_eq(FeatModHelper.GetSkillMod(hero, 999, "cooldownDelta", -9), -9,
        "missing skillId entry should return default")
end

-- 用例 5：buildState.classMods[key] 是数字 → GetClassMod 返回该数字
do
    local hero = {
        buildState = {
            classMods = {
                markSlotMax = 2,
                markPayoutPerRound = 2,
            },
        },
    }
    assert_eq(FeatModHelper.GetClassMod(hero, "markSlotMax", 1), 2,
        "classMods numeric value should be returned")
    assert_eq(FeatModHelper.GetClassMod(hero, "markPayoutPerRound", 1), 2,
        "classMods markPayoutPerRound should be returned")
end

-- 用例 6：buildState.classMods[key] 不存在 → GetClassMod 返回 default
do
    local hero = {
        buildState = {
            classMods = { markSlotMax = 2 },
        },
    }
    assert_eq(FeatModHelper.GetClassMod(hero, "markRecastPerRound", 4), 4,
        "missing classMods key should return default")
    -- 完全没有 classMods 表也应该回退 default
    local hero2 = { buildState = {} }
    assert_eq(FeatModHelper.GetClassMod(hero2, "markSlotMax", 1), 1,
        "missing classMods table should return default")
end

-- 用例 7：HasFlag 三种状态
do
    local hero = {
        buildState = {
            skillMods = {
                [200] = {
                    guardExtendsToRanged = true,
                    guardEmitsTeamShield = false,
                },
            },
        },
    }
    assert_eq(FeatModHelper.HasFlag(hero, 200, "guardExtendsToRanged"), true,
        "true flag should return true")
    assert_eq(FeatModHelper.HasFlag(hero, 200, "guardEmitsTeamShield"), false,
        "false flag should return false")
    assert_eq(FeatModHelper.HasFlag(hero, 200, "comboReentryOnce"), false,
        "missing flag should return false")
    assert_eq(FeatModHelper.HasFlag(nil, 200, "guardExtendsToRanged"), false,
        "nil hero HasFlag should return false")
end

-- 用例 8：数字字段 default 为 nil 时返回 0
do
    assert_eq(FeatModHelper.GetSkillMod(nil, 100, "cooldownDelta"), 0,
        "GetSkillMod with nil default should return 0")
    assert_eq(FeatModHelper.GetClassMod(nil, "markSlotMax"), 0,
        "GetClassMod with nil default should return 0")
    local hero = { buildState = { skillMods = { [100] = {} } } }
    assert_eq(FeatModHelper.GetSkillMod(hero, 100, "missing"), 0,
        "missing key with nil default should return 0")
end

-- 用例 9：hero_build.applyModifySkill 的 patch.classMods 通道（集成）
do
    local FeatBuildConfig = require("config.tables.feats")
    local ClassBuildProgression = require("config.tables.classes")
    local SkillRuntimeConfig = require("config.tables.skill_runtime")
    local HeroBuild = require("modules.hero_build")

    local oldGetLv1 = ClassBuildProgression.GetLv1FeatIds
    local oldGetTreePool = ClassBuildProgression.GetTreePool
    local oldHasClass = ClassBuildProgression.HasClass
    local oldGetFeat = FeatBuildConfig.GetFeat
    local oldRuntimeGet = SkillRuntimeConfig.Get

    ClassBuildProgression.GetLv1FeatIds = function(classId)
        if classId == 998 then
            return { 998001, 998002 }
        end
        return oldGetLv1(classId)
    end
    ClassBuildProgression.GetTreePool = function(classId)
        if classId == 998 then
            return {}
        end
        return oldGetTreePool(classId)
    end
    ClassBuildProgression.HasClass = function(classId)
        if classId == 998 then return true end
        return oldHasClass(classId)
    end
    FeatBuildConfig.GetFeat = function(featId)
        if featId == 998001 then
            return {
                id = featId, classId = 998, level = 1,
                effects = { { type = "grant_skill", skill = 998101 } },
            }
        elseif featId == 998002 then
            return {
                id = featId, classId = 998, level = 1,
                effects = {
                    { type = "modify_skill", skill = 998101, add = {
                        cooldownDelta = -1,
                        classMods = { markSlotMax = 2, markPayoutPerRound = 2 },
                    } },
                },
            }
        end
        return oldGetFeat(featId)
    end
    SkillRuntimeConfig.Get = function(skillId)
        if skillId == 998101 then
            return { id = 998101, runtimeKind = "active", classId = 998, name = "Probe", cooldown = 0, tags = {} }
        end
        return oldRuntimeGet(skillId)
    end

    local build = HeroBuild.CompileBuild(998, 1, {})
    local fakeHero = { buildState = build }
    assert_eq(FeatModHelper.GetSkillMod(fakeHero, 998101, "cooldownDelta", 0), -1,
        "skillMods cooldownDelta should be merged via applyModifySkill")
    assert_eq(FeatModHelper.GetClassMod(fakeHero, "markSlotMax", 0), 2,
        "patch.classMods.markSlotMax should be merged into buildState.classMods")
    assert_eq(FeatModHelper.GetClassMod(fakeHero, "markPayoutPerRound", 0), 2,
        "patch.classMods.markPayoutPerRound should be merged into buildState.classMods")

    ClassBuildProgression.GetLv1FeatIds = oldGetLv1
    ClassBuildProgression.GetTreePool = oldGetTreePool
    ClassBuildProgression.HasClass = oldHasClass
    FeatBuildConfig.GetFeat = oldGetFeat
    SkillRuntimeConfig.Get = oldRuntimeGet
end

print("[test_feat_mod_helper] OK")
