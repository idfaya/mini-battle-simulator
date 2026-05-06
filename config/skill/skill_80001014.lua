local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80001014 = {}

function skill_80001014.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80001014,
        frames = {
            { frame = 0, op = "cast", effect = "rogue_trickster_blade_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "rogue_trickster_blade_execute",
                targetRef = "selected",
                tags = {
                    { tag = "rogue_trickster_blade", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "rogue_trickster_blade_end", targetRef = "selected" },
        },
    })
end

return skill_80001014
