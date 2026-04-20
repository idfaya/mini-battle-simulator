local RunBlessingConfig = {}

RunBlessingConfig.BLESSINGS = {
    [101001] = {
        id = 101001,
        code = "frontline_discipline",
        name = "Frontline Discipline",
        rarity = "common",
        scope = "class",
        effectType = "class_stat_pct",
        params = {
            classIds = { 1, 2, 3, 4, 5 },
            hpPct = 0.12,
            defPct = 0.10,
        },
    },
    [101002] = {
        id = 101002,
        code = "burst_rhythm",
        name = "Burst Rhythm",
        rarity = "common",
        scope = "team",
        effectType = "turn_start_energy",
        params = {
            rounds = 2,
            amount = 8,
        },
    },
    [101003] = {
        id = 101003,
        code = "holy_reserve",
        name = "Holy Reserve",
        rarity = "rare",
        scope = "class",
        effectType = "class_heal_bonus_pct",
        params = {
            classIds = { 6 },
            value = 0.20,
            overhealShieldPct = 0.25,
        },
    },
    [101004] = {
        id = 101004,
        code = "venom_spark",
        name = "Venom Spark",
        rarity = "rare",
        scope = "class",
        effectType = "class_dot_damage_pct",
        params = {
            classIds = { 5, 7, 8, 9 },
            value = 0.25,
        },
    },
    [101005] = {
        id = 101005,
        code = "pursuit_instinct",
        name = "Pursuit Instinct",
        rarity = "rare",
        scope = "class",
        effectType = "extra_follow_up_trigger",
        params = {
            classIds = { 1, 3 },
            perRoundLimit = 1,
        },
    },
    [101006] = {
        id = 101006,
        code = "elite_hunter",
        name = "Elite Hunter",
        rarity = "boss",
        scope = "team",
        effectType = "damage_pct_vs_monster_type",
        params = {
            monsterTypes = { 1, 2 },
            value = 0.12,
        },
    },
    [101007] = {
        id = 101007,
        code = "winter_breath",
        name = "Winter Breath",
        rarity = "boss",
        scope = "team",
        effectType = "battle_start_apply_shield_and_resist",
        params = {
            shieldPct = 0.08,
            controlResistPct = 0.18,
        },
    },
}

function RunBlessingConfig.GetBlessing(blessingId)
    return RunBlessingConfig.BLESSINGS[blessingId]
end

return RunBlessingConfig
