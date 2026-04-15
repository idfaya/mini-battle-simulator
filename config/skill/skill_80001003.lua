local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80001003 = {}

local DEF = {
    id = 80001003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80001003_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "damage",
            effect = "skill_80001003_execute",
            targetRef = "selected",
            damageRate = 20000,
            tags = {
                { tag = "select_lowest_hp_enemy", phase = "pre" },
                { tag = "pursuit_on_kill", phase = "post" },
            },
        },
    },
}

function skill_80001003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80001003




