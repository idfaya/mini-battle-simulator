---@alias BuildFeatEffectType
---| "grant_skill"
---| "modify_skill"
---| "replace_skill"

---@alias BuildFeatTier "small"|"medium"|"high"

---@class BuildFeatEffect
---@field type BuildFeatEffectType
---@field skill integer|nil
---@field oldSkill integer|nil
---@field newSkill integer|nil
---@field add table|nil

---@class BuildFeatDef
---@field id integer
---@field classId integer
---@field level integer
---@field name string
---@field description string
---@field choiceGroup string|nil
---@field effects BuildFeatEffect[]
---@field tier BuildFeatTier|nil
---@field tags string[]|nil
---@field isSubclassCore boolean|nil
---@field prerequisites integer[]|nil
---@field requireAllPrerequisites boolean|nil
---@field isRoot boolean|nil
---@field trunk string|nil  -- "T1" | "T2"
---@field isCapstone boolean|nil
---@field treeSlot string|nil  -- "R" | "B" | "J" | "T1" | "T2" | "C"

local FeatBuildConfig = {}

local function FeatId(level, index)
    return 2100000 + level * 100 + index
end

FeatBuildConfig.Ids = {
    rogue_training = FeatId(401, 1),
    rogue_sneak_attack = FeatId(401, 2),
    rogue_uncanny_dodge = FeatId(403, 1),
    rogue_cunning_strike = FeatId(405, 1),
    cleric_training = FeatId(501, 1),
    cleric_healing_word = FeatId(501, 2),
    cleric_shelter_prayer = FeatId(502, 2),
    cleric_guardian_domain = FeatId(503, 3),
    fighter_training = FeatId(1, 1),
    fighter_second_wind = FeatId(1, 2),
    fighter_guard = FeatId(3, 2),
    fighter_counter_basic = FeatId(4, 2),
    monk_training = FeatId(101, 1),
    monk_martial_arts = FeatId(101, 2),
    monk_open_hand = FeatId(103, 1),
    monk_harmonize = FeatId(103, 3),
    paladin_training = FeatId(201, 1),
    paladin_shelter_prayer = FeatId(202, 1),
    paladin_lay_on_hands = FeatId(203, 1),
    paladin_vengeance_smite = FeatId(203, 2),
    ranger_training = FeatId(301, 1),
    ranger_hunter_mark = FeatId(301, 2),
    ranger_hunter_shot = FeatId(303, 1),
    ranger_hunter_mastery = FeatId(305, 1),
    sorcerer_training = FeatId(701, 1),
    sorcerer_ember_ignite = FeatId(701, 2),
    sorcerer_ash_burst = FeatId(703, 1),
    sorcerer_flame_storm = FeatId(705, 1),
    wizard_training = FeatId(801, 1),
    wizard_frost_lag = FeatId(801, 2),
    wizard_freezing_nova = FeatId(803, 1),
    wizard_blizzard = FeatId(805, 1),
    warlock_training = FeatId(901, 1),
    warlock_static_mark = FeatId(901, 2),
    warlock_thunder_chain = FeatId(903, 1),
    warlock_thunderstorm = FeatId(905, 1),
    barbarian_training = FeatId(1001, 1),
    barbarian_rage = FeatId(1001, 2),
    barbarian_heavy_strike = FeatId(1003, 1),
    barbarian_berserk = FeatId(1005, 1),
}

