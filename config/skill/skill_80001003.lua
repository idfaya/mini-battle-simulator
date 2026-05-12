local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80001003 = {}

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

local DEF = {
    id = 80001003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80001003_cast", targetRef = "selected" },
        {
            frame = 30,
            op = "damage",
            effect = "skill_80001003_execute",
            targetRef = "selected",
            tags = {
                { tag = "select_lowest_hp_enemy", phase = "pre" },
                { tag = "pursuit_on_kill", phase = "post" },
            },
        },
        { frame = 45, op = "effect", effect = "skill_80001003_end", targetRef = "selected" },
    },
}

function skill_80001003.BuildTimeline(hero, targets, skill)
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
        -- Tier2: 附带轻度减速，帮助触发“窗口”。
        table.insert(damageFrame.tags, { tag = "apply_freeze", phase = "post", param = { turns = 0, slowPct = 2500 } })
    end
    if lv >= 3 then
        -- Tier3: 附带中毒，形成持续压制（更偏 build 化）。
        table.insert(damageFrame.tags, { tag = "apply_poison", phase = "post", param = { layers = 1 } })
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, { id = DEF.id, frames = frames })
end

return skill_80001003


