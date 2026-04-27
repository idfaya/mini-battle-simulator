---@alias BattleRhythmProfileKind
---| "normal"
---| "active"
---| "ultimate"

---@class BattleRhythmProfile
---@field impactFrame integer
---@field endFrame integer

---@class BattleRhythmTimeline
---@field fps integer
---@field maxKeyframes integer
---@field profiles table<BattleRhythmProfileKind, BattleRhythmProfile>

---@class BattleRhythmConfig
---@field logicStepMs integer
---@field postGapMs integer
---@field inputWindowMs integer
---@field damageScalar number
---@field healScalar number
---@field maxQueuedCommands integer
---@field speedPresets number[]
---@field timeline BattleRhythmTimeline

---@type BattleRhythmConfig
local BattleRhythmConfig = {
    logicStepMs = 80,
    postGapMs = 180,
    inputWindowMs = 900,
    damageScalar = 1.00,
    healScalar = 1.00,
    maxQueuedCommands = 4,
    speedPresets = { 0.5, 1, 2, 3 },
    timeline = {
        fps = 30,
        maxKeyframes = 8,
        profiles = {
            normal = {
                impactFrame = 24,
                endFrame = 36,
            },
            active = {
                impactFrame = 30,
                endFrame = 45,
            },
            ultimate = {
                impactFrame = 42,
                endFrame = 66,
            },
        },
    },
}

return BattleRhythmConfig
