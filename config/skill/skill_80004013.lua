local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80004013 = {}

function skill_80004013.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80004013,
        frames = {
            { frame = 0, op = "cast", effect = "paladin_lay_on_hands_cast", targetRef = "self" },
            {
                frame = 24,
                op = "effect",
                effect = "paladin_lay_on_hands_execute",
                targetRef = "self",
                tags = {
                    { tag = "paladin_lay_on_hands", phase = "post" },
                },
            },
            { frame = 42, op = "effect", effect = "paladin_lay_on_hands_end", targetRef = "self" },
        },
    })
end

return skill_80004013
