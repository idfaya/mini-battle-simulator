local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80002003 = {}

function skill_80002003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80002003,
        frames = {
            { frame = 0, op = "cast", effect = "fighter_action_surge_cast", targetRef = "selected" },
            {
                frame = 18,
                op = "effect",
                effect = "fighter_action_surge_execute",
                targetRef = "selected",
                tags = {
                    { tag = "repeat_basic_attack", phase = "post", param = { count = 2 } },
                },
            },
            { frame = 36, op = "effect", effect = "fighter_action_surge_end", targetRef = "selected" },
        },
    })
end

return skill_80002003
