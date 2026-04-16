local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80002001 = {}

local DEF = {
    id = 80002001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80002001_cast", targetRef = "selected" },
        {
            frame = 24,
            op = "damage",
            effect = "skill_80002001_execute",
            targetRef = "selected",
            damageRate = 10000,
            tags = {
                { tag = "apply_buff_targets", phase = "post", param = { buffId = 820001 } },
            },
        },
        { frame = 36, op = "effect", effect = "skill_80002001_end", targetRef = "selected" },
    },
}

function skill_80002001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80002001




