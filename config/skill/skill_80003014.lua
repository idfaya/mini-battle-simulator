local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80003014 = {}

function skill_80003014.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80003014,
        frames = {
            { frame = 0, op = "cast", effect = "monk_shadow_combo_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "monk_shadow_combo_execute",
                targetRef = "selected",
                tags = {
                    { tag = "monk_shadow_combo", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "monk_shadow_combo_end", targetRef = "selected" },
        },
    })
end

return skill_80003014
