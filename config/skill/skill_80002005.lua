local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80002005 = {}

function skill_80002005.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80002005,
        frames = {
            { frame = 0, op = "cast", effect = "fighter_guard_stance_cast", targetRef = "self" },
            {
                frame = 10,
                op = "effect",
                effect = "fighter_guard_stance_execute",
                targetRef = "self",
                tags = {
                    { tag = "activate_guard_stance", phase = "post" },
                },
            },
            { frame = 20, op = "effect", effect = "fighter_guard_stance_end", targetRef = "self" },
        },
    })
end

return skill_80002005
