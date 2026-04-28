local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80003001 = {}

function skill_80003001.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    local tags = {
        { tag = "combo_additional_damage", phase = "post" },
    }
    if tier >= 2 then
        tags[#tags + 1] = { tag = "crit_rate_bonus", phase = "pre", param = { amount = 500 * (tier - 1) } }
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80003001,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80003001_cast", targetRef = "selected" },
            {
                frame = 24,
                op = "damage",
                effect = "skill_80003001_execute",
                targetRef = "selected",
                damageRate = 11000 + math.max(0, tier - 1) * 500,
                tags = tags,
            },
            { frame = 36, op = "effect", effect = "skill_80003001_end", targetRef = "selected" },
        },
    })
end

return skill_80003001




