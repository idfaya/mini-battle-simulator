local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80010013 = {}

function skill_80010013.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80010013,
        frames = {
            { frame = 0, op = "cast", effect = "barbarian_heavy_strike_cast", targetRef = "selected" },
            {
                frame = 16,
                op = "effect",
                effect = "barbarian_heavy_strike_execute",
                targetRef = "selected",
                tags = {
                    { tag = "barbarian_heavy_strike", phase = "post" },
                },
            },
            { frame = 32, op = "effect", effect = "barbarian_heavy_strike_end", targetRef = "selected" },
        },
    })
end

return skill_80010013
