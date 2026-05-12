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
---@field damagePct number|nil
---@field defPct number|nil
---@field hitDelta integer|nil
---@field acDelta integer|nil
---@field spellDCDelta integer|nil
---@field healBonusPct number|nil
---@field saveDelta integer|nil
---@field blockRate integer|nil

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

---@type table<integer, RunEquipmentEntry>
RunEquipmentConfig.EQUIPMENTS = {
    [101001] = {
        id = 101001,
        code = "longsword_plus_1",
        name = "+1 长剑",
        rarity = "common",
        slot = "weapon",
        effectType = "martial_weapon",
        params = {
            classIds = { 2, 4 },
            damagePct = 0.08,
            hitDelta = 1,
        },
    },
    [101002] = {
        id = 101002,
        code = "shortbow_plus_1",
        name = "+1 短弓",
        rarity = "common",
        slot = "weapon",
        effectType = "ranged_weapon",
        params = {
            classIds = { 1, 5 },
            damagePct = 0.08,
            hitDelta = 1,
        },
    },
    [101003] = {
        id = 101003,
        code = "chain_mail",
        name = "锁子甲",
        rarity = "rare",
        slot = "armor",
        effectType = "armor_ac",
        params = {
            classIds = { 2, 4 },
            acDelta = 1,
            defPct = 0.08,
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
            blockRate = 400,
        },
    },
    [101005] = {
        id = 101005,
        code = "arcane_focus_plus_1",
        name = "+1 奥术法器",
        rarity = "boss",
        slot = "focus",
        effectType = "spell_focus",
        params = {
            classIds = { 7, 8, 9 },
            damagePct = 0.06,
            spellDCDelta = 1,
        },
    },
    [101006] = {
        id = 101006,
        code = "holy_symbol_plus_1",
        name = "+1 圣徽",
        rarity = "boss",
        slot = "focus",
        effectType = "holy_symbol",
        params = {
            classIds = { 6, 4 },
            spellDCDelta = 1,
            healBonusPct = 0.12,
        },
    },
    [101007] = {
        id = 101007,
        code = "cloak_of_resistance",
        name = "抗性斗篷",
        rarity = "rare",
        slot = "accessory",
        effectType = "saving_throw_charm",
        params = {
            classIds = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            saveDelta = 1,
        },
    },
}

function RunEquipmentConfig.GetEquipment(equipmentId)
    return RunEquipmentConfig.EQUIPMENTS[equipmentId]
end

return RunEquipmentConfig