---@type table<integer, BuildFeatDef>
local FEATS = {
    -- Rogue (classId = 1)
    [FeatBuildConfig.Ids.rogue_training] = {
        id = FeatBuildConfig.Ids.rogue_training,
        classId = 1,
        level = 1,
        name = "盗贼训练",
        description = "获得基础武器攻击，对单体敌人进行一次标准轻巧近战攻击。",
        effects = {
            { type = "grant_skill", skill = 80001011 },
        },
    },
    [FeatBuildConfig.Ids.rogue_sneak_attack] = {
        id = FeatBuildConfig.Ids.rogue_sneak_attack,
        classId = 1,
        level = 1,
        name = "偷袭基础",
        description = "基础攻击命中后若目标处于失能态，或至少 1 名友军与目标相邻，额外 +1d6。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80001101 },
        },
    },
    [FeatBuildConfig.Ids.rogue_uncanny_dodge] = {
        id = FeatBuildConfig.Ids.rogue_uncanny_dodge,
        classId = 1,
        level = 3,
        name = "直觉闪避基础",
        description = "每回合首次被单体攻击命中时，受到的伤害减半。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80001108 },
        },
    },
    [FeatBuildConfig.Ids.rogue_cunning_strike] = {
        id = FeatBuildConfig.Ids.rogue_cunning_strike,
        classId = 1,
        level = 5,
        name = "诡诈打击基础",
        description = "执行一次基础攻击且强制满足偷袭；命中后目标体豁失败则 POISON 1 回合。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80001013 },
        },
    },
    -- Cleric (classId = 6)
    [FeatBuildConfig.Ids.cleric_training] = {
        id = FeatBuildConfig.Ids.cleric_training,
        classId = 6,
        level = 1,
        name = "牧师祷训",
        description = "获得神圣火花：对敌方造成 1 次远程神术伤害；若目标为友军，则改为回复生命。",
        effects = {
            { type = "grant_skill", skill = 80006011 },
        },
    },
    [FeatBuildConfig.Ids.cleric_healing_word] = {
        id = FeatBuildConfig.Ids.cleric_healing_word,
        classId = 6,
        level = 3,
        name = "治愈基础",
        description = "获得治愈之言，CD3，为生命最低的友军回复 1d8 + 等级生命。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80006012 },
        },
    },
    [FeatBuildConfig.Ids.cleric_shelter_prayer] = {
        id = FeatBuildConfig.Ids.cleric_shelter_prayer,
        classId = 6,
        level = 1,
        name = "庇护基础",
        description = "核心被动。每个友军每回合第一次受到伤害时，该次伤害减少 1d6。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80006103 },
        },
    },
    [FeatBuildConfig.Ids.cleric_guardian_domain] = {
        id = FeatBuildConfig.Ids.cleric_guardian_domain,
        classId = 6,
        level = 5,
        name = "圣域基础",
        description = "获得圣域祷言，CD3，持续 2 回合；我方全体 AC +1，施放时立即为最低血友军回复 1d4 并提供 4 点临时生命。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80006015 },
        },
    },
    -- Sorcerer (classId = 7)
    [FeatBuildConfig.Ids.sorcerer_training] = {
        id = FeatBuildConfig.Ids.sorcerer_training,
        classId = 7,
        level = 1,
        name = "术士火焰训练",
        description = "获得火焰弹，对单体敌人造成火焰法术伤害。",
        effects = {
            { type = "grant_skill", skill = 80007001 },
        },
    },
    [FeatBuildConfig.Ids.sorcerer_ember_ignite] = {
        id = FeatBuildConfig.Ids.sorcerer_ember_ignite,
        classId = 7,
        level = 1,
        name = "点燃基础",
        description = "火焰法术命中后附加燃烧；已燃烧目标只刷新持续时间，不重复叠层。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80007002 },
        },
    },
    [FeatBuildConfig.Ids.sorcerer_ash_burst] = {
        id = FeatBuildConfig.Ids.sorcerer_ash_burst,
        classId = 7,
        level = 3,
        name = "爆燃基础",
        description = "获得灰烬爆燃，CD3，2d8 火焰；目标已点燃则额外 +1d8。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80007003 },
        },
    },
    [FeatBuildConfig.Ids.sorcerer_flame_storm] = {
        id = FeatBuildConfig.Ids.sorcerer_flame_storm,
        classId = 7,
        level = 5,
        name = "风暴基础",
        description = "获得烈焰风暴，CD5，对全体敌人造成火焰伤害；已点燃目标额外 +1d8 并延燃。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80007004 },
        },
    },
    -- Wizard (classId = 8)
    [FeatBuildConfig.Ids.wizard_training] = {
        id = FeatBuildConfig.Ids.wizard_training,
        classId = 8,
        level = 1,
        name = "法师寒霜训练",
        description = "获得寒霜射线，对单体敌人造成冰霜法术伤害。",
        effects = {
            { type = "grant_skill", skill = 80008001 },
        },
    },
    [FeatBuildConfig.Ids.wizard_frost_lag] = {
        id = FeatBuildConfig.Ids.wizard_frost_lag,
        classId = 8,
        level = 1,
        name = "减速基础",
        description = "寒霜法术命中后施加减速（降先攻）。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80008002 },
        },
    },
    [FeatBuildConfig.Ids.wizard_freezing_nova] = {
        id = FeatBuildConfig.Ids.wizard_freezing_nova,
        classId = 8,
        level = 3,
        name = "冻结基础",
        description = "获得冻结新星，CD3，十字范围；减速目标转 FROZEN 1 回合，未减速施加减速。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80008003 },
        },
    },
    [FeatBuildConfig.Ids.wizard_blizzard] = {
        id = FeatBuildConfig.Ids.wizard_blizzard,
        classId = 8,
        level = 5,
        name = "暴风基础",
        description = "获得暴风雪，CD5，全体冰系基础伤害；命中减速目标额外 +1d8 并刷新减速。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80008004 },
        },
    },
    -- Warlock (classId = 9)
    [FeatBuildConfig.Ids.warlock_training] = {
        id = FeatBuildConfig.Ids.warlock_training,
        classId = 9,
        level = 1,
        name = "邪术师雷霆训练",
        description = "获得邪能冲击，对单体敌人造成雷电法术伤害。",
        effects = {
            { type = "grant_skill", skill = 80009001 },
        },
    },
    [FeatBuildConfig.Ids.warlock_static_mark] = {
        id = FeatBuildConfig.Ids.warlock_static_mark,
        classId = 9,
        level = 1,
        name = "印记基础",
        description = "邪能冲击命中后附加印记；本回合首次对带印记目标伤害 +1d6。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80009002 },
        },
    },
    [FeatBuildConfig.Ids.warlock_thunder_chain] = {
        id = FeatBuildConfig.Ids.warlock_thunder_chain,
        classId = 9,
        level = 3,
        name = "雷链基础",
        description = "获得雷链，CD3，对目标造成雷电伤害并额外弹射 1 名敌人；带印记优先。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80009003 },
        },
    },
    [FeatBuildConfig.Ids.warlock_thunderstorm] = {
        id = FeatBuildConfig.Ids.warlock_thunderstorm,
        classId = 9,
        level = 5,
        name = "雷暴基础",
        description = "获得雷暴，CD5，对全体敌人造成雷电伤害；带印记目标额外 +1d8 并清印记。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80009004 },
        },
    },
    -- Barbarian (classId = 10)
    [FeatBuildConfig.Ids.barbarian_training] = {
        id = FeatBuildConfig.Ids.barbarian_training,
        classId = 10,
        level = 1,
        name = "野蛮人训练",
        description = "获得狂斧劈砍，对单体敌人进行一次标准近战武器攻击。",
        effects = {
            { type = "grant_skill", skill = 80010011 },
        },
    },
    [FeatBuildConfig.Ids.barbarian_rage] = {
        id = FeatBuildConfig.Ids.barbarian_rage,
        classId = 10,
        level = 1,
        name = "狂暴基础",
        description = "攻击或受击触发狂暴：每场 1 次，期间物理减伤 -2 且伤害 +2。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80010101 },
        },
    },
    [FeatBuildConfig.Ids.barbarian_heavy_strike] = {
        id = FeatBuildConfig.Ids.barbarian_heavy_strike,
        classId = 10,
        level = 3,
        name = "重击基础",
        description = "获得重击，CD2，对当前目标发动一次强化近战攻击：自身 AC -2，暴击范围翻倍，且力量加值翻倍。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80010013 },
        },
    },
    [FeatBuildConfig.Ids.barbarian_berserk] = {
        id = FeatBuildConfig.Ids.barbarian_berserk,
        classId = 10,
        level = 5,
        name = "狂暴精通",
        description = "取消狂暴每场 1 次限制。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80010103 },
        },
    },
    [FeatBuildConfig.Ids.fighter_training] = {
        id = FeatBuildConfig.Ids.fighter_training,
        classId = 2,
        level = 1,
        name = "战士训练",
        description = "获得基础武器攻击，对单体敌人进行一次标准近战武器攻击。",
        effects = {
            { type = "grant_skill", skill = 80002001 },
        },
    },
    [FeatBuildConfig.Ids.fighter_second_wind] = {
        id = FeatBuildConfig.Ids.fighter_second_wind,
        classId = 2,
        level = 1,
        name = "回气基础",
        description = "获得回气；CD3，回复 1d10 + 体质修正生命；每场战斗 1 次。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80002006 },
        },
    },
    [FeatBuildConfig.Ids.fighter_guard] = {
        id = FeatBuildConfig.Ids.fighter_guard,
        classId = 2,
        level = 5,
        name = "护卫基础",
        description = "获得护卫架势，CD3，持续到你下次行动开始；期间己方承受的近战攻击都由你承担，且你会在其攻击结算后对攻击者发动 1 次基础武器攻击；护卫期间你自身 AC+2。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80002005 },
            { type = "grant_skill", skill = 80002105 },
        },
    },
    [FeatBuildConfig.Ids.fighter_counter_basic] = {
        id = FeatBuildConfig.Ids.fighter_counter_basic,
        classId = 2,
        level = 3,
        name = "反击基础",
        description = "核心被动。敌方对你发动近战武器攻击后，无论命中与否，你都在该次攻击结算后反击 1 次；反击不触发反击。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80002104 },
        },
    },
    -- Monk (classId = 3)
    [FeatBuildConfig.Ids.monk_training] = {
        id = FeatBuildConfig.Ids.monk_training,
        classId = 3,
        level = 1,
        name = "武僧修行",
        description = "获得徒手打击，对单体敌人进行一次标准徒手攻击。",
        effects = {
            { type = "grant_skill", skill = 80003011 },
        },
    },
    [FeatBuildConfig.Ids.monk_martial_arts] = {
        id = FeatBuildConfig.Ids.monk_martial_arts,
        classId = 3,
        level = 1,
        name = "疾风连击",
        description = "初始核心被动。每回合第一次徒手打击后必定对同一目标追加 1 次额外攻击；本次触发不要求徒手打击命中，也不走概率。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80003101 },
            { type = "modify_skill", skill = 80003101, add = { firstHitGuaranteedCombo = true } },
        },
    },
    [FeatBuildConfig.Ids.monk_open_hand] = {
        id = FeatBuildConfig.Ids.monk_open_hand,
        classId = 3,
        level = 3,
        name = "震慑拳",
        description = "获得震慑拳，CD3，对当前目标发动 1 次徒手打击；若命中，强韧豁免失败则 STUN 1 回合。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80003013 },
        },
    },
    [FeatBuildConfig.Ids.monk_harmonize] = {
        id = FeatBuildConfig.Ids.monk_harmonize,
        classId = 3,
        level = 5,
        name = "调息基础",
        description = "获得明镜止水，CD3，回复自身生命；调息熟练后同时清除 Frozen / STUN / SILENT。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80003015 },
            { type = "modify_skill", skill = 80003015, add = { healDiceOverride = "2d8+3" } },
        },
    },
    -- Paladin (classId = 4)
    [FeatBuildConfig.Ids.paladin_training] = {
        id = FeatBuildConfig.Ids.paladin_training,
        classId = 4,
        level = 1,
        name = "圣武训练",
        description = "获得基础武器攻击，对单体敌人进行一次标准近战武器攻击。",
        effects = {
            { type = "grant_skill", skill = 80004011 },
        },
    },
    [FeatBuildConfig.Ids.paladin_shelter_prayer] = {
        id = FeatBuildConfig.Ids.paladin_shelter_prayer,
        classId = 4,
        level = 5,
        name = "灵光基础",
        description = "获得神圣灵光。你存活时，灵光范围内友军获得 AC +1。",
        tier = "high",
        isSubclassCore = true,
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80004102 },
        },
    },
    [FeatBuildConfig.Ids.paladin_lay_on_hands] = {
        id = FeatBuildConfig.Ids.paladin_lay_on_hands,
        classId = 4,
        level = 1,
        name = "圣疗基础",
        description = "获得圣疗：每场 1 次，为生命最低友军回复生命，作为圣武士的初始救场能力。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80004013 },
        },
    },
    [FeatBuildConfig.Ids.paladin_vengeance_smite] = {
        id = FeatBuildConfig.Ids.paladin_vengeance_smite,
        classId = 4,
        level = 3,
        name = "惩戒基础",
        description = "获得破邪斩主动技能 CD3：先执行 1 次基础武器攻击；若命中，追加 2d8 光耀伤害。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80004014 },
        },
    },
    -- Ranger (classId = 5)
    [FeatBuildConfig.Ids.ranger_training] = {
        id = FeatBuildConfig.Ids.ranger_training,
        classId = 5,
        level = 1,
        name = "游侠训练",
        description = "获得基础武器攻击，对单体敌人进行一次标准远程武器攻击。",
        effects = {
            { type = "grant_skill", skill = 80005011 },
        },
    },
    [FeatBuildConfig.Ids.ranger_hunter_mark] = {
        id = FeatBuildConfig.Ids.ranger_hunter_mark,
        classId = 5,
        level = 1,
        name = "印记基础",
        description = "每回合 1 次，基础武器攻击命中后施加短时印记；印记目标 AC 与反射豁免 -1。",
        treeSlot = "R",
        isRoot = true,
        effects = {
            { type = "grant_skill", skill = 80005101 },
        },
    },
    [FeatBuildConfig.Ids.ranger_hunter_shot] = {
        id = FeatBuildConfig.Ids.ranger_hunter_shot,
        classId = 5,
        level = 3,
        name = "狩猎基础",
        description = "获得二连射，CD3；对最多 2 名敌人同时各射 1 箭（标准远程武器攻击）。",
        trunk = "T1",
        treeSlot = "T1",
        effects = {
            { type = "grant_skill", skill = 80005013 },
        },
    },
    [FeatBuildConfig.Ids.ranger_hunter_mastery] = {
        id = FeatBuildConfig.Ids.ranger_hunter_mastery,
        classId = 5,
        level = 5,
        name = "箭雨",
        description = "获得箭雨，每场限 1 次。连续发动 4 次标准远程武器攻击；每次随机选择 1 名敌人，若同一次箭雨内再次命中同一目标，则该次伤害依次减半。",
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80005109 },
        },
    },
}

