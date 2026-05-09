---@alias RunChapterMapVision
---| "node_type_only"

---@class RunChapterEncounterPools
---@field normal integer[]
---@field elite integer[]
---@field boss integer[]
---@field eventBattle integer[]

---@class RunChapterClearRewards
---@field gold integer
---@field healPct number

---@class RunChapterPostBattleRest
---@field healPct number
---@field clearCooldowns boolean
---@field restoreUltimateCharges boolean
---@field reviveDead boolean

---@class RunChapterEntry
---@field id integer
---@field code string
---@field name string
---@field theme string
---@field floorCount integer
---@field startNodeId integer
---@field bossNodeId integer
---@field startGold integer
---@field startFood integer
---@field targetMaxLevel integer
---@field initialHeroCount integer
---@field maxHeroCount integer
---@field reviveLimit integer
---@field mapVision RunChapterMapVision
---@field mapGenProfileId integer|nil
---@field routeBlueprint table<integer, integer[]>
---@field encounterPools RunChapterEncounterPools
---@field shopId integer
---@field campId integer
---@field chapterClearRewards RunChapterClearRewards
---@field postBattleRest RunChapterPostBattleRest

---@class RunChapterConfigModule
---@field CHAPTERS table<integer, RunChapterEntry>
---@field GetChapter fun(chapterId: integer): RunChapterEntry|nil

---@type RunChapterConfigModule
local RunChapterConfig = {}

---@type table<integer, RunChapterEntry>
RunChapterConfig.CHAPTERS = {
    [101] = {
        id = 101,
        code = "act_1",
        name = "Frostbound Pass",
        theme = "ruins_snowfield",
        floorCount = 8,
        startNodeId = 101001,
        bossNodeId = 101011,
        startGold = 100,
        startFood = 1,
        targetMaxLevel = 8,
        initialHeroCount = 4,
        maxHeroCount = 6,
        reviveLimit = 1,
        mapVision = "node_type_only",
        mapGenProfileId = 101001,
        routeBlueprint = {
            [1] = { 101001 },
            [2] = { 101002, 101003 },
            [3] = { 101004, 101005 },
            [4] = { 101006, 101007 },
            [5] = { 101008, 101009 },
            [6] = { 101012, 101013 },
            [7] = { 101010 },
            [8] = { 101011 },
        },
        encounterPools = {
            normal = { 101001, 101002, 101003 },
            elite = { 101101, 101102 },
            boss = { 101201 },
            eventBattle = { 101103, 101104 },
        },
        shopId = 101001,
        campId = 101001,
        postBattleRest = {
            healPct = 0.02,
            clearCooldowns = true,
            restoreUltimateCharges = true,
            reviveDead = false,
        },
        chapterClearRewards = {
            gold = 90,
            healPct = 0.00,
        },
    },
}

function RunChapterConfig.GetChapter(chapterId)
    return RunChapterConfig.CHAPTERS[chapterId]
end

return RunChapterConfig
