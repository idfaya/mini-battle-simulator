local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80008004 = {}

function skill_80008004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80008004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80008004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "damage",
                effect = "skill_80008004_execute",
                targetRef = "selected",
                tags = {
                    { tag = "set_targets_all_alive_enemies", phase = "pre" },
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "ice" } },
                    { tag = "wizard_blizzard_settlement", phase = "both", param = { bonusDice = "1d8" } },
                },
            },
            { frame = 66, op = "effect", effect = "skill_80008004_end", targetRef = "selected" },
        },
    })
end

return skill_80008004



