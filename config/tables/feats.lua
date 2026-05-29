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
    cleric_training = FeatId(501, 1),
    cleric_healing_word = FeatId(501, 2),
    cleric_radiant_prayer = FeatId(502, 1),
    cleric_shelter_prayer = FeatId(502, 2),
    cleric_revival_prayer = FeatId(502, 3),
    cleric_guardian_domain = FeatId(503, 3),
    cleric_spell_mastery = FeatId(504, 1),
    cleric_healing_mastery = FeatId(504, 2),
    cleric_sanctuary_mastery = FeatId(504, 3),
    fighter_training = FeatId(1, 1),
    fighter_second_wind = FeatId(1, 2),
    fighter_guard = FeatId(3, 2),
    fighter_counter_basic = FeatId(4, 2),
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
        treeSlot = "R",
        isRoot = true,
        -- SSOT §5.3：致命准头 B（critThresholdDelta -1）合并到 R 选定路径。
        effects = {
            { type = "grant_skill", skill = 80001101 },
            { type = "modify_skill", skill = 80001101, add = {
                critThresholdDelta = -1,
                classMods = { critThresholdDelta = -1 },
            } },
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
        trunk = "T1",
        treeSlot = "T1",
        -- SSOT §5.3：T1 mid 核心主动；影袭再起 J（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80001013 },
            { type = "modify_skill", skill = 80001013, add = {
                cooldownDelta = -1,
            } },
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
        trunk = "T2",
        treeSlot = "T2",
        effects = {
            { type = "grant_skill", skill = 80001108 },
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
        trunk = "T1",
        treeSlot = "T1",
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
        name = "庇护基础",
        description = "核心被动。每个友军每回合第一次受到伤害时，该次伤害减少 1d6。",
        treeSlot = "R",
        isRoot = true,
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
    [FeatBuildConfig.Ids.cleric_guardian_domain] = {
        id = FeatBuildConfig.Ids.cleric_guardian_domain,
        classId = 6,
        level = 5,
        name = "圣域祷言",
        description = "获得圣域祷言，CD3，持续 2 回合；我方全体 AC +1，施放时立即为最低血友军回复 1d4 并提供 4 点临时生命。",
        trunk = "T2",
        treeSlot = "T2",
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
        treeSlot = "R",
        isRoot = true,
        -- SSOT §5.8：R 核心被动；燃烧延续 B（dotDurationDelta +1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80007002 },
            { type = "modify_skill", skill = 80007002, add = {
                dotDurationDelta = 1,
                classMods = { dotDurationDelta = 1 },
            } },
        },
    },
    [FeatBuildConfig.Ids.sorcerer_ash_burst] = {
        id = FeatBuildConfig.Ids.sorcerer_ash_burst,
        classId = 7,
        level = 3,
        name = "灰烬爆燃",
        description = "获得灰烬爆燃，CD3，攻击燃烧目标时额外造成火焰伤害并刷新燃烧。",
        trunk = "T1",
        treeSlot = "T1",
        -- SSOT §5.8：T1 mid 主动；余烬主教 C（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80007003 },
            { type = "modify_skill", skill = 80007003, add = {
                cooldownDelta = -1,
            } },
        },
    },
    [FeatBuildConfig.Ids.sorcerer_flame_storm] = {
        id = FeatBuildConfig.Ids.sorcerer_flame_storm,
        classId = 7,
        level = 5,
        name = "烈焰风暴",
        description = "获得烈焰风暴，CD5，对全体敌人造成火焰伤害；燃烧目标额外受 1d8 火焰伤害，未燃烧目标被点燃。",
        trunk = "T2",
        treeSlot = "T2",
        -- SSOT §5.8：T2 high 主动；风暴回响 B（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80007004 },
            { type = "modify_skill", skill = 80007004, add = {
                cooldownDelta = -1,
            } },
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
        treeSlot = "R",
        isRoot = true,
        -- SSOT §5.7：R 核心被动；寒霜深锁 B（dotDurationDelta +1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80008002 },
            { type = "modify_skill", skill = 80008002, add = {
                dotDurationDelta = 1,
                classMods = { dotDurationDelta = 1 },
            } },
        },
    },
    [FeatBuildConfig.Ids.wizard_freezing_nova] = {
        id = FeatBuildConfig.Ids.wizard_freezing_nova,
        classId = 8,
        level = 3,
        name = "冻结新星",
        description = "获得冻结新星，CD3，十字范围冰霜法术；已霜冻目标冻结 1 回合，未霜冻目标施加霜冻。",
        trunk = "T1",
        treeSlot = "T1",
        -- SSOT §5.7：T1 mid 主动；霜咒 J（cooldownDelta -1）+ 寒域扩张 B（aoeRadiusDelta +1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80008003 },
            { type = "modify_skill", skill = 80008003, add = {
                cooldownDelta = -1,
                aoeRadiusDelta = 1,
            } },
        },
    },
    [FeatBuildConfig.Ids.wizard_blizzard] = {
        id = FeatBuildConfig.Ids.wizard_blizzard,
        classId = 8,
        level = 5,
        name = "暴风雪",
        description = "获得暴风雪，CD5，对全体敌人造成冰霜伤害；已霜冻目标额外受 1d8 伤害并刷新霜冻，未霜冻目标施加霜冻。",
        trunk = "T2",
        treeSlot = "T2",
        -- SSOT §5.7：T2 high 主动；风暴回返 B（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80008004 },
            { type = "modify_skill", skill = 80008004, add = {
                cooldownDelta = -1,
            } },
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
        treeSlot = "R",
        isRoot = true,
        -- SSOT §5.10：R 核心被动；印记延续 B（dotDurationDelta +1）+ 印记加深 B（markRecastPerRound +1）+ 印记爆发 J（markPayoutPerRound +1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80009002 },
            { type = "modify_skill", skill = 80009002, add = {
                dotDurationDelta = 1,
                markRecastPerRound = 2,
                markPayoutPerRound = 2,
                classMods = {
                    dotDurationDelta = 1,
                    markRecastPerRound = 2,
                    markPayoutPerRound = 2,
                },
            } },
        },
    },
    [FeatBuildConfig.Ids.warlock_thunder_chain] = {
        id = FeatBuildConfig.Ids.warlock_thunder_chain,
        classId = 9,
        level = 3,
        name = "雷链",
        description = "获得雷链，CD3，攻击当前目标并额外弹射 1 名敌人，优先弹向带静电印记的目标。",
        trunk = "T1",
        treeSlot = "T1",
        -- SSOT §5.10：T1 mid 主动；雷链扩展 B（chainCountDelta +1）+ 雷契宗师 C（chainCountDelta +1，最多 4 段）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80009003 },
            { type = "modify_skill", skill = 80009003, add = {
                chainCountDelta = 2,
            } },
        },
    },
    [FeatBuildConfig.Ids.warlock_thunderstorm] = {
        id = FeatBuildConfig.Ids.warlock_thunderstorm,
        classId = 9,
        level = 5,
        name = "雷暴",
        description = "获得雷暴，CD5，对全体敌人造成雷电伤害；印记目标额外受 1d8 伤害并清除印记，未印记目标被附加印记。",
        trunk = "T2",
        treeSlot = "T2",
        -- SSOT §5.10：T2 high 主动；雷暴回响 B（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80009004 },
            { type = "modify_skill", skill = 80009004, add = {
                cooldownDelta = -1,
            } },
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
        name = "狂暴",
        description = "核心被动。每次完成基础攻击或受到攻击时自动触发，不能叠层，持续到下回合结束；每场战斗只能触发一次。期间受到物理伤害 -2，所有攻击造成伤害 +2。",
        treeSlot = "R",
        isRoot = true,
        -- SSOT §5.6：R 核心被动；怒袭 B（critThresholdDelta -1，狂暴期间）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80010101 },
            { type = "modify_skill", skill = 80010101, add = {
                critThresholdDelta = -1,
                classMods = { critThresholdDelta = -1 },
            } },
        },
    },
    [FeatBuildConfig.Ids.barbarian_heavy_strike] = {
        id = FeatBuildConfig.Ids.barbarian_heavy_strike,
        classId = 10,
        level = 3,
        name = "重击",
        description = "获得重击，CD2，对当前目标发动一次强化近战攻击：自身 AC -2，暴击范围翻倍，且力量加值翻倍。",
        trunk = "T1",
        treeSlot = "T1",
        -- SSOT §5.6：T1 mid 主动；重斩频率 B（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80010013 },
            { type = "modify_skill", skill = 80010013, add = {
                cooldownDelta = -1,
            } },
        },
    },
    [FeatBuildConfig.Ids.barbarian_berserk] = {
        id = FeatBuildConfig.Ids.barbarian_berserk,
        classId = 10,
        level = 5,
        name = "不倦狂暴",
        description = "高阶被动。取消狂暴每场战斗只能触发一次的限制；其余触发条件、持续时间与增益效果保持不变。",
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
        name = "连击",
        description = "核心被动。徒手打击命中后有 50% 概率对同一目标追加 1 次额外攻击；额外攻击不会再次触发连击。",
        treeSlot = "R",
        isRoot = true,
        -- SSOT §5.2：拳影回响 J + 连环宗师 C 都注入 comboReentryOnce 到 R 路径。
        effects = {
            { type = "grant_skill", skill = 80003101 },
            { type = "modify_skill", skill = 80003101, add = {
                comboReentryOnce = 1,
                classMods = { comboReentryOnce = 1 },
            } },
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
        trunk = "T1",
        treeSlot = "T1",
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
        description = "获得明镜止水，CD3，回复自身生命并清除 Frozen / STUN / SILENT；当前治疗沿用旧调息时间线，数值按 skill.level 为 1d8+3 / 2d8+3 / 2d8+6。",
        choiceGroup = "monk_lv3_subclass",
        trunk = "T2",
        treeSlot = "T2",
        -- SSOT §5.2：T2 high 主动；心流 B（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80003015 },
            { type = "modify_skill", skill = 80003015, add = {
                cooldownDelta = -1,
            } },
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
        name = "灵光基础",
        description = "核心被动。你存活时，灵光范围内友军获得 AC +1。",
        choiceGroup = "paladin_lv2_prayer",
        treeSlot = "R",
        isRoot = true,
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
        -- 与设计文档一致：Lv5 high-tier capstone，归入 paladin_lv5_capstone 组。
        choiceGroup = "paladin_lv5_capstone",
        tier = "high",
        isSubclassCore = true,
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
        trunk = "T1",
        treeSlot = "T1",
        -- SSOT §5.5：T1 mid 主动；净化光耀 J（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80004014 },
            { type = "modify_skill", skill = 80004014, add = {
                cooldownDelta = -1,
            } },
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
        treeSlot = "R",
        isRoot = true,
        -- SSOT §5.4：R 核心被动；双印记 B（markSlotMax）+ 持久印记 B（dotDurationDelta）+ 印记爆发 J（markPayoutPerRound）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80005101 },
            { type = "modify_skill", skill = 80005101, add = {
                markSlotMax = 2,
                markPayoutPerRound = 2,
                dotDurationDelta = 1,
                classMods = {
                    markSlotMax = 2,
                    markPayoutPerRound = 2,
                    dotDurationDelta = 1,
                },
            } },
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
        description = "获得箭雨，CD4。作为独立主动技能连续发动 4 次标准远程武器攻击；每次随机选择 1 名敌人，若同一次箭雨内再次命中同一目标，则该次伤害依次减半。",
        choiceGroup = "ranger_lv5_capstone",
        trunk = "T2",
        treeSlot = "T2",
        -- SSOT §5.4：T2 箭雨；箭雨溢出 B（chainCountDelta +1）+ 万箭 C（chainCountDelta +2）+ 风暴箭幕 J（cooldownDelta -1）合并到选定路径。
        effects = {
            { type = "grant_skill", skill = 80005109 },
            { type = "modify_skill", skill = 80005109, add = {
                chainCountDelta = 3,
                cooldownDelta = -1,
            } },
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
        isCapstone = spec.isCapstone,
        effects = spec.effects or {},
    }
