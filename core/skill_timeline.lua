local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")

local SkillTimeline = {}
local FRAME_DURATION_MS = 1000 / 30
local activeRuntime = nil
local lastCompletedResult = nil

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

local function BuildRuntime(hero, targets, skill, timeline, onComplete)
    if not timeline or #timeline == 0 then
        return nil, { totalDamage = 0, totalHeal = 0, succeeded = false }
    end

    local frames = {}
    for _, frame in ipairs(timeline) do
        table.insert(frames, CloneFrame(frame))
    end
    SortFrames(frames)

    return {
        hero = hero,
        targets = targets,
        skill = skill,
        frames = frames,
        context = {
            hero = hero,
            targets = targets,
            skill = skill,
            timeline = frames,
            totalDamage = 0,
            totalHeal = 0,
        },
        nextFrameIndex = 1,
        currentFrame = 0,
        elapsedMs = 0,
        executed = false,
        onComplete = onComplete,
    }, nil
end

local function FinalizeRuntime(runtime, succeeded)
    local result = {
        totalDamage = runtime.context.totalDamage,
        totalHeal = runtime.context.totalHeal,
        succeeded = succeeded ~= false and (runtime.executed or #runtime.frames > 0),
    }

    BattleEvent.Publish(BattleVisualEvents.SKILL_TIMELINE_COMPLETED,
        BattleVisualEvents.BuildSkillTimelineCompleted(runtime.hero, runtime.skill, runtime.frames, result))

    lastCompletedResult = result
    activeRuntime = nil

    if type(runtime.onComplete) == "function" then
        runtime.onComplete(result.succeeded, result)
    end

    return result
end

local function ExecuteDueFrames(runtime)
    while runtime.nextFrameIndex <= #runtime.frames do
        local frame = runtime.frames[runtime.nextFrameIndex]
        if (frame.frame or 0) > runtime.currentFrame then
            break
        end

        local frameCopy = CloneFrame(frame)
        if type(frame.execute) == "function" then
            local ok, result = pcall(frame.execute, runtime.context, frameCopy)
            if not ok then
                Logger.LogError(string.format("[SkillTimeline] Frame execution failed: skill=%s frame=%s err=%s",
                    tostring(runtime.skill and runtime.skill.skillId), tostring(frameCopy.frame), tostring(result)))
                return FinalizeRuntime(runtime, false)
            end
            frameCopy = MergeFrameResult(frameCopy, result)
            runtime.executed = true
            if type(frameCopy.damage) == "number" then
                runtime.context.totalDamage = runtime.context.totalDamage + frameCopy.damage
            end
            if type(frameCopy.healAmount) == "number" then
                runtime.context.totalHeal = runtime.context.totalHeal + frameCopy.healAmount
            end
        end

        BattleEvent.Publish(BattleVisualEvents.SKILL_TIMELINE_FRAME,
            BattleVisualEvents.BuildSkillTimelineFrame(runtime.hero, runtime.skill, frameCopy, runtime.nextFrameIndex))
        runtime.nextFrameIndex = runtime.nextFrameIndex + 1
    end

    if runtime.nextFrameIndex > #runtime.frames then
        return FinalizeRuntime(runtime, true)
    end

    return nil
end

function SkillTimeline.Reset()
    activeRuntime = nil
    lastCompletedResult = nil
end

function SkillTimeline.Start(hero, targets, skill, timeline, onComplete)
    if activeRuntime then
        return false, { totalDamage = 0, totalHeal = 0, succeeded = false, reason = "timeline_busy" }
    end

    local runtime, emptyResult = BuildRuntime(hero, targets, skill, timeline, onComplete)
    if not runtime then
        lastCompletedResult = emptyResult
        return false, emptyResult
    end

    activeRuntime = runtime
    lastCompletedResult = nil

    BattleEvent.Publish(BattleVisualEvents.SKILL_TIMELINE_STARTED,
        BattleVisualEvents.BuildSkillTimelineStarted(hero, skill, runtime.frames))

    local immediateResult = ExecuteDueFrames(runtime)
    if immediateResult then
        return true, immediateResult
    end

    return true, nil
end

function SkillTimeline.Update(deltaMs)
    if not activeRuntime then
        return nil
    end

    local runtime = activeRuntime
    local elapsed = deltaMs
    if type(elapsed) ~= "number" or elapsed <= 0 then
        elapsed = FRAME_DURATION_MS
    end

    runtime.elapsedMs = runtime.elapsedMs + elapsed
    local advancedFrames = math.floor(runtime.elapsedMs / FRAME_DURATION_MS)
    if advancedFrames <= 0 then
        return nil
    end

    runtime.elapsedMs = runtime.elapsedMs - (advancedFrames * FRAME_DURATION_MS)
    runtime.currentFrame = runtime.currentFrame + advancedFrames
    return ExecuteDueFrames(runtime)
end

function SkillTimeline.IsRunning()
    return activeRuntime ~= nil
end

function SkillTimeline.GetActiveHeroId()
    if not activeRuntime or not activeRuntime.hero then
        return nil
    end
    return activeRuntime.hero.instanceId or activeRuntime.hero.id
end

function SkillTimeline.GetLastCompletedResult()
    return lastCompletedResult
end

function SkillTimeline.Execute(hero, targets, skill, timeline)
    local started, result = SkillTimeline.Start(hero, targets, skill, timeline)
    if not started then
        return false, result
    end

    if result then
        return result.succeeded, result
    end

    while SkillTimeline.IsRunning() do
        SkillTimeline.Update(FRAME_DURATION_MS)
    end

    local completed = SkillTimeline.GetLastCompletedResult() or {
        totalDamage = 0,
        totalHeal = 0,
        succeeded = false,
    }
    return completed.succeeded, completed
end

return SkillTimeline
