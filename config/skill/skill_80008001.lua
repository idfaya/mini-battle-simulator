local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80008001 = {}

function skill_80008001.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    local frames = {}
    for _, t in ipairs(targets or {}) do
        if t and not t.isDead then
            table.insert(frames, { frame = 0, op = "cast", effect = "ice_arrow_cast", target = t })
            table.insert(frames, { frame = 12, op = "projectile", effect = "ice_arrow_projectile", target = t })
            table.insert(frames, {
                frame = 24,
                op = "damage",
                effect = "ice_arrow_hit",
                target = t,
                damageRate = 8500 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "set_damage_rate_passive", phase = "pre", param = { base = 10000, key = "iceDamageBonusPct" } },
                    { tag = "apply_freeze", phase = "post", param = { turns = tier >= 3 and 1 or 0, slowPct = 2500 + math.max(0, tier - 1) * 500 } },
                },
            })
            table.insert(frames, { frame = 36, op = "effect", effect = "ice_arrow_end", target = t })
        end
    end

    return SkillTimelineCompiler.Build(hero, targets, skill, { id = 80008001, frames = frames })
end

return skill_80008001



