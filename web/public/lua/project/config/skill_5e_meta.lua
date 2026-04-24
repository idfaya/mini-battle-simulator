-- Centralized 5e meta for skills.
-- This avoids inferring behavior from "targets count" at runtime and keeps the rules explicit.

local Skill5eMeta = {}

-- Default dice scale for 5e-style small numbers.
local DEFAULT_DICE_SCALE = 1

-- Meta schema:
-- kind: "physical" | "spell" | "auto"
-- saveType: "fort"|"ref"|"will"  (spell only)
-- onSaveSuccess: "half"|"none"   (spell only, default depends on isAOE/hardControl)
-- isAOE: boolean                 (spell only, influences default onSaveSuccess)
-- hardControl: boolean           (spell only; success => immune to control tags)
-- damageDice: string             (optional; dice expr. If omitted, uses base dice.)
-- diceScale: number              (optional; default 100)
-- chantTurns: number             (optional; 0 default)
-- concentration: boolean         (optional; false default)

local OVERRIDES = {
    -- Assassin (A1)
    [80001001] = { kind = "physical", damageDice = "1d4" },
    [80001003] = { kind = "physical", damageDice = "2d6" },
    [80001004] = { kind = "physical", damageDice = "1d6" },

    -- Defender (D1)
    [80002001] = { kind = "physical", damageDice = "2d6+2" },
    [80002003] = { kind = "physical", damageDice = "1d8+2" },
    [80002004] = { kind = "physical", damageDice = "2d6+3" },

    -- Swordmaster (S1)
    [80003001] = { kind = "physical", damageDice = "1d4" },
    [80003003] = { kind = "auto", healDice = "2d8+4" },
    [80003004] = { kind = "spell", saveType = "fort", hardControl = true, onSaveSuccess = "half", damageDice = "3d8+4" },

    -- Warrior (F4) - sustained team auras require concentration.
    [80004001] = { kind = "physical", damageDice = "2d6+4" },
    [80004003] = { kind = "physical", concentration = true, damageDice = "1d4" },
    [80004004] = { kind = "auto", healDice = "3d8+6" },

    -- Venom (T1)
    [80005001] = { kind = "physical", damageDice = "1d4" },
    [80005003] = { kind = "physical", damageDice = "1d4" },
    [80005004] = { kind = "physical", damageDice = "1d6" },

    -- Holy (H1)
    -- Note: holy skills use custom handlers for ally heal / enemy damage.
    -- We still define heal dice here so runtime can stay free of MaxHP% healing.
    [80006001] = { kind = "physical", damageDice = "2d8+2" },
    [80006002] = { kind = "auto", healDice = "1d4" },    -- passive tick
    [80006003] = { kind = "auto", healDice = "2d8+5" },  -- heals 2 allies
    [80006004] = {
        kind = "auto",
        revivePct = 0.20,
        revivePenaltyTurns = 2,
        revivePenaltyAtkMul = 0.75,
        revivePenaltyDefMul = 0.75,
        revivePenaltySpeedMul = 0.80,
    },  -- revive latest dead ally

    -- Fire (M1) - all offensive spells use save vs spellDC (ref)
    [80007001] = { kind = "auto", damageDice = "2d8+2" },
    [80008001] = { kind = "auto", damageDice = "1d8+3" },
    [80007004] = { kind = "spell", saveType = "ref", isAOE = true, onSaveSuccess = "half", damageDice = "4d6+5", chantTurns = 1 },

    -- Ice (M2)
    [80008001] = { kind = "spell", saveType = "ref", isAOE = false, hardControl = false, onSaveSuccess = "half", damageDice = "2d8+4" },
    [80008003] = { kind = "spell", saveType = "ref", isAOE = true, hardControl = true, onSaveSuccess = "half", damageDice = "2d6+3" },
    [80008004] = { kind = "spell", saveType = "ref", isAOE = true, hardControl = true, onSaveSuccess = "half", damageDice = "3d6+4", chantTurns = 1 },

    -- Thunder (M3)
    [80009001] = { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half", damageDice = "2d8+4", chainDice = "1d6+1" },
    [80009003] = { kind = "spell", saveType = "ref", isAOE = true, onSaveSuccess = "half", damageDice = "2d6+3" },
    [80009004] = { kind = "spell", saveType = "ref", isAOE = true, onSaveSuccess = "half", damageDice = "3d6+4", chantTurns = 1, chainDice = "1d6+1" },
}

local function resolveDefault(skillId)
    local classId = math.floor((tonumber(skillId) or 0) / 100) * 100
    if classId >= 80006000 and classId <= 80009000 then
        -- Spell classes by ID range: 80006xxx..80009xxx
        return { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half" }
    end
    return { kind = "physical" }
end

function Skill5eMeta.Get(skillId)
    local id = tonumber(skillId) or 0
    local meta = OVERRIDES[id] or resolveDefault(id)
    -- Ensure defaults.
    if meta.diceScale == nil then
        meta.diceScale = DEFAULT_DICE_SCALE
    end
    if meta.chantTurns == nil then
        meta.chantTurns = 0
    end
    if meta.concentration == nil then
        meta.concentration = false
    end
    if meta.kind == "spell" then
        if meta.isAOE == nil then meta.isAOE = false end
        if meta.hardControl == nil then meta.hardControl = false end
        if meta.onSaveSuccess == nil then
            -- Project rule: AOE defaults to half, hard control defaults to none.
            meta.onSaveSuccess = meta.isAOE and "half" or "half"
            if meta.hardControl and not meta.isAOE then
                meta.onSaveSuccess = "none"
            end
        end
        if meta.saveType == nil then
            meta.saveType = "ref"
        end
    end
    return meta
end

return Skill5eMeta
