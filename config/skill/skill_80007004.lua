local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80007004 = {}

local DEF = {
    id = 80007004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80007004_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "damage",
            effect = "skill_80007004_execute",
            targetRef = "selected",
            damageRate = 20000,
            tags = {
                { tag = "apply_burn", phase = "post", param = { stacks = 3, turns = 3 } },
            },
        },
    },
}

function skill_80007004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80007004




