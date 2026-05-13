---@alias RunEquipmentRarity
---| "common"
---| "rare"
---| "boss"

---@alias RunEquipmentSlot
---| "weapon"
---| "armor"
---| "shield"
---| "focus"
---| "accessory"

---@alias RunEquipmentEffectType
---| "martial_weapon"
---| "ranged_weapon"
---| "armor_ac"
---| "shield_ac"
---| "spell_focus"
---| "holy_symbol"
---| "saving_throw_charm"

---@class RunEquipmentParams
---@field classIds integer[]|nil
---@field hitDelta integer|nil
---@field acDelta integer|nil
---@field spellDCDelta integer|nil
---@field saveDelta integer|nil
---@field weaponDamageBonus integer|nil

---@class RunEquipmentEntry
---@field id integer
---@field code string
---@field name string
---@field rarity RunEquipmentRarity
---@field slot RunEquipmentSlot
---@field effectType RunEquipmentEffectType
---@field params RunEquipmentParams

---@class RunEquipmentConfigModule
---@field EQUIPMENTS table<integer, RunEquipmentEntry>
---@field GetEquipment fun(equipmentId: integer): RunEquipmentEntry|nil

---@type RunEquipmentConfigModule
local RunEquipmentConfig = {}

-- 5e standard equipment set for roguelike run.
-- Equipment config is expressed in 5e-like semantics:
-- hitDelta / acDelta / saveDelta / spellDCDelta / weaponDamageBonus.

---@type table<integer, RunEquipmentEntry>
RunEquipmentConfig.EQUIPMENTS = {
    [101001] = {
        id = 101001,
        code = "cloak_of_protection",
        name = "防护披风",
        rarity = "common",
        slot = "accessory",
        effectType = "saving_throw_charm",
        params = {
            classIds = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            acDelta = 1,
            saveDelta = 1,
        },
    },
    [101002] = {
        id = 101002,
        code = "longsword_plus_1",
        name = "+1 长剑",
        rarity = "common",
        slot = "weapon",
        effectType = "martial_weapon",
        params = {
            classIds = { 2, 4, 10 },
            hitDelta = 1,
            weaponDamageBonus = 1,
        },
    },
    [101003] = {
        id = 101003,
        code = "chain_mail_plus_1",
        name = "+1 锁子甲",
        rarity = "rare",
        slot = "armor",
        effectType = "armor_ac",
        params = {
            classIds = { 2, 4 },
            acDelta = 1,
        },
    },
    [101004] = {
        id = 101004,
        code = "shield_plus_1",
        name = "+1 盾牌",
        rarity = "rare",
        slot = "shield",
        effectType = "shield_ac",
        params = {
            classIds = { 2, 4, 6 },
            acDelta = 1,
        },
    },
    [101005] = {
        id = 101005,
        code = "shortbow_plus_1",
        name = "+1 短弓",
        rarity = "rare",
        slot = "weapon",
        effectType = "ranged_weapon",
        params = {
            classIds = { 1, 5 },
            hitDelta = 1,
            weaponDamageBonus = 1,
        },
    },
    [101006] = {
        id = 101006,
        code = "wand_of_the_war_mage_plus_1",
        name = "战法师魔杖 +1",
        rarity = "rare",
        slot = "focus",
        effectType = "spell_focus",
        params = {
            classIds = { 7, 8, 9 },
            spellDCDelta = 1,
        },
    },
    [101007] = {
        id = 101007,
        code = "rod_of_the_pact_keeper_plus_1",
        name = "契约守护者法杖 +1",
        rarity = "boss",
        slot = "focus",
        effectType = "spell_focus",
        params = {
            classIds = { 9 },
            spellDCDelta = 1,
        },
    },
    [101008] = {
        id = 101008,
        code = "amulet_of_the_devout_plus_1",
        name = "虔信护符 +1",
        rarity = "boss",
        slot = "focus",
        effectType = "holy_symbol",
        params = {
            classIds = { 4, 6 },
            spellDCDelta = 1,
        },
    },
}

function RunEquipmentConfig.GetEquipment(equipmentId)
    return RunEquipmentConfig.EQUIPMENTS[equipmentId]
end

return RunEquipmentConfig
