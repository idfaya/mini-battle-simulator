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

require("core.battle_enum")
local BattleEvent = require("core.battle_event")
local BattleBuff = require("modules.battle_buff")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatBuildConfig = require("config.feat_build_config")
local HeroBuild = require("modules.hero_build")
local HeroData = require("config.hero_data")
local RogueBuildPassives = require("skills.rogue_build_passives")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.skill_runtime_config")

BattleEvent.Init()
BattleBuff.Init()

local function hasSkill(list, skillId)
    for _, entry in ipairs(list or {}) do
        if tonumber(entry.id or entry.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

local function new_unit(id, name)
    return {
        id = id,
        instanceId = id,
        name = name,
        hp = 100,
        maxHp = 100,
        ac = 10,
        class = 1,
        isDead = false,
        isAlive = true,
        wpType = 1,
        skills = {},
        skillData = { skillInstances = {} },
    }
end

do
    local build = HeroBuild.CompileBuild(1, 5, {
        FeatBuildConfig.Ids.rogue_shadow_step,
        FeatBuildConfig.Ids.rogue_swashbuckler_thrust,
        FeatBuildConfig.Ids.rogue_subclass_mastery,
        FeatBuildConfig.Ids.rogue_survivor,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.rogue_basic_attack), "Rogue Lv5 grants basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.rogue_swashbuckler_thrust), "Rogue Lv5 grants swashbuckler thrust")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.rogue_sneak_attack), "Rogue Lv5 keeps sneak attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.rogue_uncanny_dodge), "Rogue Lv5 grants uncanny dodge")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.rogue_survivor), "Rogue Lv5 grants survivor capstone")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.rogue_basic_attack), "Rogue runtime exports basic attack")
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.rogue_swashbuckler_thrust), "Rogue runtime exports subclass action")
end

do
    local rogueHero = HeroData.ConvertToHeroData(900006, 5, 1, {
        buildFeatIds = {
            FeatBuildConfig.Ids.rogue_shadow_step,
            FeatBuildConfig.Ids.rogue_swashbuckler_thrust,
            FeatBuildConfig.Ids.rogue_subclass_mastery,
            FeatBuildConfig.Ids.rogue_survivor,
        },
    })
    assert_true(rogueHero and rogueHero.buildState ~= nil, "HeroData generic build compile works for rogue")
    assert_true(hasSkill(rogueHero.skillsConfig, SkillRuntimeConfig.Ids.rogue_swashbuckler_thrust), "HeroData exports rogue subclass action")
end

do
    local hero = new_unit(6101, "ShadowStepHero")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.rogue_shadow_step },
    }
    local passive = RogueBuildPassives.CreateShadowStepPassive({ src = hero })
    passive:OnBattleBegin()
    assert_true(BuildPassiveCommon.ShouldIgnoreFrontProtection(hero, { skillId = SkillRuntimeConfig.Ids.rogue_basic_attack }) == true,
        "shadow step exposes first basic attack ignore-front flag")
    passive:OnNormalAtkFinish({ data = { extraParam = { skillId = SkillRuntimeConfig.Ids.rogue_basic_attack } } })
    assert_true(BuildPassiveCommon.ShouldIgnoreFrontProtection(hero, { skillId = SkillRuntimeConfig.Ids.rogue_basic_attack }) == false,
        "shadow step is consumed after first basic attack")
end

do
    local hero = new_unit(6201, "SneakHero")
    local target = new_unit(6202, "SneakDummy")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.rogue_sneak_attack },
        { skillId = SkillRuntimeConfig.Ids.rogue_shadow_dancer },
    }
    local passive = RogueBuildPassives.CreateSneakAttackPassive({ src = hero })
    local oldApplyDirectBonusDamage = BuildPassiveCommon.ApplyDirectBonusDamage
    local bonusCalls = 0
    BuildPassiveCommon.ApplyDirectBonusDamage = function()
        bonusCalls = bonusCalls + 1
        return 7
    end

    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                skillId = SkillRuntimeConfig.Ids.rogue_basic_attack,
                target = target,
                damageDealt = 0,
            },
        },
    })
    assert_true(hero.passiveRuntime.rogueShadowDancePending == true, "shadow dancer arms when first basic attack misses sneak window")

    hero.passiveRuntime.rogueForcedSneakCharges = 1
    hero.passiveRuntime.rogueForcedSneakLabel = "测试强制偷袭"
    passive:OnNormalAtkFinish({
        data = {
            extraParam = {
                skillId = SkillRuntimeConfig.Ids.rogue_basic_attack,
                target = target,
                damageDealt = 8,
            },
        },
    })
    assert_true(bonusCalls == 1, "forced sneak attack triggers rogue sneak bonus on next hit")
    assert_true(hero.passiveRuntime.rogueShadowDancePending == false, "shadow dancer pending bonus clears after successful sneak")

    BuildPassiveCommon.ApplyDirectBonusDamage = oldApplyDirectBonusDamage
end

do
    local hero = new_unit(6301, "SurvivorHero")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.rogue_survivor },
    }
    local passive = RogueBuildPassives.CreateUncannyDodgePassive({ src = hero })
    local ctx = { data = { extraParam = { damage = 12, attacker = new_unit(6302, "Attacker") } } }
    passive:OnDefBeforeDmg(ctx)
    assert_true(ctx.data.extraParam.damage == 6, "uncanny dodge halves first incoming hit")
    assert_true((hero.passiveRuntime.rogueForcedSneakCharges or 0) == 1, "survivor grants next forced sneak after uncanny dodge")
end

do
    local hero = new_unit(6401, "BreachHero")
    local target = new_unit(6402, "BreachDummy")
    BattleBuff.Add(hero, target, {
        buffId = 880004,
        name = "破绽",
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 880004,
        duration = 1,
        canStack = false,
        value = 1,
    })
    assert_true(BuildPassiveCommon.GetDefenderAcBonus(target, hero) == -1, "breach debuff reduces defender AC through common helper")
end

log("Rogue build pipeline tests passed.")
