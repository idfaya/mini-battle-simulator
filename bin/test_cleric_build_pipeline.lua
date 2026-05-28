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
local BattleFormation = require("modules.battle_formation")
local BattleMain = require("modules.battle_main")
local BattleSkill = require("modules.battle_skill")
local BuildPassiveCommon = require("skills.build_passive_common")
local ClericBuildPassives = require("skills.cleric_build_passives")
local FeatBuildConfig = require("config.tables.feats")
local ClassBuildProgression = require("config.tables.classes")
local HeroBuild = require("modules.hero_build")
local HeroData = require("config.hero_data")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.tables.skill_runtime")

-- §5 单轨：直接用 GetCanonicalFeatChain 拓扑链路。
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

    local lv3 = HeroBuild.CompileBuild(6, 3, canonicalSelections(6, 3))
    assert_true(hasSkill(lv3.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv3 keeps divine shelter")
    assert_true(hasSkill(lv3.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv3 grants healing word")
    assert_true(not hasSkill(lv3.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv3 still does not grant sanctuary prayer")

    local build = HeroBuild.CompileBuild(6, 5, canonicalSelections(6, 5))
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_basic_spell), "Cleric Lv5 grants basic spell")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_healing_word), "Cleric Lv5 grants healing word")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric Lv5 grants sanctuary prayer")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.cleric_shelter_prayer), "Cleric Lv5 grants divine shelter")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "Cleric runtime exports sanctuary prayer")
end

do
    local build = HeroBuild.CompileBuild(6, 2, { FeatBuildConfig.Ids.b_cleric_priest_prayer })
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.cleric_turn_undead), "Cleric Lv2 tree feat grants turn undead")
end

do
    local clericHero = HeroData.ConvertToHeroData(900007, 5, 1, { buildFeatIds = canonicalSelections(6, 5) })
    assert_true(clericHero and clericHero.buildState ~= nil, "HeroData generic build compile works for cleric")
    assert_true(hasSkill(clericHero.skillsConfig, SkillRuntimeConfig.Ids.cleric_sanctuary_prayer), "HeroData exports cleric high action")
end

