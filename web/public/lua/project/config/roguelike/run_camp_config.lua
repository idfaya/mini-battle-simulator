local RunCampConfig = {}

RunCampConfig.CAMPS = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        code = "campfire_shrine",
        name = "Campfire Shrine",
        actions = {
            {
                id = 1,
                label = "Rest",
                effectType = "team_heal_pct",
                params = {
                    value = 0.22,
                },
            },
            {
                id = 2,
                label = "Sharpen",
                effectType = "grant_blessing",
                params = {
                    blessingId = 101002,
                },
            },
            {
                id = 3,
                label = "Revive",
                effectType = "revive_one",
                params = {
                    healPct = 0.30,
                },
                requirements = {
                    hasDeadHero = true,
                },
            },
        },
    },
}

function RunCampConfig.GetCamp(campId)
    return RunCampConfig.CAMPS[campId]
end

return RunCampConfig
