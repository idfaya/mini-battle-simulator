local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80007004 = {}

function skill_80007004.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80007004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80007004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "damage",
                effect = "skill_80007004_execute",
                targetRef = "selected",
                damageRate = 13000 + math.max(0, tier - 1) * 1000,
                tags = {
                    { tag = "apply_burn", phase = "post", param = { stacks = 2 + math.max(0, tier - 1), turns = tier >= 2 and 3 or 2 } },
                },
            },
            { frame = 66, op = "effect", effect = "skill_80007004_end", targetRef = "selected" },
        },
    })
end

return skill_80007004


