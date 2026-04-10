local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")

local SkillTimeline = {}

local function CloneFrame(frame)
    local copy = {}
    for k, v in pairs(frame) do
        copy[k] = v
    end
    return copy
end

local function MergeFrameResult(frameCopy, result)
    if type(result) ~= "table" then
        return frameCopy
    end
    for k, v in pairs(result) do
        frameCopy[k] = v
    end
    return frameCopy
end

local function SortFrames(frames)
    table.sort(frames, function(a, b)
        local frameA = a.frame or 0
        local frameB = b.frame or 0
        if frameA == frameB then
            return (a.order or 0) < (b.order or 0)
        end
        return frameA < frameB
    end)
end

function SkillTimeline.Execute(hero, targets, skill, timeline)
    if not timeline or #timeline == 0 then
        return false, { totalDamage = 0, succeeded = false }
    end

    local frames = {}
    for _, frame in ipairs(timeline) do
        table.insert(frames, CloneFrame(frame))
    end
    SortFrames(frames)

    local context = {
        hero = hero,
        targets = targets,
        skill = skill,
        timeline = frames,
        totalDamage = 0,
        totalHeal = 0,
    }

    BattleEvent.Publish(BattleVisualEvents.SKILL_TIMELINE_STARTED,
        BattleVisualEvents.BuildSkillTimelineStarted(hero, skill, frames))

    local executed = false
    for index, frame in ipairs(frames) do
        local frameCopy = CloneFrame(frame)
        if type(frame.execute) == "function" then
            local ok, result = pcall(frame.execute, context, frameCopy)
            if not ok then
                Logger.LogError(string.format("[SkillTimeline] Frame execution failed: skill=%s frame=%s err=%s",
                    tostring(skill and skill.skillId), tostring(frameCopy.frame), tostring(result)))
                return false, {
                    totalDamage = context.totalDamage,
                    totalHeal = context.totalHeal,
                    succeeded = false,
                }
            end
            frameCopy = MergeFrameResult(frameCopy, result)
            executed = true
            if type(frameCopy.damage) == "number" then
                context.totalDamage = context.totalDamage + frameCopy.damage
            end
            if type(frameCopy.healAmount) == "number" then
                context.totalHeal = context.totalHeal + frameCopy.healAmount
            end
        end

        BattleEvent.Publish(BattleVisualEvents.SKILL_TIMELINE_FRAME,
            BattleVisualEvents.BuildSkillTimelineFrame(hero, skill, frameCopy, index))
    end

    local result = {
        totalDamage = context.totalDamage,
        totalHeal = context.totalHeal,
        succeeded = executed or #frames > 0,
    }

    BattleEvent.Publish(BattleVisualEvents.SKILL_TIMELINE_COMPLETED,
        BattleVisualEvents.BuildSkillTimelineCompleted(hero, skill, frames, result))

    return result.succeeded, result
end

return SkillTimeline
