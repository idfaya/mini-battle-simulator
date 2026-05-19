package.path = package.path
    .. ";./?.lua"
    .. ";./?/init.lua"
    .. ";./config/?.lua"
    .. ";./config/?/init.lua"
    .. ";./modules/?.lua"
    .. ";./skills/?.lua"

local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BattleFormation = require("modules.battle_formation")
local BattleSkill = require("modules.battle_skill")
local RangerBuildPassives = require("skills.ranger_build_passives")
local BuildPassiveCommon = require("skills.build_passive_common")

local function assert_true(value, message)
    if not value then
        error(message or "assert_true failed")
    end
end

local function new_unit(id, name)
    return {
        id = id,
        instanceId = id,
        name = name,
        level = 5,
        class = 5,
        classId = 5,
        isDead = false,
        isLeft = true,
        hp = 100,
        hpMax = 100,
        wpType = 2,
        attributes = {
            hp = 100,
            hpMax = 100,
            dex = 16,
            str = 10,
            con = 12,
            attack = 12,
            armorClass = 14,
            ac = 14,
        },
        modelData = {
            power = 12,
        },
        passiveRuntime = {},
        skillData = {
            skillInstances = {},
        },
        skills = {},
    }
end

BattleFormation.OnFinal()

local ranger = new_unit(9411, "ArrowRainRanger")
ranger.skills = {
    { skillId = SkillRuntimeConfig.Ids.ranger_hunter_mastery, skillType = E_SKILL_TYPE_ACTIVE, name = "箭雨" },
}
local enemy = new_unit(9412, "ArrowRainDummy")
enemy.isLeft = false

BattleFormation.Init({
    teamLeft = { ranger },
    teamRight = { enemy },
})

local originalRandom = math.random
local originalCast = BattleSkill.CastBasicAttackAction
local originalSetMultiplier = BuildPassiveCommon.SetPendingBasicAttackDamageMultiplier
local randomCalls = 0
local shots = {}
local multipliers = {}

math.random = function(a, b)
    randomCalls = randomCalls + 1
    return 1
end

BuildPassiveCommon.SetPendingBasicAttackDamageMultiplier = function(hero, multiplier, label)
    multipliers[#multipliers + 1] = {
        value = multiplier,
        label = label,
    }
    return originalSetMultiplier(hero, multiplier, label)
end

BattleSkill.CastBasicAttackAction = function(hero, target, opts)
    shots[#shots + 1] = {
        targetId = target and (target.instanceId or target.id) or nil,
        actionSource = opts and opts.basicAttackActionSource or nil,
        isFollowUp = opts and opts.basicAttackIsFollowUp == true or false,
    }
    return true, { totalDamage = 10, succeeded = true }
end

local totalDamage = RangerBuildPassives.PerformArrowRain(ranger, {
    skillId = SkillRuntimeConfig.Ids.ranger_hunter_mastery,
    name = "箭雨",
})

BattleSkill.CastBasicAttackAction = originalCast
BuildPassiveCommon.SetPendingBasicAttackDamageMultiplier = originalSetMultiplier
math.random = originalRandom

assert_true(totalDamage == 40, "arrow rain should sum four successful standard attacks")
assert_true(randomCalls == 4, "arrow rain should roll random target once per arrow")
assert_true(#shots == 4, "arrow rain should fire exactly four standard attacks")
assert_true(shots[1].targetId ~= nil, "arrow rain first shot should lock a concrete target")
assert_true(shots[2].targetId == shots[1].targetId, "arrow rain second shot should keep hitting the only available enemy")
assert_true(shots[4].targetId == shots[1].targetId, "arrow rain repeated shots should keep using the same sole enemy")
assert_true(shots[1].actionSource == "arrow_rain_active", "arrow rain should use dedicated active action source")
assert_true(shots[1].isFollowUp == true, "arrow rain follow-up basic attacks should not recurse into extra attack")
assert_true(#multipliers == 3, "arrow rain repeated hits should emit three scaling multipliers")
assert_true(multipliers[1].value == 0.5, "arrow rain second hit on same target should deal half damage")
assert_true(multipliers[2].value == 0.25, "arrow rain third hit on same target should deal quarter damage")
assert_true(multipliers[3].value == 0.125, "arrow rain fourth hit on same target should deal one eighth damage")

BattleFormation.OnFinal()
print("test_ranger_arrow_rain ok")
