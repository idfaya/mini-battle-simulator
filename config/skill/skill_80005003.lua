local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005003 = {}

local DEF = {
    id = 80005003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80005003_cast", targetRef = "selected" },
        {
            frame = 30,
            op = "damage",
            effect = "skill_80005003_execute",
            targetRef = "selected",
            damageRate = 7000,
            tags = {
                { tag = "select_random_enemies", phase = "pre", param = { count = 3 } },
                { tag = "apply_poison", phase = "post", param = { layers = 2 } },
            },
        },
        { frame = 45, op = "effect", effect = "skill_80005003_end", targetRef = "selected" },
    },
}

function skill_80005003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80005003




