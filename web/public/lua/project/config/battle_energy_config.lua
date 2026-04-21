local BattleEnergyConfig = {
    defaultMaxEnergy = 100,
    defaultInitialEnergy = 20,
    maxInitialEnergy = 100,
    skillCostDefault = 100,
    gains = {
        turnEnd = 12,
        normalHit = 15,
        activeHit = 8,
        ultimateHit = 0,
        kill = 8,
        crit = 2,
        block = 3,
        damageTakenBase = 5,
        damageTakenByLostHpRate = 45,
    },
    caps = {
        singleDamageTaken = 14,
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
