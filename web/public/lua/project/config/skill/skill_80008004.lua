local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80008004 = {}

local DEF = {
    id = 80008004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80008004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "damage",
            effect = "skill_80008004_execute",
            targetRef = "selected",
            damageRate = 10000,
            tags = {
                { tag = "set_targets_all_alive_enemies", phase = "pre" },
                { tag = "set_damage_rate_passive", phase = "pre", param = { base = 10000, key = "iceDamageBonusPct" } },
                { tag = "chance_apply_freeze", phase = "post", param = { baseChance = 5000, key = "iceFreezeChanceBonus", turns = 1, slowPct = 3000 } },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80008004_end", targetRef = "selected" },
    },
}

function skill_80008004.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80008004



