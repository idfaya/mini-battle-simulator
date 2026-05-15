---@alias BuildFeatEffectType
---| "grant_skill"
---| "modify_skill"
---| "replace_skill"

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

local FeatBuildConfig = {}

local function FeatId(level, index)
    return 2100000 + level * 100 + index
end

FeatBuildConfig.Ids = {
    rogue_training = FeatId(401, 1),
    rogue_sneak_attack = FeatId(401, 2),
    rogue_shadow_step = FeatId(402, 1),
    rogue_flanking_expert = FeatId(402, 2),
    rogue_evasive_tumble = FeatId(402, 3),
    rogue_execute_strike = FeatId(403, 1),
    rogue_trickster_blade = FeatId(403, 2),
    rogue_swashbuckler_thrust = FeatId(403, 3),
    rogue_sneak_attack_mastery = FeatId(404, 1),
    rogue_subclass_mastery = FeatId(404, 2),
    rogue_lightfoot_mastery = FeatId(404, 3),
    rogue_executioner = FeatId(405, 1),
    rogue_shadow_dancer = FeatId(405, 2),
    rogue_survivor = FeatId(405, 3),
    cleric_training = FeatId(501, 1),
    cleric_healing_word = FeatId(501, 2),
    cleric_radiant_prayer = FeatId(502, 1),
    cleric_shelter_prayer = FeatId(502, 2),
    cleric_revival_prayer = FeatId(502, 3),
    cleric_life_domain = FeatId(503, 1),
    cleric_light_domain = FeatId(503, 2),
    cleric_guardian_domain = FeatId(503, 3),
    cleric_spell_mastery = FeatId(504, 1),
    cleric_healing_mastery = FeatId(504, 2),
    cleric_sanctuary_mastery = FeatId(504, 3),
    cleric_dawn_bishop = FeatId(505, 1),
    cleric_mercy_bishop = FeatId(505, 2),
    cleric_watch_bishop = FeatId(505, 3),
    fighter_training = FeatId(1, 1),
    fighter_second_wind = FeatId(1, 2),
    fighter_extra_attack = FeatId(2, 1),
    fighter_action_surge = FeatId(3, 1),
    fighter_guard = FeatId(3, 2),
    fighter_precise_attack = FeatId(4, 1),
    fighter_counter_basic = FeatId(4, 2),
    fighter_sweeping_attack = FeatId(5, 1),
    fighter_second_wind_mastery = FeatId(5, 2),
    monk_training = FeatId(101, 1),
    monk_martial_arts = FeatId(101, 2),
    monk_flurry_training = FeatId(102, 1),
    monk_iron_mind = FeatId(102, 2),
    monk_swift_step = FeatId(102, 3),
    monk_open_hand = FeatId(103, 1),
    monk_shadow_combo = FeatId(103, 2),
    monk_harmonize = FeatId(103, 3),
    monk_body_mastery = FeatId(104, 1),
    monk_combo_mastery = FeatId(104, 2),
    monk_body_guard = FeatId(104, 3),
    monk_combo_mastery_capstone = FeatId(105, 1),
    monk_disruption_mastery = FeatId(105, 2),
    monk_purity_mastery = FeatId(105, 3),
    paladin_training = FeatId(201, 1),
    paladin_divine_smite = FeatId(201, 2),
    paladin_shelter_prayer = FeatId(202, 1),
    paladin_heavy_armor_prayer = FeatId(202, 2),
    paladin_judgement_prayer = FeatId(202, 3),
    paladin_lay_on_hands = FeatId(203, 1),
    paladin_vengeance_smite = FeatId(203, 2),
    paladin_guardian_aura = FeatId(203, 3),
    paladin_smite_mastery = FeatId(204, 1),
    paladin_healing_mastery = FeatId(204, 2),
    paladin_aura_mastery = FeatId(204, 3),
    paladin_execution_knight = FeatId(205, 1),
    paladin_merciful_knight = FeatId(205, 2),
    paladin_sanctuary_knight = FeatId(205, 3),
    ranger_training = FeatId(301, 1),
    ranger_hunter_mark = FeatId(301, 2),
    ranger_tracking_skill = FeatId(302, 1),
    ranger_precise_shot = FeatId(302, 2),
    ranger_wild_endurance = FeatId(302, 3),
    ranger_hunter_shot = FeatId(303, 1),
    ranger_shadow_shot = FeatId(303, 2),
    ranger_snare_shot = FeatId(303, 3),
    ranger_mark_mastery = FeatId(304, 1),
    ranger_subclass_mastery = FeatId(304, 2),
    ranger_survival_mastery = FeatId(304, 3),
    ranger_hunter_mastery = FeatId(305, 1),
    ranger_shadow_mastery = FeatId(305, 2),
    ranger_snare_mastery = FeatId(305, 3),
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
        name = "伏击",
        description = "核心被动。当目标当前目标不是你，或目标本回合已被其他友军攻击过时，你的基础攻击造成额外伤害。",
        effects = {
            { type = "grant_skill", skill = 80001101 },
        },
    },
    [FeatBuildConfig.Ids.rogue_shadow_step] = {
        id = FeatBuildConfig.Ids.rogue_shadow_step,
        classId = 1,
        level = 2,
        name = "影步切入",
        description = "每回合第一次基础武器攻击可无视前排保护。",
        choiceGroup = "rogue_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80001102 },
        },
    },
    [FeatBuildConfig.Ids.rogue_flanking_expert] = {
        id = FeatBuildConfig.Ids.rogue_flanking_expert,
        classId = 1,
        level = 2,
        name = "夹击老手",
        description = "通过夹击触发偷袭时，偷袭额外再造成 1d4 伤害。",
        choiceGroup = "rogue_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80001103 },
        },
    },
    [FeatBuildConfig.Ids.rogue_evasive_tumble] = {
        id = FeatBuildConfig.Ids.rogue_evasive_tumble,
        classId = 1,
        level = 2,
        name = "翻滚脱离",
        description = "每回合第一次被近战攻击命中时，受到伤害减少 1d6。",
        choiceGroup = "rogue_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80001104 },
        },
    },
    [FeatBuildConfig.Ids.rogue_execute_strike] = {
        id = FeatBuildConfig.Ids.rogue_execute_strike,
        classId = 1,
        level = 3,
        name = "影袭处决",
        description = "获得影袭处决，CD3，对后排或低血量目标发动 1 次攻击；该次攻击视为满足伏击条件。",
        choiceGroup = "rogue_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80001013 },
        },
    },
    [FeatBuildConfig.Ids.rogue_trickster_blade] = {
        id = FeatBuildConfig.Ids.rogue_trickster_blade,
        classId = 1,
        level = 3,
        name = "诡术师",
        description = "获得扰乱飞刃，CD2，对后排目标发动 1 次基础武器攻击；若命中，目标直到下回合开始前 AC -1。",
        choiceGroup = "rogue_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80001014 },
        },
    },
    [FeatBuildConfig.Ids.rogue_swashbuckler_thrust] = {
        id = FeatBuildConfig.Ids.rogue_swashbuckler_thrust,
        classId = 1,
        level = 3,
        name = "游斗者",
        description = "获得穿行突刺，CD2，可指定任意一名敌人发动 1 次基础武器攻击；该次攻击视为满足偷袭条件。",
        choiceGroup = "rogue_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80001015 },
        },
    },
    [FeatBuildConfig.Ids.rogue_sneak_attack_mastery] = {
        id = FeatBuildConfig.Ids.rogue_sneak_attack_mastery,
        classId = 1,
        level = 4,
        name = "偷袭专精",
        description = "偷袭额外伤害提升为 2d6。",
        choiceGroup = "rogue_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80001105 },
        },
    },
    [FeatBuildConfig.Ids.rogue_subclass_mastery] = {
        id = FeatBuildConfig.Ids.rogue_subclass_mastery,
        classId = 1,
        level = 4,
        name = "子职专精",
        description = "Lv3 子职技能额外造成 1d6 伤害。",
        choiceGroup = "rogue_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80001106 },
        },
    },
    [FeatBuildConfig.Ids.rogue_lightfoot_mastery] = {
        id = FeatBuildConfig.Ids.rogue_lightfoot_mastery,
        classId = 1,
        level = 4,
        name = "轻身专精",
        description = "每回合第一次被近战攻击命中时，额外再减少 1d4 伤害。",
        choiceGroup = "rogue_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80001107 },
        },
    },
    [FeatBuildConfig.Ids.rogue_executioner] = {
        id = FeatBuildConfig.Ids.rogue_executioner,
        classId = 1,
        level = 5,
        name = "直觉闪避",
        description = "高阶被动。每回合第一次被攻击命中时，受到伤害减半。",
        choiceGroup = "rogue_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80001108 },
        },
    },
    [FeatBuildConfig.Ids.rogue_shadow_dancer] = {
        id = FeatBuildConfig.Ids.rogue_shadow_dancer,
        classId = 1,
        level = 5,
        name = "影舞者",
        description = "获得直觉闪避；若你本回合第一次基础武器攻击未触发偷袭，则本回合下一次满足条件的偷袭额外造成 2d6 伤害。",
        choiceGroup = "rogue_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80001108 },
            { type = "grant_skill", skill = 80001110 },
        },
    },
    [FeatBuildConfig.Ids.rogue_survivor] = {
        id = FeatBuildConfig.Ids.rogue_survivor,
        classId = 1,
        level = 5,
        name = "生还者",
        description = "获得直觉闪避；触发伤害减半后，你下一次基础武器攻击视为满足偷袭条件。",
        choiceGroup = "rogue_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80001108 },
            { type = "grant_skill", skill = 80001111 },
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
        name = "治愈之言",
        description = "获得治愈之言，CD3，为生命最低的友军回复 1d8 + 等级 生命。",
        effects = {
            { type = "grant_skill", skill = 80006012 },
        },
    },
    [FeatBuildConfig.Ids.cleric_radiant_prayer] = {
        id = FeatBuildConfig.Ids.cleric_radiant_prayer,
        classId = 6,
        level = 2,
        name = "裁断祷文",
        description = "神圣火花对敌命中后额外造成 1d6 光耀伤害。",
        choiceGroup = "cleric_lv2_prayer",
        effects = {
            { type = "grant_skill", skill = 80006102 },
        },
    },
    [FeatBuildConfig.Ids.cleric_shelter_prayer] = {
        id = FeatBuildConfig.Ids.cleric_shelter_prayer,
        classId = 6,
        level = 1,
        name = "神恩庇护",
        description = "核心被动。每个友军每回合第一次受到伤害时，该次伤害减少 1d6。",
        effects = {
            { type = "grant_skill", skill = 80006103 },
        },
    },
    [FeatBuildConfig.Ids.cleric_revival_prayer] = {
        id = FeatBuildConfig.Ids.cleric_revival_prayer,
        classId = 6,
        level = 2,
        name = "复苏祷文",
        description = "治愈之言额外再回复 1d8 生命。",
        choiceGroup = "cleric_lv2_prayer",
        effects = {
            { type = "grant_skill", skill = 80006104 },
        },
    },
    [FeatBuildConfig.Ids.cleric_life_domain] = {
        id = FeatBuildConfig.Ids.cleric_life_domain,
        classId = 6,
        level = 3,
        name = "生命领域",
        description = "获得群愈祷言，CD3，为生命最低的两名友军各回复 1d8 + 4 生命。",
        choiceGroup = "cleric_lv3_domain",
        effects = {
            { type = "grant_skill", skill = 80006013 },
        },
    },
    [FeatBuildConfig.Ids.cleric_light_domain] = {
        id = FeatBuildConfig.Ids.cleric_light_domain,
        classId = 6,
        level = 3,
        name = "光明领域",
        description = "获得圣焰裁决，CD3，对任意一名敌人发动 1 次神圣火花；若目标未通过该次豁免，额外造成 2d6 光耀伤害。",
        choiceGroup = "cleric_lv3_domain",
        effects = {
            { type = "grant_skill", skill = 80006014 },
        },
    },
    [FeatBuildConfig.Ids.cleric_guardian_domain] = {
        id = FeatBuildConfig.Ids.cleric_guardian_domain,
        classId = 6,
        level = 5,
        name = "圣域祷言",
        description = "获得圣域祷言，CD3，持续 2 回合；我方全体 AC +1，且每个友军每回合第一次受到的伤害减少 1d6。",
        effects = {
            { type = "grant_skill", skill = 80006015 },
        },
    },
    [FeatBuildConfig.Ids.cleric_spell_mastery] = {
        id = FeatBuildConfig.Ids.cleric_spell_mastery,
        classId = 6,
        level = 4,
        name = "神术专精",
        description = "神圣火花对敌命中后额外造成 1d6 光耀伤害。",
        choiceGroup = "cleric_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80006105 },
        },
    },
    [FeatBuildConfig.Ids.cleric_healing_mastery] = {
        id = FeatBuildConfig.Ids.cleric_healing_mastery,
        classId = 6,
        level = 4,
        name = "治疗专精",
        description = "治愈之言与群愈祷言额外再回复 1d8 生命。",
        choiceGroup = "cleric_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80006106 },
        },
    },
    [FeatBuildConfig.Ids.cleric_sanctuary_mastery] = {
        id = FeatBuildConfig.Ids.cleric_sanctuary_mastery,
        classId = 6,
        level = 4,
        name = "圣域专精",
        description = "圣域祷言额外使友军 AC +1。",
        choiceGroup = "cleric_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80006107 },
        },
    },
    [FeatBuildConfig.Ids.cleric_dawn_bishop] = {
        id = FeatBuildConfig.Ids.cleric_dawn_bishop,
        classId = 6,
        level = 5,
        name = "圣焰主教",
        description = "每回合第一次神圣火花使目标未通过豁免后，额外造成 1d8 光耀伤害。",
        choiceGroup = "cleric_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80006109 },
        },
    },
    [FeatBuildConfig.Ids.cleric_mercy_bishop] = {
        id = FeatBuildConfig.Ids.cleric_mercy_bishop,
        classId = 6,
        level = 5,
        name = "慈恩主教",
        description = "你每回合第一次回复友军生命时，额外再回复 1d6 生命。",
        choiceGroup = "cleric_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80006110 },
        },
    },
    [FeatBuildConfig.Ids.cleric_watch_bishop] = {
        id = FeatBuildConfig.Ids.cleric_watch_bishop,
        classId = 6,
        level = 5,
        name = "守望主教",
        description = "每回合第一次神圣火花使目标未通过豁免后，直到你下回合开始，我方前排 AC +1。",
        choiceGroup = "cleric_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80006111 },
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
        name = "余烬点燃",
        description = "核心被动。火焰弹命中后点燃目标；已燃烧目标只刷新持续时间，不重复叠层。",
        effects = {
            { type = "grant_skill", skill = 80007002 },
        },
    },
    [FeatBuildConfig.Ids.sorcerer_ash_burst] = {
        id = FeatBuildConfig.Ids.sorcerer_ash_burst,
        classId = 7,
        level = 3,
        name = "灰烬爆燃",
        description = "获得灰烬爆燃，CD3，攻击燃烧目标时额外造成火焰伤害并刷新燃烧。",
        effects = {
            { type = "grant_skill", skill = 80007003 },
        },
    },
    [FeatBuildConfig.Ids.sorcerer_flame_storm] = {
        id = FeatBuildConfig.Ids.sorcerer_flame_storm,
        classId = 7,
        level = 5,
        name = "烈焰风暴",
        description = "获得烈焰风暴，CD5，对全体敌人造成火焰伤害；燃烧目标额外受 1d8 火焰伤害，未燃烧目标被点燃。",
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
        name = "寒霜迟滞",
        description = "核心被动。寒霜射线命中后使目标进入霜冻状态。",
        effects = {
            { type = "grant_skill", skill = 80008002 },
        },
    },
    [FeatBuildConfig.Ids.wizard_freezing_nova] = {
        id = FeatBuildConfig.Ids.wizard_freezing_nova,
        classId = 8,
        level = 3,
        name = "冻结新星",
        description = "获得冻结新星，CD3，十字范围冰霜法术；已霜冻目标冻结 1 回合，未霜冻目标施加霜冻。",
        effects = {
            { type = "grant_skill", skill = 80008003 },
        },
    },
    [FeatBuildConfig.Ids.wizard_blizzard] = {
        id = FeatBuildConfig.Ids.wizard_blizzard,
        classId = 8,
        level = 5,
        name = "暴风雪",
        description = "获得暴风雪，CD5，对全体敌人造成冰霜伤害；已霜冻目标额外受 1d8 伤害并刷新霜冻，未霜冻目标施加霜冻。",
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
        name = "静电印记",
        description = "核心被动。邪能冲击命中后为目标附加静电印记，供雷链和雷暴引爆。",
        effects = {
            { type = "grant_skill", skill = 80009002 },
        },
    },
    [FeatBuildConfig.Ids.warlock_thunder_chain] = {
        id = FeatBuildConfig.Ids.warlock_thunder_chain,
        classId = 9,
        level = 3,
        name = "雷链",
        description = "获得雷链，CD3，攻击当前目标并额外弹射 1 名敌人，优先弹向带静电印记的目标。",
        effects = {
            { type = "grant_skill", skill = 80009003 },
        },
    },
    [FeatBuildConfig.Ids.warlock_thunderstorm] = {
        id = FeatBuildConfig.Ids.warlock_thunderstorm,
        classId = 9,
        level = 5,
        name = "雷暴",
        description = "获得雷暴，CD5，对全体敌人造成雷电伤害；印记目标额外受 1d8 伤害并清除印记，未印记目标被附加印记。",
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
        name = "狂怒",
        description = "核心被动。每次主动攻击或受到攻击后积累 1 层狂怒，上限 5 层。",
        effects = {
            { type = "grant_skill", skill = 80010101 },
        },
    },
    [FeatBuildConfig.Ids.barbarian_heavy_strike] = {
        id = FeatBuildConfig.Ids.barbarian_heavy_strike,
        classId = 10,
        level = 3,
        name = "重击",
        description = "获得重击，CD2，对当前目标发动一次强化近战攻击：命中 -2，伤害提高，且 19-20 暴击。",
        effects = {
            { type = "grant_skill", skill = 80010013 },
        },
    },
    [FeatBuildConfig.Ids.barbarian_berserk] = {
        id = FeatBuildConfig.Ids.barbarian_berserk,
        classId = 10,
        level = 5,
        name = "狂暴",
        description = "高阶被动。狂怒达到 5 层时自动触发短时狂暴，持续 2 回合；期间受到伤害减少 2，重击额外造成 1d6 伤害；每场战斗 1 次。",
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
        level = 5,
        name = "不屈之风",
        description = "高阶被动。生命值将降到 0 时不会死亡，而是清除状态并恢复 50% 最大生命值；每场战斗 1 次。",
        effects = {
            { type = "grant_skill", skill = 80002101 },
        },
    },
    [FeatBuildConfig.Ids.fighter_extra_attack] = {
        id = FeatBuildConfig.Ids.fighter_extra_attack,
        classId = 2,
        level = 2,
        name = "额外攻击",
        description = "每回合第一次基础武器攻击后，再追加 1 次基础武器攻击。",
        effects = {
            { type = "grant_skill", skill = 80002109 },
        },
    },
    [FeatBuildConfig.Ids.fighter_action_surge] = {
        id = FeatBuildConfig.Ids.fighter_action_surge,
        classId = 2,
        level = 3,
        name = "动作激增",
        description = "CD3，使用后立刻发动 1 次基础武器攻击，目标重新选择；不占用、也不替换该回合原本的普通攻击。",
        choiceGroup = "fighter_lv3_active",
        effects = {
            { type = "grant_skill", skill = 80002003 },
        },
    },
    [FeatBuildConfig.Ids.fighter_guard] = {
        id = FeatBuildConfig.Ids.fighter_guard,
        classId = 2,
        level = 3,
        name = "护卫",
        description = "获得护卫架势，CD3，持续到你下次行动开始；期间己方承受的近战攻击都由你承担，且你会在其攻击结算后对攻击者发动 1 次基础武器攻击；护卫期间你自身 AC+2。",
        choiceGroup = "fighter_lv3_active",
        effects = {
            { type = "grant_skill", skill = 80002005 },
            { type = "grant_skill", skill = 80002105 },
        },
    },
    [FeatBuildConfig.Ids.fighter_precise_attack] = {
        id = FeatBuildConfig.Ids.fighter_precise_attack,
        classId = 2,
        level = 4,
        name = "精准攻击",
        description = "基础武器攻击忽略目标 2 点 AC。",
        choiceGroup = "fighter_lv4_passive",
        effects = {
            { type = "grant_skill", skill = 80002102 },
        },
    },
    [FeatBuildConfig.Ids.fighter_counter_basic] = {
        id = FeatBuildConfig.Ids.fighter_counter_basic,
        classId = 2,
        level = 1,
        name = "反击",
        description = "核心被动。敌方对你发动近战武器攻击后，无论命中与否，你都在该次攻击结算后反击 1 次；反击不触发反击。",
        choiceGroup = "fighter_lv4_passive",
        effects = {
            { type = "grant_skill", skill = 80002104 },
        },
    },
    [FeatBuildConfig.Ids.fighter_sweeping_attack] = {
        id = FeatBuildConfig.Ids.fighter_sweeping_attack,
        classId = 2,
        level = 5,
        name = "横扫攻击",
        description = "基础武器攻击命中主目标后，对另一个敌人追加 1 次横扫伤害。",
        choiceGroup = "fighter_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80002110 },
        },
    },
    [FeatBuildConfig.Ids.fighter_second_wind_mastery] = {
        id = FeatBuildConfig.Ids.fighter_second_wind_mastery,
        classId = 2,
        level = 5,
        name = "续战专精",
        description = "二次生命额外再回复 1d10 生命。",
        choiceGroup = "fighter_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80002107 },
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
        name = "连击",
        description = "核心被动。徒手打击命中后有 50% 概率对同一目标追加 1 次额外攻击；额外攻击不会再次触发连击。",
        effects = {
            { type = "grant_skill", skill = 80003101 },
        },
    },
    [FeatBuildConfig.Ids.monk_flurry_training] = {
        id = FeatBuildConfig.Ids.monk_flurry_training,
        classId = 3,
        level = 2,
        name = "连打技",
        description = "每回合第一次触发武艺时，该次追加打击额外造成 1d4 伤害。",
        choiceGroup = "monk_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80003102 },
        },
    },
    [FeatBuildConfig.Ids.monk_iron_mind] = {
        id = FeatBuildConfig.Ids.monk_iron_mind,
        classId = 3,
        level = 2,
        name = "守心技",
        description = "每回合第一次被攻击命中时，受到伤害减少 1d4。",
        choiceGroup = "monk_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80003103 },
        },
    },
    [FeatBuildConfig.Ids.monk_swift_step] = {
        id = FeatBuildConfig.Ids.monk_swift_step,
        classId = 3,
        level = 2,
        name = "疾风技",
        description = "每回合第一次徒手打击、震劲掌或影步连打获得命中 +1；若命中，额外造成 1d4 伤害。",
        choiceGroup = "monk_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80003104 },
        },
    },
    [FeatBuildConfig.Ids.monk_open_hand] = {
        id = FeatBuildConfig.Ids.monk_open_hand,
        classId = 3,
        level = 3,
        name = "开放手",
        description = "获得震劲掌，CD3，对当前目标发动 1 次徒手打击；若命中，强韧豁免失败则 STUN 1 回合。",
        choiceGroup = "monk_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80003013 },
        },
    },
    [FeatBuildConfig.Ids.monk_shadow_combo] = {
        id = FeatBuildConfig.Ids.monk_shadow_combo,
        classId = 3,
        level = 3,
        name = "影行流",
        description = "获得影步连打，CD3，可指定任意一名敌人发动 1 次徒手打击；若目标位于后排，额外造成 1d8 伤害。",
        choiceGroup = "monk_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80003014 },
        },
    },
    [FeatBuildConfig.Ids.monk_harmonize] = {
        id = FeatBuildConfig.Ids.monk_harmonize,
        classId = 3,
        level = 5,
        name = "明镜止水",
        description = "获得明镜止水，CD3，恢复生命、清除控制或负面状态，并提供短时救场能力。",
        choiceGroup = "monk_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80003015 },
        },
    },
    [FeatBuildConfig.Ids.monk_body_mastery] = {
        id = FeatBuildConfig.Ids.monk_body_mastery,
        classId = 3,
        level = 4,
        name = "体术专精",
        description = "徒手打击额外造成 1d4 伤害。",
        choiceGroup = "monk_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80003105 },
        },
    },
    [FeatBuildConfig.Ids.monk_combo_mastery] = {
        id = FeatBuildConfig.Ids.monk_combo_mastery,
        classId = 3,
        level = 4,
        name = "连击专精",
        description = "每回合第一次武艺打击额外造成 1d4 伤害。",
        choiceGroup = "monk_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80003106 },
        },
    },
    [FeatBuildConfig.Ids.monk_body_guard] = {
        id = FeatBuildConfig.Ids.monk_body_guard,
        classId = 3,
        level = 4,
        name = "护体专精",
        description = "每回合第一次被攻击命中时，额外再减少 1d4 伤害。",
        choiceGroup = "monk_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80003107 },
        },
    },
    [FeatBuildConfig.Ids.monk_combo_mastery_capstone] = {
        id = FeatBuildConfig.Ids.monk_combo_mastery_capstone,
        classId = 3,
        level = 5,
        name = "连拳宗师",
        description = "获得额外攻击；当你执行一次徒手打击行动时，对同一目标追加第二击；若第一击命中，则额外再追加 1 次 1d4 武艺打击。",
        choiceGroup = "monk_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80003108 },
        },
    },
    [FeatBuildConfig.Ids.monk_disruption_mastery] = {
        id = FeatBuildConfig.Ids.monk_disruption_mastery,
        classId = 3,
        level = 5,
        name = "截脉宗师",
        description = "获得额外攻击；当你执行一次徒手打击行动时，对同一目标追加第二击；若第一击命中，则目标强韧豁免失败时 STUN 1 回合。",
        choiceGroup = "monk_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80003109 },
            { type = "grant_skill", skill = 80003108 },
        },
    },
    [FeatBuildConfig.Ids.monk_purity_mastery] = {
        id = FeatBuildConfig.Ids.monk_purity_mastery,
        classId = 3,
        level = 5,
        name = "无垢宗师",
        description = "获得额外攻击；当你执行一次徒手打击行动时，对同一目标追加第二击；若第一次武艺打击命中，则回复 1d6 生命。",
        choiceGroup = "monk_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80003110 },
            { type = "grant_skill", skill = 80003108 },
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
    [FeatBuildConfig.Ids.paladin_divine_smite] = {
        id = FeatBuildConfig.Ids.paladin_divine_smite,
        classId = 4,
        level = 1,
        name = "神圣惩击",
        description = "旧版核心惩击。当前三阶主线不默认授予，保留给后续分支扩展。",
        effects = {
            { type = "grant_skill", skill = 80004101 },
        },
    },
    [FeatBuildConfig.Ids.paladin_judgement_prayer] = {
        id = FeatBuildConfig.Ids.paladin_judgement_prayer,
        classId = 4,
        level = 2,
        name = "裁决祷法",
        description = "你本回合第一次基础武器攻击命中判定时，目标 AC -1；若该击命中，后续神圣惩击照常结算。",
        choiceGroup = "paladin_lv2_prayer",
        effects = {
            { type = "grant_skill", skill = 80004104 },
        },
    },
    [FeatBuildConfig.Ids.paladin_shelter_prayer] = {
        id = FeatBuildConfig.Ids.paladin_shelter_prayer,
        classId = 4,
        level = 1,
        name = "神圣庇护",
        description = "核心被动。每回合第一次受到伤害时获得减伤；对邪恶单位攻击造成的伤害可作为后续特攻扩展。",
        choiceGroup = "paladin_lv2_prayer",
        effects = {
            { type = "grant_skill", skill = 80004102 },
        },
    },
    [FeatBuildConfig.Ids.paladin_heavy_armor_prayer] = {
        id = FeatBuildConfig.Ids.paladin_heavy_armor_prayer,
        classId = 4,
        level = 2,
        name = "重甲祷法",
        description = "每回合第一次被攻击命中时，受到伤害减少 1d6。",
        choiceGroup = "paladin_lv2_prayer",
        effects = {
            { type = "grant_skill", skill = 80004103 },
        },
    },
    [FeatBuildConfig.Ids.paladin_lay_on_hands] = {
        id = FeatBuildConfig.Ids.paladin_lay_on_hands,
        classId = 4,
        level = 5,
        name = "圣手",
        description = "获得圣手，CD3，为生命最低友军回复生命，清除 1 个控制或负面状态，并承担高阶救场定位。",
        choiceGroup = "paladin_lv3_oath",
        effects = {
            { type = "grant_skill", skill = 80004013 },
        },
    },
    [FeatBuildConfig.Ids.paladin_vengeance_smite] = {
        id = FeatBuildConfig.Ids.paladin_vengeance_smite,
        classId = 4,
        level = 3,
        name = "破邪斩",
        description = "获得破邪斩，CD3，对当前目标发动 1 次神圣斩击；若命中，追加神圣伤害并驱散目标 1 个正面增益。",
        choiceGroup = "paladin_lv3_oath",
        effects = {
            { type = "grant_skill", skill = 80004014 },
        },
    },
    [FeatBuildConfig.Ids.paladin_guardian_aura] = {
        id = FeatBuildConfig.Ids.paladin_guardian_aura,
        classId = 4,
        level = 3,
        name = "古贤誓约",
        description = "获得守护灵光，CD3，持续到你下回合开始；期间我方全体 AC+1，且各自第一次受到的伤害减少 1d6。",
        choiceGroup = "paladin_lv3_oath",
        effects = {
            { type = "grant_skill", skill = 80004015 },
        },
    },
    [FeatBuildConfig.Ids.paladin_smite_mastery] = {
        id = FeatBuildConfig.Ids.paladin_smite_mastery,
        classId = 4,
        level = 4,
        name = "惩击专精",
        description = "神圣惩击额外再造成 1d6 光耀伤害。",
        choiceGroup = "paladin_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80004105 },
        },
    },
    [FeatBuildConfig.Ids.paladin_healing_mastery] = {
        id = FeatBuildConfig.Ids.paladin_healing_mastery,
        classId = 4,
        level = 4,
        name = "圣疗专精",
        description = "圣疗之手额外再回复 1d8 生命。",
        choiceGroup = "paladin_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80004106 },
        },
    },
    [FeatBuildConfig.Ids.paladin_aura_mastery] = {
        id = FeatBuildConfig.Ids.paladin_aura_mastery,
        classId = 4,
        level = 4,
        name = "灵光专精",
        description = "守护灵光额外使友军 AC+1。",
        choiceGroup = "paladin_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80004107 },
        },
    },
    [FeatBuildConfig.Ids.paladin_execution_knight] = {
        id = FeatBuildConfig.Ids.paladin_execution_knight,
        classId = 4,
        level = 5,
        name = "裁决圣骑",
        description = "获得额外攻击；当你执行一次基础武器攻击行动时，对同一目标追加第二击；若第一击命中，则第二击额外造成 1d8 光耀伤害。",
        choiceGroup = "paladin_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80004109 },
            { type = "grant_skill", skill = 80004108 },
        },
    },
    [FeatBuildConfig.Ids.paladin_merciful_knight] = {
        id = FeatBuildConfig.Ids.paladin_merciful_knight,
        classId = 4,
        level = 5,
        name = "慈光圣骑",
        description = "获得额外攻击；当你执行一次基础武器攻击行动时，对同一目标追加第二击；若第一击命中，则生命最低友军回复 1d6 生命。",
        choiceGroup = "paladin_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80004110 },
            { type = "grant_skill", skill = 80004108 },
        },
    },
    [FeatBuildConfig.Ids.paladin_sanctuary_knight] = {
        id = FeatBuildConfig.Ids.paladin_sanctuary_knight,
        classId = 4,
        level = 5,
        name = "圣域圣骑",
        description = "获得额外攻击；当你执行一次基础武器攻击行动时，对同一目标追加第二击；若第一击命中，则直到你下回合开始，我方前排 AC+1。",
        choiceGroup = "paladin_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80004111 },
            { type = "grant_skill", skill = 80004108 },
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
        name = "猎人印记",
        description = "每回合 1 次，基础武器攻击命中后施加短时印记；本回合第一次对印记目标造成伤害时额外造成 1d4 伤害。",
        effects = {
            { type = "grant_skill", skill = 80005101 },
        },
    },
    [FeatBuildConfig.Ids.ranger_tracking_skill] = {
        id = FeatBuildConfig.Ids.ranger_tracking_skill,
        classId = 5,
        level = 2,
        name = "追猎技巧",
        description = "你本回合第一次对带有猎人印记的目标造成伤害时，额外再造成 1d6 伤害。",
        choiceGroup = "ranger_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80005102 },
        },
    },
    [FeatBuildConfig.Ids.ranger_precise_shot] = {
        id = FeatBuildConfig.Ids.ranger_precise_shot,
        classId = 5,
        level = 2,
        name = "精准射击",
        description = "你对带有猎人印记的目标发动基础武器攻击时，命中 +1。",
        choiceGroup = "ranger_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80005103 },
        },
    },
    [FeatBuildConfig.Ids.ranger_wild_endurance] = {
        id = FeatBuildConfig.Ids.ranger_wild_endurance,
        classId = 5,
        level = 2,
        name = "野外坚忍",
        description = "每回合第一次被攻击命中时，受到伤害减少 1d6。",
        choiceGroup = "ranger_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80005104 },
        },
    },
    [FeatBuildConfig.Ids.ranger_hunter_shot] = {
        id = FeatBuildConfig.Ids.ranger_hunter_shot,
        classId = 5,
        level = 3,
        name = "狩猎指引",
        description = "获得狩猎指引，CD3，始终作用于当前标记目标；对标记目标发动远程攻击并造成追猎收益。",
        choiceGroup = "ranger_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80005013 },
        },
    },
    [FeatBuildConfig.Ids.ranger_shadow_shot] = {
        id = FeatBuildConfig.Ids.ranger_shadow_shot,
        classId = 5,
        level = 3,
        name = "阴影追猎者",
        description = "获得暮影射击，CD3，可指定任意敌人发动 1 次远程基础攻击；若目标位于后排，额外造成 1d8 伤害。",
        choiceGroup = "ranger_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80005014 },
        },
    },
    [FeatBuildConfig.Ids.ranger_snare_shot] = {
        id = FeatBuildConfig.Ids.ranger_snare_shot,
        classId = 5,
        level = 3,
        name = "缚林者",
        description = "获得缠绕箭，CD3，对任意敌人发动 1 次远程基础攻击；若命中，反射豁免失败则冻结 1 回合（近似 Restrained）。",
        choiceGroup = "ranger_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80005015 },
        },
    },
    [FeatBuildConfig.Ids.ranger_mark_mastery] = {
        id = FeatBuildConfig.Ids.ranger_mark_mastery,
        classId = 5,
        level = 4,
        name = "印记专精",
        description = "猎人印记的额外伤害提高 1d6。",
        choiceGroup = "ranger_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80005105 },
        },
    },
    [FeatBuildConfig.Ids.ranger_subclass_mastery] = {
        id = FeatBuildConfig.Ids.ranger_subclass_mastery,
        classId = 5,
        level = 4,
        name = "子职专精",
        description = "每回合第一次 Lv3 子职技能额外造成 1d6 伤害。",
        choiceGroup = "ranger_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80005106 },
        },
    },
    [FeatBuildConfig.Ids.ranger_survival_mastery] = {
        id = FeatBuildConfig.Ids.ranger_survival_mastery,
        classId = 5,
        level = 4,
        name = "生存专精",
        description = "每回合第一次被攻击命中时，额外再减少 1d4 伤害。",
        choiceGroup = "ranger_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80005107 },
        },
    },
    [FeatBuildConfig.Ids.ranger_hunter_mastery] = {
        id = FeatBuildConfig.Ids.ranger_hunter_mastery,
        classId = 5,
        level = 5,
        name = "箭雨",
        description = "获得箭雨。对标记目标进行多段追猎：远程基础攻击追加第二击，若第一击命中印记目标则额外造成 1d6 伤害。",
        choiceGroup = "ranger_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80005109 },
            { type = "grant_skill", skill = 80005108 },
        },
    },
    [FeatBuildConfig.Ids.ranger_shadow_mastery] = {
        id = FeatBuildConfig.Ids.ranger_shadow_mastery,
        classId = 5,
        level = 5,
        name = "影袭宗师",
        description = "获得额外攻击；当你执行一次远程基础攻击行动时，对同一目标追加第二击；若目标位于后排，则第二击额外造成 1d6 伤害。",
        choiceGroup = "ranger_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80005110 },
            { type = "grant_skill", skill = 80005108 },
        },
    },
    [FeatBuildConfig.Ids.ranger_snare_mastery] = {
        id = FeatBuildConfig.Ids.ranger_snare_mastery,
        classId = 5,
        level = 5,
        name = "缚林宗师",
        description = "获得额外攻击；当你执行一次远程基础攻击行动时，对同一目标追加第二击；若第一击命中印记目标，则反射豁免失败冻结 1 回合（近似 Restrained）。",
        choiceGroup = "ranger_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80005111 },
            { type = "grant_skill", skill = 80005108 },
        },
    },
}

local FEATS_BY_CLASS = {}
for featId, feat in pairs(FEATS) do
    local classId = tonumber(feat.classId) or 0
    FEATS_BY_CLASS[classId] = FEATS_BY_CLASS[classId] or {}
    FEATS_BY_CLASS[classId][#FEATS_BY_CLASS[classId] + 1] = featId
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
    local result = {}
    for _, featId in ipairs(FEATS_BY_CLASS[tonumber(classId) or 0] or {}) do
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

return FeatBuildConfig