-- ==========================================================================
-- §5 树形 B / J / C 节点批量定义
-- 设计文档：design/roguelike_feat_skill_fill_sheet.md §5
-- ID namespace: 2300000 + classId*1000 + idx
-- spec: { key, classId, level, slot, prereqs={parentFeatId,...} | nil,
--         name, desc, effects={...}, isCapstone? }
-- ==========================================================================

local Ids = FeatBuildConfig.Ids

local function defineTreeFeat(idx, spec)
    local id = 2300000 + spec.classId * 1000 + idx
    Ids[spec.key] = id
    FEATS[id] = {
        id = id,
        classId = spec.classId,
        level = spec.level,
        name = spec.name,
        description = spec.desc or "",
        treeSlot = spec.slot,
        prerequisites = spec.prereqs,
        requireAllPrerequisites = spec.requireAllPrerequisites == true,
        isCapstone = spec.isCapstone,
        effects = spec.effects or {},
    }
end

-- 短别名引用现有 R / T1 / T2 节点 id（作为 prerequisites 引用源）。
local F = {
    fighter_R = Ids.fighter_second_wind, fighter_T1 = Ids.fighter_counter_basic, fighter_T2 = Ids.fighter_guard,
    monk_R = Ids.monk_martial_arts, monk_T1 = Ids.monk_open_hand, monk_T2 = Ids.monk_harmonize,
    rogue_R = Ids.rogue_sneak_attack, rogue_T1 = Ids.rogue_uncanny_dodge, rogue_T2 = Ids.rogue_cunning_strike,
    ranger_R = Ids.ranger_hunter_mark, ranger_T1 = Ids.ranger_hunter_shot, ranger_T2 = Ids.ranger_hunter_mastery,
    paladin_R = Ids.paladin_lay_on_hands, paladin_T1 = Ids.paladin_vengeance_smite, paladin_T2 = Ids.paladin_shelter_prayer,
    cleric_R = Ids.cleric_shelter_prayer, cleric_T1 = Ids.cleric_healing_word, cleric_T2 = Ids.cleric_guardian_domain,
    sorcerer_R = Ids.sorcerer_ember_ignite, sorcerer_T1 = Ids.sorcerer_ash_burst, sorcerer_T2 = Ids.sorcerer_flame_storm,
    wizard_R = Ids.wizard_frost_lag, wizard_T1 = Ids.wizard_freezing_nova, wizard_T2 = Ids.wizard_blizzard,
    warlock_R = Ids.warlock_static_mark, warlock_T1 = Ids.warlock_thunder_chain, warlock_T2 = Ids.warlock_thunderstorm,
    barbarian_R = Ids.barbarian_rage, barbarian_T1 = Ids.barbarian_heavy_strike, barbarian_T2 = Ids.barbarian_berserk,
}

