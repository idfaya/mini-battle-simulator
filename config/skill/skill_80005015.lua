local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005015 = {}

function skill_80005015.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80005015,
        frames = {
            { frame = 0, op = "cast", effect = "ranger_snare_shot_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "ranger_snare_shot_execute",
                targetRef = "selected",
                tags = {
                    { tag = "ranger_snare_shot", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "ranger_snare_shot_end", targetRef = "selected" },
        },
    })
end

return skill_80005015
