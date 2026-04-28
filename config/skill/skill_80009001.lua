local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80009001 = {}

function skill_80009001.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80009001,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80009001_cast", targetRef = "selected" },
            {
                frame = 24,
                op = "damage",
                effect = "skill_80009001_execute",
                targetRef = "selected",
                damageRate = 9000 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "chance_chain_lightning", phase = "post", param = { baseChance = 2000 + math.max(0, tier - 1) * 1000, key = "thunderChainChanceBonus", hitCount = 1 + math.max(0, tier - 1), damageRate = 7500 } },
                },
            },
            { frame = 36, op = "effect", effect = "skill_80009001_end", targetRef = "selected" },
        },
    })
end

return skill_80009001




