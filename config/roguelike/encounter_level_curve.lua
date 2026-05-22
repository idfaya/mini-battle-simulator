-- Run 遭遇怪物等级：按章节楼层推进（第一章 F1–F5 对应怪物 Lv1–Lv5）。
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

--- 胜利结算 EXP 用的怪物等级（第一章与战斗等级一致：楼层 = 等级）。
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

    if chapterId == 101 then
        return depth
    end

    local chapter = RunChapterConfig.GetChapter(chapterId)
    local target = math.max(2, math.floor(tonumber(chapter and chapter.targetMaxLevel) or 12))
    local floors = math.max(1, math.floor(tonumber(chapter and chapter.floorCount) or 5))
    local startLevel = math.max(2, math.floor(target * 0.35 + 0.5))
    if floors <= 1 then
        return target
    end
    local t = (depth - 1) / (floors - 1)
    return math.max(1, math.floor(startLevel + (target - startLevel) * t + 0.5))
end

function M.GetFloorBaseline(chapterId, floorDepth)
    return M.GetFloorCombatLevel(chapterId, floorDepth)
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
    if battleKind == "elite" then
        kindOffset = 1
    elseif battleKind == "boss" then
        kindOffset = 2
    end

    local minEnemyLevel = partyLevel - 1
    if battleKind == "normal" or battleKind == "event_battle" then
        minEnemyLevel = math.max(partyLevel - 4, floorBaseline - 2)
    elseif battleKind == "elite" then
        minEnemyLevel = math.max(partyLevel - 2, floorBaseline - 1)
    elseif battleKind == "boss" then
        minEnemyLevel = math.max(partyLevel - 3, floorBaseline)
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
