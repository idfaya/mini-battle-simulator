local FeatBuildConfig = require("config.feat_build_config")

---@class ClassBuildProgressionEntry
---@field fixed integer[]|nil
---@field choiceGroup string|nil

local ClassBuildProgression = {}

---@type table<integer, table<integer, ClassBuildProgressionEntry>>
local PROGRESSION = {
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
