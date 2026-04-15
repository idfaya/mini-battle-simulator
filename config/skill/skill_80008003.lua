local SkillTimelineCompiler = require("modules.skill_timeline_compiler")

local skill_80008003 = {}

local DEF = {
    id = 80008003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80008003_cast", targetRef = "selected" },
        {
            frame = 12,
            op = "damage",
            effect = "skill_80008003_execute",
            targetRef = "selected",
            damageRate = 10000,
            tags = {
                { tag = "expand_area_targets", phase = "pre", param = { includeRow = true, includeColumn = true } },
                { tag = "set_damage_rate_passive", phase = "pre", param = { base = 10000, key = "iceDamageBonusPct" } },
                { tag = "apply_freeze", phase = "post", param = { turns = 1, slowPct = 3000 } },
            },
        },
    },
}

function skill_80008003.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
end

return skill_80008003