end

-- 短别名引用现有 R / T1 / T2 节点 id（作为 prerequisites 引用源）。
local F = {
    fighter_R = Ids.fighter_second_wind, fighter_T1 = Ids.fighter_counter_basic, fighter_T2 = Ids.fighter_guard,
    monk_R = Ids.monk_martial_arts, monk_T1 = Ids.monk_open_hand, monk_T2 = Ids.monk_harmonize,
    rogue_R = Ids.rogue_sneak_attack, rogue_T1 = Ids.rogue_execute_strike, rogue_T2 = Ids.rogue_executioner,
    ranger_R = Ids.ranger_hunter_mark, ranger_T1 = Ids.ranger_hunter_shot, ranger_T2 = Ids.ranger_hunter_mastery,
    paladin_R = Ids.paladin_shelter_prayer, paladin_T1 = Ids.paladin_vengeance_smite, paladin_T2 = Ids.paladin_lay_on_hands,
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
    {key="b_monk_fist_power", classId=3, level=2, slot="B", prereqs={F.monk_R}, name="拳力加深", desc="徒手打击伤害 +1d4。",
        effects={{type="modify_skill", skill=80003011, add={bonusDamageDice="1d4"}}}},
    {key="b_monk_nimble_step", classId=3, level=2, slot="B", prereqs={F.monk_R}, name="灵巧步法", desc="每回合首次受击伤害 -2。",
        effects={{type="modify_skill", skill=80003101, add={firstHitDamageReduce=2}}}},
    {key="b_monk_combo_intent", classId=3, level=4, slot="B", prereqs={F.monk_R}, name="连环之意", desc="连击触发概率 +10%。",
        effects={{type="modify_skill", skill=80003101, add={comboTriggerChanceDelta=10}}}},
    {key="b_monk_shadow_pace", classId=3, level=4, slot="B", prereqs={F.monk_R}, name="影步连打", desc="攻击命中后 AC +1 直到下回合。",
        effects={{type="modify_skill", skill=80003011, add={hitAcDelta=1}}}},
    {key="b_monk_focus_dc", classId=3, level=6, slot="B", prereqs={F.monk_T1}, name="凝意", desc="震劲掌 spell DC +1。",
        effects={{type="modify_skill", skill=80003013, add={spellDcDelta=1}}}},
    {key="b_monk_stun_extend", classId=3, level=6, slot="B", prereqs={F.monk_T1}, name="截脉延续", desc="震劲掌 STUN 持续 +1 回合（封顶 2）。",
        effects={{type="modify_skill", skill=80003013, add={stunDurationDelta=1}}}},
    {key="j_monk_pulse_master", classId=3, level=7, slot="J", prereqs={F.monk_T1}, name="截脉宗师", desc="徒手打击对当前处于 STUN 的目标 +1d6。",
        effects={{type="modify_skill", skill=80003011, add={bonusVsStunDice="1d6"}}}},
    {key="j_monk_fist_echo", classId=3, level=8, slot="J", prereqs={F.monk_R, F.monk_T1}, name="拳影回响", desc="一回合内连击破例触发 1 次。",
        effects={{type="modify_skill", skill=80003101, add={comboReentryOnce=1}}}},
    {key="b_monk_breath", classId=3, level=7, slot="B", prereqs={F.monk_T2}, name="调息", desc="明镜止水治疗 +1d4。",
        effects={{type="modify_skill", skill=80003015, add={bonusHealDice="1d4"}}}},
    {key="b_monk_flow", classId=3, level=9, slot="B", prereqs={F.monk_T2}, name="心流", desc="明镜止水 CD -1。",
        effects={{type="modify_skill", skill=80003015, add={cooldownDelta=-1}}}},
    {key="c_monk_combo_master", classId=3, level=10, slot="C", prereqs={F.monk_R}, isCapstone=true, name="连击大师", desc="每回合第一次徒手打击命中时连击必定触发；若目标处于 STUN，本回合连击伤害额外 +1d6。",
        effects={{type="modify_skill", skill=80003101, add={firstHitGuaranteedCombo=true, vsStunComboBonusDice="1d6"}}}},
    {key="c_monk_breath_master", classId=3, level=10, slot="C", prereqs={F.monk_T2}, isCapstone=true, name="调息大师", desc="生命低于 35% 时自动触发一次明镜止水，每场 1 次；触发后获得 4 点临时生命。",
        effects={{type="modify_skill", skill=80003015, add={autoTriggerHpThresholdPct=35, autoTriggerCharges=1, autoTriggerTempHpFlat=4}}}},
}

