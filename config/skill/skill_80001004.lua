local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80001004 = {}

local DEF = {
    id = 80001004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80001004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "effect",
            effect = "skill_80001004_execute",
            targetRef = "selected",
            tags = {
                -- Multi-hit flurry. The registry handles pursuit-on-kill internally when enabled.
                { tag = "random_hits_damage", phase = "pre", param = { hits = 2, pursuitOnKill = true } },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80001004_end", targetRef = "selected" },
    },
}

function skill_80001004.BuildTimeline(hero, targets, skill)
    local lv = tonumber(skill and skill.level) or 1
    if lv <= 1 then
        return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
    end
    local hits = math.max(2, math.min(5, 2 + (lv - 1)))
    local def = {
        id = DEF.id,
        frames = {
            DEF.frames[1],
            {
                frame = 42,
                op = "effect",
                effect = "skill_80001004_execute",
                targetRef = "selected",
                tags = {
                    { tag = "random_hits_damage", phase = "pre", param = { hits = hits, pursuitOnKill = true } },
                },
            },
            DEF.frames[3],
        },
    }
    return SkillTimelineCompiler.Build(hero, targets, skill, def)
end

return skill_80001004



