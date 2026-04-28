local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80007003 = {}

function skill_80007003.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80007003,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80007003_cast", targetRef = "selected" },
            {
                frame = 30,
                op = "damage",
                effect = "skill_80007003_execute",
                targetRef = "selected",
                damageRate = 8000 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "select_random_enemies", phase = "pre", param = { count = 3 + math.max(0, tier - 1) } },
                    { tag = "apply_burn", phase = "post", param = { stacks = 1, turns = tier >= 3 and 3 or 2 } },
                },
            },
            { frame = 45, op = "effect", effect = "skill_80007003_end", targetRef = "selected" },
        },
    })
end

return skill_80007003




