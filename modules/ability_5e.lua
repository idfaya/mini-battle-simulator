-- modules/ability_5e.lua
-- Shared 5e ability profile for hero + enemy + battle skill.
-- Single source of truth for:
--   * clampAbility / getAbilityMod (score → mod)
--   * CLASS_ABILITY_PROFILE (classId → primary_ability / spell_ability / armor_formula / save_proficiency)
--   * getAttackAbilityMod / getSpellAbilityMod / calculateArmorClass / isSaveProficient
--   * getClassHitDie / getHitDieAvg / calculate5eHp / getProficiencyBonus
--
-- Design source: design/newbattle/class_system_design.md §4.
--
-- classId map:
--   1 Rogue | 2 Fighter | 3 Monk | 4 Paladin | 5 Ranger
--   6 Cleric | 7 Sorcerer | 8 Wizard | 9 Warlock | 10 Barbarian

local Ability5e = {}

---@alias ArmorFormula
---| "heavy_fixed"         # Fighter 17
---| "unarmored_dex_con"   # Barbarian 10+dex+con
---| "unarmored_dex_wis"   # Monk 10+dex+wis
---| "medium_capped"       # Cleric/Paladin 13 + min(2,dex)
---| "light_11_dex"        # Rogue 11+dex
---| "light_12_dex"        # Ranger 12+dex
---| "robe_dex"            # Sorcerer/Wizard/Warlock 10+dex

---@class ClassAbilityProfile
---@field primary_ability "str"|"dex"|"con"|"int"|"wis"|"cha"
---@field spell_ability "none"|"str"|"dex"|"con"|"int"|"wis"|"cha"
---@field armor_formula ArmorFormula
---@field fort boolean
---@field ref boolean
---@field will boolean

---@type table<integer, ClassAbilityProfile>
local CLASS_ABILITY_PROFILE = {
    [1] = { primary_ability = "dex", spell_ability = "none", armor_formula = "light_11_dex",      fort = false, ref = true,  will = false }, -- Rogue
    [2] = { primary_ability = "str", spell_ability = "none", armor_formula = "heavy_fixed",       fort = true,  ref = false, will = true  }, -- Fighter
    [3] = { primary_ability = "dex", spell_ability = "wis",  armor_formula = "unarmored_dex_wis", fort = true,  ref = true,  will = false }, -- Monk
    [4] = { primary_ability = "str", spell_ability = "cha",  armor_formula = "medium_capped",     fort = true,  ref = false, will = false }, -- Paladin
    [5] = { primary_ability = "dex", spell_ability = "wis",  armor_formula = "light_12_dex",      fort = false, ref = true,  will = true  }, -- Ranger
    [6] = { primary_ability = "str", spell_ability = "wis",  armor_formula = "medium_capped",     fort = false, ref = false, will = true  }, -- Cleric
    [7] = { primary_ability = "int", spell_ability = "int",  armor_formula = "robe_dex",          fort = false, ref = false, will = true  }, -- Sorcerer
    [8] = { primary_ability = "int", spell_ability = "int",  armor_formula = "robe_dex",          fort = true,  ref = false, will = true  }, -- Wizard
    [9] = { primary_ability = "int", spell_ability = "int",  armor_formula = "robe_dex",          fort = false, ref = true,  will = true  }, -- Warlock
    [10] = { primary_ability = "str", spell_ability = "none", armor_formula = "unarmored_dex_con", fort = true, ref = false, will = false }, -- Barbarian
}

Ability5e.CLASS_ABILITY_PROFILE = CLASS_ABILITY_PROFILE

function Ability5e.GetClassProfile(classId)
    return CLASS_ABILITY_PROFILE[tonumber(classId) or 0]
end

--------------------------------------------------------------------
-- score / mod
--------------------------------------------------------------------

function Ability5e.ClampAbility(score)
    local v = tonumber(score) or 10
    return math.max(1, math.min(30, math.floor(v)))
end

function Ability5e.GetAbilityMod(score)
    local s = Ability5e.ClampAbility(score)
    return math.floor((s - 10) / 2)
end

--------------------------------------------------------------------
-- ability pick helpers
--------------------------------------------------------------------

