---@class RunBattleTemplateBattleEntry
---@field battleId integer
---@field weight integer

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
---@field battleEntries RunBattleTemplateBattleEntry[]
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
        -- 第一章 F1 普通：单波，避免 1 战 EXP 跨多个 partyLevel 阈值。
        expReward = 20,
        waveCountMin = 1,
        waveCountMax = 1,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101001, weight = 100 },
        },
        waveGroupPoolId = 401001,
    },
    [201002] = {
        id = 201002,
        code = "act1_normal_mid",
        name = "Act1 Normal Mid",
        kind = "normal",
        -- 中期普通：从 3 波降到 2 波，缓和单战 baseXp 通胀。
        expReward = 14,
        waveCountMin = 1,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101002, weight = 60 },
            { battleId = 101003, weight = 25 },
            { battleId = 101104, weight = 15 },
        },
        waveGroupPoolId = 401002,
    },
    [201003] = {
        id = 201003,
        code = "act1_normal_late",
        name = "Act1 Normal Late",
        kind = "normal",
        -- 晚期普通：从 3 波降到 2 波；保留更高 baseLevel pressure。
        expReward = 10,
        waveCountMin = 2,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101104, weight = 100 },
        },
        waveGroupPoolId = 401003,
    },
    [201101] = {
        id = 201101,
        code = "act1_elite_mid",
        name = "Act1 Elite Mid",
        kind = "elite",
        expReward = 16,
        -- 阶段 1 修复：早期 elite 在 economy-heavy 路线（F3/F4 跳过战斗）时玩家
        -- 仅 partyLevel≈4，多波累积 ≥8 个怪足以 wipe。统一为单波 4 怪：仍保持
        -- 高 CR 怪物的精英压强，但不会因数量碾压低战力路线。
        waveCountMin = 1,
        waveCountMax = 1,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101101, weight = 100 },
        },
        waveGroupPoolId = 401101,
    },
    [201102] = {
        id = 201102,
        code = "act1_elite_late",
        name = "Act1 Elite Late",
        kind = "elite",
        expReward = 12,
        -- 阶段 1 修复：与 201101 同因，将 wave 数下调到 1，避免 economy-heavy 路线
        -- 在 F5 第一个 elite 必然 wipe；保留更高 baseLevel/pressure 以体现"late"。
        waveCountMin = 1,
        waveCountMax = 1,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101101, weight = 35 },
            { battleId = 101102, weight = 65 },
        },
        waveGroupPoolId = 401102,
    },
    [201201] = {
        id = 201201,
        code = "act1_boss",
        name = "Act1 Boss",
        kind = "boss",
        expReward = 14,
        waveCountMin = 2,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101201, weight = 100 },
        },
        waveGroupPoolId = 401201,
        bossRequired = true,
        bossEnemyId = 910006,
    },
    [201301] = {
        id = 201301,
        code = "act1_event_battle_skirmish",
        name = "Act1 Event Battle Skirmish",
        kind = "event_battle",
        expReward = 12,
        waveCountMin = 1,
        waveCountMax = 1,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101001, weight = 100 },
        },
        waveGroupPoolId = 401001,
    },
    [201302] = {
        id = 201302,
        code = "act1_event_battle_ritual",
        name = "Act1 Event Battle Ritual",
        kind = "event_battle",
        expReward = 10,
        waveCountMin = 1,
        waveCountMax = 2,
        refreshTurns = 0,
        refreshOnClear = true,
        spawnOrder = "back_first_then_front",
        winRule = "reserve_empty_and_board_clear",
        loseRule = "all_hero_dead",
        battleEntries = {
            { battleId = 101002, weight = 60 },
            { battleId = 101003, weight = 25 },
            { battleId = 101104, weight = 15 },
        },
        waveGroupPoolId = 401002,
    },
}

function RunBattleTemplate.GetTemplate(templateId)
    return RunBattleTemplate.TEMPLATES[templateId]
end

return RunBattleTemplate
