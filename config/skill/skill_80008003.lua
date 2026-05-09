local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80008003 = {}

function skill_80008003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80008003,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80008003_cast", targetRef = "selected" },
            {
                frame = 30,
                op = "damage",
                effect = "skill_80008003_execute",
                targetRef = "selected",
                damageRate = 9000,
                tags = {
                    { tag = "expand_area_targets", phase = "pre", param = { includeRow = true, includeColumn = true } },
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "ice" } },
                    { tag = "wizard_freezing_nova", phase = "post" },
                },
            },
            { frame = 45, op = "effect", effect = "skill_80008003_end", targetRef = "selected" },
        },
    })
end

return skill_80008003




