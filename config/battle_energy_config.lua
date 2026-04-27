---@class BattleEnergyGains
---@field turnEnd integer
---@field normalHit integer
---@field activeHit integer
---@field ultimateHit integer
---@field kill integer
---@field crit integer
---@field block integer
---@field damageTakenBase integer
---@field damageTakenByLostHpRate integer

---@class BattleEnergyCaps
---@field singleDamageTaken integer
---@field singleSkillHit integer

---@alias BattleEnergyDamageKind
---| "direct"
---| "dot"
---| "reflect"
---| "splash"

---@class BattleEnergyClassModifier
---@field turnEndBonus integer
---@field skillHitBonus integer
---@field damageTakenScale number

---@class BattleEnergyConfig
---@field defaultMaxEnergy integer
---@field defaultInitialEnergy integer
---@field maxInitialEnergy integer
---@field skillCostDefault integer
---@field gains BattleEnergyGains
---@field caps BattleEnergyCaps
---@field damageKindScale table<BattleEnergyDamageKind, number>
---@field classModifiers table<integer, BattleEnergyClassModifier>

---@type BattleEnergyConfig
local BattleEnergyConfig = {
    defaultMaxEnergy = 100,
    defaultInitialEnergy = 50,
    maxInitialEnergy = 100,
    skillCostDefault = 100,
    gains = {
        turnEnd = 15,
        normalHit = 18,
        activeHit = 15,
        ultimateHit = 0,
        kill = 12,
        crit = 4,
        block = 3,
        damageTakenBase = 6,
        damageTakenByLostHpRate = 55,
    },
    caps = {
        singleDamageTaken = 18,
        singleSkillHit = 32,
    },
    damageKindScale = {
        direct = 1.0,
        dot = 0.3,
        reflect = 0.3,
        splash = 0.3,
    },
    classModifiers = {
        -- Front row: steadier turn-end gain and stronger damage-taken gain.
        [1] = {
            turnEndBonus = 2,
            skillHitBonus = 0,
            damageTakenScale = 1.25,
        },
        -- Mid row: baseline.
        [2] = {
            turnEndBonus = 0,
            skillHitBonus = 0,
            damageTakenScale = 1.0,
        },
        -- Back row: safer poke, weaker damage-taken gain.
        [3] = {
            turnEndBonus = 0,
            skillHitBonus = 3,
            damageTakenScale = 0.7,
        },
    },
}

return BattleEnergyConfig
