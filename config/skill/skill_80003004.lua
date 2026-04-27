local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80003004 = {}

local DEF = {
    id = 80003004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80003004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "damage",
            effect = "skill_80003004_execute",
            targetRef = "selected",
            damageRate = 13500,
            tags = {
                { tag = "apply_buff_targets", phase = "post", param = { buffId = 880002 } },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80003004_end", targetRef = "selected" },
    },
}

function skill_80003004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80003004


