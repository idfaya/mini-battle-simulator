local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80002004 = {}

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

local DEF = {
    id = 80002004,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80002004_cast", targetRef = "selected" },
        {
            frame = 42,
            op = "damage",
            effect = "skill_80002004_execute",
            targetRef = "selected",
            damageRate = 10500,
            tags = {
                { tag = "select_random_enemies", phase = "pre", param = { count = 3 } },
            },
        },
        { frame = 66, op = "effect", effect = "skill_80002004_end", targetRef = "selected" },
    },
}

function skill_80002004.BuildTimeline(hero, targets, skill)
    local lv = tonumber(skill and skill.level) or 1
    if lv <= 1 then
        return SkillTimelineCompiler.Build(hero, targets, skill, DEF)
    end
    local frames = {}
    for i, f in ipairs(DEF.frames) do
        frames[i] = shallowCopy(f)
    end
    local damageFrame = frames[2]
    local count = math.max(3, math.min(5, 3 + (lv - 1)))
    damageFrame.tags = damageFrame.tags or {}
    damageFrame.tags[1] = { tag = "select_random_enemies", phase = "pre", param = { count = count } }
    return SkillTimelineCompiler.Build(hero, targets, skill, { id = DEF.id, frames = frames })
end

return skill_80002004
