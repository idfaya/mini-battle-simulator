local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80003003 = {}

local DEF = {
    id = 80003003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80003003_cast", targetRef = "selected" },
        { frame = 24, op = "damage", effect = "skill_80003003_execute_1", targetRef = "selected", damageRate = 10000 },
        { frame = 36, op = "damage", effect = "skill_80003003_execute_2", targetRef = "selected", damageRate = 10000 },
        { frame = 45, op = "effect", effect = "skill_80003003_end", targetRef = "selected" },
    },
}

function skill_80003003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80003003