-- Rogue 盗贼 (classId=1)
local rogueTree = {
    {key="b_rogue_sneak_specialty", classId=1, level=2, slot="B", prereqs={F.rogue_R}, name="偷袭专精", desc="伏击额外伤害改为 +1d8。",
        effects={{type="modify_skill", skill=80001101, add={sneakBonusDice="1d8"}}}},
    {key="b_rogue_lethal_aim", classId=1, level=2, slot="B", prereqs={F.rogue_R}, name="致命准头", desc="基础攻击暴击阈值 -1。",
        effects={{type="modify_skill", skill=80001011, add={critThresholdDelta=-1}}}},
    {key="b_rogue_nimble", classId=1, level=4, slot="B", prereqs={F.rogue_R}, name="灵巧", desc="AC +1。",
        effects={{type="modify_skill", skill=80001101, add={statMods={ac=1}}}}},
    {key="b_rogue_flank_veteran", classId=1, level=4, slot="B", prereqs={F.rogue_R}, name="夹击老手", desc="伏击触发条件放宽：包含 SLOW 目标。",
        effects={{type="modify_skill", skill=80001101, add={flankIncludesSlow=true}}}},
    {key="b_rogue_execute_heavy", classId=1, level=6, slot="B", prereqs={F.rogue_T1}, name="处决重斩", desc="影袭处决伤害 +1d6。",
        effects={{type="modify_skill", skill=80001013, add={bonusDamageDice="1d6"}}}},
    {key="b_rogue_pass_thrust", classId=1, level=6, slot="B", prereqs={F.rogue_T1}, name="穿行突刺", desc="影袭处决无视前排。",
        effects={{type="modify_skill", skill=80001013, add={ignoresFrontRow=true}}}},
    {key="j_rogue_execute_recharge", classId=1, level=7, slot="J", prereqs={F.rogue_T1}, name="影袭再起", desc="影袭处决 CD -1。",
        effects={{type="modify_skill", skill=80001013, add={cooldownDelta=-1}}}},
    {key="j_rogue_bleed", classId=1, level=8, slot="J", prereqs={F.rogue_R}, name="出血", desc="伏击命中后，目标在你下次攻击它时额外 +1d4。",
        effects={{type="modify_skill", skill=80001101, add={bleedFollowupDice="1d4"}}}},
    {key="b_rogue_evasion_plus", classId=1, level=7, slot="B", prereqs={F.rogue_T2}, name="闪避加深", desc="直觉闪避也对 AOE 生效。",
        effects={{type="modify_skill", skill=80001108, add={appliesToAoe=true}}}},
    {key="b_rogue_intuition_counter", classId=1, level=9, slot="B", prereqs={F.rogue_T2}, name="直觉反击", desc="直觉闪避触发后下次基础攻击视为满足伏击。",
        effects={{type="modify_skill", skill=80001108, add={grantsSneakNextHit=true}}}},
    {key="c_rogue_ambush_master", classId=1, level=10, slot="C", prereqs={F.rogue_R}, isCapstone=true, name="伏击大师", desc="击杀本回合被你伏击过的目标后，对最低血敌人发动 1 次基础攻击（每场 2 次）。",
        effects={{type="modify_skill", skill=80001101, add={onKillBasicAttackCharges=2, onKillTargetLowestHp=true}}}},
    {key="c_rogue_execute_master", classId=1, level=10, slot="C", prereqs={F.rogue_T1}, isCapstone=true, name="处决大师", desc="影袭处决变为对相邻 2 个目标各发动一次半伤基础攻击，优先后排目标。",
        effects={{type="modify_skill", skill=80001013, add={splitAdjacentTargets=2, splitDamageScale=50, splitPreferBackRow=true}}}},
}

