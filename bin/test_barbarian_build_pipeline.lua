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

local HeroBuild = require("modules.hero_build")
local SkillRuntime = require("modules.skill_runtime")
local SkillRuntimeConfig = require("config.skill_runtime_config")
local HeroData = require("config.hero_data")
local BarbarianBuildPassives = require("skills.barbarian_build_passives")
local BattleSkill = require("modules.battle_skill")
local BattleFormula = require("core.battle_formula")
local Ability5e = require("modules.ability_5e")
local ClassWeaponConfig = require("config.class_weapon_config")

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
        hit = 7,
        ac = 15,
        isDead = false,
        skills = {},
        passiveRuntime = {},
    }
end

do
    local build = HeroBuild.CompileBuild(10, 1, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.barbarian_basic_attack), "Barbarian Lv1 grants basic attack")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.barbarian_rage), "Barbarian Lv1 grants rage")
end

do
    local build = HeroBuild.CompileBuild(10, 5, {})
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.barbarian_basic_attack), "Barbarian Lv5 keeps basic attack")
    assert_true(hasSkill(build.activeSkills, SkillRuntimeConfig.Ids.barbarian_heavy_strike), "Barbarian Lv5 grants heavy strike")
    assert_true(hasSkill(build.passiveSkills, SkillRuntimeConfig.Ids.barbarian_berserk), "Barbarian Lv5 grants berserk")
    local runtimeSkills = SkillRuntime.BuildSkillsConfig(build)
    assert_true(hasSkill(runtimeSkills, SkillRuntimeConfig.Ids.barbarian_heavy_strike), "Barbarian runtime exports heavy strike")
end

do
    local hero = HeroData.ConvertToHeroData(900010, 5, 1, {
        buildFeatIds = {},
    })
    assert_true(hero and hero.buildState ~= nil, "HeroData compile works for barbarian")
    assert_true(hasSkill(hero.skillsConfig, SkillRuntimeConfig.Ids.barbarian_basic_attack), "HeroData exports barbarian basic attack")
    assert_true(hasSkill(hero.skillsConfig, SkillRuntimeConfig.Ids.barbarian_heavy_strike), "HeroData exports barbarian heavy strike")
end

do
    local hero = new_unit(9691, "BarbarianDamageHero")
    local target = new_unit(9692, "BarbarianDamageTarget")
    hero.class = 10
    hero.strMod = 4
    hero.dexMod = 2
    hero.conMod = 3

    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        meta = {
            kind = "physical",
            damageDice = "",
        },
    })

    assert_true(result.damageRoll ~= nil and result.damageRoll.expr == ClassWeaponConfig.GetWeaponDice(10), "barbarian basic attack uses weapon die only under 5e rules")
    assert_true((result.damage or 0) >= 5, "barbarian basic attack still adds strength modifier after weapon die")
    local profile = Ability5e.GetClassProfile(10)
    assert_true(profile ~= nil and profile.primary_ability == "str", "barbarian class profile uses strength as primary ability")
    assert_true(Ability5e.GetClassHitDie(10) == 12, "barbarian class profile uses d12 hit die")
end

do
    local hero = new_unit(9701, "Barbarian")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
        { skillId = SkillRuntimeConfig.Ids.barbarian_berserk },
    }
    local rage = BarbarianBuildPassives.CreateRagePassive({ src = hero })
    rage:OnNormalAtkFinish({ data = { extraParam = { skillId = SkillRuntimeConfig.Ids.barbarian_basic_attack } } })
    assert_true(hero.passiveRuntime.barbarianRageStacks == 1, "Rage gains stack after basic attack")
    rage:OnDefBeforeDmg({ data = { extraParam = { attacker = new_unit(9702, "Enemy"), damage = 5 } } })
    assert_true(hero.passiveRuntime.barbarianRageStacks == 2, "Rage gains stack after being attacked")
    BarbarianBuildPassives.AddRage(hero, 3, "test")
    assert_true(hero.passiveRuntime.barbarianBerserkUsed == true, "Berserk activates immediately at 5 rage")
    assert_true(hero.passiveRuntime.barbarianRageStacks == 0, "Berserk consumes rage stacks")
end

do
    local hero = new_unit(9711, "Berserker")
    hero.skills = {
        { skillId = SkillRuntimeConfig.Ids.barbarian_rage },
        { skillId = SkillRuntimeConfig.Ids.barbarian_berserk },
    }
    hero.passiveRuntime.barbarianBerserkUntilRound = 99
    local passive = BarbarianBuildPassives.CreateBerserkPassive({ src = hero })
    local ctx = { data = { extraParam = { attacker = new_unit(9712, "Enemy"), damage = 7 } } }
    passive:OnDefBeforeDmg(ctx)
    assert_true(ctx.data.extraParam.damage == 5, "Berserk reduces incoming damage by 2")
end

do
    local hero = new_unit(9721, "HeavyStrikeHero")
    local target = new_unit(9722, "HeavyStrikeTarget")
    hero.class = 10
    hero.hit = 8
    hero.strMod = 4
    local oldRollHit = BattleFormula.RollHit
    BattleFormula.RollHit = function(_, _, opts)
        return {
            hit = true,
            crit = false,
            total = 19 + (tonumber(opts and opts.attackBonus) or 0),
            roll = 19,
            bonus = tonumber(opts and opts.attackBonus) or 0,
            nat20 = false,
            nat1 = false,
            targetAC = tonumber(opts and opts.targetAC) or 10,
            raw = { 19 },
        }
    end

    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        meta = {
            kind = "physical",
            damageDice = "1d12+3",
        },
        attackBonus = hero.hit - 2,
        critMin = 19,
    })

    BattleFormula.RollHit = oldRollHit
    assert_true(result.isCrit == true, "expanded crit range is honored by unified damage resolver")
end

log("Barbarian build pipeline tests passed.")
