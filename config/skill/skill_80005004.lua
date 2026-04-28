local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005004 = {}

function skill_80005004.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    local tags = {
        { tag = "poison_burst", phase = "pre" },
    }
    if tier >= 2 then
        table.insert(tags, 1, { tag = "set_targets_all_alive_enemies", phase = "pre" })
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80005004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80005004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "effect",
                effect = "skill_80005004_execute",
                targetRef = "selected",
                tags = tags,
            },
            { frame = 66, op = "effect", effect = "skill_80005004_end", targetRef = "selected" },
        },
    })
end

return skill_80005004



