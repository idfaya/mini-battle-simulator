local skill_80006012 = {}

function skill_80006012.BuildTimeline(hero, targets, skill)
    local ClericBuildPassives = require("skills.cleric_build_passives")
    return {
        { frame = 0, op = "cast", effect = "cleric_healing_word_cast", targetRef = "self" },
        {
            frame = 18,
            op = "effect",
            effect = "cleric_healing_word_execute",
            targetRef = "selected",
            execute = function()
                local healAmount, target = ClericBuildPassives.PerformHealingWord(hero, skill)
                return {
                    healAmount = healAmount,
                    targets = target and { target } or {},
                }
            end,
        },
        { frame = 32, op = "effect", effect = "cleric_healing_word_end", targetRef = "self" },
    }
end

return skill_80006012
