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
local ClericBuildPassives = require("skills.cleric_build_passives")
local FeatBuildConfig = require("config.feat_build_config")
local HeroBuild = require("modules.hero_build")
local HeroData = require("config.hero_data")
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
        class = 6,
        level = 5,
        isDead = false,
        isAlive = true,
        wpType = 1,
        spellDC = 17,
        skills = {},
        skillData = { skillInstances = {} },
    }
end

do
    local build = HeroBuild.CompileBuild(6, 5, {
        FeatBuildConfig.Ids.cleric_radiant_prayer,
        FeatBuildConfig.Ids.cleric_light_domain,
        FeatBuildConfig.Ids.cleric_spell_mastery,
        FeatBuildConfig.Ids.cleric_dawn_bishop,
    })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv5 grants basic spell")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv5 grants healing word")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_holy_verdict), "Cleric Lv5 grants light domain action")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.cleric_dawn_bishop), "Cleric Lv5 grants dawn bishop")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.cleric_holy_verdict), "Cleric runtime exports domain action")
end

do
    local clericHero = HeroData.ConvertToHeroData(900007, 5, 1, {
        buildFeatIds = {
            FeatBuildConfig.Ids.cleric_radiant_prayer,
            FeatBuildConfig.Ids.cleric_light_domain,
            FeatBuildConfig.Ids.cleric_spell_mastery,
            FeatBuildConfig.Ids.cleric_dawn_bishop,
        },
    })
    assert_true(clericHero and clericHero.buildState ~= nil, "HeroData generic build compile works for cleric")
    assert_true(hasSkill(clericHero.skillsConfig, SkillRuntimeConfig.Ids.cleric_holy_verdict), "HeroData exports cleric subclass action")
end

do
    local hero = new_unit(7101, "MercyCleric")
    local ally = new_unit(7102, "LowHpAlly")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.cleric_revival_prayer },
        { skillId = SkillRuntimeConfig.Ids.cleric_healing_mastery },
        { skillId = SkillRuntimeConfig.Ids.cleric_mercy_bishop },
    }
    hero.passiveRuntime = {}
    ally.hp = 20
    ally.maxHp = 100

    local oldPickLowestHpAlly = BuildPassiveCommon.PickLowestHpAlly
    local oldCalcHeal = require("modules.battle_skill").CalculateHealDice
    local BattleSkill = require("modules.battle_skill")
    local oldApplyHeal = require("modules.battle_dmg_heal").ApplyHeal
    local healed = 0

    BuildPassiveCommon.PickLowestHpAlly = function()
        return ally
    end
    BattleSkill.CalculateHealDice = function(_, _, dice)
        if dice == "1d8" then return 8 end
        if dice == "1d6" then return 6 end
        return 0
    end
    require("modules.battle_dmg_heal").ApplyHeal = function(_, amount)
        healed = healed + amount
    end

    local total = ClericBuildPassives.PerformHealingWord(hero, { skillId = SkillRuntimeConfig.Ids.cleric_healing_word, name = "治愈之言" })
    assert_true(total == 35, "healing word stacks revival prayer, healing mastery and mercy bishop")
    local second = ClericBuildPassives.PerformHealingWord(hero, { skillId = SkillRuntimeConfig.Ids.cleric_healing_word, name = "治愈之言" })
    assert_true(second == 0, "healing word can only be used once per battle")
    assert_true(healed == 35, "healing word applies the expected total heal once")

    BuildPassiveCommon.PickLowestHpAlly = oldPickLowestHpAlly
    BattleSkill.CalculateHealDice = oldCalcHeal
    require("modules.battle_dmg_heal").ApplyHeal = oldApplyHeal
end

do
    local cleric = new_unit(7201, "GuardianCleric")
    local defender = new_unit(7202, "FrontAlly")
    defender.class = 2
    defender.wpType = 1
    cleric.skills = {
        { skillId = SkillRuntimeConfig.Ids.cleric_sanctuary_mastery },
        { skillId = SkillRuntimeConfig.Ids.cleric_watch_bishop },
        { skillId = SkillRuntimeConfig.Ids.cleric_shelter_prayer },
    }
    cleric.passiveRuntime = {
        clericSanctuaryExpireRound = BuildPassiveCommon.GetRound() + 1,
        clericWatchBishopExpireRound = BuildPassiveCommon.GetRound() + 1,
        clericSanctuaryProtectedTargets = {},
    }

    local oldGetFriendTeam = require("modules.battle_formation").GetFriendTeam
    local BattleFormation = require("modules.battle_formation")
    BattleFormation.GetFriendTeam = function()
        return { cleric, defender }
    end

    local acBonus = ClericBuildPassives.GetAuraAcBonus(defender, nil)
    assert_true(acBonus >= 2, "sanctuary mastery grants stacked AC bonus on front ally")

    local oldRollDice = BuildPassiveCommon.RollDice
    BuildPassiveCommon.RollDice = function(dice)
        if dice == "1d6" then return 6 end
        return 0
    end
    local damageContext = { damage = 20 }
    ClericBuildPassives.ApplyClericProtections(defender, { damageContext = damageContext })
    assert_true(damageContext.damage <= 14, "cleric protections reduce incoming damage")

    BuildPassiveCommon.RollDice = oldRollDice
    BattleFormation.GetFriendTeam = oldGetFriendTeam
end

do
    local hero = new_unit(7301, "DawnCleric")
    local target = new_unit(7302, "Dummy")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.cleric_dawn_bishop },
    }
    hero.passiveRuntime = {}
    local BattleSkill = require("modules.battle_skill")
    local oldCastSmallSkill = BattleSkill.CastSmallSkillWithResult
    local oldApplyDirectBonusDamage = BuildPassiveCommon.ApplyDirectBonusDamage
    local bonusCalls = 0

    BattleSkill.CastSmallSkillWithResult = function()
        return true, { totalDamage = 10 }
    end
    BuildPassiveCommon.ApplyDirectBonusDamage = function(_, _, dice)
        if dice == "1d8" then
            bonusCalls = bonusCalls + 1
            return 8
        end
        return 0
    end

    local total = ClericBuildPassives.PerformHolyVerdict(hero, target, { skillId = SkillRuntimeConfig.Ids.cleric_holy_verdict, name = "圣焰裁决" })
    assert_true(total >= 10, "holy verdict resolves base damage")
    BattleSkill.CastSmallSkillWithResult = oldCastSmallSkill
    BuildPassiveCommon.ApplyDirectBonusDamage = oldApplyDirectBonusDamage
end

log("Cleric build pipeline tests passed.")
