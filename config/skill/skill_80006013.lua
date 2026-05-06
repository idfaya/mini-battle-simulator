local skill_80006013 = {}

function skill_80006013.BuildTimeline(hero, targets, skill)
    local ClericBuildPassives = require("skills.cleric_build_passives")
    return {
        { frame = 0, op = "cast", effect = "cleric_life_prayer_cast", targetRef = "self" },
        {
            frame = 24,
            op = "effect",
            effect = "cleric_life_prayer_execute",
            targetRef = "self",
            execute = function()
                local healAmount = ClericBuildPassives.PerformLifePrayer(hero, skill)
                return {
                    healAmount = healAmount,
                    targets = { hero },
                }
            end,
        },
        { frame = 42, op = "effect", effect = "cleric_life_prayer_end", targetRef = "self" },
    }
end

return skill_80006013