-- Fighter 战士 (classId=2)
-- SSOT: design/roguelike_feat_skill_fill_sheet.md §5.1
-- 根节点：回气；Lv3/T1：反击；Lv5/T2：护卫；另有连击支线
local fighterTree = {
    -- 回气线
    {key="b_fighter_second_wind_plus", classId=2, level=2, slot="B", prereqs={F.fighter_R}, name="回气熟练", desc="回气治疗额外 +1d6。",
        effects={{type="modify_skill", skill=80002006, add={bonusHealDice="1d6"}}}},
    {key="j_fighter_second_wind_master", classId=2, level=4, slot="J", prereqs={F.fighter_R}, name="回气精通", desc="使用回气后，直到下回合开始前获得 AC +2。",
        effects={{type="modify_skill", skill=80002006, add={postUseAcDelta=2}}}},
    {key="c_fighter_second_wind_grandmaster", classId=2, level=10, slot="C", prereqs={F.fighter_R}, isCapstone=true, name="回气大师", desc="回气的可用次数从每场 1 次提升为每场 2 次。",
        effects={{type="modify_skill", skill=80002006, add={secondWindCharges=1}}}},
    -- 反击线
    {key="b_fighter_counter_basic_plus", classId=2, level=2, slot="B", prereqs={F.fighter_T1}, name="反击熟练", desc="反击 hit +1。",
        effects={{type="modify_skill", skill=80002104, add={counterBonusHit=1}}}},
    {key="j_fighter_counter_master", classId=2, level=4, slot="J", prereqs={F.fighter_T1}, name="反击精通", desc="反击额外造成 +1d6 伤害。",
        effects={{type="modify_skill", skill=80002104, add={counterBonusDice="1d6"}}}},
    {key="c_fighter_double_counter", classId=2, level=10, slot="C", prereqs={F.fighter_T1}, isCapstone=true, name="反击大师", desc="敌方近战攻击你时，先执行反击，再结算该次敌方攻击；你的反击获得 hit +1、额外 +1d6 伤害。",
        effects={{type="modify_skill", skill=80002104, add={counterBeforeAttack=true, counterBonusHit=1, counterBonusDice="1d6"}}}},
    -- 护卫线
    {key="b_fighter_guard_extends_ranged", classId=2, level=2, slot="B", prereqs={F.fighter_T2}, name="护卫熟练", desc="护卫架势可承担友军受到的远程攻击；仅限攻击检定类远程伤害。",
        effects={{type="modify_skill", skill=80002005, add={guardExtendsToRanged=true}}}},
    {key="j_fighter_guard_master", classId=2, level=4, slot="J", prereqs={F.fighter_T2}, name="护卫精通", desc="护卫承担远程攻击时若该次攻击因 AC 未命中你，将该远程攻击反弹给发射者。",
        effects={{type="modify_skill", skill=80002005, add={guardReflectRanged=true}}}},
    {key="c_fighter_guard_grandmaster", classId=2, level=10, slot="C", prereqs={F.fighter_T2}, isCapstone=true, name="护卫大师", desc="护卫成功（替友军承担一次攻击）时，你回复 1d6 生命。",
        effects={{type="modify_skill", skill=80002005, add={guardHealOnSuccess=true}}}},
    -- 连击线（由回气根节点外放）
    {key="b_fighter_combo_basic", classId=2, level=2, slot="B", prereqs={F.fighter_R}, name="连击基础", desc="主动使用基础武器攻击命中时，立即对同一目标追加 1 次连击；反击与护卫反击不触发连击。",
        effects={{type="grant_skill", skill=80002109}}},
    {key="b_fighter_combo_plus", classId=2, level=4, slot="B", prereqs={F.fighter_R}, name="连击熟练", desc="连击 hit +1。",
        effects={{type="modify_skill", skill=80002109, add={extraAttackBonusHit=1}}}},
    {key="j_fighter_combo_master", classId=2, level=6, slot="J", prereqs={F.fighter_R}, name="连击精通", desc="连击额外造成 +1d6 伤害。",
        effects={{type="modify_skill", skill=80002109, add={extraAttackBonusDice="1d6"}}}},
    {key="c_fighter_combo_grandmaster", classId=2, level=10, slot="C", prereqs={F.fighter_R}, isCapstone=true, name="连击大师", desc="若本次基础武器攻击击杀目标，则本次连击可改为攻击另一名目标；若未击杀，连击仍攻击原目标。",
        effects={{type="modify_skill", skill=80002109, add={extraAttackRetargetOnKill=true}}}},
}

-- Monk 武僧 (classId=3)
local monkTree = {
    {key="b_monk_combo_plus", classId=3, level=5, slot="B", prereqs={F.monk_R}, name="徒手强化", desc="徒手打击伤害骰提升至 1d8。",
        effects={{type="modify_skill", skill=80003011, add={weaponDiceOverride="1d8"}}}},
    {key="b_monk_combo_shadow_step", classId=3, level=2, slot="B", prereqs={F.monk_R}, name="疾风步", desc="被动。徒手打击无视前排保护；只要未失能，就免疫偷袭。",
        effects={{type="modify_skill", skill=80003011, add={ignoreFrontProtection=true, sneakAttackImmune=true}}}},
    {key="b_monk_stun_extend", classId=3, level=6, slot="B", prereqs={F.monk_R}, name="拨挡攻击", desc="受到物理伤害时，伤害 -3。",
        effects={{type="modify_skill", skill=80003101, add={deflectAttackFlat=3}}}},
    {key="j_monk_pulse_master", classId=3, level=7, slot="J", prereqs={F.monk_R}, name="拨挡能量", desc="受到法术伤害时，伤害 -3。",
        effects={{type="modify_skill", skill=80003101, add={deflectSpellFlat=3}}}},
    {key="j_monk_combo_master", classId=3, level=10, slot="J", prereqs={F.monk_R}, name="徒手大师", desc="徒手打击伤害骰提升至 1d10。",
        effects={{type="modify_skill", skill=80003011, add={weaponDiceOverride="1d10"}}}},
    {key="b_monk_breath_plus", classId=3, level=7, slot="B", prereqs={F.monk_T2}, name="调息熟练", desc="明镜止水同时解除 Frozen / STUN / SILENT。",
        effects={{type="modify_skill", skill=80003015, add={clearDebuffs=true}}}},
    {key="j_monk_breath_master", classId=3, level=8, slot="J", prereqs={F.monk_T2}, name="调息精通", desc="明镜止水治疗 +1d4。",
        effects={{type="modify_skill", skill=80003015, add={bonusHealDice="1d4"}}}},
    {key="c_monk_combo_grandmaster", classId=3, level=10, slot="C", prereqs={F.monk_R}, requireAllPrerequisites=true, isCapstone=true, name="无懈可击", desc="每回合第一次受到的伤害全免。",
        effects={{type="modify_skill", skill=80003101, add={flawlessFirstHitImmune=true}}}},
}

-- Rogue 盗贼 (classId=1)
local rogueTree = {
    {key="b_rogue_sneak_bonus", classId=1, level=2, slot="B", prereqs={F.rogue_R}, name="偷袭增伤", desc="偷袭额外伤害骰 +1d6。",
        effects={{type="modify_skill", skill=80001101, add={sneakDiceCountDelta=1}}}},
    {key="b_rogue_sneak_relax", classId=1, level=2, slot="B", prereqs={F.rogue_R}, name="偷袭放宽", desc="被 BLEED / POISON / MARK 标记的目标也视为满足偷袭。",
        effects={{type="modify_skill", skill=80001101, add={relaxedSneakStatus=true}}}},
    {key="j_rogue_reflex_evasion", classId=1, level=4, slot="J", prereqs={F.rogue_T1}, name="反射闪避", desc="受到 AOE / 敏捷豁免类伤害时，成功免伤，失败半伤。",
        effects={{type="modify_skill", skill=80001108, add={evasion=true}}}},
    {key="b_rogue_cunning_blind", classId=1, level=6, slot="B", prereqs={F.rogue_T2}, name="诡诈·盲目", desc="诡诈打击命中后追加：目标体豁失败则 BLIND 1 回合（攻击命中 -2）。",
        effects={{type="modify_skill", skill=80001013, add={addBlind=true}}}},
    {key="j_rogue_cunning_stun", classId=1, level=7, slot="J", prereqs={F.rogue_T2}, requireAllPrerequisites=true, name="诡诈·眩晕", desc="诡诈打击命中后追加：目标感豁失败则 STUN 1 回合。",
        effects={{type="modify_skill", skill=80001013, add={addDaze=true}}}},
    {key="c_rogue_deadly_sneak", classId=1, level=10, slot="C", prereqs={F.rogue_R}, requireAllPrerequisites=true, isCapstone=true, name="致命偷袭", desc="偷袭无需任何前置条件即可触发；偷袭命中时暴击阈值 -1；偷袭命中暴击则伤害骰加倍。",
        effects={{type="modify_skill", skill=80001101, add={unconditional=true, sneakDiceDoubleOnCrit=true}}, {type="modify_skill", skill=80001011, add={critThresholdDelta=1}}}},
    {key="c_rogue_cunning_master", classId=1, level=10, slot="C", prereqs={F.rogue_T2}, requireAllPrerequisites=true, isCapstone=true, name="诡诈大师", desc="诡诈打击全部附加效果持续 +1 回合；若目标已处于失能态，本次攻击自动暴击。",
        effects={{type="modify_skill", skill=80001013, add={cunningDurationDelta=1, autoCritOnIncapacitated=true}}}},
}

