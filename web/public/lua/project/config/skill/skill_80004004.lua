local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80004004 = {}

local DEF = {
    id = 80004004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80004004_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "effect",
            effect = "skill_80004004_execute",
            targetRef = "selected",
            tags = {
                { tag = "battle_intent_buff", phase = "pre" },
            },
        },
    },
}

function skill_80004004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80004004




