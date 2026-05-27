local skill_80002006 = {}

function skill_80002006.BuildTimeline(hero, targets, skill)
    local FighterBuildPassives = require("skills.fighter_build_passives")
    return {
        { frame = 0, op = "cast", effect = "fighter_second_wind_cast", targetRef = "self" },
        {
            frame = 16,
            op = "effect",
            effect = "fighter_second_wind_execute",
            targetRef = "self",
            execute = function()
                local healAmount = FighterBuildPassives.PerformSecondWindAction(hero, skill)
                return {
                    effectValue = healAmount,
                    healAmount = healAmount,
                    targets = { hero },
                }
            end,
        },
        { frame = 30, op = "effect", effect = "fighter_second_wind_end", targetRef = "self" },
    }
end

return skill_80002006