-- Ranger 游侠 (classId=5)
local rangerTree = {
    {key="b_ranger_mark_specialty", classId=5, level=2, slot="B", prereqs={F.ranger_R}, name="印记专精", desc="印记额外伤害 +1d4（合计 +2d4）。",
        effects={{type="modify_skill", skill=80005101, add={markBonusDice="1d4"}}}},
    {key="b_ranger_precise_shot", classId=5, level=2, slot="B", prereqs={F.ranger_R}, name="精准射击", desc="远程基础攻击命中 +1。",
        effects={{type="modify_skill", skill=80005011, add={bonusHit=1}}}},
    {key="b_ranger_archery_training", classId=5, level=4, slot="B", prereqs={F.ranger_R}, name="弓术训练", desc="远程基础攻击伤害 +1d4。",
        effects={{type="modify_skill", skill=80005011, add={bonusDamageDice="1d4"}}}},
    {key="b_ranger_dual_mark", classId=5, level=4, slot="B", prereqs={F.ranger_R}, name="双印记", desc="同时维持 2 个印记。",
        effects={{type="modify_skill", skill=80005101, add={markSlotMax=2}}}},
    {key="b_ranger_lasting_mark", classId=5, level=6, slot="B", prereqs={F.ranger_R}, name="持久印记", desc="印记持续时间 +1 回合。",
        effects={{type="modify_skill", skill=80005101, add={dotDurationDelta=1}}}},
    {key="b_ranger_guidance_plus", classId=5, level=6, slot="B", prereqs={F.ranger_T1}, name="指引强化", desc="狩猎指引伤害 +1d6。",
        effects={{type="modify_skill", skill=80005013, add={bonusDamageDice="1d6"}}}},
    {key="b_ranger_snare_arrow", classId=5, level=7, slot="B", prereqs={F.ranger_T1}, name="缠绕箭", desc="狩猎指引命中后目标 SLOW 1 回合。",
        effects={{type="modify_skill", skill=80005013, add={onHitApplySlowDuration=1}}}},
    {key="j_ranger_mark_burst", classId=5, level=8, slot="J", prereqs={F.ranger_R}, name="印记爆发", desc="印记每回合可兑现 2 次。",
        effects={{type="modify_skill", skill=80005101, add={markPayoutPerRound=2}}}},
    {key="b_ranger_arrow_overflow", classId=5, level=7, slot="B", prereqs={F.ranger_T2}, name="箭雨溢出", desc="箭雨射击次数从 4 提升到 5。",
        effects={{type="modify_skill", skill=80005109, add={chainCountDelta=1}}}},
    {key="b_ranger_lethal_volley", classId=5, level=9, slot="B", prereqs={F.ranger_T2}, name="致命箭雨", desc="箭雨重复命中时不再减半。",
        effects={{type="modify_skill", skill=80005109, add={duplicateHitNoHalving=true}}}},
    {key="j_ranger_storm_volley", classId=5, level=8, slot="J", prereqs={F.ranger_T2}, name="风暴箭幕", desc="箭雨 CD -1。",
        effects={{type="modify_skill", skill=80005109, add={cooldownDelta=-1}}}},
    {key="c_ranger_mark_master", classId=5, level=10, slot="C", prereqs={F.ranger_R}, isCapstone=true, name="印记大师", desc="对带印记目标命中 +1，伤害 +1d8（仅对你的印记目标生效）。",
        effects={{type="modify_skill", skill=80005011, add={vsMarkBonusHit=1, vsMarkBonusDice="1d8"}}}},
    {key="c_ranger_arrow_master", classId=5, level=10, slot="C", prereqs={F.ranger_T2}, isCapstone=true, name="箭雨大师", desc="箭雨射击次数 +1，优先射向已标记目标；首次命中已标记目标时额外 +1d4。",
        effects={{type="modify_skill", skill=80005109, add={chainCountDelta=1, prioritizeMarkedTargets=true, firstHitMarkedBonusDice="1d4"}}}},
}

