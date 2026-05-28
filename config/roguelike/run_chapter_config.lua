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
---@field floorTemplateIds integer[]
---@field hiddenFloorTemplateId integer|nil
---@field startGold integer
---@field startFood integer
---@field targetMaxLevel integer
---@field initialHeroCount integer
---@field maxHeroCount integer
---@field reviveLimit integer
---@field mapGenProfileId integer|nil
---@field shopId integer
---@field campId integer
---@field chapterClearRewards RunChapterClearRewards
---@field postBattleRest RunChapterPostBattleRest

---@class RunChapterConfigModule
---@field CHAPTERS table<integer, RunChapterEntry>
---@field GetChapter fun(chapterId: integer): RunChapterEntry|nil

---@type RunChapterConfigModule
local RunChapterConfig = {}

local DEFAULT_POST_BATTLE_REST = {
    healPct = 0.20,
    clearCooldowns = true,
    restoreUltimateCharges = true,
    reviveDead = false,
}

local DEFAULT_CLEAR_REWARDS = {
    gold = 90,
    healPct = 0.00,
}

---@type table<integer, RunChapterEntry>
RunChapterConfig.CHAPTERS = {
    [101] = {
        id = 101,
        code = "act_1",
        name = "霜缚山道",
        theme = "ruins_snowfield",
        floorCount = 5,
        floorTemplateIds = { 10101, 10102, 10103, 10104, 10105 },
        hiddenFloorTemplateId = 10901,
        startGold = 100,
        startFood = 1,
        -- 普通怪 F1–F5 = Lv1–5；8 只定义章节常规节奏目标，Boss 单体额外等级由战斗桥接按总等级预算抬档。
        targetMaxLevel = 8,
        initialHeroCount = 4,
        maxHeroCount = 6,
        reviveLimit = 1,
        mapGenProfileId = 101001,
        shopId = 101001,
        campId = 101001,
        postBattleRest = DEFAULT_POST_BATTLE_REST,
        chapterClearRewards = DEFAULT_CLEAR_REWARDS,
    },
    [102] = {
        id = 102,
        code = "act_2",
        name = "灰烬幽谷",
        theme = "ruins_ashland",
        floorCount = 5,
        floorTemplateIds = { 10201, 10202, 10203, 10204, 10205 },
        hiddenFloorTemplateId = 10901,
        startGold = 100,
        startFood = 1,
        targetMaxLevel = 18,
        initialHeroCount = 4,
        maxHeroCount = 6,
        reviveLimit = 1,
        mapGenProfileId = 102001,
        shopId = 101001,
        campId = 101001,
        postBattleRest = DEFAULT_POST_BATTLE_REST,
        chapterClearRewards = DEFAULT_CLEAR_REWARDS,
    },
    [103] = {
        id = 103,
        code = "act_3",
        name = "深渊王座",
        theme = "abyss_throne",
        floorCount = 5,
        floorTemplateIds = { 10301, 10302, 10303, 10304, 10305 },
        hiddenFloorTemplateId = 10901,
        startGold = 100,
        startFood = 1,
        targetMaxLevel = 24,
        initialHeroCount = 4,
        maxHeroCount = 6,
        reviveLimit = 1,
        mapGenProfileId = 103001,
        shopId = 101001,
        campId = 101001,
        postBattleRest = DEFAULT_POST_BATTLE_REST,
        chapterClearRewards = DEFAULT_CLEAR_REWARDS,
    },
}

function RunChapterConfig.GetChapter(chapterId)
    return RunChapterConfig.CHAPTERS[chapterId]
end

return RunChapterConfig
