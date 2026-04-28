local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005003 = {}

function skill_80005003.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80005003,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80005003_cast", targetRef = "selected" },
            {
                frame = 30,
                op = "damage",
                effect = "skill_80005003_execute",
                targetRef = "selected",
                damageRate = 7000 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "select_random_enemies", phase = "pre", param = { count = 3 + math.max(0, tier - 1) } },
                    { tag = "apply_poison", phase = "post", param = { layers = tier >= 3 and 3 or 2 } },
                },
            },
            { frame = 45, op = "effect", effect = "skill_80005003_end", targetRef = "selected" },
        },
    })
end

return skill_80005003