-- Paladin 圣武士 (classId=4)
local paladinTree = {
    {key="b_paladin_shelter_plus", classId=4, level=2, slot="B", prereqs={F.paladin_R}, name="灵光熟练", desc="神圣灵光范围内友军所有豁免 +1。",
        effects={{type="modify_skill", skill=80004102, add={classMods={paladinAuraSaveBonus=1}}}}},
    {key="b_paladin_war_cry", classId=4, level=2, slot="B", prereqs={F.paladin_R}, name="灵光扩张", desc="神圣灵光范围扩大。",
        effects={{type="modify_skill", skill=80004102, add={classMods={paladinAuraRangeDelta=1}}}}},
    {key="b_paladin_heavy_armor", classId=4, level=4, slot="B", prereqs={F.paladin_R}, name="重甲祷法", desc="自身 AC +1。",
        effects={{type="modify_skill", skill=80004102, add={statMods={ac=1}}}}},
    {key="b_paladin_guard_aura", classId=4, level=4, slot="B", prereqs={F.paladin_R}, name="守护灵光", desc="友军每回合首次受到法术伤害 -2。",
        effects={{type="modify_skill", skill=80004102, add={firstSpellHitReduce=2}}}},
    {key="b_paladin_break_evil_plus", classId=4, level=6, slot="B", prereqs={F.paladin_T1}, name="破邪重斩", desc="破邪斩伤害 +1d8。",
        effects={{type="modify_skill", skill=80004014, add={bonusDamageDice="1d8"}}}},
    {key="b_paladin_holy_mark", classId=4, level=6, slot="B", prereqs={F.paladin_T1}, name="神圣印记", desc="破邪斩命中后目标受到所有伤害 +1 持续 1 回合。",
        effects={{type="modify_skill", skill=80004014, add={onHitVulnerableDelta=1, onHitVulnerableDuration=1}}}},
    {key="j_paladin_purify_radiance", classId=4, level=7, slot="J", prereqs={F.paladin_T1}, name="净化光耀", desc="破邪斩 CD -1。",
        effects={{type="modify_skill", skill=80004014, add={cooldownDelta=-1}}}},
    {key="b_paladin_lay_on_plus", classId=4, level=7, slot="B", prereqs={F.paladin_T2}, name="圣手精通", desc="圣手治疗 +1d4，CD -1；治疗目标额外获得 4 点临时生命。",
        effects={{type="modify_skill", skill=80004013, add={bonusHealDice="1d4", cooldownDelta=-1, postHealShield=4}}}},
    {key="b_paladin_lay_on_recharge", classId=4, level=9, slot="B", prereqs={F.paladin_T2}, name="灵光精通", desc="神圣灵光扩大到全队；范围内友军维持 AC +1、豁免 +1。",
        effects={{type="modify_skill", skill=80004102, add={classMods={paladinAuraGlobal=true, paladinAuraSaveBonus=1}}}}},
    {key="j_paladin_double_shelter", classId=4, level=8, slot="J", prereqs={F.paladin_R}, name="灵光双重", desc="神圣灵光范围内友军 AC 额外 +1，且灵光按永久全队计算。",
        effects={{type="modify_skill", skill=80004102, add={classMods={paladinAuraAcBonus=1, paladinAuraGlobal=true}}}}},
    {key="c_paladin_smite_master", classId=4, level=10, slot="C", prereqs={F.paladin_T1}, isCapstone=true, name="惩戒大师", desc="破邪斩对主目标与其相邻目标各造成一次武器伤害 +1d8 光耀；若主目标带神圣印记，额外驱散 1 个增益。",
        effects={{type="modify_skill", skill=80004014, add={splitAdjacentTargets=2, splitBonusDice="1d8", vsHolyMarkDispelBonus=1}}}},
    {key="c_paladin_aura_master", classId=4, level=10, slot="C", prereqs={F.paladin_T2}, isCapstone=true, name="灵光大师", desc="神圣灵光范围内友军 AC 额外 +1；你的灵光范围计算改为永久全队。",
        effects={{type="modify_skill", skill=80004102, add={classMods={paladinAuraAcBonus=1, paladinAuraGlobal=true, paladinAuraSaveBonus=1}}}}},
}

