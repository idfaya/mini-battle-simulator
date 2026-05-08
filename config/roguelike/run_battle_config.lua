---@alias RunBattleKind
---| "normal"
---| "elite"
---| "boss"
---| "event_battle"

---@class RunBattleEntry
---@field id integer
---@field chapterId integer
---@field code string
---@field kind RunBattleKind
---@field openingGroupId integer
---@field expReward integer
---@field reserveUnits integer[]
---@field refreshTurns integer
---@field refreshOnClear boolean
---@field spawnOrder string
---@field winRule string
---@field loseRule string
---@field bossId integer|nil

---@class RunBattleConfigModule
---@field BATTLES table<integer, RunBattleEntry>
---@field GetBattle fun(battleId: integer): RunBattleEntry|nil

---@type RunBattleConfigModule
local RunBattleConfig = {}

---@type table<integer, RunBattleEntry>
RunBattleConfig.BATTLES = {
    [101001] = {
        id = 101001,
        chapterId = 101,
        code = "frontier_scouts",
        kind = "normal",
        openingGroupId = 101001,
        expReward = 24,
        reserveUnits = { 910001 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
    },
    [101002] = {
        id = 101002,
        chapterId = 101,
        code = "snowfield_ambush",
        kind = "normal",
        openingGroupId = 101002,
        expReward = 20,
        reserveUnits = { 910002, 910001 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
    },
    [101003] = {
        id = 101003,
        chapterId = 101,
        code = "collapsed_bridge",
        kind = "normal",
        openingGroupId = 101003,
        expReward = 20,
        reserveUnits = { 910004, 910003, 910005 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
    },
    [101101] = {
        id = 101101,
        chapterId = 101,
        code = "bone_patrol",
        kind = "elite",
        openingGroupId = 101101,
        expReward = 42,
        reserveUnits = { 910004, 910003, 910002 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
    },
    [101102] = {
        id = 101102,
        chapterId = 101,
        code = "dark_cabal",
        kind = "elite",
        openingGroupId = 101102,
        expReward = 36,
        reserveUnits = { 910005, 910005, 910004 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
    },
    [101103] = {
        id = 101103,
        chapterId = 101,
        code = "frostbite_raid",
        kind = "event_battle",
        openingGroupId = 101103,
        expReward = 24,
        reserveUnits = { 910003, 910002 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
    },
    [101104] = {
        id = 101104,
        chapterId = 101,
        code = "ember_ambush",
        kind = "event_battle",
        openingGroupId = 101104,
        expReward = 24,
        reserveUnits = { 910003, 910002, 910001 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
    },
    [101201] = {
        id = 101201,
        chapterId = 101,
        code = "frozen_gate",
        kind = "boss",
        openingGroupId = 101201,
        expReward = 60,
        reserveUnits = { 910005, 910004, 910003, 910007 },
        refreshTurns = 2,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "boss_dead",
        loseRule = "all_hero_dead",
        bossId = 910007,
    },
}

function RunBattleConfig.GetBattle(battleId)
    return RunBattleConfig.BATTLES[battleId]
end

return RunBattleConfig
