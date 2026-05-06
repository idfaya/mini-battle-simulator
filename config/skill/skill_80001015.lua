local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80001015 = {}

function skill_80001015.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80001015,
        frames = {
            { frame = 0, op = "cast", effect = "rogue_swashbuckler_thrust_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "rogue_swashbuckler_thrust_execute",
                targetRef = "selected",
                tags = {
                    { tag = "rogue_swashbuckler_thrust", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "rogue_swashbuckler_thrust_end", targetRef = "selected" },
        },
    })
end

return skill_80001015
