local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005001 = {}

function skill_80005001.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80005001,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80005001_cast", targetRef = "selected" },
            {
                frame = 24,
                op = "damage",
                effect = "skill_80005001_execute",
                targetRef = "selected",
                damageRate = 10500 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "apply_poison", phase = "post", param = { layers = 1 + math.max(0, tier - 1) } },
                },
            },
            { frame = 36, op = "effect", effect = "skill_80005001_end", targetRef = "selected" },
        },
    })
end

return skill_80005001




