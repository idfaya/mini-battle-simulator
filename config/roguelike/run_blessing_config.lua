---@alias RunBlessingRarity
---| "common"
---| "rare"
---| "boss"

---@alias RunBlessingScope
---| "class"
---| "team"

---@alias RunBlessingEffectType
---| "class_stat_pct"
---| "turn_start_energy"
---| "class_heal_bonus_pct"
---| "class_dot_damage_pct"
---| "extra_follow_up_trigger"
---| "damage_pct_vs_monster_type"
---| "battle_start_apply_shield_and_resist"

---@class RunBlessingParams
---@field classIds integer[]|nil
---@field monsterTypes integer[]|nil
---@field hpPct number|nil
---@field damagePct number|nil
---@field defPct number|nil
---@field value number|nil
---@field rounds integer|nil
---@field amount integer|nil
---@field overhealShieldPct number|nil
---@field perRoundLimit integer|nil
---@field shieldPct number|nil
---@field controlResistPct number|nil

---@class RunBlessingEntry
---@field id integer
---@field code string
---@field name string
---@field rarity RunBlessingRarity
---@field scope RunBlessingScope
---@field effectType RunBlessingEffectType
---@field params RunBlessingParams

---@class RunBlessingConfigModule
---@field BLESSINGS table<integer, RunBlessingEntry>
---@field GetBlessing fun(blessingId: integer): RunBlessingEntry|nil

---@type RunBlessingConfigModule
local RunBlessingConfig = {}

---@type table<integer, RunBlessingEntry>
RunBlessingConfig.BLESSINGS = {
    [101001] = {
        id = 101001,
        code = "frontline_discipline",
        name = "前线军纪",
        rarity = "common",
        scope = "class",
        effectType = "class_stat_pct",
        params = {
            classIds = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            hpPct = 0.18,
            defPct = 0.16,
        },
    },
    [101002] = {
        id = 101002,
        code = "burst_rhythm",
        name = "爆发节奏",
        rarity = "common",
        scope = "team",
        effectType = "turn_start_energy",
        params = {
            rounds = 3,
            amount = 12,
        },
    },
    [101003] = {
        id = 101003,
        code = "holy_reserve",
        name = "神圣储备",
        rarity = "rare",
        scope = "class",
        effectType = "class_heal_bonus_pct",
        params = {
            classIds = { 6 },
            value = 0.20,
            overhealShieldPct = 0.25,
        },
    },
    [101004] = {
        id = 101004,
        code = "venom_spark",
        name = "毒火余烬",
        rarity = "rare",
        scope = "class",
        effectType = "class_dot_damage_pct",
        params = {
            classIds = { 5, 7, 8, 9 },
            value = 0.35,
        },
    },
    [101005] = {
        id = 101005,
        code = "pursuit_instinct",
        name = "追猎本能",
        rarity = "rare",
        scope = "class",
        effectType = "extra_follow_up_trigger",
        params = {
            classIds = { 1, 3 },
            perRoundLimit = 1,
        },
    },
    [101006] = {
        id = 101006,
        code = "elite_hunter",
        name = "精英猎手",
        rarity = "boss",
        scope = "team",
        effectType = "damage_pct_vs_monster_type",
        params = {
            monsterTypes = { 1, 2 },
            value = 0.12,
        },
    },
    [101007] = {
        id = 101007,
        code = "winter_breath",
        name = "寒冬吐息",
        rarity = "boss",
        scope = "team",
        effectType = "battle_start_apply_shield_and_resist",
        params = {
            shieldPct = 0.08,
            controlResistPct = 0.18,
        },
    },
}

function RunBlessingConfig.GetBlessing(blessingId)
    return RunBlessingConfig.BLESSINGS[blessingId]
end

return RunBlessingConfig
