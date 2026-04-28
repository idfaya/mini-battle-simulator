local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80006001 = {}

local DEF = {
    id = 80006001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80006001_cast", targetRef = "selected" },
        {
            frame = 24,
            op = "damage",
            effect = "skill_80006001_execute",
            targetRef = "selected",
            damageRate = 10500,
            tags = {
                { tag = "holy_light", phase = "pre" },
            },
        },
        { frame = 36, op = "effect", effect = "skill_80006001_end", targetRef = "selected" },
    },
}

function skill_80006001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80006001


