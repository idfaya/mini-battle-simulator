local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80007001 = {}

function skill_80007001.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    local frames = {}
    for _, t in ipairs(targets or {}) do
        if t and not t.isDead then
            table.insert(frames, { frame = 0, op = "cast", effect = "fireball_cast", target = t })
            table.insert(frames, { frame = 12, op = "projectile", effect = "fireball_projectile", target = t })
            table.insert(frames, {
                frame = 24,
                op = "damage",
                effect = "fireball_hit",
                target = t,
                damageRate = 9000 + math.max(0, tier - 1) * 500,
                tags = {
                    -- Tag as fire damage so fire affinity can scale it.
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "fire" } },
                    { tag = "apply_burn", phase = "post", param = { stacks = tier >= 2 and 2 or 1, turns = tier >= 3 and 3 or 2 } },
                },
            })
        end
    end

    return SkillTimelineCompiler.Build(hero, targets, skill, { id = 80007001, frames = frames })
end

return skill_80007001
