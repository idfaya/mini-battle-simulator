local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80006001 = {}

local DEF = {
    id = 80006001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80006001_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "effect",
            effect = "skill_80006001_execute",
            targetRef = "selected",
            tags = {
                { tag = "holy_light", phase = "pre" },
            },
        },
    },
}

function skill_80006001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80006001




