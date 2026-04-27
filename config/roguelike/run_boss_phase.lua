---@class RunBossPhaseModifiers
---@field bossDamagePct number|nil
---@field bossShieldPct number|nil
---@field bossSpeedPct number|nil
---@field bossControlChancePct number|nil
---@field playerHealTakenPct number|nil
---@field addMinionIds integer[]|nil

---@class RunBossPhaseWarning
---@field text string

---@class RunBossPhaseEntry
---@field phase integer
---@field hpThreshold number
---@field label string
---@field modifiers RunBossPhaseModifiers
---@field warning RunBossPhaseWarning|nil

---@class RunBossPhaseGroup
---@field id integer
---@field chapterId integer
---@field bossEncounterId integer
---@field phases RunBossPhaseEntry[]

---@class RunBossPhaseModule
---@field PHASE_GROUPS table<integer, RunBossPhaseGroup>
---@field GetGroup fun(groupId: integer): RunBossPhaseGroup|nil

---@type RunBossPhaseModule
local RunBossPhase = {}

---@type table<integer, RunBossPhaseGroup>
RunBossPhase.PHASE_GROUPS = {
    [101201] = {
        id = 101201,
        chapterId = 101,
        bossEncounterId = 101201,
        phases = {
            {
                phase = 1,
                hpThreshold = 1.00,
                label = "Frozen Watch",
                modifiers = {
                    bossDamagePct = 0.00,
                    bossShieldPct = 0.00,
                },
            },
            {
                phase = 2,
                hpThreshold = 0.70,
                label = "Shattered Ice",
                modifiers = {
                    bossDamagePct = 0.10,
                    bossSpeedPct = 0.08,
                    addMinionIds = { 910002 },
                },
                warning = {
                    text = "The gate cracks and cold winds surge.",
                },
            },
            {
                phase = 3,
                hpThreshold = 0.40,
                label = "Winter Execution",
                modifiers = {
                    bossDamagePct = 0.18,
                    bossControlChancePct = 0.15,
                    playerHealTakenPct = -0.20,
                },
                warning = {
                    text = "The demon enters a lethal frost frenzy.",
                },
            },
        },
    },
}

function RunBossPhase.GetGroup(groupId)
    return RunBossPhase.PHASE_GROUPS[groupId]
end

return RunBossPhase
