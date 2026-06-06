local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local Common = dofile(script_dir .. "test_helpers/class_build_test_common.lua")
Common.bootstrapFromCaller(script_source)
local assert_true, log = Common.makeAssert()

local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local FeatBuildConfig = require("config.tables.feats")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local HeroData = require("config.hero_data")
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleMain = require("modules.battle_main")

local canonicalSelections = function(classId, toLevel)
    return Common.canonicalSelections(ClassBuildProgression, classId, toLevel)
end
local hasSkill = Common.hasSkill
local findSkill = Common.findSkill
local new_unit = Common.newUnit

do
    local sel = canonicalSelections(5, 5)
    local build = HeroBuild.CompileBuild(5, 5, sel)
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_basic_attack), "Ranger Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_hunter_shot), "Ranger Lv5 grants double shot")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_hunter_mastery), "Ranger Lv5 grants arrow rain")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.ranger_hunter_mark), "Ranger Lv5 keeps hunter mark")

    local arrowRain = findSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_hunter_mastery)
    local arrowRainSkillType = tonumber(arrowRain and (arrowRain.skillType or (arrowRain.runtimeData or {}).skillType))
    assert_true(arrowRainSkillType == 3, "Ranger arrow rain is limited-use skillType 3")
    local doubleShot = findSkill(build.activeSkills, SkillRuntimeConfig.Ids.ranger_hunter_shot)
    assert_true(doubleShot and tonumber(doubleShot.cooldown) == 3, "Ranger double shot starts at CD3")
end

do
    local defenseBasicId = FeatBuildConfig.Ids.b_ranger_defense_basic
    local defensePlusId = FeatBuildConfig.Ids.b_ranger_defense_plus
    local defenseMasterId = FeatBuildConfig.Ids.j_ranger_defense_master
    local build = HeroBuild.CompileBuild(5, 6, { defenseBasicId, defensePlusId, defenseMasterId })
    assert_true(build.grantedSkillIds[80005102] == true, "Ranger defense basic grants defense stance passive")
    local defenseMods = build.skillMods[80005102] or {}
    assert_true((tonumber(defenseMods.baseAcBonus) or 0) == 1, "Ranger defense basic sets baseAcBonus 1")
    assert_true((tonumber(defenseMods.onHitAcBonus) or 0) == 1, "Ranger defense plus sets onHitAcBonus 1")
    assert_true((tonumber(defenseMods.onDamageReductionFlat) or 0) == 2, "Ranger defense master sets onDamageReductionFlat 2")
end

do
    local rangerHero = HeroData.ConvertToHeroData(900008, 5, 1, {
        buildFeatIds = canonicalSelections(5, 5),
    })
    assert_true(rangerHero and rangerHero.buildState ~= nil, "HeroData generic build compile works for ranger")
    assert_true(hasSkill(rangerHero.skillsConfig, SkillRuntimeConfig.Ids.ranger_hunter_shot), "HeroData exports ranger double shot")
    assert_true(hasSkill(rangerHero.skillsConfig, SkillRuntimeConfig.Ids.ranger_hunter_mastery), "HeroData exports ranger arrow rain")

    BattleFormation.OnFinal()
    local rangerEnemy = new_unit(9402, "RangerEnemy", 8, 4)
    rangerEnemy.isLeft = false
    BattleFormation.Init({
        teamLeft = { rangerHero },
        teamRight = { rangerEnemy },
    })
    local teamLeft = BattleFormation.GetTeams()
    local battleRanger = teamLeft[1]
    BattleSkill.Init(battleRanger, battleRanger.skillsConfig)
    local rangerSelectedSkill = BattleMain.DebugSelectAvailableSkill(battleRanger)
    assert_true(rangerSelectedSkill ~= nil, "Ranger has an auto-selected action")
    assert_true(rangerSelectedSkill.skillId ~= SkillRuntimeConfig.Ids.ranger_hunter_mark,
        "Ranger auto action does not select passive hunter mark")
    assert_true(rangerSelectedSkill.skillId == SkillRuntimeConfig.Ids.ranger_hunter_mastery,
        "Ranger auto action prioritizes limited-use arrow rain")
    BattleFormation.OnFinal()
end

log("Ranger build pipeline tests passed.")
