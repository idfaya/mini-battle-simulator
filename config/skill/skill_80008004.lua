local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80008004 = {}

function skill_80008004.BuildTimeline(hero, targets, skill)
    local tier = tonumber(skill and skill.level) or 1
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80008004,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80008004_cast", targetRef = "selected" },
            {
                frame = 42,
                op = "damage",
                effect = "skill_80008004_execute",
                targetRef = "selected",
                damageRate = 9000 + math.max(0, tier - 1) * 500,
                tags = {
                    { tag = "set_targets_all_alive_enemies", phase = "pre" },
                    { tag = "set_damage_rate_passive", phase = "pre", param = { base = 9500 + math.max(0, tier - 1) * 500, key = "iceDamageBonusPct" } },
                    { tag = "chance_apply_freeze", phase = "post", param = { baseChance = 3500 + math.max(0, tier - 1) * 1000, key = "iceFreezeChanceBonus", turns = 1, slowPct = 2000 + math.max(0, tier - 1) * 500 } },
                },
            },
            { frame = 66, op = "effect", effect = "skill_80008004_end", targetRef = "selected" },
        },
    })
end

return skill_80008004




