local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80009004 = {}

local DEF = {
    id = 80009004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80009004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "damage",
            effect = "skill_80009004_execute",
            targetRef = "selected",
            damageRate = 10000,
            tags = {
                { tag = "set_targets_all_alive_enemies", phase = "pre" },
                { tag = "chain_lightning", phase = "post", param = { hitCount = 3, damageRate = 10000 } },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80009004_end", targetRef = "selected" },
    },
}

function skill_80009004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80009004




