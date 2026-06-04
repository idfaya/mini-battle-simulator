local skill_80006016 = {}

function skill_80006016.BuildTimeline(hero, targets, skill)
    local ClericBuildPassives = require("skills.cleric_build_passives")
    return {
        { frame = 0, op = "cast", effect = "cleric_turn_undead_cast", targetRef = "selected" },
        {
            frame = 18,
            op = "effect",
            effect = "cleric_turn_undead_execute",
            targetRef = "selected",
            execute = function()
                local damage, affectedTargets = ClericBuildPassives.PerformTurnUndead(hero, skill, targets)
                return {
                    damage = damage,
                    targets = affectedTargets or {},
                }
            end,
        },
        { frame = 36, op = "effect", effect = "cleric_turn_undead_end", targetRef = "selected" },
    }
end

return skill_80006016
