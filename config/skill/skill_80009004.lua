local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80009004 = {}

function skill_80009004.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80009004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80009004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "damage",
                effect = "skill_80009004_execute",
                targetRef = "selected",
                damageRate = 8500 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "set_targets_all_alive_enemies", phase = "pre" },
                    { tag = "chain_lightning", phase = "post", param = { hitCount = 2 + math.max(0, tier - 1), damageRate = 3000 } },
                },
            },
            { frame = 66, op = "effect", effect = "skill_80009004_end", targetRef = "selected" },
        },
    })
end

return skill_80009004



