local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80003003 = {}

local DEF = {
    id = 80003003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80003003_cast", targetRef = "selected" },
        { frame = 12, op = "damage", effect = "skill_80003003_execute", targetRef = "selected", damageRate = 10000 },
    },
}

function skill_80003003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80003003




