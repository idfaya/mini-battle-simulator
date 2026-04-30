local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80004014 = {}

function skill_80004014.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80004014,
        frames = {
            { frame = 0, op = "cast", effect = "paladin_vengeance_smite_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "paladin_vengeance_smite_execute",
                targetRef = "selected",
                tags = {
                    { tag = "paladin_vengeance_smite", phase = "post" },
                },
            },
            { frame = 36, op = "effect", effect = "paladin_vengeance_smite_end", targetRef = "selected" },
        },
    })
end

return skill_80004014
