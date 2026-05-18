local SkillTimelineCompiler = require("skills.skill_timeline_compiler")
local Skill5eMeta = require("config.tables.skill_meta")

local skill_80008001 = {}

function skill_80008001.BuildTimeline(hero, targets, skill)
    local damageDice = Skill5eMeta.ResolveStageDamageDice(80008001, skill and skill.level)
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
                damageDice = damageDice,
                tags = {
                    { tag = "set_damage_kind", phase = "pre", param = { kind = "ice" } },
                    { tag = "apply_frost", phase = "post", param = { turns = 2 } },
                },
            })
            table.insert(frames, { frame = 36, op = "effect", effect = "ice_arrow_end", target = t })
        end
    end

    return SkillTimelineCompiler.Build(hero, targets, skill, { id = 80008001, frames = frames })
end

return skill_80008001