-- Ranger 游侠 (classId=5)
local rangerTree = {
    {key="b_ranger_mark_plus", classId=5, level=2, slot="B", prereqs={F.ranger_R}, name="印记熟练", desc="对带自己印记的目标，远程攻击附加 +1d6 伤害。",
        effects={{type="modify_skill", skill=80005101, add={classMods={vsMarkBonusDice="1d6"}}}}},
    {key="b_ranger_mark_extend", classId=5, level=2, slot="B", prereqs={F.ranger_R}, name="印记延续", desc="印记持续时间 +1 回合。",
        effects={{type="modify_skill", skill=80005101, add={dotDurationDelta=1}}}},
    {key="b_ranger_hunt_plus", classId=5, level=6, slot="B", prereqs={F.ranger_T1}, name="狩猎熟练", desc="二连射 CD -1。",
        effects={{type="modify_skill", skill=80005013, add={cooldownDelta=-1}}}},
    {key="j_ranger_mark_master", classId=5, level=4, slot="J", prereqs={F.ranger_R}, name="印记精通", desc="对带自己印记的目标，远程攻击附加 +1d10 伤害。",
        effects={{type="modify_skill", skill=80005101, add={classMods={vsMarkBonusDice="1d10"}}}}},
    {key="b_ranger_defense_basic", classId=5, level=2, slot="B", prereqs={F.ranger_R}, name="防守基础", desc="AC +1。",
        effects={{type="grant_skill", skill=80005102}, {type="modify_skill", skill=80005102, add={baseAcBonus=1}}}},
    {key="b_ranger_defense_plus", classId=5, level=4, slot="B", prereqs={F.ranger_R}, name="防守熟练", desc="受到攻击命中后，AC +1 持续到当前回合结束。",
        effects={{type="modify_skill", skill=80005102, add={onHitAcBonus=1}}}},
    {key="j_ranger_defense_master", classId=5, level=6, slot="J", prereqs={F.ranger_R}, requireAllPrerequisites=true, name="防守精通", desc="受到伤害后，伤害减免 +2 持续到当前回合结束。",
        effects={{type="modify_skill", skill=80005102, add={onDamageReductionFlat=2}}}},
}

-- Paladin 圣武士 (classId=4)
local paladinTree = {
    {key="j_paladin_lay_on_master", classId=4, level=2, slot="J", prereqs={F.paladin_R}, name="圣疗精通", desc="圣疗清除关键负面状态。",
        effects={{type="modify_skill", skill=80004013, add={cleanseDebuffs=true}}}},
    {key="b_paladin_smite_plus", classId=4, level=4, slot="B", prereqs={F.paladin_T1}, name="惩戒熟练", desc="破邪斩伤害 +1d8。",
        effects={{type="modify_skill", skill=80004014, add={bonusDamageDice="1d8"}}}},
    {key="b_paladin_holy_mark", classId=4, level=4, slot="B", prereqs={F.paladin_T1}, name="惩戒印记", desc="破邪斩命中后目标受到所有伤害 +1 持续 1 回合。",
        effects={{type="modify_skill", skill=80004014, add={onHitVulnerableDelta=1, onHitVulnerableDuration=1}}}},
    {key="b_paladin_shelter_plus", classId=4, level=6, slot="B", prereqs={F.paladin_T2}, name="灵光熟练", desc="神圣灵光范围内友军所有豁免 +1。",
        effects={{type="modify_skill", skill=80004102, add={classMods={paladinAuraSaveBonus=1}}}}},
    {key="b_paladin_war_cry", classId=4, level=6, slot="B", prereqs={F.paladin_T2}, name="灵光扩张", desc="神圣灵光范围扩大。",
        effects={{type="modify_skill", skill=80004102, add={classMods={paladinAuraRangeDelta=1}}}}},
    {key="c_paladin_smite_master", classId=4, level=10, slot="C", prereqs={F.paladin_T1}, isCapstone=true, name="惩戒大师", desc="破邪斩额外对相邻目标造成一次武器伤害 +1d8 光耀。",
        effects={{type="modify_skill", skill=80004014, add={splitAdjacentTargets=2, splitBonusDice="1d8"}}}},
    {key="b_paladin_combo_basic", classId=4, level=2, slot="B", prereqs={F.paladin_R}, name="连击基础", desc="主动使用圣武打击时，立即对同一目标追加 1 次连击；连击不再触发连击。",
        effects={{type="grant_skill", skill=80004103}}},
}

-- Cleric 牧师 (classId=6)
local clericTree = {
    {key="b_cleric_shelter_plus", classId=6, level=2, slot="B", prereqs={F.cleric_R}, name="庇护熟练", desc="庇护触发后，为该友军提供 1d4 点临时生命。",
        effects={{type="modify_skill", skill=80006103, add={shelterTempHpDice="1d4"}}}},
    {key="b_cleric_turn_undead", classId=6, level=2, slot="B", prereqs={F.cleric_R}, name="驱散基础", desc="获得驱散亡灵主动：对敌方全体造成 1d8 光耀伤害；豁免失败则 SLOW 1 回合。",
        effects={{type="grant_skill", skill=80006016}}},
    {key="b_cleric_heal_plus", classId=6, level=6, slot="B", prereqs={F.cleric_T1}, name="治愈熟练", desc="治愈之言再额外 +1d4，且 CD -1。",
        effects={{type="modify_skill", skill=80006012, add={bonusHealDice="1d4", cooldownDelta=-1}}}},
    {key="j_cleric_heal_master", classId=6, level=7, slot="J", prereqs={F.cleric_T1}, name="治愈精通", desc="治愈之言额外为治疗目标提供 4 点临时生命。",
        effects={{type="modify_skill", skill=80006012, add={postHealShield=4}}}},
    {key="j_cleric_shelter_master", classId=6, level=8, slot="J", prereqs={F.cleric_T2}, name="庇护精通", desc="神恩庇护改为 per-unit；每个友军独立 1 次/回合；被庇护单位获得 2 点临时生命。",
        effects={{type="modify_skill", skill=80006103, add={shelterPerUnit=true, shelterTempHpFlat=2}}}},
    {key="j_cleric_turn_master", classId=6, level=8, slot="J", prereqs={F.cleric_T2}, name="驱散精通", desc="驱散亡灵伤害额外 +1d8；若目标生命低于 25%，则可直接净化。",
        effects={{type="modify_skill", skill=80006016, add={bonusDamageDice="1d8", executeThresholdPct=25}}}},
    {key="c_cleric_shelter_grandmaster", classId=6, level=10, slot="C", prereqs={F.cleric_T2}, requireAllPrerequisites=true, isCapstone=true, name="庇护大师", desc="你的庇护与临时生命效果共享最低血优先逻辑；庇护触发后，为该友军提供 4 点临时生命，并使其下次受到的负面状态持续时间 -1 回合。",
        effects={{type="modify_skill", skill=80006103, add={shelterPerUnit=true, shelterTempHpFlat=4, shelterDebuffDurationDelta=-1, shelterPrioritizeLowestHp=true}}}},
    {key="c_cleric_heal_grandmaster", classId=6, level=10, slot="C", prereqs={F.cleric_T1}, requireAllPrerequisites=true, isCapstone=true, name="治愈大师", desc="治愈之言治疗 2 名最低血友军，但只对主目标驱散 1 个负面。",
        effects={{type="modify_skill", skill=80006012, add={healLowestCount=2, dispelOnlyPrimary=true}}}},
}

