local skill_80006011 = {}

function skill_80006011.BuildTimeline(hero, targets, skill)
    local ClericBuildPassives = require("skills.cleric_build_passives")
    return {
        { frame = 0, op = "cast", effect = "cleric_basic_spell_cast", targetRef = "selected" },
        {
            frame = 20,
            op = "attack",
            effect = "cleric_basic_spell_execute",
            targetRef = "selected",
            execute = function()
                local target = targets and targets[1] or nil
                local damage = ClericBuildPassives.PerformBasicSpellAttack(hero, target, skill)
                return {
                    damage = damage,
                    targets = target and { target } or {},
                }
            end,
        },
        { frame = 36, op = "effect", effect = "cleric_basic_spell_end", targetRef = "selected" },
    }
end

return skill_80006011
