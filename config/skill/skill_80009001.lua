local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80009001 = {}

local DEF = {
    id = 80009001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80009001_cast", targetRef = "selected" },
        {
            frame = 24,
            op = "damage",
            effect = "skill_80009001_execute",
            targetRef = "selected",
            damageRate = 9000,
            tags = {
                { tag = "chance_chain_lightning", phase = "post", param = { baseChance = 2000, key = "thunderChainChanceBonus", hitCount = 1, damageRate = 7500 } },
            },
        },
        { frame = 36, op = "effect", effect = "skill_80009001_end", targetRef = "selected" },
    },
}

function skill_80009001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80009001





