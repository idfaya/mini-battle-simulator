local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80001001 = {}

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

local DEF = {
    id = 80001001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80001001_cast", targetRef = "selected" },
        {
            frame = 24,
            op = "damage",
            effect = "skill_80001001_execute",
            targetRef = "selected",
            tags = {
                -- +20% crit rate (design: "+20%暴击率")
                { tag = "crit_rate_bonus", phase = "pre", param = { amount = 2000 } },
            },
        },
        { frame = 36, op = "effect", effect = "skill_80001001_end", targetRef = "selected" },
    },
}

function skill_80001001.BuildTimeline(hero, targets, skill)
    local lv = tonumber(skill and skill.level) or 1
    if lv <= 1 then
        return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
    end
    local frames = {}
    for i, f in ipairs(DEF.frames) do
        frames[i] = shallowCopy(f)
    end
    local damageFrame = frames[2]
    damageFrame.tags = damageFrame.tags or {}
    if lv >= 2 then
        -- Tier2: 背刺窗口更稳（提高暴击加成）。
        damageFrame.tags[1] = { tag = "crit_rate_bonus", phase = "pre", param = { amount = 3000 } }
    end
    if lv >= 3 then
        -- Tier3: 命中后附带 1 层毒，形成持续压制。
        table.insert(damageFrame.tags, { tag = "apply_poison", phase = "post", param = { layers = 1 } })
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, { id = DEF.id, frames = frames })
end

return skill_80001001



