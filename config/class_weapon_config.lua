local ClassWeaponConfig = {}

-- Dice-first model:
-- - Physical damage = weaponDice (by class) + skill bonus dice (by skill meta)
-- - Spell damage uses skill dice only (no weaponDice here)
--
-- Notes:
-- - classId 1..5 are melee streams (see class_role_config.lua)
-- - classId 6 is a support caster, but its basic attack is a melee mace swing.
-- - classId 7..9 are backline casters and should not use weapon dice for damage.

ClassWeaponConfig.WEAPON_DICE_BY_CLASS = {
    [1] = "1d10", -- A1 pursuit: sharper burst to keep short fights lethal
    [2] = "1d10", -- D1 defender: slower class still needs meaningful swings
    [3] = "1d10", -- S1 combo: baseline longsword up one step
    [4] = "1d12", -- B1 war spirit: heaviest martial baseline
    [5] = "1d8",  -- T1 poison: finesse damage should not drag fights
    [6] = "1d6",  -- H1 healer: modest mace basic attack
}

function ClassWeaponConfig.GetWeaponDice(classId)
    local id = tonumber(classId) or 0
    return ClassWeaponConfig.WEAPON_DICE_BY_CLASS[id]
end

return ClassWeaponConfig
