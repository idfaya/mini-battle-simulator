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
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.rogue_execute_strike,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.rogue_executioner,
            },
        },
    },
    [6] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.cleric_training,
                FeatBuildConfig.Ids.cleric_shelter_prayer,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.cleric_healing_word,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.cleric_guardian_domain,
            },
        },
    },
    [7] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.sorcerer_training,
                FeatBuildConfig.Ids.sorcerer_ember_ignite,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.sorcerer_ash_burst,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.sorcerer_flame_storm,
            },
        },
    },
    [8] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.wizard_training,
                FeatBuildConfig.Ids.wizard_frost_lag,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.wizard_freezing_nova,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.wizard_blizzard,
            },
        },
    },
    [9] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.warlock_training,
                FeatBuildConfig.Ids.warlock_static_mark,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.warlock_thunder_chain,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.warlock_thunderstorm,
            },
        },
    },
    [10] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.barbarian_training,
                FeatBuildConfig.Ids.barbarian_rage,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.barbarian_heavy_strike,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.barbarian_berserk,
            },
        },
    },
    [2] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.fighter_training,
                FeatBuildConfig.Ids.fighter_counter_basic,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.fighter_guard,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.fighter_second_wind,
            },
        },
    },
    [3] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.monk_training,
                FeatBuildConfig.Ids.monk_martial_arts,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.monk_open_hand,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.monk_harmonize,
            },
        },
    },
    [4] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.paladin_training,
                FeatBuildConfig.Ids.paladin_shelter_prayer,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.paladin_vengeance_smite,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.paladin_lay_on_hands,
            },
        },
    },
    [5] = {
        [1] = {
            fixed = {
                FeatBuildConfig.Ids.ranger_training,
                FeatBuildConfig.Ids.ranger_hunter_mark,
            },
        },
        [3] = {
            fixed = {
                FeatBuildConfig.Ids.ranger_hunter_shot,
            },
        },
        [5] = {
            fixed = {
                FeatBuildConfig.Ids.ranger_hunter_mastery,
            },
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
