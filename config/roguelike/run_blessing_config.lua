---@alias RunBlessingRarity
---| "common"
---| "rare"
---| "boss"

---@alias RunBlessingScope
---| "class"
---| "team"

---@alias RunBlessingEffectType
---| "battle_rounds_hit_and_save"
---| "battle_start_temp_hp"
---| "class_healing_bonus"
---| "class_ac"
---| "class_damage_reduce"
---| "class_spell_protection"

---@class RunBlessingParams
---@field classIds integer[]|nil
---@field monsterTypes integer[]|nil
---@field hitDelta integer|nil
---@field tempHp integer|nil
---@field acDelta integer|nil
---@field saveDelta integer|nil
---@field damageReduce integer|nil
---@field spellDamageReduce integer|nil
---@field healingBonus integer|nil
---@field rounds integer|nil

---@class RunBlessingEntry
---@field id integer
---@field code string
---@field name string
---@field description string
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
        code = "bless",
        name = "祝圣",
        description = "前 3 回合：全队命中 +1、全豁免 +1。",
        rarity = "common",
        scope = "team",
        effectType = "battle_rounds_hit_and_save",
        params = {
            rounds = 3,
            hitDelta = 1,
            saveDelta = 1,
        },
    },
    [101002] = {
        id = 101002,
        code = "aid",
        name = "援助术",
        description = "战斗开始时：全队获得 5 点临时生命。",
        rarity = "common",
        scope = "team",
        effectType = "battle_start_temp_hp",
        params = {
            tempHp = 5,
        },
    },
    [101003] = {
        id = 101003,
        code = "healing_grace",
        name = "治疗恩典",
        description = "圣武士、牧师的治疗额外 +2。",
        rarity = "rare",
        scope = "class",
        effectType = "class_healing_bonus",
        params = {
            classIds = { 4, 6 },
            healingBonus = 2,
        },
    },
    [101004] = {
        id = 101004,
        code = "shield_of_faith",
        name = "信仰护盾",
        description = "战士、武僧、圣武士、野蛮人 AC +1。",
        rarity = "rare",
        scope = "class",
        effectType = "class_ac",
        params = {
            classIds = { 2, 3, 4, 10 },
            acDelta = 1,
        },
    },
    [101005] = {
        id = 101005,
        code = "stoneskin_prayer",
        name = "石肤祷言",
        description = "战士、武僧、圣武士、野蛮人固定减伤 +2。",
        rarity = "rare",
        scope = "class",
        effectType = "class_damage_reduce",
        params = {
            classIds = { 2, 3, 4, 10 },
            damageReduce = 2,
        },
    },
    [101006] = {
        id = 101006,
        code = "spell_ward",
        name = "法术防护",
        description = "全队豁免 +1，额外获得 2 点法术减伤。",
        rarity = "boss",
        scope = "team",
        effectType = "class_spell_protection",
        params = {
            classIds = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            saveDelta = 1,
            spellDamageReduce = 2,
        },
    },
}

function RunBlessingConfig.GetBlessing(blessingId)
    return RunBlessingConfig.BLESSINGS[blessingId]
end

return RunBlessingConfig
