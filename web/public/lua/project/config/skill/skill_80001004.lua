local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80001004 = {}

local DEF = {
    id = 80001004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80001004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "damage",
            effect = "skill_80001004_execute",
            targetRef = "selected",
            damageRate = 20000,
            tags = {
                { tag = "pursuit_on_kill", phase = "post" },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80001004_end", targetRef = "selected" },
    },
}

function skill_80001004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80001004




