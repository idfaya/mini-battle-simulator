local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80003004 = {}

function skill_80003004.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    local tags = {
        { tag = "apply_buff_targets", phase = "post", param = { buffId = 880002 } },
    }
    if tier >= 3 then
        tags[#tags + 1] = { tag = "crit_rate_bonus", phase = "pre", param = { amount = 500 } }
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80003004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80003004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "damage",
                effect = "skill_80003004_execute",
                targetRef = "selected",
                damageRate = 13500 + math.max(0, tier - 1) * 1000,
                tags = tags,
            },
            { frame = 66, op = "effect", effect = "skill_80003004_end", targetRef = "selected" },
        },
    })
end

return skill_80003004

