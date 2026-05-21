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
---@field tags string[]                       构筑标签：用于 build_constraints 过滤、UI 分类（如 "weapon_martial"、"armor_heavy"）
---@field mutuallyExclusiveGroup string|nil   互斥组：同 group 的装备同英雄只能存在 1 件（如 "weapon"、"armor"、"shield"）

---@class RunEquipmentConfigModule
---@field EQUIPMENTS table<integer, RunEquipmentEntry>
---@field GetEquipment fun(equipmentId: integer): RunEquipmentEntry|nil

---@type RunEquipmentConfigModule
local RunEquipmentConfig = {}

-- 5e standard equipment set for roguelike run.
-- Equipment config is expressed in 5e-like semantics:
-- hitDelta / acDelta / saveDelta / spellDCDelta / weaponDamageBonus.
-- 设计文档：design/character_progression_design.md §4 装备/祝福约束。
-- tags 与 mutuallyExclusiveGroup 由 roguelike/build_constraints.lua 在入库点统一过滤。

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
        tags = { "accessory", "save_buff", "ac_buff" },
        mutuallyExclusiveGroup = "accessory_cloak",
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
        tags = { "weapon_martial", "weapon_melee" },
        mutuallyExclusiveGroup = "weapon",
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
        tags = { "armor_heavy" },
        mutuallyExclusiveGroup = "armor",
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
        tags = { "shield" },
        mutuallyExclusiveGroup = "shield",
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
        tags = { "weapon_martial", "weapon_ranged" },
        mutuallyExclusiveGroup = "weapon",
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
        tags = { "focus_arcane", "spell_dc_buff" },
        mutuallyExclusiveGroup = "focus",
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
        tags = { "focus_arcane", "spell_dc_buff", "boss_drop" },
        mutuallyExclusiveGroup = "focus",
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
        tags = { "focus_divine", "spell_dc_buff", "boss_drop" },
        mutuallyExclusiveGroup = "focus",
    },
}

function RunEquipmentConfig.GetEquipment(equipmentId)
    return RunEquipmentConfig.EQUIPMENTS[equipmentId]
end

return RunEquipmentConfig
