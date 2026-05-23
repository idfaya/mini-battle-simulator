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
---@field tags string[]                       构筑标签：用于 build_constraints 过滤、UI 分类（如 "team_buff"、"class_offense"）
---@field mutuallyExclusiveGroup string|nil   互斥组：同 group 的祝福同一 run 只能存在 1 件（如 "team_save_buff"、"class_ac_buff"）

---@class RunBlessingConfigModule
---@field BLESSINGS table<integer, RunBlessingEntry>
---@field GetBlessing fun(blessingId: integer): RunBlessingEntry|nil

---@type RunBlessingConfigModule
local RunBlessingConfig = {}

-- 设计文档：design/character_progression_design.md §4 装备/祝福约束。
-- tags 与 mutuallyExclusiveGroup 由 roguelike/build_constraints.lua 在入库点统一过滤。

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
        tags = { "team_buff", "round_buff", "hit_buff", "save_buff" },
        mutuallyExclusiveGroup = "team_round_opening_buff",
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
        tags = { "team_buff", "battle_start", "temp_hp" },
        mutuallyExclusiveGroup = "team_temp_hp",
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
        tags = { "class_buff", "healing_bonus" },
        mutuallyExclusiveGroup = "class_healing_buff",
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
        tags = { "class_buff", "ac_buff", "physical_classes" },
        mutuallyExclusiveGroup = "class_ac_buff",
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
        tags = { "class_buff", "damage_reduce", "physical_classes" },
        mutuallyExclusiveGroup = "class_damage_reduce",
    },
    [101006] = {
        id = 101006,
        code = "spell_ward",
        name = "法术防护",
        description = "全队豁免 +1（5e：对抗法术效应时提高豁免成功率）。",
        rarity = "boss",
        scope = "team",
        effectType = "class_spell_protection",
        params = {
            classIds = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            saveDelta = 1,
        },
        tags = { "team_buff", "save_buff", "boss_drop" },
        mutuallyExclusiveGroup = "team_spell_protection",
    },
    -- 扩展两件，使总池 > BLESSING_TOTAL_LIMIT(6)，玩家在刷新时仍有真选择空间。
    -- 数值严格遵守 5e 平衡：命中加成 ≤ +2、伤害加成 ≤ +2。
    [101007] = {
        id = 101007,
        code = "guidance",
        name = "指引",
        description = "前 3 回合：施法系职业（牧师 / 术士 / 法师 / 邪术师）命中 +1。",
        rarity = "common",
        scope = "class",
        effectType = "battle_rounds_hit_and_save",
        params = {
            classIds = { 6, 7, 8, 9 },
            rounds = 3,
            hitDelta = 1,
        },
        tags = { "class_buff", "round_buff", "hit_buff", "caster_classes" },
        mutuallyExclusiveGroup = "caster_round_buff",
    },
    [101008] = {
        id = 101008,
        code = "warding_bond",
        name = "守护契约",
        description = "盗贼、游侠、武僧 AC +1。",
        rarity = "rare",
        scope = "class",
        effectType = "class_ac",
        params = {
            classIds = { 1, 3, 5 },
            acDelta = 1,
        },
        tags = { "class_buff", "ac_buff", "agile_classes" },
        mutuallyExclusiveGroup = "agile_ac_buff",
    },
}

function RunBlessingConfig.GetBlessing(blessingId)
    return RunBlessingConfig.BLESSINGS[blessingId]
end

return RunBlessingConfig
