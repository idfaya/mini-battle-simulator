local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80001001 = {}

local DEF = {
    id = 80001001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80001001_cast", targetRef = "selected" },
        {
            frame = 24,
            op = "damage",
            effect = "skill_80001001_execute",
            targetRef = "selected",
            damageRate = 12500,
            tags = {
                -- +20% crit rate (design: "+20%暴击率")
                { tag = "crit_rate_bonus", phase = "pre", param = { amount = 2000 } },
            },
        },
        { frame = 36, op = "effect", effect = "skill_80001001_end", targetRef = "selected" },
    },
}

function skill_80001001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80001001


