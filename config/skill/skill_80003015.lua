local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80003015 = {}

function skill_80003015.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80003015,
        frames = {
            { frame = 0, op = "cast", effect = "monk_harmonize_cast", targetRef = "self" },
            {
                frame = 18,
                op = "effect",
                effect = "monk_harmonize_execute",
                targetRef = "self",
                tags = {
                    { tag = "monk_harmonize", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "monk_harmonize_end", targetRef = "self" },
        },
    })
end

return skill_80003015
