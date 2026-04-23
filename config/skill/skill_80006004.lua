local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80006004 = {}

local DEF = {
    id = 80006004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80006004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "effect",
            effect = "skill_80006004_execute",
            targetRef = "selected",
            tags = {
                { tag = "revive_latest_ally", phase = "pre" },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80006004_end", targetRef = "selected" },
    },
}

function skill_80006004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80006004



