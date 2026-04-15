local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80005001 = {}

local DEF = {
    id = 80005001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80005001_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "damage",
            effect = "skill_80005001_execute",
            targetRef = "selected",
            damageRate = 10000,
            tags = {
                { tag = "apply_poison", phase = "post", param = { layers = 1 } },
            },
        },
    },
}

function skill_80005001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80005001




