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

local BattleEvent = require("core.battle_event")
local BattleBuff = require("modules.battle_buff")
local BattleSkill = require("modules.battle_skill")
local BattleFormula = require("core.battle_formula")
local json = require("utils.json")

BattleEvent.Init()
BattleBuff.Init()
BattleSkill.InitModule()

local function count_entries(t)
    local count = 0
    for _, _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

local function new_unit(id, name)
    return {
        id = id,
        instanceId = id,
        name = name,
        hp = 1000,
        maxHp = 1000,
        ac = 10,
        saveRef = 2,
        dexMod = 2,
        wisMod = 0,
        conMod = 0,
        class = 8000500,
        isDead = false,
        isAlive = true,
        attributes = { final = {} },
    }
end

local function load_raw_buff_rows()
    local paths = {
        "config/data/buffs.json",
        "../config/data/buffs.json",
    }

    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local content = file:read("*a")
            file:close()
            return json.JsonDecode(content)
        end
    end

    return nil
end

local rawRows = load_raw_buff_rows()
assert_true(type(rawRows) == "table" and #rawRows == 29, "buffs.json contains 29 buff entries")

local BuffTable = require("config.tables.buffs")
assert_true(type(BuffTable) == "table", "buffs table loads as table")
assert_true(count_entries(BuffTable) == 29, "buffs table contains 29 buff entries")

local poison = BattleSkill.LoadBuffConfig(850001)
assert_true(poison ~= nil, "LoadBuffConfig loads poison from merged table")
assert_true(poison.stackRule == "add", "poison stack rule preserved")
assert_true(type(poison.effects) == "table" and poison.effects[1] and poison.effects[1].timing == 3,
    "poison round-begin effect preserved")
assert_true(type(poison.effects[1].func) == "function", "poison handler restored from handlerId")

local slow = BattleSkill.LoadBuffConfig(880001)
assert_true(slow ~= nil and slow.displayMode == "pct", "slow display mode preserved")
assert_true(type(slow.effects) == "table" and #slow.effects == 2, "slow add/remove hooks preserved")
assert_true(type(slow.effects[1].func) == "function" and type(slow.effects[2].func) == "function",
    "slow handlers restored from handlerId")

local burn = BattleSkill.LoadBuffConfig(870001)
assert_true(burn ~= nil and burn.canStack == false, "burn is non-stackable")
assert_true(burn.stackRule == "refresh", "burn stack rule is refresh")

local aura = BattleSkill.LoadBuffConfig(890012)
assert_true(aura ~= nil and aura.isPermanent == true, "permanent aura config preserved")

local hero = new_unit(1001, "Caster")
local target = new_unit(1002, "Target")
BattleSkill.ApplyBuffFromSkill(hero, target, 890001, nil)
assert_true(BattleBuff.GetBuff(target, 890001) ~= nil, "ApplyBuffFromSkill still applies merged buff config")

BattleSkill.ApplyBurn(target, 2, 2, hero)
local appliedBurn = BattleBuff.GetBuff(target, 870001)
assert_true(appliedBurn ~= nil and appliedBurn.stackCount == 1, "ApplyBurn first apply keeps burn at one stack")

BattleSkill.ApplyBurn(target, 3, 4, hero)
appliedBurn = BattleBuff.GetBuff(target, 870001)
assert_true(appliedBurn ~= nil and appliedBurn.stackCount == 1, "ApplyBurn refresh does not add burn stacks")
assert_true(appliedBurn ~= nil and appliedBurn.duration == 4, "ApplyBurn refreshes burn duration")
assert_true(appliedBurn ~= nil and appliedBurn.__burnPendingTick == true, "ApplyBurn rearms delayed burn tick")

local burnTarget = new_unit(1003, "BurnSuccess")
BattleSkill.ApplyBurn(burnTarget, 1, 2, hero)
local burnHpBefore = burnTarget.hp
BattleBuff.OnRoundBegin(burnTarget)
assert_true(burnTarget.hp == burnHpBefore, "Burn waits one round before first damage check")
BattleBuff.OnRoundEnd(burnTarget)
local oldRollSave = BattleFormula.RollSave
BattleFormula.RollSave = function(targetUnit, dc, saveBonus, opts)
    return {
        success = true,
        total = (tonumber(dc) or 10),
        roll = 10,
        bonus = tonumber(saveBonus) or 0,
        dc = tonumber(dc) or 10,
    }
end
BattleBuff.OnRoundBegin(burnTarget)
assert_true(burnTarget.hp == burnHpBefore, "Burn save success prevents delayed damage")
assert_true(BattleBuff.GetBuff(burnTarget, 870001) ~= nil, "Burn save success does not remove buff immediately")
BattleBuff.OnRoundEnd(burnTarget)
assert_true(BattleBuff.GetBuff(burnTarget, 870001) == nil, "Burn naturally expires after delayed save window")

local failTarget = new_unit(1004, "BurnFail")
BattleSkill.ApplyBurn(failTarget, 1, 2, hero)
local failHpBefore = failTarget.hp
BattleBuff.OnRoundBegin(failTarget)
BattleBuff.OnRoundEnd(failTarget)
BattleFormula.RollSave = function(targetUnit, dc, saveBonus, opts)
    return {
        success = false,
        total = math.max(0, (tonumber(dc) or 10) - 5),
        roll = 5,
        bonus = tonumber(saveBonus) or 0,
        dc = tonumber(dc) or 10,
    }
end
BattleBuff.OnRoundBegin(failTarget)
BattleFormula.RollSave = oldRollSave
assert_true(failTarget.hp < failHpBefore, "Burn save failure deals delayed damage")
assert_true(BattleBuff.GetBuff(failTarget, 870001) == nil, "Burn ends immediately after failed save")

log("ALL TESTS PASSED")
