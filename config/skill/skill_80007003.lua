local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80007003 = {}

function skill_80007003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80007003,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80007003_cast", targetRef = "selected" },
            {
                frame = 30,
                op = "damage",
                effect = "skill_80007003_execute",
                targetRef = "selected",
                damageRate = 9000,
                tags = {
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "fire" } },
                    { tag = "sorcerer_burn_settlement", phase = "both", param = { bonusDice = "1d8", turns = 2 } },
                },
            },
            { frame = 45, op = "effect", effect = "skill_80007003_end", targetRef = "selected" },
        },
    })
end

return skill_80007003



