local skill_80006015 = {}

function skill_80006015.BuildTimeline(hero, targets, skill)
    local ClericBuildPassives = require("skills.cleric_build_passives")
    return {
        { frame = 0, op = "cast", effect = "cleric_sanctuary_cast", targetRef = "self" },
        {
            frame = 18,
            op = "effect",
            effect = "cleric_sanctuary_execute",
            targetRef = "self",
            execute = function()
                local effectValue = ClericBuildPassives.ActivateSanctuary(hero, skill)
                return {
                    effectValue = effectValue,
                    targets = { hero },
                }
            end,
        },
        { frame = 36, op = "effect", effect = "cleric_sanctuary_end", targetRef = "self" },
    }
end

return skill_80006015
