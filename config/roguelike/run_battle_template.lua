---@class RunBattleTemplateEntry
---@field id integer
---@field code string
---@field name string
---@field kind string
---@field expReward integer
---@field waveCountMin integer
---@field waveCountMax integer
---@field refreshTurns integer
---@field refreshOnClear boolean
---@field spawnOrder string
---@field winRule string
---@field loseRule string
---@field encounterPoolId integer
---@field waveGroupPoolId integer
---@field bossRequired boolean|nil
---@field bossEnemyId integer|nil

---@class RunBattleTemplateModule
---@field TEMPLATES table<integer, RunBattleTemplateEntry>
---@field GetTemplate fun(templateId: integer): RunBattleTemplateEntry|nil

---@type RunBattleTemplateModule
local RunBattleTemplate = {}

---@type table<integer, RunBattleTemplateEntry>
RunBattleTemplate.TEMPLATES = {
    [201001] = {
        id = 201001,
        code = "act1_normal_early",
        name = "Act1 Normal Early",
        kind = "normal",
        expReward = 18,
        waveCountMin = 1,
        waveCountMax = 1,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        encounterPoolId = 301001,
        waveGroupPoolId = 401001,
    },
    [201002] = {
        id = 201002,
        code = "act1_normal_mid",
        name = "Act1 Normal Mid",
        kind = "normal",
        expReward = 24,
        waveCountMin = 1,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        encounterPoolId = 301002,
        waveGroupPoolId = 401002,
    },
    [201003] = {
        id = 201003,
        code = "act1_normal_late",
        name = "Act1 Normal Late",
        kind = "normal",
        expReward = 28,
        waveCountMin = 1,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        encounterPoolId = 301003,
        waveGroupPoolId = 401003,
    },
    [201101] = {
        id = 201101,
        code = "act1_elite_mid",
        name = "Act1 Elite Mid",
        kind = "elite",
        expReward = 36,
        waveCountMin = 2,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        encounterPoolId = 301101,
        waveGroupPoolId = 401101,
    },
    [201102] = {
        id = 201102,
        code = "act1_elite_late",
        name = "Act1 Elite Late",
        kind = "elite",
        expReward = 42,
        waveCountMin = 2,
        waveCountMax = 3,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        encounterPoolId = 301102,
        waveGroupPoolId = 401102,
    },
    [201201] = {
        id = 201201,
        code = "act1_boss",
        name = "Act1 Boss",
        kind = "boss",
        expReward = 60,
        waveCountMin = 2,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "boss_dead",
        loseRule = "all_hero_dead",
        encounterPoolId = 301201,
        waveGroupPoolId = 401201,
        bossRequired = true,
        bossEnemyId = 910006,
    },
    [201301] = {
        id = 201301,
        code = "act1_event_battle_skirmish",
        name = "Act1 Event Battle Skirmish",
        kind = "event_battle",
        expReward = 22,
        waveCountMin = 2,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        encounterPoolId = 301001,
        waveGroupPoolId = 401001,
    },
    [201302] = {
        id = 201302,
        code = "act1_event_battle_ritual",
        name = "Act1 Event Battle Ritual",
        kind = "event_battle",
        expReward = 26,
        waveCountMin = 2,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        encounterPoolId = 301002,
        waveGroupPoolId = 401002,
    },
}

function RunBattleTemplate.GetTemplate(templateId)
    return RunBattleTemplate.TEMPLATES[templateId]
end

return RunBattleTemplate
