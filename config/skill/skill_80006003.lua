local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80006003 = {}

local DEF = {
    id = 80006003,
    params = {
        -- Reuse existing SkillParam for now to avoid changing config schema.
        -- skillParam[1] is heal rate (1/10000), skillParam[2] is heal count.
    },
    frames = {
        { frame = 0, op = "cast", effect = "skill_80006003_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "effect",
            effect = "skill_80006003_execute",
            targetRef = "selected",
            tags = {
                -- Use centralized handler for now; later can be rewritten into pure "heal" op frames.
                { tag = "group_heal", phase = "pre" },
            },
        },
    },
}

function skill_80006003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80006003