-- Sorcerer 术士 (classId=7)
local sorcererTree = {
    {key="b_sorcerer_ignite_plus", classId=7, level=2, slot="B", prereqs={F.sorcerer_R}, name="点燃熟练", desc="基础火焰法术发射物 +1；燃烧持续 +1 回合。",
        effects={{type="modify_skill", skill=80007001, add={projectileCountDelta=1}}, {type="modify_skill", skill=80007002, add={dotDurationDelta=1}}}},
    {key="b_sorcerer_burst_link", classId=7, level=6, slot="B", prereqs={F.sorcerer_T1}, name="爆燃链接", desc="灰烬爆燃伤害 +1d6；命中后对相邻溅射 1d6。",
        effects={{type="modify_skill", skill=80007003, add={bonusDamageDice="1d6", splashAdjacentDice="1d6"}}}},
    {key="j_sorcerer_ignite_master", classId=7, level=4, slot="J", prereqs={F.sorcerer_R}, name="点燃精通", desc="燃烧目标死亡时引爆 1d6 火焰对相邻目标；每回合最多触发 1 次。",
        effects={{type="modify_skill", skill=80007002, add={onKillExplodeDice="1d6"}}}},
    {key="b_sorcerer_storm_plus", classId=7, level=7, slot="B", prereqs={F.sorcerer_T2}, name="风暴熟练", desc="烈焰风暴命中已点燃目标时额外 +1d6。",
        effects={{type="modify_skill", skill=80007004, add={bonusDamageDice="1d6"}}}},
    {key="b_sorcerer_storm_echo", classId=7, level=8, slot="B", prereqs={F.sorcerer_T2}, name="风暴回响", desc="烈焰风暴 CD -1。",
        effects={{type="modify_skill", skill=80007004, add={cooldownDelta=-1}}}},
    {key="j_sorcerer_storm_master", classId=7, level=7, slot="J", prereqs={F.sorcerer_R, F.sorcerer_T2}, name="风暴精通", desc="火焰技能命中已点燃目标时本次 +1d4；同一技能结算只追加 1 次。",
        effects={{type="modify_skill", skill=80007001, add={vsBurningBonusDice="1d4"}}, {type="modify_skill", skill=80007003, add={vsBurningBonusDice="1d4"}}, {type="modify_skill", skill=80007004, add={vsBurningBonusDice="1d4"}}}},
    {key="c_sorcerer_storm_master", classId=7, level=10, slot="C", prereqs={F.sorcerer_T2}, isCapstone=true, name="风暴大师", desc="烈焰风暴命中已点燃目标时额外 +1d4，并延长燃烧 1 回合；命中未点燃目标时仅负责点燃。",
        effects={{type="modify_skill", skill=80007004, add={vsBurningBonusDice="1d4", vsBurningExtendDuration=1, ignoreDamageOnUnignited=true}}}},
    {key="c_sorcerer_burst_master", classId=7, level=10, slot="C", prereqs={F.sorcerer_T1}, requireAllPrerequisites=true, isCapstone=true, name="爆燃大师", desc="灰烬爆燃 CD -1；命中已点燃目标时返还 1 次半伤火焰弹追击，每回合 1 次。",
        effects={{type="modify_skill", skill=80007003, add={cooldownDelta=-1, vsBurningFollowupHalfChargesPerRound=1}}}},
}

-- Wizard 法师(冰) (classId=8)
local wizardTree = {
    {key="b_wizard_frost_plus", classId=8, level=2, slot="B", prereqs={F.wizard_R}, name="减速熟练", desc="减速持续 +1 回合。",
        effects={{type="modify_skill", skill=80008002, add={dotDurationDelta=1}}}},
    {key="b_wizard_frost_armor", classId=8, level=2, slot="B", prereqs={F.wizard_R}, name="减速冰甲", desc="施法后获得 4 点临时生命，每场最多 2 次。",
        effects={{type="modify_skill", skill=80008001, add={onCastShield=4, onCastShieldCharges=2}}}},
    {key="b_wizard_frost_master", classId=8, level=4, slot="B", prereqs={F.wizard_R}, name="减速精通", desc="对减速目标命中额外 +1d4。",
        effects={{type="modify_skill", skill=80008001, add={vsFrostBonusDice="1d4"}}}},
    {key="b_wizard_freeze_plus", classId=8, level=6, slot="B", prereqs={F.wizard_T1}, name="冻结熟练", desc="冻结新星伤害 +1d8。",
        effects={{type="modify_skill", skill=80008003, add={bonusDamageDice="1d8"}}}},
    {key="b_wizard_freeze_expand", classId=8, level=6, slot="B", prereqs={F.wizard_T1}, name="冻结扩张", desc="冻结新星 AOE 半径 +1。",
        effects={{type="modify_skill", skill=80008003, add={aoeRadiusDelta=1}}}},
    {key="j_wizard_freeze_spell", classId=8, level=7, slot="J", prereqs={F.wizard_T1}, name="冻结咒术", desc="冻结新星 CD -1。",
        effects={{type="modify_skill", skill=80008003, add={cooldownDelta=-1}}}},
    {key="b_wizard_storm_echo", classId=8, level=7, slot="B", prereqs={F.wizard_T2}, name="暴风回返", desc="暴风雪 CD -1。",
        effects={{type="modify_skill", skill=80008004, add={cooldownDelta=-1}}}},
    {key="j_wizard_freeze_master", classId=8, level=8, slot="J", prereqs={F.wizard_T1, F.wizard_T2}, name="冻结精通", desc="冻结新星与暴风雪命中 FROZEN 目标时再 +1d4；不对单纯减速目标生效。",
        effects={{type="modify_skill", skill=80008003, add={vsFrozenBonusDice="1d4"}}, {type="modify_skill", skill=80008004, add={vsFrozenBonusDice="1d4"}}}},
    {key="c_wizard_frost_grandmaster", classId=8, level=10, slot="C", prereqs={F.wizard_R}, requireAllPrerequisites=true, isCapstone=true, name="减速大师", desc="冰系技能对减速 / 冻结目标 hit +1、伤害 +1d4；寒霜射线命中冻结目标时刷新减速。",
        effects={{type="modify_skill", skill=80008001, add={vsFrostBonusHit=1, vsFrostBonusDice="1d4", refreshFrostOnFrozenHit=true}},
                 {type="modify_skill", skill=80008003, add={vsFrostBonusHit=1, vsFrostBonusDice="1d4"}},
                 {type="modify_skill", skill=80008004, add={vsFrostBonusHit=1, vsFrostBonusDice="1d4"}}}},
    {key="c_wizard_freeze_grandmaster", classId=8, level=10, slot="C", prereqs={F.wizard_T2}, requireAllPrerequisites=true, isCapstone=true, name="冻结大师", desc="暴风雪命中已 FROZEN 目标时延长 1 回合；同一目标总冻结持续不超过 2 回合。",
        effects={{type="modify_skill", skill=80008004, add={vsFrozenExtendDuration=1, vsFrozenExtendCap=2}}}},
}

