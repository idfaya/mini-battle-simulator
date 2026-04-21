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
    -- Holy (H1)
    [80006001] = { kind = "auto" }, -- holy_light is handled by effect registry (ally heal / enemy spell)
    [80006003] = { kind = "auto" }, -- group heal
    [80006004] = { kind = "auto" }, -- full heal + cleanse

    -- Fire (M1) - all offensive spells use save vs spellDC (ref)
    [80007001] = { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half" },
    [80007003] = { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half" },
    [80007004] = { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half", chantTurns = 1 },

    -- Ice (M2)
    [80008001] = { kind = "spell", saveType = "ref", isAOE = false, hardControl = false, onSaveSuccess = "half" },
    [80008003] = { kind = "spell", saveType = "ref", isAOE = true, hardControl = true, onSaveSuccess = "half" },
    [80008004] = { kind = "spell", saveType = "ref", isAOE = true, hardControl = true, onSaveSuccess = "half", chantTurns = 1 },

    -- Thunder (M3)
    [80009001] = { kind = "spell", saveType = "ref", isAOE = false, onSaveSuccess = "half" },
    [80009003] = { kind = "spell", saveType = "ref", isAOE = true, onSaveSuccess = "half" },
    [80009004] = { kind = "spell", saveType = "ref", isAOE = true, onSaveSuccess = "half", chantTurns = 1 },
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
