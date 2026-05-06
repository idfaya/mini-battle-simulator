---@class ClassWeaponConfigModule
---@field WEAPON_DICE_BY_CLASS table<integer, string>
---@field GetWeaponDice fun(classId: integer): string|nil

---@type ClassWeaponConfigModule
local ClassWeaponConfig = {}

-- Dice-first model:
-- - Physical damage = weaponDice (by class) + skill bonus dice/flat (by skill meta)
-- - Spell damage uses skill dice only (no weaponDice here)
--
-- Notes:
-- - classId 1..5 are melee streams (see class_role_config.lua)
-- - classId 6 is a support caster, but its basic attack is a melee mace swing.
-- - classId 7..9 are backline casters and should not use weapon dice for damage.

---@type table<integer, string>
ClassWeaponConfig.WEAPON_DICE_BY_CLASS = {
    [1] = "1d6", -- A1 pursuit: keep weapon random but reduce swing
    [2] = "1d6", -- Fighter frontline: stable martial baseline
    [3] = "1d4", -- S1 combo: lighter weapon roll, more damage from skill flat
    [4] = "1d6", -- B1 war spirit: avoid large spike from heavy die alone
    [5] = "1d6", -- T1 poison: finesse baseline stays stable
    [6] = "1d4", -- H1 healer: modest mace basic attack
}

function ClassWeaponConfig.GetWeaponDice(classId)
    local id = tonumber(classId) or 0
    return ClassWeaponConfig.WEAPON_DICE_BY_CLASS[id]
end

return ClassWeaponConfig