-- Cleric 牧师 (classId=6)
local clericTree = {
    {key="b_cleric_spark_plus", classId=6, level=2, slot="B", prereqs={F.cleric_R}, name="圣火加深", desc="神圣火花伤害 +1d8。",
        effects={{type="modify_skill", skill=80006011, add={bonusDamageDice="1d8"}}}},
    {key="b_cleric_priest_prayer", classId=6, level=2, slot="B", prereqs={F.cleric_R}, name="驱散基础", desc="获得驱散亡灵主动：对敌方全体造成 1d8 光耀伤害；豁免失败则 SLOW 1 回合。",
        effects={{type="grant_skill", skill=80006016}}},
    {key="b_cleric_shelter_extend", classId=6, level=4, slot="B", prereqs={F.cleric_R}, name="庇护熟练", desc="庇护触发后，为该友军提供 1d4 点临时生命。",
        effects={{type="modify_skill", skill=80006103, add={shelterTempHpDice="1d4"}}}},
    {key="b_cleric_spark_buddy", classId=6, level=4, slot="B", prereqs={F.cleric_R}, name="圣火联动", desc="神圣火花命中后，为最低血友军 +1d4 临时生命。",
        effects={{type="modify_skill", skill=80006011, add={onHitTempHpDice="1d4"}}}},
    {key="b_cleric_soothing_word", classId=6, level=6, slot="B", prereqs={F.cleric_T1}, name="治愈熟练", desc="治愈之言再额外 +1d4，且 CD -1。",
        effects={{type="modify_skill", skill=80006012, add={bonusHealDice="1d4", cooldownDelta=-1}}}},
    {key="b_cleric_heal_master", classId=6, level=6, slot="B", prereqs={F.cleric_T1}, name="驱散精通", desc="驱散亡灵伤害额外 +1d8；若目标生命低于 25%，则可直接净化。",
        effects={{type="modify_skill", skill=80006016, add={bonusDamageDice="1d8", executeThresholdPct=25}}}},
    {key="j_cleric_grace", classId=6, level=7, slot="J", prereqs={F.cleric_T1}, name="治愈精通", desc="治愈之言额外为治疗目标提供 4 点临时生命。",
        effects={{type="modify_skill", skill=80006012, add={postHealShield=4}}}},
    {key="b_cleric_sanctuary_extend", classId=6, level=7, slot="B", prereqs={F.cleric_T2}, name="圣域延续", desc="圣域祷言持续 +1 回合。",
        effects={{type="modify_skill", skill=80006015, add={durationDelta=1}}}},
    {key="b_cleric_sanctuary_recharge", classId=6, level=9, slot="B", prereqs={F.cleric_T2}, name="圣域回响", desc="圣域祷言 CD -1。",
        effects={{type="modify_skill", skill=80006015, add={cooldownDelta=-1}}}},
    {key="j_cleric_per_unit_shelter", classId=6, level=8, slot="J", prereqs={F.cleric_R}, name="庇护精通", desc="神恩庇护改为 per-unit；每个友军独立 1 次/回合；被庇护单位获得 2 点临时生命。",
        effects={{type="modify_skill", skill=80006103, add={shelterPerUnit=true, shelterTempHpFlat=2}}}},
    {key="c_cleric_shelter_master", classId=6, level=10, slot="C", prereqs={F.cleric_T2}, isCapstone=true, name="庇护大师", desc="你的庇护与临时生命效果共享最低血优先逻辑；庇护触发后，为该友军提供 4 点临时生命，并使其下次受到的负面状态持续时间 -1 回合。",
        effects={{type="modify_skill", skill=80006103, add={shelterPerUnit=true, shelterTempHpFlat=4, shelterDebuffDurationDelta=-1, shelterPrioritizeLowestHp=true}}}},
    {key="c_cleric_heal_master", classId=6, level=10, slot="C", prereqs={F.cleric_T1}, isCapstone=true, name="治愈大师", desc="治愈之言治疗 2 名最低血友军，但只对主目标驱散 1 个负面。",
        effects={{type="modify_skill", skill=80006012, add={healLowestCount=2, dispelOnlyPrimary=true}}}},
}

-- Sorcerer 术士 (classId=7)
local sorcererTree = {
    {key="b_sorcerer_flame_shape", classId=7, level=2, slot="B", prereqs={F.sorcerer_R}, name="烈焰塑形", desc="基础火焰法术发射物 +1。",
        effects={{type="modify_skill", skill=80007001, add={projectileCountDelta=1}}}},
    {key="b_sorcerer_spell_amp", classId=7, level=2, slot="B", prereqs={F.sorcerer_R}, name="法术增幅", desc="基础火焰法术伤害 +1d4。",
        effects={{type="modify_skill", skill=80007001, add={bonusDamageDice="1d4"}}}},
    {key="b_sorcerer_residual_heat", classId=7, level=4, slot="B", prereqs={F.sorcerer_R}, name="余热", desc="燃烧每跳 +1。",
        effects={{type="modify_skill", skill=80007002, add={tickBonusFlat=1}}}},
    {key="b_sorcerer_burn_extend", classId=7, level=4, slot="B", prereqs={F.sorcerer_R}, name="燃烧延续", desc="燃烧持续 +1 回合。",
        effects={{type="modify_skill", skill=80007002, add={dotDurationDelta=1}}}},
    {key="b_sorcerer_burst_plus", classId=7, level=6, slot="B", prereqs={F.sorcerer_T1}, name="爆燃强化", desc="灰烬爆燃伤害 +1d6。",
        effects={{type="modify_skill", skill=80007003, add={bonusDamageDice="1d6"}}}},
    {key="b_sorcerer_flame_link", classId=7, level=6, slot="B", prereqs={F.sorcerer_T1}, name="火焰链接", desc="灰烬爆燃命中后对相邻溅射 1d6。",
        effects={{type="modify_skill", skill=80007003, add={splashAdjacentDice="1d6"}}}},
    {key="j_sorcerer_ember_relight", classId=7, level=8, slot="J", prereqs={F.sorcerer_R}, name="烬火再燃", desc="燃烧目标死亡时引爆 1d6 火焰对相邻目标。",
        effects={{type="modify_skill", skill=80007002, add={onKillExplodeDice="1d6"}}}},
    {key="b_sorcerer_storm_climax", classId=7, level=7, slot="B", prereqs={F.sorcerer_T2}, name="烈焰高潮", desc="烈焰风暴伤害 +1d6。",
        effects={{type="modify_skill", skill=80007004, add={bonusDamageDice="1d6"}}}},
    {key="b_sorcerer_storm_echo", classId=7, level=9, slot="B", prereqs={F.sorcerer_T2}, name="风暴回响", desc="烈焰风暴 CD -1。",
        effects={{type="modify_skill", skill=80007004, add={cooldownDelta=-1}}}},
    {key="j_sorcerer_burn_stack", classId=7, level=7, slot="J", prereqs={F.sorcerer_R, F.sorcerer_T2}, name="灼烧叠层", desc="火焰技能命中已点燃目标时本次 +1d4。",
        effects={{type="modify_skill", skill=80007001, add={vsBurningBonusDice="1d4"}}}},
    {key="c_sorcerer_storm_master", classId=7, level=10, slot="C", prereqs={F.sorcerer_T2}, isCapstone=true, name="风暴大师", desc="烈焰风暴命中已点燃目标时额外 +1d4，并延长燃烧 1 回合；命中未点燃目标时仅负责点燃。",
        effects={{type="modify_skill", skill=80007004, add={vsBurningBonusDice="1d4", vsBurningExtendDuration=1, ignoreDamageOnUnignited=true}}}},
    {key="c_sorcerer_burst_master", classId=7, level=10, slot="C", prereqs={F.sorcerer_T1}, isCapstone=true, name="爆燃大师", desc="灰烬爆燃 CD -1；命中已点燃目标时返还 1 次半伤火焰弹追击，每回合 1 次。",
        effects={{type="modify_skill", skill=80007003, add={cooldownDelta=-1, vsBurningFollowupHalfChargesPerRound=1}}}},
}

