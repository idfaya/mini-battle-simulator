local skill_80006014 = {}

function skill_80006014.BuildTimeline(hero, targets, skill)
    local ClericBuildPassives = require("skills.cleric_build_passives")
    return {
        { frame = 0, op = "cast", effect = "cleric_holy_verdict_cast", targetRef = "selected" },
        {
            frame = 22,
            op = "effect",
            effect = "cleric_holy_verdict_execute",
            targetRef = "selected",
            execute = function()
                local target = targets and targets[1] or nil
                local damage = ClericBuildPassives.PerformHolyVerdict(hero, target, skill)
                return {
                    damage = damage,
                    targets = target and { target } or {},
                }
            end,
        },
        { frame = 40, op = "effect", effect = "cleric_holy_verdict_end", targetRef = "selected" },
    }
end

return skill_80006014