-- Warlock 邪术师(雷) (classId=9)
local warlockTree = {
    {key="b_warlock_mark_plus", classId=9, level=2, slot="B", prereqs={F.warlock_R}, name="印记熟练", desc="印记额外伤害 +1d6。",
        effects={{type="modify_skill", skill=80009002, add={markBonusDice="1d6"}}}},
    {key="b_warlock_mark_deepen", classId=9, level=2, slot="B", prereqs={F.warlock_R}, name="印记加深", desc="每回合可对 2 个目标分别上印记。",
        effects={{type="modify_skill", skill=80009002, add={markRecastPerRound=2}}}},
    {key="b_warlock_chain_plus", classId=9, level=6, slot="B", prereqs={F.warlock_T1}, name="雷链熟练", desc="雷链额外弹射 1 次。",
        effects={{type="modify_skill", skill=80009003, add={chainCountDelta=1}}}},
    {key="b_warlock_chain_echo", classId=9, level=6, slot="B", prereqs={F.warlock_T1}, name="雷链残响", desc="雷链最后一跳若命中带印记目标，额外 +1d6。",
        effects={{type="modify_skill", skill=80009003, add={lastHopBonusDice="1d6"}}}},
    {key="j_warlock_chain_master", classId=9, level=7, slot="J", prereqs={F.warlock_T1}, name="雷链精通", desc="雷链命中带印记目标后该印记持续 +1 回合。",
        effects={{type="modify_skill", skill=80009003, add={onHitMarkDurationDelta=1}}}},
    {key="b_warlock_storm_echo", classId=9, level=7, slot="B", prereqs={F.warlock_T2}, name="雷暴回响", desc="雷暴 CD -1。",
        effects={{type="modify_skill", skill=80009004, add={cooldownDelta=-1}}}},
    {key="j_warlock_mark_master", classId=9, level=8, slot="J", prereqs={F.warlock_R}, name="印记精通", desc="每回合可兑现 2 次印记，但同一目标每回合最多兑现 1 次。",
        effects={{type="modify_skill", skill=80009002, add={markPayoutPerRound=2}}}},
    {key="c_warlock_chain_grandmaster", classId=9, level=10, slot="C", prereqs={F.warlock_T1}, requireAllPrerequisites=true, isCapstone=true, name="雷链大师", desc="雷链优先弹向带印记目标；首段若命中带印记目标，额外 +1d8；总弹射段数仍受全局上限约束。",
        effects={{type="modify_skill", skill=80009003, add={prioritizeMarkedTargets=true, firstHopVsMarkBonusDice="1d8"}}}},
    {key="c_warlock_storm_grandmaster", classId=9, level=10, slot="C", prereqs={F.warlock_T2}, requireAllPrerequisites=true, isCapstone=true, name="雷暴大师", desc="雷暴命中带印记目标后，额外产生 1 次半伤雷击弹射；单次雷暴最多追加 1 次。",
        effects={{type="modify_skill", skill=80009004, add={onMarkHitChainHalf=1, onMarkHitChainHalfPerCast=1}}}},
}

-- Barbarian 野蛮人 (classId=10)
local barbarianTree = {
    {key="b_barbarian_rage_extend", classId=10, level=2, slot="B", prereqs={F.barbarian_R}, name="狂暴延续", desc="狂暴持续时间 +1 回合。",
        effects={{type="modify_skill", skill=80010101, add={rageDurationDelta=1}}}},
    {key="b_barbarian_rage_recovery", classId=10, level=2, slot="B", prereqs={F.barbarian_R}, name="狂暴恢复", desc="每次进入狂暴时回复 1d6 生命。",
        effects={{type="modify_skill", skill=80010101, add={onRageEnterHealDice="1d6"}}}},
    {key="b_barbarian_heavy_plus", classId=10, level=6, slot="B", prereqs={F.barbarian_T1}, name="重击熟练", desc="重击自损破绽由 AC -2 降为 AC -1。",
        effects={{type="modify_skill", skill=80010013, add={acPenaltyDelta=-1}}}},
    {key="b_barbarian_heavy_echo", classId=10, level=6, slot="B", prereqs={F.barbarian_T1}, name="重击回转", desc="重击 CD -1。",
        effects={{type="modify_skill", skill=80010013, add={cooldownDelta=-1}}}},
    {key="j_barbarian_heavy_master", classId=10, level=7, slot="J", prereqs={F.barbarian_T1}, name="顺劈斩", desc="重击额外对 1 名前排目标造成完整重击。",
        effects={{type="modify_skill", skill=80010013, add={frontRowSplitTargets=2}}}},
    {key="j_barbarian_blood_master", classId=10, level=8, slot="J", prereqs={F.barbarian_T2}, name="嗜血精通", desc="狂暴期间击杀回复 1d8 生命。",
        effects={{type="modify_skill", skill=80010101, add={onKillHealDice="1d8"}}}},
    {key="c_barbarian_strike_master", classId=10, level=10, slot="C", prereqs={F.barbarian_T1}, requireAllPrerequisites=true, isCapstone=true, name="顺劈斩目标+1", desc="顺劈斩额外目标 +1。",
        effects={{type="modify_skill", skill=80010013, add={frontRowSplitDelta=1}}}},
}

local TreeFeatGroups = { fighterTree, monkTree, rogueTree, rangerTree, paladinTree, clericTree, sorcererTree, wizardTree, warlockTree, barbarianTree }
do
    local nextIdxByClass = {}
    for _, group in ipairs(TreeFeatGroups) do
        for _, spec in ipairs(group) do
            local cid = spec.classId
            nextIdxByClass[cid] = (nextIdxByClass[cid] or 0) + 1
            defineTreeFeat(nextIdxByClass[cid], spec)
        end
    end
end