-- Wizard 法师(冰) (classId=8)
local wizardTree = {
    {key="b_wizard_frost_lock", classId=8, level=2, slot="B", prereqs={F.wizard_R}, name="寒霜深锁", desc="霜冻持续 +1 回合。",
        effects={{type="modify_skill", skill=80008002, add={dotDurationDelta=1}}}},
    {key="b_wizard_spell_amp", classId=8, level=2, slot="B", prereqs={F.wizard_R}, name="法术增幅", desc="基础冰系法术伤害 +1d4。",
        effects={{type="modify_skill", skill=80008001, add={bonusDamageDice="1d4"}}}},
    {key="b_wizard_ice_armor", classId=8, level=4, slot="B", prereqs={F.wizard_R}, name="冰甲", desc="施法后获得 4 点护盾，1 场 3 次。",
        effects={{type="modify_skill", skill=80008001, add={onCastShield=4, onCastShieldCharges=3}}}},
    {key="b_wizard_frost_prison", classId=8, level=4, slot="B", prereqs={F.wizard_R}, name="霜牢", desc="对霜冻目标命中额外 +1d6。",
        effects={{type="modify_skill", skill=80008001, add={vsFrostBonusDice="1d6"}}}},
    {key="b_wizard_freeze_amp", classId=8, level=6, slot="B", prereqs={F.wizard_T1}, name="冻结增幅", desc="冻结新星伤害 +1d8。",
        effects={{type="modify_skill", skill=80008003, add={bonusDamageDice="1d8"}}}},
    {key="b_wizard_cold_expand", classId=8, level=6, slot="B", prereqs={F.wizard_T1}, name="寒域扩张", desc="冻结新星 AOE 半径 +1。",
        effects={{type="modify_skill", skill=80008003, add={aoeRadiusDelta=1}}}},
    {key="j_wizard_frost_curse", classId=8, level=7, slot="J", prereqs={F.wizard_T1}, name="霜咒", desc="冻结新星 CD -1。",
        effects={{type="modify_skill", skill=80008003, add={cooldownDelta=-1}}}},
    {key="b_wizard_extreme_cold", classId=8, level=7, slot="B", prereqs={F.wizard_T2}, name="极寒暴风", desc="暴风雪伤害 +1d6。",
        effects={{type="modify_skill", skill=80008004, add={bonusDamageDice="1d6"}}}},
    {key="b_wizard_storm_recharge", classId=8, level=9, slot="B", prereqs={F.wizard_T2}, name="风暴回返", desc="暴风雪 CD -1。",
        effects={{type="modify_skill", skill=80008004, add={cooldownDelta=-1}}}},
    {key="j_wizard_freeze_echo", classId=8, level=8, slot="J", prereqs={F.wizard_T1, F.wizard_T2}, name="冻结回响", desc="冻结新星与暴风雪命中冻结目标时再 +1d4。",
        effects={{type="modify_skill", skill=80008003, add={vsFrozenBonusDice="1d4"}}, {type="modify_skill", skill=80008004, add={vsFrozenBonusDice="1d4"}}}},
    {key="c_wizard_frost_master", classId=8, level=10, slot="C", prereqs={F.wizard_R}, isCapstone=true, name="霜冻大师", desc="冰系技能对霜冻 / 冻结目标 hit +1、伤害 +1d4；寒霜射线命中冻结目标时刷新霜冻。",
        effects={{type="modify_skill", skill=80008001, add={vsFrostBonusHit=1, vsFrostBonusDice="1d4", refreshFrostOnFrozenHit=true}},
                 {type="modify_skill", skill=80008003, add={vsFrostBonusHit=1, vsFrostBonusDice="1d4"}},
                 {type="modify_skill", skill=80008004, add={vsFrostBonusHit=1, vsFrostBonusDice="1d4"}}}},
    {key="c_wizard_freeze_master", classId=8, level=10, slot="C", prereqs={F.wizard_T2}, isCapstone=true, name="冻结大师", desc="暴风雪命中已 FROZEN 目标时延长 1 回合；同一目标总冻结持续不超过 2 回合。",
        effects={{type="modify_skill", skill=80008004, add={vsFrozenExtendDuration=1, vsFrozenExtendCap=2}}}},
}

