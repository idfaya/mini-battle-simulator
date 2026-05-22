-- Run 遭遇怪物等级：战斗缩放与胜利 EXP 可分层（第一章前几层战斗偏低、EXP 按目标抬高）。
local RunChapterConfig = require("config.roguelike.run_chapter_config")

---@class EncounterLevelCurveModule
---@field GetFloorCombatLevel fun(chapterId: integer, floorDepth: integer): integer
---@field GetFloorExpLevel fun(chapterId: integer, floorDepth: integer): integer
---@field GetFloorBaseline fun(chapterId: integer, floorDepth: integer): integer
---@field ResolveEnemyLevel fun(opts: table): integer

local M = {}

---@param chapterId integer
---@param floorDepth integer
---@return integer
function M.GetFloorExpLevel(chapterId, floorDepth)
    local chapter = RunChapterConfig.GetChapter(chapterId)
    local target = math.max(2, math.floor(tonumber(chapter and chapter.targetMaxLevel) or 12))
    local floors = math.max(1, math.floor(tonumber(chapter and chapter.floorCount) or 5))
    local depth = math.max(1, math.min(floors, math.floor(tonumber(floorDepth) or 1)))

    if chapterId == 101 then
        local act1Exp = { 10, 12, 14, 16, 18 }
        return act1Exp[depth] or act1Exp[#act1Exp]
    end

    local startLevel = math.max(2, math.floor(target * 0.35 + 0.5))
    if floors <= 1 then
        return target
    end
    local t = (depth - 1) / (floors - 1)
    return math.max(1, math.floor(startLevel + (target - startLevel) * t + 0.5))
end

---@param chapterId integer
---@param floorDepth integer
---@return integer
function M.GetFloorCombatLevel(chapterId, floorDepth)
    if chapterId == 101 then
        local floors = math.max(1, math.floor(tonumber(RunChapterConfig.GetChapter(101).floorCount) or 5))
        local depth = math.max(1, math.min(floors, math.floor(tonumber(floorDepth) or 1)))
        local act1Combat = { 2, 5, 10, 14, 17 }
        return act1Combat[depth] or act1Combat[#act1Combat]
    end
    return M.GetFloorExpLevel(chapterId, floorDepth)
end

--- 战斗缩放用楼层基线（同 GetFloorCombatLevel）。
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
