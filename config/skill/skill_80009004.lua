local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80009004 = {}

function skill_80009004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80009004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80009004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "damage",
                effect = "skill_80009004_execute",
                targetRef = "selected",
                tags = {
                    { tag = "set_targets_all_alive_enemies", phase = "pre" },
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "thunder" } },
                    { tag = "warlock_thunderstorm_settlement", phase = "both", param = { bonusDice = "1d8", turns = 2 } },
                },
            },
            { frame = 66, op = "effect", effect = "skill_80009004_end", targetRef = "selected" },
        },
    })
end

return skill_80009004


