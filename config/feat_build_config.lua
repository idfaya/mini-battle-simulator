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
}

---@type table<integer, BuildFeatDef>
local FEATS = {
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
        name = "二次生命",
        description = "每场战斗 1 次，生命首次降到一半及以下时回复 1d10 + 等级 生命。",
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
        description = "获得护卫架势，CD3，持续到你下回合开始；期间你和友军被攻击时获得 AC+2，并减少等同熟练加值的伤害；若攻击者为近战单位，你会在其攻击结算后对其发动 1 次基础武器攻击。",
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
        level = 4,
        name = "反击战法",
        description = "每回合 1 次，被近战攻击指定为目标时，在该次攻击结算后对攻击者发动 1 次基础武器攻击。",
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
        name = "武艺",
        description = "每回合第一次徒手打击命中后，再追加 1 次 1d4 武艺打击。",
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
        description = "你所有攻击都无视前排保护。",
        choiceGroup = "monk_lv2_basic",
        effects = {
            { type = "grant_skill", skill = 80003104 },
            { type = "modify_skill", skill = 80003011, add = { runtimeData = { targetsSelections = { ignoreFrontProtection = true } } } },
            { type = "modify_skill", skill = 80003013, add = { runtimeData = { targetsSelections = { ignoreFrontProtection = true } } } },
            { type = "modify_skill", skill = 80003014, add = { runtimeData = { targetsSelections = { ignoreFrontProtection = true } } } },
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
        level = 3,
        name = "调和流",
        description = "获得调息自愈，CD3，回复 2d8+4 生命，并清除 1 个控制或负面状态。",
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
        description = "每回合第一次基础武器攻击命中后，额外造成 1d6 光耀伤害。",
        effects = {
            { type = "grant_skill", skill = 80004101 },
        },
    },
    [FeatBuildConfig.Ids.paladin_judgement_prayer] = {
        id = FeatBuildConfig.Ids.paladin_judgement_prayer,
        classId = 4,
        level = 2,
        name = "裁决祷法",
        description = "神圣惩击额外忽略目标 1 点 AC。",
        choiceGroup = "paladin_lv2_prayer",
        effects = {
            { type = "grant_skill", skill = 80004104 },
        },
    },
    [FeatBuildConfig.Ids.paladin_shelter_prayer] = {
        id = FeatBuildConfig.Ids.paladin_shelter_prayer,
        classId = 4,
        level = 2,
        name = "庇护祷法",
        description = "每回合第一次有友军被攻击命中时，该次伤害减少 1d6。",
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
        level = 3,
        name = "奉献誓约",
        description = "获得圣疗之手，CD3，为生命最低友军回复 2d8+4 生命，并清除 1 个控制或负面状态。",
        choiceGroup = "paladin_lv3_oath",
        effects = {
            { type = "grant_skill", skill = 80004013 },
        },
    },
    [FeatBuildConfig.Ids.paladin_vengeance_smite] = {
        id = FeatBuildConfig.Ids.paladin_vengeance_smite,
        classId = 4,
        level = 3,
        name = "复仇誓约",
        description = "获得复仇裁击，CD3，对当前目标发动 1 次基础武器攻击；若命中，额外造成 2d8 光耀伤害。",
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
        name = "猎人",
        description = "获得猎杀箭，CD3，对当前目标发动 1 次远程基础攻击；若目标带有印记，额外造成 2d6 伤害。",
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
        description = "Lv3 子职技能额外造成 1d6 伤害。",
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
        name = "逐猎宗师",
        description = "获得额外攻击；当你执行一次远程基础攻击行动时，对同一目标追加第二击；若第一击命中印记目标，则额外造成 1d6 伤害。",
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
