local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80004001 = {}

function skill_80004001.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    local tags = nil
    if tier >= 3 then
        tags = {
            { tag = "crit_rate_bonus", phase = "pre", param = { amount = 500 } },
        }
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80004001,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80004001_cast", targetRef = "selected" },
            { frame = 24, op = "damage", effect = "skill_80004001_execute", targetRef = "selected", damageRate = 11000 + math.max(0, tier - 1) * 750, tags = tags },
            { frame = 36, op = "effect", effect = "skill_80004001_end", targetRef = "selected" },
        },
    })
end

return skill_80004001




