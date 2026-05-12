local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80009001 = {}

function skill_80009001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80009001,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80009001_cast", targetRef = "selected" },
            {
                frame = 24,
                op = "damage",
                effect = "skill_80009001_execute",
                targetRef = "selected",
                tags = {
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "thunder" } },
                    { tag = "apply_static_mark", phase = "post", param = { turns = 2 } },
                },
            },
            { frame = 36, op = "effect", effect = "skill_80009001_end", targetRef = "selected" },
        },
    })
end

return skill_80009001



