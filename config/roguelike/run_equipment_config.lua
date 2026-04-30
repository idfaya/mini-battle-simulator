---@alias RunEquipmentRarity
---| "common"
---| "rare"
---| "boss"

---@alias RunEquipmentTrigger
---| "battle_start"
---| "battle_win"
---| "elite_win"
---| "ally_die"
---| "turn_start"

---@alias RunEquipmentEffectType
---| "team_energy_flat"
---| "bonus_gold_by_battle_kind"
---| "team_heal_pct"
---| "class_attack_pct"
---| "team_shield_pct_max_hp"
---| "team_attack_stack_pct"

---@class RunEquipmentParams
---@field amount integer|nil
---@field normal integer|nil
---@field elite integer|nil
---@field classIds integer[]|nil
---@field value number|nil
---@field maxStacks integer|nil

---@class RunEquipmentEntry
---@field id integer
---@field code string
---@field name string
---@field rarity RunEquipmentRarity
---@field trigger RunEquipmentTrigger
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
        code = "ember_tinder",
        name = "灰烬火种",
        rarity = "common",
        trigger = "battle_start",
        effectType = "team_energy_flat",
        params = {
            amount = 20,
        },
    },
    [101002] = {
        id = 101002,
        code = "caravan_tools",
        name = "商旅工具",
        rarity = "common",
        trigger = "battle_win",
        effectType = "bonus_gold_by_battle_kind",
        params = {
            normal = 15,
            elite = 25,
        },
    },
    [101003] = {
        id = 101003,
        code = "saint_bandage",
        name = "圣者绷带",
        rarity = "rare",
        trigger = "elite_win",
        effectType = "team_heal_pct",
        params = {
            value = 0.12,
        },
    },
    [101004] = {
        id = 101004,
        code = "warbanner_hook",
        name = "战旗钩刃",
        rarity = "rare",
        trigger = "battle_start",
        effectType = "class_attack_pct",
        params = {
            classIds = { 1, 3, 4 },
            value = 0.12,
        },
    },
    [101005] = {
        id = 101005,
        code = "frostward_charm",
        name = "霜卫符坠",
        rarity = "boss",
        trigger = "battle_start",
        effectType = "team_shield_pct_max_hp",
        params = {
            value = 0.10,
        },
    },
    [101006] = {
        id = 101006,
        code = "last_flame_censer",
        name = "余烬香炉",
        rarity = "boss",
        trigger = "ally_die",
        effectType = "team_attack_stack_pct",
        params = {
            value = 0.10,
            maxStacks = 2,
        },
    },
}

function RunEquipmentConfig.GetEquipment(equipmentId)
    return RunEquipmentConfig.EQUIPMENTS[equipmentId]
end

return RunEquipmentConfig