do
    -- §5 单轨：纯施法者 Lv5 build 验证基础攻击 / 核心被动 / 高阶爆发。
    -- 通过 canonicalSelections 自动选取 trunk T1 / T2 / capstone 节点。
    local casterBuilds = {
        { classId = 7, basic = SkillRuntimeConfig.Ids.sorcerer_fire_bolt, core = SkillRuntimeConfig.Ids.sorcerer_ember_ignite, high = SkillRuntimeConfig.Ids.sorcerer_flame_storm },
        { classId = 8, basic = SkillRuntimeConfig.Ids.wizard_frost_ray, core = SkillRuntimeConfig.Ids.wizard_frost_lag, high = SkillRuntimeConfig.Ids.wizard_blizzard },
        { classId = 9, basic = SkillRuntimeConfig.Ids.warlock_eldritch_blast, core = SkillRuntimeConfig.Ids.warlock_static_mark, high = SkillRuntimeConfig.Ids.warlock_thunderstorm },
    }
    for _, spec in ipairs(casterBuilds) do
        local build = HeroBuild.CompileBuild(spec.classId, 5, canonicalSelections(spec.classId, 5))
        assert_true(hasSkill(build.activeSkills, spec.basic), "Caster Lv5 grants basic skill for class " .. spec.classId)
        assert_true(hasSkill(build.passiveSkills, spec.core), "Caster Lv5 grants core passive for class " .. spec.classId)
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
    assert_true(total > 0, "healing word stacks revival prayer and healing mastery")
    local second = ClericBuildPassives.PerformHealingWord(hero, { skillId = SkillRuntimeConfig.Ids.cleric_healing_word, name = "治愈之言" })
    assert_true(second > 0, "healing word can be reused after cooldown control")
    assert_true(healed == total + second, "healing word applies repeated heals without once-per-battle lock")

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
        { skillId = SkillRuntimeConfig.Ids.cleric_shelter_prayer },
    }
    cleric.passiveRuntime = {
        clericSanctuaryExpireRound = BuildPassiveCommon.GetRound() + 1,
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
    BattleFormation.OnFinal()

    local cleric = new_unit(7601, "AutoCleric")
    local ally = new_unit(7602, "FrontAlly")
    local enemy = new_unit(7603, "EnemyDummy")
    cleric.class = 6
    cleric.wpType = 4
    ally.class = 2
    ally.wpType = 1
    enemy.class = 2
    enemy.wpType = 1
    enemy.isLeft = false
    cleric.skills = {}
    cleric.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(6, 1, {}))

    BattleFormation.Init({
        teamLeft = { cleric, ally },
        teamRight = { enemy },
    })
    local battleCleric = BattleFormation.FindHeroByCampAndPos(true, 4)
    local battleAlly = BattleFormation.FindHeroByCampAndPos(true, 1)
    BattleSkill.Init(battleCleric, battleCleric.skillsConfig)

    battleAlly.hp = 82
    local holySkill = battleCleric.skillData.skillInstances[SkillRuntimeConfig.Ids.cleric_basic_spell]
    local healthyTargets = BattleSkill.SelectTarget(battleCleric, holySkill)
    assert_true(#healthyTargets == 1 and healthyTargets[1].isLeft == false, "holy spark keeps attacking enemies when allies are only lightly scratched")

    battleAlly.hp = 72
    local injuredTargets = BattleSkill.SelectTarget(battleCleric, holySkill)
    assert_true(#injuredTargets == 1 and injuredTargets[1].isLeft == true, "holy spark switches to healing when lowest ally drops below heal threshold")

    BattleFormation.OnFinal()
end

do
    BattleFormation.OnFinal()

    local cleric = new_unit(7701, "DecisionCleric")
    local allyA = new_unit(7702, "TankAlly")
    local allyB = new_unit(7703, "BacklineAlly")
    local enemy = new_unit(7704, "EnemyTarget")
    cleric.class = 6
    cleric.wpType = 4
    allyA.class = 2
    allyA.wpType = 1
    allyB.class = 8
    allyB.wpType = 5
    enemy.class = 2
    enemy.wpType = 1
    enemy.isLeft = false
    cleric.skills = {}
    -- §5 单轨：用 canonical 拓扑链路构建 cleric Lv5 build，让决策测试覆盖 basic spell / healing word / sanctuary prayer。
    cleric.skillsConfig = SkillRuntime.BuildSkillsConfig(HeroBuild.CompileBuild(6, 5, canonicalSelections(6, 5)))

    BattleFormation.Init({
        teamLeft = { cleric, allyA, allyB },
        teamRight = { enemy },
    })
    local battleCleric = BattleFormation.FindHeroByCampAndPos(true, 4)
    local battleAllyA = BattleFormation.FindHeroByCampAndPos(true, 1)
    local battleAllyB = BattleFormation.FindHeroByCampAndPos(true, 5)
    BattleSkill.Init(battleCleric, battleCleric.skillsConfig)

    battleAllyA.hp = 72
    battleAllyA.maxHp = 100
    battleAllyB.hp = 100
    battleAllyB.maxHp = 100
    local mildSkill, mildTargets = BattleMain.DebugSelectAvailableSkill(battleCleric)
    assert_true(mildSkill and mildSkill.skillId == SkillRuntimeConfig.Ids.cleric_basic_spell, "cleric saves healing word for real danger and uses holy spark on moderate injuries")
    assert_true(#(mildTargets or {}) == 1 and mildTargets[1].isLeft == true, "moderate injury makes holy spark target the ally for healing")

    battleAllyA.hp = 50
    local emergencySkill = BattleMain.DebugSelectAvailableSkill(battleCleric)
    assert_true(emergencySkill and emergencySkill.skillId == SkillRuntimeConfig.Ids.cleric_healing_word, "cleric uses healing word when the lowest ally is in danger")

    battleAllyA.hp = 74
    battleAllyB.hp = 77
    local pressureSkill = BattleMain.DebugSelectAvailableSkill(battleCleric)
    assert_true(pressureSkill and pressureSkill.skillId == SkillRuntimeConfig.Ids.cleric_sanctuary_prayer, "cleric uses sanctuary prayer when multiple allies are pressured")

    BattleFormation.OnFinal()
end

log("Cleric build pipeline tests passed.")