-- Warlock 邪术师(雷) (classId=9)
local warlockTree = {
    {key="b_warlock_static_overload", classId=9, level=2, slot="B", prereqs={F.warlock_R}, name="静电过载", desc="印记额外伤害 +1d4。",
        effects={{type="modify_skill", skill=80009002, add={markBonusDice="1d4"}}}},
    {key="b_warlock_spell_amp", classId=9, level=2, slot="B", prereqs={F.warlock_R}, name="法术增幅", desc="邪能冲击伤害 +1d4。",
        effects={{type="modify_skill", skill=80009001, add={bonusDamageDice="1d4"}}}},
    {key="b_warlock_mark_double", classId=9, level=4, slot="B", prereqs={F.warlock_R}, name="印记加深", desc="每回合可对 2 个目标分别上印记。",
        effects={{type="modify_skill", skill=80009002, add={markRecastPerRound=2}}}},
    {key="b_warlock_mark_extend", classId=9, level=4, slot="B", prereqs={F.warlock_R}, name="印记延续", desc="印记持续 +1 回合。",
        effects={{type="modify_skill", skill=80009002, add={dotDurationDelta=1}}}},
    {key="b_warlock_chain_extend", classId=9, level=6, slot="B", prereqs={F.warlock_T1}, name="雷链扩展", desc="雷链额外弹射 1 次。",
        effects={{type="modify_skill", skill=80009003, add={chainCountDelta=1}}}},
    {key="b_warlock_aftershock", classId=9, level=6, slot="B", prereqs={F.warlock_T1}, name="残响", desc="雷链最后一跳额外 +1d6。",
        effects={{type="modify_skill", skill=80009003, add={lastHopBonusDice="1d6"}}}},
    {key="j_warlock_mark_anchor", classId=9, level=7, slot="J", prereqs={F.warlock_R, F.warlock_T1}, name="印记锚定", desc="雷链命中带印记目标后该印记持续 +1 回合。",
        effects={{type="modify_skill", skill=80009003, add={onHitMarkDurationDelta=1}}}},
    {key="b_warlock_storm_amp", classId=9, level=7, slot="B", prereqs={F.warlock_T2}, name="雷暴增幅", desc="雷暴伤害 +1d6。",
        effects={{type="modify_skill", skill=80009004, add={bonusDamageDice="1d6"}}}},
    {key="b_warlock_storm_recharge", classId=9, level=9, slot="B", prereqs={F.warlock_T2}, name="雷暴回响", desc="雷暴 CD -1。",
        effects={{type="modify_skill", skill=80009004, add={cooldownDelta=-1}}}},
    {key="j_warlock_mark_burst", classId=9, level=8, slot="J", prereqs={F.warlock_R}, name="印记爆发", desc="印记每回合可兑现 2 次。",
        effects={{type="modify_skill", skill=80009002, add={markPayoutPerRound=2}}}},
    {key="c_warlock_chain_master", classId=9, level=10, slot="C", prereqs={F.warlock_T1}, isCapstone=true, name="雷链大师", desc="雷链优先弹向带印记目标；首段若命中带印记目标，额外 +1d8；总弹射段数仍受全局上限约束。",
        effects={{type="modify_skill", skill=80009003, add={prioritizeMarkedTargets=true, firstHopVsMarkBonusDice="1d8"}}}},
    {key="c_warlock_storm_master", classId=9, level=10, slot="C", prereqs={F.warlock_T2}, isCapstone=true, name="雷暴大师", desc="雷暴命中带印记目标后，额外产生 1 次半伤雷击弹射；单次雷暴最多追加 1 次。",
        effects={{type="modify_skill", skill=80009004, add={onMarkHitChainHalf=1, onMarkHitChainHalfPerCast=1}}}},
}

-- Barbarian 野蛮人 (classId=10)
local barbarianTree = {
    {key="b_barbarian_rage_amp", classId=10, level=2, slot="B", prereqs={F.barbarian_R}, name="怒火加深", desc="狂暴期间伤害再 +1。",
        effects={{type="modify_skill", skill=80010101, add={rageBonusDamageDelta=1}}}},
    {key="b_barbarian_steel_skin", classId=10, level=2, slot="B", prereqs={F.barbarian_R}, name="钢皮", desc="狂暴期间额外 -1 物理伤害。",
        effects={{type="modify_skill", skill=80010101, add={ragePhysicalReduceDelta=1}}}},
    {key="b_barbarian_savage_chop", classId=10, level=4, slot="B", prereqs={F.barbarian_R}, name="凶猛劈砍", desc="基础攻击伤害 +1d4。",
        effects={{type="modify_skill", skill=80010011, add={bonusDamageDice="1d4"}}}},
    {key="b_barbarian_furious_strike", classId=10, level=4, slot="B", prereqs={F.barbarian_R}, name="怒袭", desc="狂暴期间暴击阈值 -1。",
        effects={{type="modify_skill", skill=80010011, add={rageCritThresholdDelta=-1}}}},
    {key="b_barbarian_desperate", classId=10, level=6, slot="B", prereqs={F.barbarian_R}, name="拼命", desc="受击进入狂暴时立即获得 1d6 临时生命，1 场 1 次。",
        effects={{type="modify_skill", skill=80010101, add={onRageEnterTempHpDice="1d6"}}}},
    {key="b_barbarian_heavy_master", classId=10, level=6, slot="B", prereqs={F.barbarian_T1}, name="重击精通", desc="重击伤害 +1d6。",
        effects={{type="modify_skill", skill=80010013, add={bonusDamageDice="1d6"}}}},
    {key="b_barbarian_heavy_freq", classId=10, level=7, slot="B", prereqs={F.barbarian_T1}, name="重斩频率", desc="重击 CD -1。",
        effects={{type="modify_skill", skill=80010013, add={cooldownDelta=-1}}}},
    {key="j_barbarian_quake", classId=10, level=8, slot="J", prereqs={F.barbarian_T1}, name="裂地", desc="重击命中后对相邻目标造成 1d6 溅射。",
        effects={{type="modify_skill", skill=80010013, add={splashAdjacentDice="1d6"}}}},
    {key="b_barbarian_rage_extend", classId=10, level=7, slot="B", prereqs={F.barbarian_T2}, name="狂暴延续", desc="狂暴持续时间 +1 回合。",
        effects={{type="modify_skill", skill=80010101, add={rageDurationDelta=1}}}},
    {key="j_barbarian_blood_courage", classId=10, level=9, slot="J", prereqs={F.barbarian_T2}, name="嗜血精通", desc="狂暴期间击杀回 1d6 生命。",
        effects={{type="modify_skill", skill=80010101, add={onKillHealDice="1d6"}}}},
    {key="c_barbarian_rage_master", classId=10, level=10, slot="C", prereqs={F.barbarian_T2}, isCapstone=true, name="狂暴大师", desc="狂暴期间首次击杀敌人时，刷新重击冷却并使狂暴持续 +1 回合。",
        effects={{type="modify_skill", skill=80010101, add={onKillRefreshHeavyStrikeCd=true, onKillRageDurationDelta=1}}}},
    {key="c_barbarian_strike_master", classId=10, level=10, slot="C", prereqs={F.barbarian_T1}, isCapstone=true, name="重击大师", desc="重击改为对前排 2 个目标；若当前处于狂暴，本次重击暴击阈值 -1。",
        effects={{type="modify_skill", skill=80010013, add={frontRowSplitTargets=2, rageCritThresholdDelta=-1}}}},
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
