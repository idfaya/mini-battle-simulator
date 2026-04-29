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
