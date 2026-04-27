local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005004 = {}

local DEF = {
    id = 80005004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80005004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "effect",
            effect = "skill_80005004_execute",
            targetRef = "selected",
            tags = {
                { tag = "poison_burst", phase = "pre" },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80005004_end", targetRef = "selected" },
    },
}

function skill_80005004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80005004




