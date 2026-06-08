local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

local skill_80005013 = {}

local MAX_SHOTS = 2
local CAST_FRAME = 0
local PROJECTILE_FRAME = 12
local DAMAGE_FRAME = 24
local END_FRAME = 36

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
    for _, target in ipairs(shotTargets) do
        frames[#frames + 1] = { frame = CAST_FRAME, op = "cast", effect = "ranger_hunter_shot_cast", target = target }
        frames[#frames + 1] = { frame = PROJECTILE_FRAME, op = "projectile", effect = "ranger_hunter_shot_projectile", target = target }
        frames[#frames + 1] = { frame = DAMAGE_FRAME, op = "damage", target = target }
        frames[#frames + 1] = { frame = END_FRAME, op = "effect", effect = "ranger_hunter_shot_end", target = target }
    end
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80005013,
        frames = frames,
    })
end

return skill_80005013
