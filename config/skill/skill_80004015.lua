local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80004015 = {}

function skill_80004015.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80004015,
        frames = {
            { frame = 0, op = "cast", effect = "paladin_guardian_aura_cast", targetRef = "self" },
            {
                frame = 10,
                op = "effect",
                effect = "paladin_guardian_aura_execute",
                targetRef = "self",
                tags = {
                    { tag = "activate_guardian_aura", phase = "post" },
                },
            },
            { frame = 24, op = "effect", effect = "paladin_guardian_aura_end", targetRef = "self" },
        },
    })
end

return skill_80004015
