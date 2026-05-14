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
        isLeft = true,
        wpType = 1,
        spellDC = 17,
        skills = {},
        skillData = { skillInstances = {} },
    }
end

do
    local lv1 = HeroBuild.CompileBuild(6, 1, {})
    assert_true(hasSkill(lv1.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv1 grants basic spell")
    assert_true(not hasSkill(lv1.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv1 does not grant healing word yet")
    assert_true(hasSkill(lv1.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv1 grants divine shelter")
    assert_true(not hasSkill(lv1.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv1 does not grant sanctuary prayer yet")

    local lv3 = HeroBuild.CompileBuild(6, 3, {})
    assert_true(hasSkill(lv3.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv3 keeps divine shelter")
    assert_true(hasSkill(lv3.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv3 grants healing word")
    assert_true(not hasSkill(lv3.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv3 still does not grant sanctuary prayer")

    local build = HeroBuild.CompileBuild(6, 5, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv5 grants basic spell")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv5 grants healing word")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv5 grants sanctuary prayer")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv5 grants divine shelter")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric runtime exports sanctuary prayer")
end

do
    local clericHero = HeroData.ConvertToHeroData(900007, 5, 1, {})
    assert_true(clericHero and clericHero.buildState ~= nil, "HeroData generic build compile works for cleric")
    assert_true(hasSkill(clericHero.skillsConfig, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "HeroData exports cleric high action")
end

do
    local casterBuilds = {
        { classId = 7, basic = SkillRuntimeConfig.Ids.sorcerer_fire_bolt, core = SkillRuntimeConfig.Ids.sorcerer_ember_ignite, mid = SkillRuntimeConfig.Ids.sorcerer_ash_burst, high = SkillRuntimeConfig.Ids.sorcerer_flame_storm },
        { classId = 8, basic = SkillRuntimeConfig.Ids.wizard_frost_ray, core = SkillRuntimeConfig.Ids.wizard_frost_lag, mid = SkillRuntimeConfig.Ids.wizard_freezing_nova, high = SkillRuntimeConfig.Ids.wizard_blizzard },
        { classId = 9, basic = SkillRuntimeConfig.Ids.warlock_eldritch_blast, core = SkillRuntimeConfig.Ids.warlock_static_mark, mid = SkillRuntimeConfig.Ids.warlock_thunder_chain, high = SkillRuntimeConfig.Ids.warlock_thunderstorm },
    }
    for _, spec in ipairs(casterBuilds) do
        local build = HeroBuild.CompileBuild(spec.classId, 5, {})
        assert_true(hasSkill(build.activeSkills, spec.basic), "Caster Lv5 grants basic skill for class " .. spec.classId)
        assert_true(hasSkill(build.passiveSkills, spec.core), "Caster Lv5 grants core passive for class " .. spec.classId)
        assert_true(hasSkill(build.activeSkills, spec.mid), "Caster Lv5 grants mid skill for class " .. spec.classId)
        assert_true(hasSkill(build.activeSkills, spec.high), "Caster Lv5 grants high skill for class " .. spec.classId)
    end
end

do
    local hero = new_unit(7051, "SparkCleric")
    local ally = new_unit(7052, "InjuredAlly")
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local oldIsAlly = BattleSkill.IsAlly
    local oldCalcHeal = BattleSkill.CalculateHealDice
    local oldApplyHeal = BattleDmgHeal.ApplyHeal
    local healed = 0

    ally.hp = 40
    ally.maxHp = 100
    BattleSkill.IsAlly = function(_, dst)
        return dst == ally
    end
    BattleSkill.CalculateHealDice = function(_, _, dice)
        if dice == "1d8" then
            return 8
        end
        return 0
    end
    BattleDmgHeal.ApplyHeal = function(_, amount)
        healed = healed + amount
    end

    local total = ClericBuildPassives.PerformBasicSpellAttack(hero, ally, {
        skillId = SkillRuntimeConfig.Ids.cleric_basic_spell,
        name = "神圣火花",
    })
    assert_true(total == 8, "holy spark heals ally targets instead of damaging them")
    assert_true(healed == 8, "holy spark applies heal amount to ally target")

    BattleSkill.IsAlly = oldIsAlly
    BattleSkill.CalculateHealDice = oldCalcHeal
    BattleDmgHeal.ApplyHeal = oldApplyHeal
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
    assert_true(second == 29, "healing word can be reused after cooldown control")
    assert_true(healed == 64, "healing word applies repeated heals without once-per-battle lock")

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
    cleric.passiveRuntime.clericSanctuaryExpireRound = -1
    cleric.passiveRuntime.clericSanctuaryProtectedTargets = {}

    local oldRollDice = BuildPassiveCommon.RollDice
    BuildPassiveCommon.RollDice = function(dice)
        if dice == "1d6" then return 6 end
        return 0
    end
    local damageContext = { damage = 20 }
    ClericBuildPassives.ApplyClericProtections(defender, { damageContext = damageContext })
    assert_true(damageContext.damage <= 14, "cleric protections reduce incoming damage")

    local secondDefender = new_unit(7203, "BackAlly")
    secondDefender.class = 8
    secondDefender.wpType = 5
    local secondDamageContext = { damage = 20 }
    ClericBuildPassives.ApplyClericProtections(secondDefender, { damageContext = secondDamageContext })
    assert_true(secondDamageContext.damage == 20, "cleric shelter prayer is shared once per round across allies")

    BuildPassiveCommon.RollDice = oldRollDice
    BattleFormation.GetFriendTeam = oldGetFriendTeam
end

do
    local hero = new_unit(7301, "DawnCleric")
    local target = new_unit(7302, "Dummy")
    target.isLeft = false
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

do
    local hero = new_unit(7401, "SaveCleric")
    local target = new_unit(7402, "TargetDummy")
    target.isLeft = false
    local BattleFormula = require("core.battle_formula")
    local oldRollSave = BattleFormula.RollSave
    local oldRollHit = BattleFormula.RollHit
    local saveCalls = 0
    local hitCalls = 0

    BattleFormula.RollSave = function(_, dc, bonus)
        saveCalls = saveCalls + 1
        return {
            success = false,
            total = 5,
            roll = 5,
            bonus = bonus or 0,
            dc = dc or 10,
            nat20 = false,
            nat1 = false,
        }
    end
    BattleFormula.RollHit = function(...)
        hitCalls = hitCalls + 1
        return oldRollHit(...)
    end

    ClericBuildPassives.PerformBasicSpellAttack(hero, target, {
        skillId = SkillRuntimeConfig.Ids.cleric_basic_spell,
        name = "神圣火花",
    })

    assert_true(saveCalls == 1, "holy spark against enemies resolves via save check")
    assert_true(hitCalls == 0, "holy spark against enemies does not roll against AC")

    BattleFormula.RollSave = oldRollSave
    BattleFormula.RollHit = oldRollHit
end

do
    local hero = new_unit(7501, "JudgementCleric")
    local target = new_unit(7502, "Dummy")
    target.isLeft = false
    hero.passiveRuntime = {}
    local BattleSkill = require("modules.battle_skill")
    local oldCastSmallSkill = BattleSkill.CastSmallSkillWithResult
    local oldApplyDirectBonusDamage = BuildPassiveCommon.ApplyDirectBonusDamage
    local bonusCalls = 0

    BattleSkill.CastSmallSkillWithResult = function(srcHero)
        srcHero.passiveRuntime.clericBasicSpellLastConnected = false
        return true, { totalDamage = 5 }
    end
    BuildPassiveCommon.ApplyDirectBonusDamage = function()
        bonusCalls = bonusCalls + 1
        return 8
    end

    local total = ClericBuildPassives.PerformHolyVerdict(hero, target, {
        skillId = SkillRuntimeConfig.Ids.cleric_holy_verdict,
        name = "圣焰裁决",
    })
    assert_true(total == 5, "holy verdict radiant rider requires failed save")
    assert_true(bonusCalls == 0, "holy verdict does not add radiant rider on successful save")

    BattleSkill.CastSmallSkillWithResult = oldCastSmallSkill
    BuildPassiveCommon.ApplyDirectBonusDamage = oldApplyDirectBonusDamage
end

log("Cleric build pipeline tests passed.")
