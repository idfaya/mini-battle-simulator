local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80001013 = {}

function skill_80001013.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80001013,
        frames = {
            { frame = 0, op = "cast", effect = "rogue_execute_strike_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "rogue_execute_strike_execute",
                targetRef = "selected",
                tags = {
                    { tag = "rogue_execute_strike", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "rogue_execute_strike_end", targetRef = "selected" },
        },
    })
end

return skill_80001013
