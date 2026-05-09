local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80007004 = {}

function skill_80007004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80007004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80007004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "damage",
                effect = "skill_80007004_execute",
                targetRef = "selected",
                damageRate = 9000,
                tags = {
                    { tag = "set_targets_all_alive_enemies", phase = "pre" },
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "fire" } },
                    { tag = "sorcerer_burn_settlement", phase = "both", param = { bonusDice = "1d8", turns = 3 } },
                },
            },
            { frame = 66, op = "effect", effect = "skill_80007004_end", targetRef = "selected" },
        },
    })
end

return skill_80007004