local function pickMod(abilityKey, mods)
    if abilityKey == "str" then return mods.str or 0 end
    if abilityKey == "dex" then return mods.dex or 0 end
    if abilityKey == "con" then return mods.con or 0 end
    if abilityKey == "int" then return mods.int or 0 end
    if abilityKey == "wis" then return mods.wis or 0 end
    if abilityKey == "cha" then return mods.cha or 0 end
    return 0
end

-- mods: { str, dex, con, int, wis, cha } (any omitted → 0)
function Ability5e.GetAttackAbilityMod(classId, mods)
    local profile = CLASS_ABILITY_PROFILE[tonumber(classId) or 0]
    if not profile then return mods and mods.str or 0 end
    return pickMod(profile.primary_ability, mods or {})
end

-- Physical damage uses primary_ability, same channel as attack roll.
function Ability5e.GetPhysicalDamageAbilityMod(classId, mods)
    return Ability5e.GetAttackAbilityMod(classId, mods)
end

function Ability5e.GetSpellAbilityMod(classId, mods)
    local profile = CLASS_ABILITY_PROFILE[tonumber(classId) or 0]
    if not profile then return 0 end
    if profile.spell_ability == "none" then
        -- No spellcasting ability; fall back to primary for non-spell DC callers.
        return pickMod(profile.primary_ability, mods or {})
    end
    return pickMod(profile.spell_ability, mods or {})
end

function Ability5e.IsSaveProficient(classId, saveType)
    local profile = CLASS_ABILITY_PROFILE[tonumber(classId) or 0]
    if not profile then return false end
    if saveType == "fort" then return profile.fort == true end
    if saveType == "ref"  then return profile.ref  == true end
    if saveType == "will" then return profile.will == true end
    return false
end

--------------------------------------------------------------------
-- AC
--------------------------------------------------------------------

function Ability5e.CalculateArmorClass(classId, mods)
    local profile = CLASS_ABILITY_PROFILE[tonumber(classId) or 0]
    local dex = (mods and mods.dex) or 0
    local wis = (mods and mods.wis) or 0
    local con = (mods and mods.con) or 0
    if not profile then
        return 10 + dex
    end
    local f = profile.armor_formula
    if f == "heavy_fixed"       then return 17 end
    if f == "unarmored_dex_con" then return 10 + dex + con end
    if f == "unarmored_dex_wis" then return 10 + dex + wis end
    if f == "medium_capped"     then return 13 + math.min(2, dex) end
    if f == "light_11_dex"      then return 11 + dex end
    if f == "light_12_dex"      then return 12 + dex end
    if f == "robe_dex"          then return 10 + dex end
    return 10 + dex
end

--------------------------------------------------------------------
-- hit die / hp / proficiency
--------------------------------------------------------------------

function Ability5e.GetClassHitDie(classId)
    local id = tonumber(classId) or 0
    if id == 10 then return 12 end                    -- Barbarian
    if id == 2 or id == 4 or id == 5 then return 10 end -- Fighter / Paladin / Ranger
    if id == 1 or id == 3 or id == 6 then return 8 end  -- Rogue / Monk / Cleric
    if id == 7 or id == 8 or id == 9 then return 6 end  -- Sorcerer / Wizard / Warlock
    return 8
end

function Ability5e.GetHitDieAvg(hitDie)
    local d = tonumber(hitDie) or 8
    if d == 6  then return 4 end
    if d == 8  then return 5 end
    if d == 10 then return 6 end
    if d == 12 then return 7 end
    return math.max(1, math.floor((d / 2) + 1))
end

function Ability5e.Calculate5eHp(level, hitDie, conMod)
    local lv = math.max(1, math.min(20, tonumber(level) or 1))
    local die = tonumber(hitDie) or 8
    local avg = Ability5e.GetHitDieAvg(die)
    local cm = tonumber(conMod) or 0

    local total = die + cm
    for _ = 2, lv do
        total = total + math.max(1, avg + cm)
    end
    return math.max(1, total)
end

function Ability5e.GetProficiencyBonus(level)
    local lv = math.max(1, math.min(20, tonumber(level) or 1))
    if lv >= 17 then return 6 end
    if lv >= 13 then return 5 end
    if lv >= 9  then return 4 end
    if lv >= 5  then return 3 end
    return 2
end

return Ability5e
