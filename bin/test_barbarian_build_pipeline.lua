local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local Common = dofile(script_dir .. "test_helpers/class_build_test_common.lua")
Common.bootstrapFromCaller(script_source)
local assert_true, log = Common.makeAssert()

local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BarbarianBuildPassives = require("skills.barbarian_build_passives")
local BuildPassiveCommon = require("skills.build_passive_common")

local canonicalSelections = function(classId, toLevel)
    return Common.canonicalSelections(ClassBuildProgression, classId, toLevel)
end

do
    local recoveryBuild = HeroBuild.CompileBuild(10, 2, { FeatBuildConfig.Ids.b_barbarian_rage_recovery })
    assert_true(((recoveryBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_rage] or {}).onRageEnterHealDice) == "1d6",
        "Barbarian rage recovery heals on berserk entry")
    assert_true(((recoveryBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_rage] or {}).onRageEnterTempHpDice) == nil,
        "Barbarian rage recovery no longer grants temp hp")

    local cleaveSel = canonicalSelections(10, 6)
    cleaveSel[#cleaveSel + 1] = FeatBuildConfig.Ids.j_barbarian_heavy_master
    local cleaveBuild = HeroBuild.CompileBuild(10, 7, cleaveSel)
    assert_true(((cleaveBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_heavy_strike] or {}).acPenaltyDelta) == -1,
        "Barbarian heavy mastery reduces self ac penalty")
    assert_true(((cleaveBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_heavy_strike] or {}).frontRowSplitTargets) == 2,
        "Barbarian cleave enables front-row split")

    local capstoneSel = canonicalSelections(10, 6)
    capstoneSel[#capstoneSel + 1] = FeatBuildConfig.Ids.b_barbarian_heavy_echo
    capstoneSel[#capstoneSel + 1] = FeatBuildConfig.Ids.j_barbarian_heavy_master
    capstoneSel[#capstoneSel + 1] = FeatBuildConfig.Ids.c_barbarian_strike_master
    local capstoneBuild = HeroBuild.CompileBuild(10, 10, capstoneSel)
    assert_true(((capstoneBuild.skillMods[SkillRuntimeConfig.Ids.barbarian_heavy_strike] or {}).frontRowSplitDelta) == 1,
        "Barbarian cleave capstone adds one more split target")
    assert_true(not FeatBuildConfig.GetFeat(FeatBuildConfig.Ids.c_barbarian_rage_master),
        "Barbarian rage capstone removed from feat table")

    local lv5Build = HeroBuild.CompileBuild(10, 5, canonicalSelections(10, 5))
    assert_true(Common.hasSkill(lv5Build.passiveSkills, SkillRuntimeConfig.Ids.barbarian_berserk),
        "Barbarian Lv5 grants berserk mastery passive")

    local hero = {
        id = 9401,
        instanceId = 9401,
        name = "RageRecoveryHero",
        hp = 20,
        maxHp = 40,
        isDead = false,
        isAlive = true,
        buildState = recoveryBuild,
        passiveRuntime = {},
        skills = { { skillId = SkillRuntimeConfig.Ids.barbarian_rage } },
        skillData = { skillInstances = { [SkillRuntimeConfig.Ids.barbarian_rage] = true } },
    }
    local oldRollDice = BuildPassiveCommon.RollDice
    local healed = 0
    BuildPassiveCommon.RollDice = function(expr)
        if expr == "1d6" then
            return 4
        end
        return oldRollDice(expr)
    end
    BuildPassiveCommon.ApplyHeal = function(unit, amount)
        unit.hp = math.min(unit.maxHp, (tonumber(unit.hp) or 0) + amount)
        healed = amount
    end
    assert_true(BarbarianBuildPassives.TryActivateBerserk(hero), "Barbarian rage recovery triggers berserk")
    assert_true(healed == 4, "Barbarian rage recovery heals on berserk entry")
    BuildPassiveCommon.RollDice = oldRollDice
end

log("Barbarian build pipeline tests passed.")
