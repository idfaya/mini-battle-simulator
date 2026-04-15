local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80007003 = {}

local DEF = {
    id = 80007003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80007003_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "damage",
            effect = "skill_80007003_execute",
            targetRef = "selected",
            damageRate = 10000,
            tags = {
                { tag = "apply_burn", phase = "post", param = { stacks = 2, turns = 2 } },
            },
        },
    },
}

function skill_80007003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80007003




