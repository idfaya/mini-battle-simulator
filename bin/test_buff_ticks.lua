-- Buff tick / debuff mechanics: burn, poison, bleed, blind, slow initiative
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

local BattleBuff = require("modules.battle_buff")
local BattleSkill = require("modules.battle_skill")
local BattleSkillStatus = require("skills.battle_skill_status")
local BattleActionOrder = require("modules.battle_action_order")
local BattleFormula = require("core.battle_formula")

BattleBuff.Init()
BattleSkill.InitModule()

local function new_unit(id, name, hp)
    return {
        id = id,
        instanceId = id,
        name = name,
        hp = hp or 10000,
        maxHp = hp or 10000,
        hit = 10,
        spellAttack = 10,
        ac = 10,
        spellDC = 10,
        saveFort = 0,
        saveRef = 0,
        saveWill = 0,
        __ignoreNatRules = true,
        isDead = false,
        isAlive = true,
        attributes = { final = {} },
    }
end

local function with_mocked_save(resultBuilder, fn)
    local oldRollSave = BattleFormula.RollSave
    BattleFormula.RollSave = resultBuilder
    local ok, err = pcall(fn)
    BattleFormula.RollSave = oldRollSave
    if not ok then
        error(err)
    end
end

-- Burn: ref save success removes
do
    local caster = new_unit(5001, "BurnCaster")
    caster.spellDC = 10
    local target = new_unit(5002, "BurnTarget")
    BattleSkillStatus.ApplyBurnRefreshOnly(target, 2, caster)
    assert_true(BattleBuff.GetBuff(target, 870001) ~= nil, "burn applied")

    with_mocked_save(function(_, dc, bonus)
        return { success = true, total = bonus + 20, dc = dc }
    end, function()
        BattleBuff.OnRoundBegin(target)
    end)
    assert_true(BattleBuff.GetBuff(target, 870001) == nil, "burn removed on ref save success")
end

-- Burn: ref save fail deals fire damage
do
    local caster = new_unit(5003, "BurnCaster2")
    caster.spellDC = 30
    local target = new_unit(5004, "BurnTarget2")
    BattleSkillStatus.ApplyBurnRefreshOnly(target, 2, caster)
    local hpBefore = target.hp

    with_mocked_save(function(_, dc, bonus)
        return { success = false, total = bonus + 1, dc = dc }
    end, function()
        BattleBuff.OnRoundBegin(target)
    end)
    assert_true(target.hp < hpBefore, "burn tick deals damage on ref save fail")
    assert_true(BattleBuff.GetBuff(target, 870001) ~= nil, "burn remains after failed ref save")
end

-- Poison: fort save success removes all stacks
do
    local caster = new_unit(5005, "PoisonCaster")
    caster.spellDC = 10
    local target = new_unit(5006, "PoisonTarget")
    BattleSkill.ApplyPoison(target, 3, caster)
    assert_true(BattleBuff.GetBuffStackNumBySubType(target, 850001) == 3, "poison applied with stacks")

    with_mocked_save(function(_, dc, bonus)
        return { success = true, total = bonus + 15, dc = dc }
    end, function()
        BattleBuff.OnRoundBegin(target)
    end)
    assert_true(BattleBuff.GetBuff(target, 850001) == nil, "poison removed on fort save success")
end

-- Poison: fort save fail deals stack-scaled damage
do
    local caster = new_unit(5007, "PoisonCaster2")
    caster.spellDC = 30
    local target = new_unit(5008, "PoisonTarget2")
    BattleSkill.ApplyPoison(target, 2, caster)
    local hpBefore = target.hp

    with_mocked_save(function(_, dc, bonus)
        return { success = false, total = bonus + 1, dc = dc }
    end, function()
        BattleBuff.OnRoundBegin(target)
    end)
    assert_true(target.hp < hpBefore, "poison tick deals damage on fort save fail")
    assert_true(BattleBuff.GetBuffStackNumBySubType(target, 850001) == 2, "poison stacks remain after failed save")
end

-- Bleed: fort save success removes
do
    local caster = new_unit(5009, "BleedCaster")
    caster.spellDC = 10
    local target = new_unit(5010, "BleedTarget")
    BattleSkillStatus.ApplyBleed(target, 2, caster)
    assert_true(BattleBuff.GetBuff(target, 880007) ~= nil, "bleed applied")

    with_mocked_save(function(_, dc, bonus)
        return { success = true, total = bonus + 12, dc = dc }
    end, function()
        BattleBuff.OnRoundBegin(target)
    end)
    assert_true(BattleBuff.GetBuff(target, 880007) == nil, "bleed removed on fort save success")
end

-- Bleed: fort save fail deals slashing damage
do
    local caster = new_unit(5011, "BleedCaster2")
    caster.spellDC = 30
    local target = new_unit(5012, "BleedTarget2")
    BattleSkillStatus.ApplyBleed(target, 2, caster)
    local hpBefore = target.hp

    with_mocked_save(function(_, dc, bonus)
        return { success = false, total = bonus + 1, dc = dc }
    end, function()
        BattleBuff.OnRoundBegin(target)
    end)
    assert_true(target.hp < hpBefore, "bleed tick deals damage on fort save fail")
    assert_true(BattleBuff.GetBuff(target, 880007) ~= nil, "bleed remains after failed save")
end

-- Blind: attacker hit penalty in ResolveScaledDamage
do
    local attacker = new_unit(5013, "BlindAttacker")
    attacker.hit = 10
    local defender = new_unit(5014, "BlindDefender")
    defender.ac = 20
    BattleSkill.ApplyBuffFromSkill(attacker, attacker, 880006, nil, { duration = 1, value = 2 })

    local lastAttackBonus = nil
    local oldRollHit = BattleFormula.RollHit
    BattleFormula.RollHit = function(_, _, params)
        lastAttackBonus = params and params.attackBonus or nil
        return { hit = true, roll = 20, crit = false }
    end
    BattleSkill.ResolveScaledDamage(attacker, defender, {
        meta = { kind = "physical" },
        attackBonus = attacker.hit,
        damageDice = "1d4",
    })
    BattleFormula.RollHit = oldRollHit
    assert_true(lastAttackBonus == 8, "blind reduces attack bonus by value=2")
end

-- Slow: ON_ADD lowers initiative, ON_REMOVE restores
do
    local hero = new_unit(5015, "SlowHero")
    BattleActionOrder.Init({ hero }, {})
    local before = (BattleActionOrder.GetHeroInitiative(hero) or {}).total or 0

    BattleSkillStatus.ApplySlow(hero, 2, hero, 5)
    local during = (BattleActionOrder.GetHeroInitiative(hero) or {}).total or 0
    assert_true(during == before - 5, "slow reduces initiative total by penalty")

    local slowBuff = BattleBuff.GetBuff(hero, 880001)
    assert_true(slowBuff ~= nil, "slow buff present after apply")
    BattleBuff.RemoveBuffById(hero, slowBuff.id)
    local after = (BattleActionOrder.GetHeroInitiative(hero) or {}).total or 0
    assert_true(after == before, "slow removal restores initiative total")

    BattleActionOrder.OnFinal()
end

log("All buff tick assertions passed.")
os.exit(0)
