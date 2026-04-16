local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80002003 = {}

local DEF = {
    id = 80002003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80002003_cast", targetRef = "selected" },
        {
            frame = 30,
            op = "effect",
            effect = "skill_80002003_execute",
            targetRef = "selected",
            tags = {
                { tag = "apply_buff_self", phase = "pre", param = { buffId = 820002 } },
                { tag = "apply_buff_all_enemies", phase = "pre", param = { buffId = 820001 } },
            },
        },
        { frame = 45, op = "effect", effect = "skill_80002003_end", targetRef = "selected" },
    },
}

function skill_80002003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80002003