-- 树形 feat 父子链回填：feat_picker.lua 的 prerequisites 走 OR 语义，
-- 当一个 J/C 节点 SSOT 要求 "基础 + 熟练" 这种 AND 时，必须串到最近父节点
-- 形成单亲链，隐式实现 AND。SSOT: design/roguelike_feat_skill_fill_sheet.md §8。
-- 表项格式: { childKey, parentKey } —— parentKey 必须存在于 FEATS。
do
    local I = FeatBuildConfig.Ids
    local PREREQ_FIXES = {
        -- 战士 §8.1
        { "j_fighter_second_wind_master",   "b_fighter_second_wind_plus" },
        { "c_fighter_second_wind_grandmaster", "j_fighter_second_wind_master" },
        { "j_fighter_counter_master",       "b_fighter_counter_basic_plus" },
        { "c_fighter_double_counter",       "j_fighter_counter_master" },
        { "j_fighter_guard_master",         "b_fighter_guard_extends_ranged" },
        { "c_fighter_guard_grandmaster",    "j_fighter_guard_master" },
        { "b_fighter_combo_plus",           "b_fighter_combo_basic" },
        { "j_fighter_combo_master",         "b_fighter_combo_plus" },
        { "c_fighter_combo_grandmaster",    "j_fighter_combo_master" },
        -- 武僧 §8.2
        { "j_monk_pulse_master",            "b_monk_stun_extend" },
        { "j_monk_combo_master",            "b_monk_combo_plus" },
        { "j_monk_breath_master",           "b_monk_breath_plus" },
        { "c_monk_combo_grandmaster",       "j_monk_pulse_master" },
        -- 盗贼 §8.3
        { "c_rogue_deadly_sneak",           "b_rogue_sneak_bonus" },
        { "c_rogue_deadly_sneak",           "b_rogue_sneak_relax" },
        { "c_rogue_deadly_sneak",           "j_rogue_reflex_evasion" },
        { "j_rogue_cunning_stun",           "b_rogue_cunning_blind" },
        { "c_rogue_cunning_master",         "b_rogue_cunning_blind" },
        { "c_rogue_cunning_master",         "j_rogue_cunning_stun" },
        -- 游侠 §8.4
        { "j_ranger_mark_master",           "b_ranger_mark_plus" },
        { "b_ranger_defense_plus",          "b_ranger_defense_basic" },
        { "j_ranger_defense_master",        "b_ranger_defense_basic" },
        { "j_ranger_defense_master",        "b_ranger_defense_plus" },
        -- 圣武士 §8.5
        { "c_paladin_smite_master",         "b_paladin_holy_mark" },
        -- 牧师 §8.9
        { "j_cleric_heal_master",           "b_cleric_shelter_plus" },
        { "j_cleric_shelter_master",        "b_cleric_shelter_plus" },
        { "j_cleric_turn_master",           "b_cleric_turn_undead" },
        { "c_cleric_shelter_grandmaster",   "j_cleric_shelter_master" },
        { "c_cleric_heal_grandmaster",      "j_cleric_heal_master" },
        -- 术士 §8.8
        { "j_sorcerer_ignite_master",       "b_sorcerer_ignite_plus" },
        { "j_sorcerer_storm_master",        "b_sorcerer_storm_plus" },
        { "c_sorcerer_storm_master",        "b_sorcerer_storm_echo" },
        { "c_sorcerer_burst_master",        "j_sorcerer_ignite_master" },
        -- 法师 §8.7
        { "j_wizard_freeze_spell",          "b_wizard_frost_plus" },
        { "c_wizard_frost_grandmaster",     "j_wizard_freeze_master" },
        { "c_wizard_freeze_grandmaster",    "j_wizard_freeze_master" },
        { "c_wizard_freeze_grandmaster",    "b_wizard_storm_echo" },
        -- 邪术师 §8.10
        { "j_warlock_chain_master",         "b_warlock_chain_plus" },
        { "j_warlock_mark_master",          "b_warlock_mark_deepen" },
        { "c_warlock_chain_grandmaster",    "j_warlock_chain_master" },
        { "c_warlock_chain_grandmaster",    "b_warlock_chain_echo" },
        { "c_warlock_storm_grandmaster",    "j_warlock_mark_master" },
        { "c_warlock_storm_grandmaster",    "b_warlock_storm_echo" },
        -- 野蛮人 §8.6
        { "j_barbarian_heavy_master",       "b_barbarian_heavy_plus" },
        { "j_barbarian_blood_master",       "b_barbarian_rage_recovery" },
        { "c_barbarian_strike_master",      "b_barbarian_heavy_echo" },
        { "c_barbarian_strike_master",      "j_barbarian_heavy_master" },
    }
    for _, pair in ipairs(PREREQ_FIXES) do
        local childKey, parentKey = pair[1], pair[2]
        local childId = I[childKey]
        local parentId = I[parentKey]
        local feat = childId and FEATS[childId]
        assert(feat, "[feats.lua] PREREQ_FIXES child not found: " .. tostring(childKey))
        assert(parentId, "[feats.lua] PREREQ_FIXES parent not found: " .. tostring(parentKey))
        if feat.requireAllPrerequisites == true then
            feat.prerequisites = feat.prerequisites or {}
            local exists = false
            for _, existingId in ipairs(feat.prerequisites) do
                if tonumber(existingId) == tonumber(parentId) then
                    exists = true
                    break
                end
            end
            if not exists then
                feat.prerequisites[#feat.prerequisites + 1] = parentId
            end
        else
            feat.prerequisites = { parentId }
        end
    end
end

local FEATS_BY_CLASS = {}
for featId, feat in pairs(FEATS) do
    local classId = tonumber(feat.classId) or 0
    FEATS_BY_CLASS[classId] = FEATS_BY_CLASS[classId] or {}
    FEATS_BY_CLASS[classId][#FEATS_BY_CLASS[classId] + 1] = featId
end

-- ==========================================================================
-- 规范化：根据 level 自动补齐 tier / tags / isSubclassCore（设计文档 §3.2）
--   Lv2 → small（通用）
--   Lv3 → medium，子职业核心（choiceGroup 非空，且 classId>0）
--   Lv4 → medium（通用 mastery）
--   Lv5 → high，子职业 capstone（classId>0）
--   classId=0 的通用 feat 则 isSubclassCore 一律 false
-- 仅写入未显式标注的字段，保留手工配置的优先级。
-- ==========================================================================
local function isSubclassChoiceGroup(group)
    if type(group) ~= "string" or group == "" then
        return false
    end
    -- Lv3 子职业分支统一通过 choiceGroup 标记（subclass / oath / domain / prayer / active 等）。
    return group:find("_lv3_", 1, true) ~= nil
end

for _, feat in pairs(FEATS) do
    local level = tonumber(feat.level) or 0
    local classId = tonumber(feat.classId) or 0
    if feat.tier == nil then
        if level == 2 then
            feat.tier = "small"
        elseif level == 3 then
            feat.tier = "medium"
        elseif level == 4 then
            feat.tier = "medium"
        elseif level == 5 then
            feat.tier = "high"
        end
    end
    if feat.isSubclassCore == nil then
        if classId > 0 and level == 3 and isSubclassChoiceGroup(feat.choiceGroup) then
            feat.isSubclassCore = true
        elseif classId > 0 and level == 5 then
            feat.isSubclassCore = true
        else
            feat.isSubclassCore = false
        end
    end
    if feat.tags == nil then
        feat.tags = {}
    end
end

local function sortById(list)
    table.sort(list, function(a, b)
        return (tonumber(a and a.id) or 0) < (tonumber(b and b.id) or 0)
    end)
    return list
end

---@param featId integer
---@return BuildFeatDef|nil
function FeatBuildConfig.GetFeat(featId)
    return FEATS[tonumber(featId) or 0]
end

---@param classId integer
---@return BuildFeatDef[]
function FeatBuildConfig.GetFeatsByClass(classId)
    local ClassBuildProgression = require("config.tables.classes")
    local resolvedClassId = tonumber(classId) or 0
    local activeFeatIds = {}
    local seen = {}
    for _, featId in ipairs(ClassBuildProgression.GetLv1FeatIds(resolvedClassId) or {}) do
        local id = tonumber(featId) or 0
        if id > 0 and FEATS[id] and not seen[id] then
            seen[id] = true
            activeFeatIds[#activeFeatIds + 1] = id
        end
    end
    for _, featId in ipairs(ClassBuildProgression.GetTreePool(resolvedClassId) or {}) do
        local id = tonumber(featId) or 0
        if id > 0 and FEATS[id] and not seen[id] then
            seen[id] = true
            activeFeatIds[#activeFeatIds + 1] = id
        end
    end
    local result = {}
    local sourceIds = activeFeatIds
    if #sourceIds == 0 then
        sourceIds = FEATS_BY_CLASS[resolvedClassId] or {}
    end
    for _, featId in ipairs(sourceIds) do
        result[#result + 1] = FEATS[featId]
    end
    return sortById(result)
end

---@param classId integer
---@param level integer
---@param choiceGroup string|nil
---@return BuildFeatDef[]
function FeatBuildConfig.GetFeatsByLevel(classId, level, choiceGroup)
    local result = {}
    for _, feat in ipairs(FeatBuildConfig.GetFeatsByClass(classId)) do
        if feat.level == level then
            if choiceGroup == nil or feat.choiceGroup == choiceGroup then
                result[#result + 1] = feat
            end
        end
    end
    return result
end

---@param classId integer
---@param level integer
---@param tier BuildFeatTier
---@return integer[]
function FeatBuildConfig.GetFeatsByTier(classId, level, tier)
    local result = {}
    local target = tostring(tier or "")
    for _, feat in ipairs(FeatBuildConfig.GetFeatsByClass(classId)) do
        if feat.level == level and feat.tier == target then
            result[#result + 1] = feat.id
        end
    end
    return result
end

---@param classId integer
---@param level integer
---@return integer[]
function FeatBuildConfig.GetSubclassCoreFeats(classId, level)
    local result = {}
    for _, feat in ipairs(FeatBuildConfig.GetFeatsByClass(classId)) do
        if feat.level == level and feat.isSubclassCore == true then
            result[#result + 1] = feat.id
        end
    end
    return result
end

---@param featId integer
---@return BuildFeatTier|nil
function FeatBuildConfig.GetFeatTier(featId)
    local feat = FeatBuildConfig.GetFeat(featId)
    return feat and feat.tier or nil
end

return FeatBuildConfig
