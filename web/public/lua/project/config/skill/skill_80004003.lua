local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80004003 = {}

local DEF = {
    id = 80004003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80004003_cast", targetRef = "selected" },
        {
            frame = 30,
            op = "effect",
            effect = "skill_80004003_execute",
            targetRef = "selected",
            tags = {
                { tag = "battle_intent_buff", phase = "pre" },
            },
        },
        { frame = 45, op = "effect", effect = "skill_80004003_end", targetRef = "selected" },
    },
}

function skill_80004003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80004003




