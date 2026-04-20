local RunChapterConfig = {}

RunChapterConfig.CHAPTERS = {
    [101] = {
        id = 101,
        code = "act_1",
        name = "Frostbound Pass",
        theme = "ruins_snowfield",
        floorCount = 7,
        startNodeId = 101001,
        bossNodeId = 101011,
        startGold = 100,
        startFood = 1,
        initialHeroCount = 3,
        maxHeroCount = 5,
        reviveLimit = 1,
        mapVision = "node_type_only",
        routeBlueprint = {
            [1] = { 101001 },
            [2] = { 101002, 101003 },
            [3] = { 101004, 101005 },
            [4] = { 101006, 101007 },
            [5] = { 101008, 101009 },
            [6] = { 101010 },
            [7] = { 101011 },
        },
        encounterPools = {
            normal = { 101001, 101002, 101003 },
            elite = { 101101, 101102 },
            boss = { 101201 },
            eventBattle = { 101103, 101104 },
        },
        rewardPools = {
            normal = 101001,
            elite = 101101,
            event = 101301,
            boss = 101201,
        },
        shopId = 101001,
        campId = 101001,
        chapterClearRewards = {
            gold = 90,
            healPct = 0.30,
            rewardGroupId = 101201,
        },
    },
}

function RunChapterConfig.GetChapter(chapterId)
    return RunChapterConfig.CHAPTERS[chapterId]
end

return RunChapterConfig
