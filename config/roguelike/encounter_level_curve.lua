-- Run 遭遇怪物等级：第一章 F1–F5 普通怪固定 Lv1–Lv5；精英/Boss 在楼层基线上加成。
local RunChapterConfig = require("config.roguelike.run_chapter_config")

---@class EncounterLevelCurveModule
---@field GetFloorCombatLevel fun(chapterId: integer, floorDepth: integer): integer
---@field GetFloorExpLevel fun(chapterId: integer, floorDepth: integer): integer
---@field GetFloorBaseline fun(chapterId: integer, floorDepth: integer): integer
---@field ResolveEnemyLevel fun(opts: table): integer

local M = {}

local function clampFloorDepth(chapterId, floorDepth)
    local chapter = RunChapterConfig.GetChapter(chapterId)
    local floors = math.max(1, math.floor(tonumber(chapter and chapter.floorCount) or 5))
    return math.max(1, math.min(floors, math.floor(tonumber(floorDepth) or 1)))
end

--- 胜利结算 EXP 用的怪物等级（第一章按楼层 1–5，与战斗普通怪一致）。
---@param chapterId integer
---@param floorDepth integer
---@return integer
function M.GetFloorExpLevel(chapterId, floorDepth)
    return M.GetFloorCombatLevel(chapterId, floorDepth)
end

---@param chapterId integer
---@param floorDepth integer
---@return integer
function M.GetFloorCombatLevel(chapterId, floorDepth)
    local depth = clampFloorDepth(chapterId, floorDepth)

    local chapter = RunChapterConfig.GetChapter(chapterId)
    local target = math.max(2, math.floor(tonumber(chapter and chapter.targetMaxLevel) or 12))
    local floors = math.max(1, math.floor(tonumber(chapter and chapter.floorCount) or 5))
    local startLevel = math.max(1, math.floor(target * 0.25 + 0.5))
    if chapterId == 101 then
        startLevel = 1
    end
    if floors <= 1 then
        return target
    end
    local t = (depth - 1) / (floors - 1)
    return math.max(1, math.floor(startLevel + (target - startLevel) * t + 0.5))
end

function M.GetFloorBaseline(chapterId, floorDepth)
    return M.GetFloorCombatLevel(chapterId, floorDepth)
end

function M.GetFloorTotalEnemyLevel(chapterId, floorDepth)
    local depth = clampFloorDepth(chapterId, floorDepth)
    -- 第一章：随楼层深度线性增长的总等级
    -- F1: 4, F2: 6, F3: 8, F4: 10, F5: 12
    if chapterId == 101 then
        return 2 + depth * 2
    end
    -- 其他章节按默认缩放
    local chapter = RunChapterConfig.GetChapter(chapterId)
    local target = math.max(2, math.floor(tonumber(chapter and chapter.targetMaxLevel) or 12))
    return depth * math.max(2, math.floor(target / 2))
end

---@class EncounterLevelResolveOptions
---@field chapterId integer|nil
---@field floorDepth integer|nil
---@field battleKind string|nil
---@field profileLevel integer|nil
---@field partyLevel integer|nil

---@param opts EncounterLevelResolveOptions
---@return integer effectiveEnemyLevel
function M.ResolveEnemyLevel(opts)
    opts = opts or {}
    local chapterId = tonumber(opts.chapterId) or 101
    local floorDepth = tonumber(opts.floorDepth) or 1
    local partyLevel = math.max(1, math.floor(tonumber(opts.partyLevel) or 1))
    local profileLevel = math.max(1, math.floor(tonumber(opts.profileLevel) or partyLevel))
    local battleKind = opts.battleKind or "normal"

    local floorBaseline = M.GetFloorCombatLevel(chapterId, floorDepth)

    local baseLevel = math.max(profileLevel, floorBaseline)

    local kindOffset = 0
    if chapterId == 101 then
        if battleKind == "elite" then
            kindOffset = 0
        elseif battleKind == "boss" then
            kindOffset = 1
        end
    else
        if battleKind == "elite" then
            kindOffset = 1
        elseif battleKind == "boss" then
            kindOffset = 2
        end
    end

    local minEnemyLevel = partyLevel - 1
    if battleKind == "normal" or battleKind == "event_battle" then
        minEnemyLevel = math.max(partyLevel - 4, floorBaseline - 2)
    elseif battleKind == "elite" then
        if chapterId == 101 then
            minEnemyLevel = math.max(partyLevel - 3, floorBaseline - 2)
        else
            minEnemyLevel = math.max(partyLevel - 2, floorBaseline - 1)
        end
    elseif battleKind == "boss" then
        if chapterId == 101 then
            minEnemyLevel = math.max(partyLevel - 3, floorBaseline - 1)
        else
            minEnemyLevel = math.max(partyLevel - 3, floorBaseline)
        end
    end
    minEnemyLevel = math.max(1, minEnemyLevel)

    local maxEnemyLevel = math.max(partyLevel + 1 + kindOffset, floorBaseline + kindOffset)
    if baseLevel < minEnemyLevel then
        baseLevel = minEnemyLevel
    end
    if baseLevel > maxEnemyLevel then
        baseLevel = maxEnemyLevel
    end
    return math.max(1, baseLevel)
end

return M
