package.path = package.path
    .. ";./?.lua"
    .. ";./core/?.lua"
    .. ";./modules/?.lua"
    .. ";./config/?.lua"
    .. ";./utils/?.lua"
    .. ";./ui/?.lua"
    .. ";../?.lua"
    .. ";../core/?.lua"
    .. ";../modules/?.lua"
    .. ";../config/?.lua"
    .. ";../utils/?.lua"
    .. ";../ui/?.lua"

require("core.battle_types")
require("core.battle_enum")
require("core.battle_default_types")
require("modules.BattleDefaultTypesOpt")

local BattleFormation = require("modules.battle_formation")
local Runtime = require("modules.browser_battle_runtime")

local function assert_true(condition, message)
    if not condition then
        error(message or "assert failed")
    end
end

local function new_unit(id, name, wpType, isLeft)
    return {
        configId = id,
        heroId = id,
        id = id,
        name = name,
        wpType = wpType,
        class = 1,
        hp = 1000,
        maxHp = 1000,
        atk = 100,
        def = 10,
        speed = 100,
        skillsConfig = {
            { skillId = 80001001, skillType = E_SKILL_TYPE_NORMAL, name = "刺击", skillCost = 0 },
        },
        isLeft = isLeft,
    }
end

do
    BattleFormation.Init({
        teamLeft = {
            new_unit(1001, "Attacker", 2, true),
        },
        teamRight = {
            new_unit(2001, "FrontGuard", 1, false),
            new_unit(2002, "BackCaster", 5, false),
        },
    })

    local attacker = BattleFormation.FindHeroByCampAndPos(true, 2)
    local targetId = BattleFormation.GetRandomEnemyInstanceId(attacker)
    local target = BattleFormation.FindHeroByInstanceId(targetId)
    assert_true(target ~= nil, "front protection should still produce a target")
    assert_true(target.wpType == 1, "default single target should prefer alive front row")

    local selectable = BattleFormation.GetSelectableEnemyHeroes(attacker, false)
    assert_true(#selectable == 1 and selectable[1].wpType == 1, "front protection candidate set should only include front row")

    BattleFormation.OnFinal()
end

do
    BattleFormation.Init({
        teamLeft = {
            new_unit(1101, "Owner", 2, true),
            new_unit(1102, "Occupied", 5, true),
        },
        teamRight = {},
    })

    local owner = BattleFormation.FindHeroByCampAndPos(true, 2)
    local token = BattleFormation.CreateToken(owner, 91001, 2, 5)
    assert_true(token == nil, "explicit occupied summon position should fail instead of auto-fallback")

    local revived = BattleFormation.ReviveHero(5, new_unit(1103, "Revived", 5, true), true)
    assert_true(revived == nil, "explicit occupied revive position should fail instead of auto-fallback")

    local autoToken = BattleFormation.CreateToken(owner, 91001, 2)
    assert_true(autoToken ~= nil, "summon without explicit position should auto-allocate")

    BattleFormation.OnFinal()
end

do
    local snapshot = Runtime.init({
        teamLeft = {
            new_unit(3001, "LeftBack", 5, true),
            new_unit(3002, "LeftFront", 2, true),
        },
        teamRight = {
            new_unit(4001, "RightFront", 1, false),
            new_unit(4002, "RightBack", 4, false),
        },
        initialEnergy = 80,
    })

    local leftPositions = {}
    for _, unit in ipairs(snapshot.leftTeam or {}) do
        leftPositions[unit.name] = unit.position
    end
    assert_true(leftPositions.LeftBack == 5, "runtime should preserve explicit left back position")
    assert_true(leftPositions.LeftFront == 2, "runtime should preserve explicit left front position")

    local rightPositions = {}
    for _, unit in ipairs(snapshot.rightTeam or {}) do
        rightPositions[unit.name] = unit.position
    end
    assert_true(rightPositions.RightFront == 1, "runtime should preserve explicit right front position")
    assert_true(rightPositions.RightBack == 4, "runtime should preserve explicit right back position")
end

print("positioning test passed")
