---
--- Battle Formula Module
--- 5e 命中/豁免/专注检定；伤害由骰子 + ResolveScaledDamage 结算，不走 atk-def 公式。
---

local BattleFormula = {}

BattleFormula.FORMULA_TYPE = {
    STANDARD = 1,
    DND5E = 4,
}

local DEFAULT_CONFIG = {
    diceScale = 1,
}

local currentConfig = nil
local currentFormulaType = nil
local Dice = nil

function BattleFormula.Init(formulaType)
    currentFormulaType = formulaType or BattleFormula.FORMULA_TYPE.STANDARD
    currentConfig = DEFAULT_CONFIG
    if not Dice then
        local ok, mod = pcall(require, "core.dice")
        if ok then
            Dice = mod
        end
    end
end

local function ensureInit()
    if not currentConfig then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
end

function BattleFormula.GetDiceScale()
    ensureInit()
    return tonumber(currentConfig and currentConfig.diceScale) or 1
end

--- 5e-style d20 roll with advantage/disadvantage
--- @param mode string|nil "normal"|"adv"|"disadv"
--- @return number roll
--- @return table meta { nat20, nat1, raw = {..} }
function BattleFormula.RollD20(mode)
    ensureInit()
    if Dice and Dice.RollD20 then
        return Dice.RollD20(mode)
    end
    local r = math.random(1, 20)
    return r, { raw = { r }, nat20 = (r == 20), nat1 = (r == 1) }
end

--- 5e-style physical hit check against AC.
--- @return table result { hit, crit, total, roll, nat20, nat1, targetAC, bonus }
function BattleFormula.RollHit(attacker, defender, opts)
    opts = opts or {}
    local mode = opts.mode or "normal"
    local roll, meta = BattleFormula.RollD20(mode)
    local attackBonus = tonumber((opts.attackBonus ~= nil) and opts.attackBonus or (attacker and attacker.hit)) or 0
    local targetAC = tonumber((opts.targetAC ~= nil) and opts.targetAC or (defender and defender.ac)) or 10
    local total = roll + attackBonus
    local hit = (total >= targetAC)
    if opts.ignoreNatRules ~= true then
        if meta.nat20 then
            hit = true
        elseif meta.nat1 then
            hit = false
        end
    end
    return {
        hit = hit,
        crit = meta.nat20 == true,
        total = total,
        roll = roll,
        bonus = attackBonus,
        nat20 = meta.nat20 == true,
        nat1 = meta.nat1 == true,
        targetAC = targetAC,
        raw = meta.raw,
    }
end

--- 5e-style saving throw against spell DC.
--- @return table result { success, total, roll, nat20, nat1, dc, bonus }
function BattleFormula.RollSave(target, dc, saveBonus, opts)
    opts = opts or {}
    local mode = opts.mode or "normal"
    local roll, meta = BattleFormula.RollD20(mode)
    local bonus = tonumber(saveBonus) or 0
    local saveDC = tonumber(dc) or 10
    local total = roll + bonus
    local success = (total >= saveDC)
    if opts.ignoreNatRules ~= true then
        if meta.nat20 then
            success = true
        elseif meta.nat1 then
            success = false
        end
    end
    return {
        success = success,
        total = total,
        roll = roll,
        bonus = bonus,
        nat20 = meta.nat20 == true,
        nat1 = meta.nat1 == true,
        dc = saveDC,
        raw = meta.raw,
    }
end

--- 5e-style concentration check when damaged.
--- @return table result { success, dc, total, roll, ... }
function BattleFormula.RollConcentration(caster, damage, opts)
    opts = opts or {}
    local conBonus = tonumber(opts.conSaveBonus or (caster and caster.saveFort)) or 0
    local dc = math.max(10, math.floor((tonumber(damage) or 0) / 2))
    local r = BattleFormula.RollSave(caster, dc, conBonus, opts)
    r.dc = dc
    return r
end

function BattleFormula.GetConfig()
    ensureInit()
    return currentConfig
end

function BattleFormula.GetFormulaType()
    ensureInit()
    return currentFormulaType
end

function BattleFormula.SetConfig(config)
    ensureInit()
    if config then
        for k, v in pairs(config) do
            currentConfig[k] = v
        end
    end
end

return BattleFormula
