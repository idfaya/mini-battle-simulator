local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80005003 = {}

local DEF = {
    id = 80005003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80005003_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "damage",
            effect = "skill_80005003_execute",
            targetRef = "selected",
            damageRate = 10000,
            tags = {
                { tag = "select_random_enemies", phase = "pre", param = { count = 3 } },
                { tag = "apply_poison", phase = "post", param = { layers = 2 } },
            },
        },
    },
}

function skill_80005003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80005003




