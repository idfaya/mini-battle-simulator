local BattleRhythmConfig = {
    logicStepMs = 80,
    postGapMs = 180,
    inputWindowMs = 900,
    damageScalar = 13.50,
    healScalar = 0.07,
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
