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
---@field waveGroupIds integer[]|nil
---@field expReward integer
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
        waveGroupIds = { 101001, 201001 },
        expReward = 24,
        refreshTurns = 0,
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
        waveGroupIds = { 101002, 201002 },
        expReward = 20,
        refreshTurns = 0,
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
        waveGroupIds = { 101003, 201003, 201004 },
        expReward = 20,
        refreshTurns = 0,
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
        waveGroupIds = { 101101, 201101 },
        expReward = 42,
        refreshTurns = 0,
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
        waveGroupIds = { 101102, 201102 },
        expReward = 36,
        refreshTurns = 0,
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
        waveGroupIds = { 101103, 201103 },
        expReward = 24,
        refreshTurns = 0,
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
        waveGroupIds = { 101104, 201104 },
        expReward = 24,
        refreshTurns = 0,
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
        waveGroupIds = { 101201, 201201 },
        expReward = 60,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        bossId = 910007,
    },
}

function RunBattleConfig.GetBattle(battleId)
    return RunBattleConfig.BATTLES[battleId]
end

return RunBattleConfig
