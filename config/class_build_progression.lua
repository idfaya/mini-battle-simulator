local FeatBuildConfig = require("config.feat_build_config")

---@class ClassBuildProgressionEntry
---@field fixed integer[]|nil
---@field choiceGroup string|nil

local ClassBuildProgression = {}

---@type table<integer, table<integer, ClassBuildProgressionEntry>>
local PROGRESSION = {
    [1] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.rogue_training,
                FeatBuildConfig.Ids.rogue_sneak_attack,
            },
        },
        [2] = {
            choiceGroup = "rogue_lv2_basic",
        },
        [3] = {
            choiceGroup = "rogue_lv3_subclass",
        },
        [4] = {
            choiceGroup = "rogue_lv4_mastery",
        },
        [5] = {
            choiceGroup = "rogue_lv5_capstone",
        },
    },
    [6] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.cleric_training,
                FeatBuildConfig.Ids.cleric_healing_word,
            },
        },
        [2] = {
            choiceGroup = "cleric_lv2_prayer",
        },
        [3] = {
            choiceGroup = "cleric_lv3_domain",
        },
        [4] = {
            choiceGroup = "cleric_lv4_mastery",
        },
        [5] = {
            choiceGroup = "cleric_lv5_capstone",
        },
    },
    [2] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.fighter_training,
                FeatBuildConfig.Ids.fighter_second_wind,
            },
        },
        [2] = {
            fixed = {
                FeatBuildConfig.Ids.fighter_extra_attack,
            },
        },
        [3] = {
            choiceGroup = "fighter_lv3_active",
        },
        [4] = {
            choiceGroup = "fighter_lv4_passive",
        },
        [5] = {
            choiceGroup = "fighter_lv5_capstone",
        },
    },
    [3] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.monk_training,
                FeatBuildConfig.Ids.monk_martial_arts,
            },
        },
        [2] = {
            choiceGroup = "monk_lv2_basic",
        },
        [3] = {
            choiceGroup = "monk_lv3_subclass",
        },
        [4] = {
            choiceGroup = "monk_lv4_mastery",
        },
        [5] = {
            choiceGroup = "monk_lv5_capstone",
        },
    },
    [4] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.paladin_training,
                FeatBuildConfig.Ids.paladin_divine_smite,
            },
        },
        [2] = {
            choiceGroup = "paladin_lv2_prayer",
        },
        [3] = {
            choiceGroup = "paladin_lv3_oath",
        },
        [4] = {
            choiceGroup = "paladin_lv4_mastery",
        },
        [5] = {
            choiceGroup = "paladin_lv5_capstone",
        },
    },
    [5] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.ranger_training,
                FeatBuildConfig.Ids.ranger_hunter_mark,
            },
        },
        [2] = {
            choiceGroup = "ranger_lv2_basic",
        },
        [3] = {
            choiceGroup = "ranger_lv3_subclass",
        },
        [4] = {
            choiceGroup = "ranger_lv4_mastery",
        },
        [5] = {
            choiceGroup = "ranger_lv5_capstone",
        },
    },
}

---@param classId integer
---@return table<integer, ClassBuildProgressionEntry>|nil
function ClassBuildProgression.GetProgression(classId)
    return PROGRESSION[tonumber(classId) or 0]
end

---@param classId integer
---@param level integer
---@return ClassBuildProgressionEntry|nil
function ClassBuildProgression.GetLevelEntry(classId, level)
    local progression = ClassBuildProgression.GetProgression(classId)
    return progression and progression[tonumber(level) or 0] or nil
end

---@param classId integer
---@param toLevel integer
---@return integer[]
function ClassBuildProgression.CollectFixedFeatIds(classId, toLevel)
    local result = {}
    local progression = ClassBuildProgression.GetProgression(classId) or {}
    for level = 1, math.max(1, tonumber(toLevel) or 1) do
        local entry = progression[level]
        for _, featId in ipairs(entry and entry.fixed or {}) do
            result[#result + 1] = featId
        end
    end
    return result
end

---@param classId integer
---@param toLevel integer
---@return string[]
function ClassBuildProgression.CollectChoiceGroups(classId, toLevel)
    local result = {}
    local progression = ClassBuildProgression.GetProgression(classId) or {}
    for level = 1, math.max(1, tonumber(toLevel) or 1) do
        local entry = progression[level]
        if entry and entry.choiceGroup then
            result[#result + 1] = entry.choiceGroup
        end
    end
    return result
end

return ClassBuildProgression
