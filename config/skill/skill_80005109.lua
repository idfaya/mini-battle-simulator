local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005109 = {}

function skill_80005109.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80005109,
        frames = {
            { frame = 0, op = "cast", effect = "ranger_arrow_rain_cast", targetRef = "selected" },
            {
                frame = 16,
                op = "effect",
                effect = "ranger_arrow_rain_execute",
                targetRef = "selected",
                tags = {
                    { tag = "ranger_arrow_rain", phase = "post" },
                },
            },
            { frame = 40, op = "effect", effect = "ranger_arrow_rain_end", targetRef = "selected" },
        },
    })
end

return skill_80005109
