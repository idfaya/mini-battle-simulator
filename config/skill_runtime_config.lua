---@class RuntimeSkillEntry
---@field id integer
---@field symbol string
---@field runtimeKind "active"|"passive"
---@field designKind "active"|"passive"|"reaction"|"feature"
---@field classId integer
---@field name string
---@field hidden boolean
---@field cooldown integer
---@field luaFile string|nil
---@field trigger string|nil
---@field execution table|nil
---@field tags string[]
---@field runtimeData table|nil

local SkillRuntimeConfig = {}

SkillRuntimeConfig.Ids = {
    fighter_basic_attack = 80002001,
    fighter_action_surge = 80002003,
    fighter_guard_stance = 80002005,
    fighter_second_wind = 80002101,
    fighter_precise_attack = 80002102,
    fighter_counter_basic = 80002104,
    fighter_guard_counter = 80002105,
    fighter_second_wind_mastery = 80002107,
    fighter_extra_attack = 80002109,
    fighter_sweeping_attack = 80002110,
}

local function tags(...)
    return { ... }
end

---@type table<integer, RuntimeSkillEntry>
local SKILLS = {
    [SkillRuntimeConfig.Ids.fighter_basic_attack] = {
        id = SkillRuntimeConfig.Ids.fighter_basic_attack,
        symbol = "fighter_basic_attack",
        runtimeKind = "active",
        designKind = "active",
        classId = 2,
        name = "基础武器攻击",
        hidden = false,
        cooldown = 0,
        luaFile = "config.skill.skill_80002001",
        execution = { type = "basic_weapon_attack" },
        tags = tags("fighter", "basic_attack"),
        runtimeData = {
            skillType = 1,
        },
    },
    [SkillRuntimeConfig.Ids.fighter_action_surge] = {
        id = SkillRuntimeConfig.Ids.fighter_action_surge,
        symbol = "fighter_action_surge",
        runtimeKind = "active",
        designKind = "active",
        classId = 2,
        name = "动作激增",
        hidden = false,
        cooldown = 3,
        luaFile = "config.skill.skill_80002003",
        execution = { type = "repeat_basic_attack", count = 1, retarget = "random_enemy" },
        tags = tags("fighter", "signature", "burst"),
        runtimeData = {
            skillType = 2,
            skillCost = 0,
        },
    },
    [SkillRuntimeConfig.Ids.fighter_guard_stance] = {
        id = SkillRuntimeConfig.Ids.fighter_guard_stance,
        symbol = "fighter_guard_stance",
        runtimeKind = "active",
        designKind = "active",
        classId = 2,
        name = "护卫架势",
        hidden = false,
        cooldown = 3,
        luaFile = "config.skill.skill_80002005",
        execution = { type = "guard_stance" },
        tags = tags("fighter", "signature", "guard"),
        runtimeData = {
            skillType = 2,
            skillCost = 0,
        },
    },
    [SkillRuntimeConfig.Ids.fighter_second_wind] = {
        id = SkillRuntimeConfig.Ids.fighter_second_wind,
        symbol = "fighter_second_wind",
        runtimeKind = "passive",
        designKind = "passive",
        classId = 2,
        name = "二次生命",
        hidden = true,
        cooldown = 0,
        trigger = "hp_half_or_lower_once_per_battle",
        execution = { type = "second_wind" },
        tags = tags("fighter", "survivability"),
    },
    [SkillRuntimeConfig.Ids.fighter_precise_attack] = {
        id = SkillRuntimeConfig.Ids.fighter_precise_attack,
        symbol = "fighter_precise_attack",
        runtimeKind = "passive",
        designKind = "feature",
        classId = 2,
        name = "精准攻击",
        hidden = true,
        cooldown = 0,
        trigger = "before_basic_attack_hit_check",
        execution = { type = "modify_basic_attack" },
        tags = tags("fighter", "basic_attack", "precision"),
    },
    [SkillRuntimeConfig.Ids.fighter_counter_basic] = {
        id = SkillRuntimeConfig.Ids.fighter_counter_basic,
        symbol = "fighter_counter_basic",
        runtimeKind = "passive",
        designKind = "reaction",
        classId = 2,
        name = "反击战法",
        hidden = true,
        cooldown = 0,
        trigger = "on_melee_targeted_each_turn",
        execution = { type = "counter_basic" },
        tags = tags("fighter", "reaction"),
    },
    [SkillRuntimeConfig.Ids.fighter_guard_counter] = {
        id = SkillRuntimeConfig.Ids.fighter_guard_counter,
        symbol = "fighter_guard_counter",
        runtimeKind = "passive",
        designKind = "reaction",
        classId = 2,
        name = "护卫反击",
        hidden = true,
        cooldown = 0,
        trigger = "on_ally_hit_while_guarding",
        execution = { type = "guard_counter" },
        tags = tags("fighter", "guard", "reaction"),
    },
    [SkillRuntimeConfig.Ids.fighter_second_wind_mastery] = {
        id = SkillRuntimeConfig.Ids.fighter_second_wind_mastery,
        symbol = "fighter_second_wind_mastery",
        runtimeKind = "passive",
        designKind = "passive",
        classId = 2,
        name = "续战专精",
        hidden = true,
        cooldown = 0,
        trigger = "second_wind_bonus_heal",
        execution = { type = "bonus_heal" },
        tags = tags("fighter", "survivability", "mastery"),
    },
    [SkillRuntimeConfig.Ids.fighter_extra_attack] = {
        id = SkillRuntimeConfig.Ids.fighter_extra_attack,
        symbol = "fighter_extra_attack",
        runtimeKind = "passive",
        designKind = "feature",
        classId = 2,
        name = "额外攻击",
        hidden = true,
        cooldown = 0,
        trigger = "after_first_basic_attack_each_turn",
        execution = { type = "extra_attack" },
        tags = tags("fighter", "extra_attack"),
    },
    [SkillRuntimeConfig.Ids.fighter_sweeping_attack] = {
        id = SkillRuntimeConfig.Ids.fighter_sweeping_attack,
        symbol = "fighter_sweeping_attack",
        runtimeKind = "passive",
        designKind = "feature",
        classId = 2,
        name = "横扫攻击",
        hidden = true,
        cooldown = 0,
        trigger = "after_basic_attack_hit",
        execution = { type = "sweeping_attack" },
        tags = tags("fighter", "basic_attack", "sweep"),
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for k, v in pairs(value) do
        result[k] = deepCopy(v)
    end
    return result
end

---@param skillId integer
---@return RuntimeSkillEntry|nil
function SkillRuntimeConfig.Get(skillId)
    local entry = SKILLS[tonumber(skillId) or 0]
    if not entry then
        return nil
    end
    return deepCopy(entry)
end

---@param classId integer
---@return RuntimeSkillEntry[]
function SkillRuntimeConfig.GetByClass(classId)
    local result = {}
    for _, entry in pairs(SKILLS) do
        if tonumber(entry.classId) == tonumber(classId) then
            result[#result + 1] = deepCopy(entry)
        end
    end
    table.sort(result, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)
    return result
end

return SkillRuntimeConfig
