local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local Common = dofile(script_dir .. "test_helpers/class_build_test_common.lua")
Common.bootstrapFromCaller(script_source)
local assert_true, log = Common.makeAssert()

local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local FeatBuildConfig = require("config.tables.feats")
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
    local sel = canonicalSelections(3, 5)
    local build = HeroBuild.CompileBuild(3, 5, sel)
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_open_hand), "Monk Lv5 keeps open hand")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.monk_harmonize), "Monk Lv5 grants still mind")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.monk_martial_arts), "Monk Lv5 keeps combo")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_basic_attack), "Monk runtime exports basic attack")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_open_hand), "Monk runtime exports mid-tier active skill")
    assert_true((findSkill(runtimeSkills, SkillRuntimeConfig.Ids.monk_harmonize) or {}).skillType == 3,
        "Monk runtime exports harmonize as LIMITED")
end

do
    local monkHero = HeroData.ConvertToHeroData(900001, 5, 1, {
        buildFeatIds = canonicalSelections(3, 5),
    })
    assert_true(monkHero and monkHero.buildState ~= nil, "HeroData generic build compile works for monk")
    assert_true(hasSkill(monkHero.skillsConfig, SkillRuntimeConfig.Ids.monk_basic_attack), "HeroData exports monk build basic attack")
end

do
    BattleFormation.OnFinal()

    local monk = new_unit(9301, "FrontLockedMonk", 3, 4)
    local frontEnemy = new_unit(9302, "FrontEnemy", 2, 1)
    local backEnemy = new_unit(9303, "BackEnemy", 2, 5)
    monk.isLeft = true
    frontEnemy.isLeft = false
    backEnemy.isLeft = false

    local baseBuild = HeroBuild.CompileBuild(3, 5, {
        FeatBuildConfig.Ids.monk_open_hand,
        FeatBuildConfig.Ids.monk_harmonize,
    })
    monk.skillsConfig = SkillRuntime.BuildSkillsConfig(baseBuild)
    monk.buildState = baseBuild
    BattleFormation.Init({
        teamLeft = { monk },
        teamRight = { frontEnemy, backEnemy },
    })
    local battleMonk = BattleFormation.FindHeroByCampAndPos(true, 4)
    BattleSkill.Init(battleMonk, battleMonk.skillsConfig)
    local basicSkill = findSkill(battleMonk.skillsConfig, SkillRuntimeConfig.Ids.monk_basic_attack)
    local baseTargets = BattleSkill.SelectTarget(battleMonk, basicSkill)
    assert_true(#baseTargets == 1 and baseTargets[1].wpType == 1,
        "Monk basic attack respects front protection by default")
    local openHandSkill = findSkill(battleMonk.skillsConfig, SkillRuntimeConfig.Ids.monk_open_hand)
    local openHandTargets = BattleSkill.SelectTarget(battleMonk, openHandSkill)
    assert_true(#openHandTargets == 1 and openHandTargets[1].wpType == 1,
        "Monk open hand respects front protection by default")
    local shadowComboConfig = BattleSkill.GetSkillConfig(SkillRuntimeConfig.Ids.monk_shadow_combo)
    local shadowComboSkill = {
        skillId = SkillRuntimeConfig.Ids.monk_shadow_combo,
        config = shadowComboConfig,
        targetsSelections = shadowComboConfig
            and shadowComboConfig.runtimeData
            and shadowComboConfig.runtimeData.targetsSelections
            or nil,
    }
    local oldRandom = math.random
    math.random = function(_, upper)
        return upper or 2
    end
    local shadowComboTargets = BattleSkill.SelectTarget(battleMonk, shadowComboSkill)
    local shadowComboCanReachBack = false
    for _, target in ipairs(shadowComboTargets) do
        if target.wpType == 5 then
            shadowComboCanReachBack = true
            break
        end
    end
    assert_true(shadowComboCanReachBack, "Monk shadow combo keeps backline access")

    BattleFormation.OnFinal()
    monk.skillsConfig = nil
    monk.buildState = nil
    frontEnemy.isDead = false
    frontEnemy.isAlive = true
    backEnemy.isDead = false
    backEnemy.isAlive = true

    local shadowStepBuild = HeroBuild.CompileBuild(3, 5, {
        FeatBuildConfig.Ids.monk_open_hand,
        FeatBuildConfig.Ids.monk_harmonize,
        FeatBuildConfig.Ids.b_monk_combo_shadow_step,
    })
    monk.skillsConfig = SkillRuntime.BuildSkillsConfig(shadowStepBuild)
    monk.buildState = shadowStepBuild
    BattleFormation.Init({
        teamLeft = { monk },
        teamRight = { frontEnemy, backEnemy },
    })
    battleMonk = BattleFormation.FindHeroByCampAndPos(true, 4)
    BattleSkill.Init(battleMonk, battleMonk.skillsConfig)
    basicSkill = findSkill(battleMonk.skillsConfig, SkillRuntimeConfig.Ids.monk_basic_attack)
    local unlockedTargets = BattleSkill.SelectTarget(battleMonk, basicSkill)
    local canReachBack = false
    for _, target in ipairs(unlockedTargets) do
        if target.wpType == 5 then
            canReachBack = true
            break
        end
    end
    assert_true(canReachBack, "Monk gale step lets basic attack ignore front protection")
    math.random = oldRandom

    BattleFormation.OnFinal()
end

do
    BattleFormation.OnFinal()

    local monk = new_unit(9201, "DecisionMonk", 3, 4)
    local ally = new_unit(9202, "MonkAlly", 2, 1)
    local enemy = new_unit(9203, "EnemyTarget", 2, 1)
    ally.isLeft = true
    enemy.isLeft = false
    monk.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(3, 5, canonicalSelections(3, 5)))

    BattleFormation.Init({
        teamLeft = { monk, ally },
        teamRight = { enemy },
    })

    local battleMonk = BattleFormation.FindHeroByCampAndPos(true, 4)
    BattleSkill.Init(battleMonk, battleMonk.skillsConfig)

    battleMonk.hp = 100
    battleMonk.maxHp = 100
    local fullHpSkill = BattleMain.DebugSelectAvailableSkill(battleMonk)
    assert_true(fullHpSkill and fullHpSkill.skillId == SkillRuntimeConfig.Ids.monk_open_hand,
        "Monk does not spend harmonize at full HP")

    battleMonk.hp = 50
    local injuredSkill = BattleMain.DebugSelectAvailableSkill(battleMonk)
    assert_true(injuredSkill and injuredSkill.skillId == SkillRuntimeConfig.Ids.monk_harmonize,
        "Monk uses harmonize automatically at half HP")

    BattleFormation.OnFinal()
end

log("Monk build pipeline tests passed.")
