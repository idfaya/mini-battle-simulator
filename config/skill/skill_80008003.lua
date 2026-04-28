local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80008003 = {}

function skill_80008003.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80008003,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80008003_cast", targetRef = "selected" },
            {
                frame = 30,
                op = "damage",
                effect = "skill_80008003_execute",
                targetRef = "selected",
                damageRate = 7000 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "expand_area_targets", phase = "pre", param = { includeRow = true, includeColumn = true } },
                    { tag = "set_damage_rate_passive", phase = "pre", param = { base = 8000 + math.max(0, tier - 1) * 500, key = "iceDamageBonusPct" } },
                    { tag = "apply_freeze", phase = "post", param = { turns = tier >= 3 and 2 or 1, slowPct = 2500 + math.max(0, tier - 1) * 500 } },
                },
            },
            { frame = 45, op = "effect", effect = "skill_80008003_end", targetRef = "selected" },
        },
    })
end

return skill_80008003





