local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80002003 = {}

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

local DEF = {
    id = 80002003,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80002003_cast", targetRef = "selected" },
        {
            frame = 30,
            op = "damage",
            effect = "skill_80002003_execute",
            targetRef = "selected",
            damageRate = 7800,
            tags = {
                { tag = "select_random_enemies", phase = "pre", param = { count = 2 } },
            },
        },
        { frame = 45, op = "effect", effect = "skill_80002003_end", targetRef = "selected" },
    },
}

function skill_80002003.BuildTimeline(hero, targets, skill)
    local lv = tonumber(skill and skill.level) or 1
    if lv <= 1 then
        return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
    end

    local frames = {}
    for i, f in ipairs(DEF.frames) do
        frames[i] = shallowCopy(f)
    end
    local damageFrame = frames[2]
    local count = math.max(2, math.min(4, 2 + (lv - 1)))
    damageFrame.tags = damageFrame.tags or {}
    -- Replace the default selection tag with scaled count.
    damageFrame.tags[1] = { tag = "select_random_enemies", phase = "pre", param = { count = count } }
    if lv >= 3 then
        -- Tier3: 顺劈更“压制”，附带轻度减速（用 slow 代替复杂控制）。
        table.insert(damageFrame.tags, { tag = "apply_freeze", phase = "post", param = { turns = 0, slowPct = 2500 } })
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, { id = DEF.id, frames = frames })
end

return skill_80002003
