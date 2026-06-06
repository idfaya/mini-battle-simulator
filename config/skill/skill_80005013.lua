local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005013 = {}

local MAX_SHOTS = 2
local SHOT_SPACING = 42

local function collectShotTargets(targets)
    local shotTargets = {}
    local seen = {}
    for _, target in ipairs(targets or {}) do
        local targetId = tonumber(target and (target.instanceId or target.id)) or 0
        if target and not target.isDead and targetId ~= 0 and not seen[targetId] then
            seen[targetId] = true
            shotTargets[#shotTargets + 1] = target
            if #shotTargets >= MAX_SHOTS then
                break
            end
        end
    end
    return shotTargets
end

function skill_80005013.BuildTimeline(hero, targets, skill)
    local shotTargets = collectShotTargets(targets)
    local frames = {}
    for index, target in ipairs(shotTargets) do
        local baseFrame = (index - 1) * SHOT_SPACING
        frames[#frames + 1] = { frame = baseFrame, op = "cast", effect = "ranger_hunter_shot_cast", target = target }
        frames[#frames + 1] = { frame = baseFrame + 12, op = "projectile", effect = "ranger_hunter_shot_projectile", target = target }
        frames[#frames + 1] = { frame = baseFrame + 24, op = "damage", target = target }
        frames[#frames + 1] = { frame = baseFrame + 36, op = "effect", effect = "ranger_hunter_shot_end", target = target }
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80005013,
        frames = frames,
    })
end

return skill_80005013
