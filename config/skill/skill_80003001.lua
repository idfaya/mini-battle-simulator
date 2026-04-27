local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80003001 = {}

local DEF = {
    id = 80003001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80003001_cast", targetRef = "selected" },
        {
            frame = 24,
            op = "damage",
            effect = "skill_80003001_execute",
            targetRef = "selected",
            damageRate = 11000,
            tags = {
                { tag = "combo_additional_damage", phase = "post" },
            },
        },
        { frame = 36, op = "effect", effect = "skill_80003001_end", targetRef = "selected" },
    },
}

function skill_80003001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80003001




