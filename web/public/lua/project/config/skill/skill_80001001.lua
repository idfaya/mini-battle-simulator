local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80001001 = {}

local DEF = {
    id = 80001001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80001001_cast", targetRef = "selected" },
        { frame = 12, op = "damage", effect = "skill_80001001_execute", targetRef = "selected", damageRate = 11000 },
    },
}

function skill_80001001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80001001




