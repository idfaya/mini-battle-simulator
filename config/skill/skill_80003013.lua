local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80003013 = {}

function skill_80003013.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80003013,
        frames = {
            { frame = 0, op = "cast", effect = "monk_open_hand_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "monk_open_hand_execute",
                targetRef = "selected",
                tags = {
                    { tag = "monk_open_hand_strike", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "monk_open_hand_end", targetRef = "selected" },
        },
    })
end

return skill_80003013
