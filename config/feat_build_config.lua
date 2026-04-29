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
    fighter_pressure_style = FeatId(2, 1),
    fighter_second_wind_followup = FeatId(2, 2),
    fighter_counter_style = FeatId(2, 3),
    fighter_champion = FeatId(3, 1),
    fighter_battle_master = FeatId(3, 2),
    fighter_guard = FeatId(3, 3),
    fighter_weapon_mastery = FeatId(4, 1),
    fighter_second_wind_mastery = FeatId(4, 2),
    fighter_signature_mastery = FeatId(4, 3),
    fighter_extra_attack = FeatId(5, 1),
    fighter_extra_attack_pressure = FeatId(5, 2),
    fighter_extra_attack_guard = FeatId(5, 3),
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
    [FeatBuildConfig.Ids.fighter_pressure_style] = {
        id = FeatBuildConfig.Ids.fighter_pressure_style,
        classId = 2,
        level = 2,
        name = "压制战法",
        description = "基础武器攻击忽略目标 1 点 AC。",
        choiceGroup = "fighter_lv2_style",
        effects = {
            { type = "grant_skill", skill = 80002102 },
        },
    },
    [FeatBuildConfig.Ids.fighter_second_wind_followup] = {
        id = FeatBuildConfig.Ids.fighter_second_wind_followup,
        classId = 2,
        level = 2,
        name = "续战战法",
        description = "二次生命触发后，下一次基础武器攻击额外造成 1d8 伤害。",
        choiceGroup = "fighter_lv2_style",
        effects = {
            { type = "grant_skill", skill = 80002103 },
        },
    },
    [FeatBuildConfig.Ids.fighter_counter_style] = {
        id = FeatBuildConfig.Ids.fighter_counter_style,
        classId = 2,
        level = 2,
        name = "反击战法",
        description = "每回合 1 次，被近战攻击命中后，立刻对攻击者发动 1 次基础武器攻击。",
        choiceGroup = "fighter_lv2_style",
        effects = {
            { type = "grant_skill", skill = 80002104 },
        },
    },
    [FeatBuildConfig.Ids.fighter_champion] = {
        id = FeatBuildConfig.Ids.fighter_champion,
        classId = 2,
        level = 3,
        name = "冠军",
        description = "获得动作激增，CD3，立刻对当前目标连续发动 2 次基础武器攻击。",
        choiceGroup = "fighter_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80002003 },
        },
    },
    [FeatBuildConfig.Ids.fighter_battle_master] = {
        id = FeatBuildConfig.Ids.fighter_battle_master,
        classId = 2,
        level = 3,
        name = "战斗大师",
        description = "获得压制打击，CD3，对当前目标发动 1 次基础武器攻击；该次攻击忽略目标 2 点 AC，且命中后额外造成 1d8 伤害。",
        choiceGroup = "fighter_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80002004 },
        },
    },
    [FeatBuildConfig.Ids.fighter_guard] = {
        id = FeatBuildConfig.Ids.fighter_guard,
        classId = 2,
        level = 3,
        name = "护卫",
        description = "获得护卫架势，CD3，持续到你下回合开始；期间你和友军被攻击时获得 AC+2，并减少等同熟练加值的伤害；若攻击者为近战单位，你会在其攻击结算后对其发动 1 次基础武器攻击。",
        choiceGroup = "fighter_lv3_subclass",
        effects = {
            { type = "grant_skill", skill = 80002005 },
            { type = "grant_skill", skill = 80002105 },
        },
    },
    [FeatBuildConfig.Ids.fighter_weapon_mastery] = {
        id = FeatBuildConfig.Ids.fighter_weapon_mastery,
        classId = 2,
        level = 4,
        name = "武器专精",
        description = "基础武器攻击额外造成 1d6 伤害。",
        choiceGroup = "fighter_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80002106 },
        },
    },
    [FeatBuildConfig.Ids.fighter_second_wind_mastery] = {
        id = FeatBuildConfig.Ids.fighter_second_wind_mastery,
        classId = 2,
        level = 4,
        name = "续战专精",
        description = "二次生命额外再回复 1d10 生命。",
        choiceGroup = "fighter_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80002107 },
        },
    },
    [FeatBuildConfig.Ids.fighter_signature_mastery] = {
        id = FeatBuildConfig.Ids.fighter_signature_mastery,
        classId = 2,
        level = 4,
        name = "战技专精",
        description = "Lv3 子职技能额外造成 1d6 伤害。",
        choiceGroup = "fighter_lv4_mastery",
        effects = {
            { type = "grant_skill", skill = 80002108 },
        },
    },
    [FeatBuildConfig.Ids.fighter_extra_attack] = {
        id = FeatBuildConfig.Ids.fighter_extra_attack,
        classId = 2,
        level = 5,
        name = "连斩者",
        description = "获得额外攻击；每回合第一次基础武器攻击后，再对同一目标发动 1 次基础武器攻击。",
        choiceGroup = "fighter_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80002109 },
        },
    },
    [FeatBuildConfig.Ids.fighter_extra_attack_pressure] = {
        id = FeatBuildConfig.Ids.fighter_extra_attack_pressure,
        classId = 2,
        level = 5,
        name = "压制者",
        description = "获得额外攻击；若第一次基础武器攻击命中，则第二次攻击忽略目标 1 点 AC，且额外造成 1d6 伤害。",
        choiceGroup = "fighter_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80002109 },
            { type = "grant_skill", skill = 80002110 },
        },
    },
    [FeatBuildConfig.Ids.fighter_extra_attack_guard] = {
        id = FeatBuildConfig.Ids.fighter_extra_attack_guard,
        classId = 2,
        level = 5,
        name = "钢铁护卫",
        description = "获得额外攻击；若目标本回合攻击过你的友军，则第二次攻击额外造成 1d8 伤害。",
        choiceGroup = "fighter_lv5_capstone",
        effects = {
            { type = "grant_skill", skill = 80002109 },
            { type = "grant_skill", skill = 80002111 },
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
