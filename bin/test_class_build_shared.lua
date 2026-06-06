local script_source = debug.getinfo(1, "S").source
local script_path = script_source:sub(2)
local script_dir = script_path:match("(.*[/\\])") or "./"
local Common = dofile(script_dir .. "test_helpers/class_build_test_common.lua")
Common.bootstrapFromCaller(script_source)
local assert_true, log = Common.makeAssert()

local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local BattleMain = require("modules.battle_main")

local canonicalSelections = function(classId, toLevel)
    return Common.canonicalSelections(ClassBuildProgression, classId, toLevel)
end
local findSkill = Common.findSkill
local new_unit = Common.newUnit

do
    BattleFormation.OnFinal()

    local fighter = new_unit(9101, "DecisionFighter", 2, 1)
    local enemy = new_unit(9102, "FighterEnemy", 2, 1)
    enemy.isLeft = false
    fighter.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(2, 5, canonicalSelections(2, 5)))

    BattleFormation.Init({
        teamLeft = { fighter },
        teamRight = { enemy },
    })

    local battleFighter = BattleFormation.GetTeams()[1]
    BattleSkill.Init(battleFighter, battleFighter.skillsConfig)
    battleFighter.hp = 50
    battleFighter.maxHp = 100
    local injuredFighterSkill = BattleMain.DebugSelectAvailableSkill(battleFighter)
    assert_true(injuredFighterSkill and injuredFighterSkill.skillId == SkillRuntimeConfig.Ids.fighter_second_wind_action,
        "Fighter uses second wind automatically at half HP")

    battleFighter.hp = 100
    assert_true(BattleMain.QueueUltimate(battleFighter.instanceId), "Fighter can queue limited skill manually")
    local queuedAtFullHp = BattleMain.DebugSelectAvailableSkill(battleFighter)
    assert_true(queuedAtFullHp and queuedAtFullHp.skillId ~= SkillRuntimeConfig.Ids.fighter_second_wind_action,
        "Queued limited skill is not consumed when fighter still fails self-heal gate")
    assert_true(BattleMain.HasQueuedUltimate(battleFighter.instanceId),
        "Queued limited skill is preserved when no valid limited candidate exists")
    battleFighter.hp = 50
    local queuedAtHalfHp = BattleMain.DebugSelectAvailableSkill(battleFighter)
    assert_true(queuedAtHalfHp and queuedAtHalfHp.skillId == SkillRuntimeConfig.Ids.fighter_second_wind_action,
        "Queued limited skill fires once fighter becomes eligible")
    assert_true(not BattleMain.HasQueuedUltimate(battleFighter.instanceId),
        "Queued limited skill clears only after a valid limited candidate is selected")

    BattleFormation.OnFinal()
end

do
    local dualLimitedHero = new_unit(9351, "DualLimitedHero", 2, 1)
    local fighterRuntime = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(2, 5, canonicalSelections(2, 5)))
    local paladinRuntime = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(4, 5, canonicalSelections(4, 5)))
    dualLimitedHero.skillsConfig = {
        findSkill(fighterRuntime, SkillRuntimeConfig.Ids.fighter_second_wind_action),
        findSkill(paladinRuntime, SkillRuntimeConfig.Ids.paladin_lay_on_hands),
    }
    BattleSkill.Init(dualLimitedHero, dualLimitedHero.skillsConfig)
    local fighterCharges, fighterMax = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.fighter_second_wind_action)
    local paladinCharges, paladinMax = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.paladin_lay_on_hands)
    assert_true(fighterCharges == 1 and fighterMax == 1, "fighter limited skill starts with its own charge")
    assert_true(paladinCharges == 1 and paladinMax == 1, "paladin limited skill starts with its own charge")
    assert_true(BattleSkill.ConsumeLimitedSkillCharge(dualLimitedHero, SkillRuntimeConfig.Ids.fighter_second_wind_action),
        "Consuming one limited skill charge succeeds")
    fighterCharges = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.fighter_second_wind_action)
    paladinCharges = BattleSkill.GetLimitedSkillCharges(dualLimitedHero, SkillRuntimeConfig.Ids.paladin_lay_on_hands)
    assert_true(fighterCharges == 0, "Consumed limited skill charge is tracked per skill")
    assert_true(paladinCharges == 1, "Other limited skill keeps its own remaining charge")
end

do
    local sel = canonicalSelections(3, 5)
    local reversed = {}
    for i = #sel, 1, -1 do
        reversed[#reversed + 1] = sel[i]
    end
    local ok = pcall(HeroBuild.CompileBuild, 3, 5, reversed)
    assert_true(ok, "CompileBuild stable when selectedFeatIds reversed")
end

do
    local andCapstoneCases = {
        { class = 1,  parents = 4 },
        { class = 3,  parents = 2 },
        { class = 5,  parents = 3 },
        { class = 6,  parents = 2 },
        { class = 9,  parents = 3 },
        { class = 10, parents = 3 },
    }
    for _, case in ipairs(andCapstoneCases) do
        local fullSel = canonicalSelections(case.class, 10)
        local capstoneId = fullSel[#fullSel]
        local capstone = FeatBuildConfig.GetFeat(capstoneId)
        assert_true(capstone and capstone.isCapstone == true,
            string.format("class %d canonical chain ends with capstone", case.class))
        assert_true(capstone.requireAllPrerequisites == true,
            string.format("class %d capstone %s marked requireAllPrerequisites",
                case.class, tostring(capstoneId)))
        local parents = capstone.prerequisites or {}
        assert_true(#parents == case.parents,
            string.format("class %d capstone has %d parents", case.class, case.parents))
        local okFull = pcall(HeroBuild.CompileBuild, case.class, 10, fullSel)
        assert_true(okFull,
            string.format("class %d canonical chain accepts capstone", case.class))
        local lv1Set = {}
        for _, fid in ipairs(ClassBuildProgression.GetLv1FeatIds(case.class)) do
            lv1Set[tonumber(fid) or 0] = true
        end
        local prunableCount = 0
        for _, parentId in ipairs(parents) do
            if not lv1Set[tonumber(parentId) or 0] then
                prunableCount = prunableCount + 1
                local pruned = {}
                for _, fid in ipairs(fullSel) do
                    if tonumber(fid) ~= tonumber(parentId) then
                        pruned[#pruned + 1] = fid
                    end
                end
                local okMissing = pcall(HeroBuild.CompileBuild, case.class, 10, pruned)
                assert_true(not okMissing,
                    string.format("class %d capstone rejects build missing parent %s",
                        case.class, tostring(parentId)))
            end
        end
        assert_true(prunableCount > 0,
            string.format("class %d capstone has at least one non-Lv1 parent", case.class))
    end
end

log("Shared class build pipeline tests passed.")
