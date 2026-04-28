local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80002001 = {}

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t or {}) do
        out[k] = v
    end
    return out
end

local DEF = {
    id = 80002001,
    frames = {
        { frame = 0, op = "cast", effect = "skill_80002001_cast", targetRef = "selected" },
        {
            frame = 24,
            op = "damage",
            effect = "skill_80002001_execute",
            targetRef = "selected",
            damageRate = 9000,
            tags = {
                { tag = "apply_buff_targets", phase = "post", param = { buffId = 820001 } },
            },
        },
        { frame = 36, op = "effect", effect = "skill_80002001_end", targetRef = "selected" },
    },
}

function skill_80002001.BuildTimeline(hero, targets, skill)
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
        -- Tier2: 盾击后进入反击姿态（一次性）。
        table.insert(damageFrame.tags, { tag = "apply_buff_self", phase = "post", param = { buffId = 820002 } })
    end
    if lv >= 3 then
        -- Tier3: 盾击后进入盾墙姿态（更强减伤+反击）。
        table.insert(damageFrame.tags, { tag = "apply_buff_self", phase = "post", param = { buffId = 820003 } })
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, { id = DEF.id, frames = frames })
end

return skill_80002001



