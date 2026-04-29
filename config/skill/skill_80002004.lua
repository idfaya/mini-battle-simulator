local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80002004 = {}

function skill_80002004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80002004,
        frames = {
            { frame = 0, op = "cast", effect = "fighter_pressure_strike_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "fighter_pressure_strike_execute",
                targetRef = "selected",
                tags = {
                    { tag = "fighter_pressure_strike", phase = "post" },
                },
            },
            { frame = 32, op = "effect", effect = "fighter_pressure_strike_end", targetRef = "selected" },
        },
    })
end

return skill_80002004
