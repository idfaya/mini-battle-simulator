local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80007003 = {}

local DEF = {
    id = 80007003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80007003_cast", targetRef = "selected" },
        {
            frame = 30,
            op = "damage",
            effect = "skill_80007003_execute",
            targetRef = "selected",
            damageRate = 8000,
            tags = {
                { tag = "select_random_enemies", phase = "pre", param = { count = 3 } },
                { tag = "apply_burn", phase = "post", param = { stacks = 1, turns = 2 } },
            },
        },
        { frame = 45, op = "effect", effect = "skill_80007003_end", targetRef = "selected" },
    },
}

function skill_80007003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80007003





