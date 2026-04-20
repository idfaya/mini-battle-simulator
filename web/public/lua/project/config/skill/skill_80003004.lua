local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80003004 = {}

local DEF = {
    id = 80003004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80003004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "effect",
            effect = "skill_80003004_execute",
            targetRef = "selected",
            tags = {
                { tag = "random_hits_damage", phase = "pre", param = { hits = 6, damageRate = 7000, pursuitOnKill = true } },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80003004_end", targetRef = "selected" },
    },
}

function skill_80003004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80003004



