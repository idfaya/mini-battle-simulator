local ClassWeaponConfig = {}

-- Dice-first model:
-- - Physical damage = weaponDice (by class) + skill bonus dice (by skill meta)
-- - Spell damage uses skill dice only (no weaponDice here)
--
-- Notes:
-- - classId 1..5 are melee streams (see class_role_config.lua)
-- - classId 6..9 are backline/casters and should not use weapon dice for damage.

ClassWeaponConfig.WEAPON_DICE_BY_CLASS = {
    [1] = "1d8",  -- A1 pursuit: rapier-like
    [2] = "1d8",  -- D1 defender: sword+shield baseline
    [3] = "1d8",  -- S1 combo: longsword baseline
    [4] = "1d10", -- B1 war spirit: heavier weapon baseline
    [5] = "1d6",  -- T1 poison: light weapon baseline
}

function ClassWeaponConfig.GetWeaponDice(classId)
    local id = tonumber(classId) or 0
    return ClassWeaponConfig.WEAPON_DICE_BY_CLASS[id]
end

return ClassWeaponConfig

