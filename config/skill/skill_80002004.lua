local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80002004 = {}

local DEF = {
    id = 80002004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80002004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "effect",
            effect = "skill_80002004_execute",
            targetRef = "selected",
            tags = {
                { tag = "remove_buff_by_subtype", phase = "pre", param = { subType = 820002 } },
                { tag = "apply_buff_self", phase = "pre", param = { buffId = 820003 } },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80002004_end", targetRef = "selected" },
    },
}

function skill_80002004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80002004




