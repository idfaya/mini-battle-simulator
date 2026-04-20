local RunRelicConfig = {}

-- trigger examples:
-- battle_start, battle_win, elite_win, ally_die, turn_start
RunRelicConfig.RELICS = {
    [101001] = {
        id = 101001,
        code = "ember_tinder",
        name = "Ember Tinder",
        rarity = "common",
        trigger = "battle_start",
        effectType = "team_energy_flat",
        params = {
            amount = 20,
        },
    },
    [101002] = {
        id = 101002,
        code = "caravan_tools",
        name = "Caravan Tools",
        rarity = "common",
        trigger = "battle_win",
        effectType = "bonus_gold_by_battle_kind",
        params = {
            normal = 15,
            elite = 25,
        },
    },
    [101003] = {
        id = 101003,
        code = "saint_bandage",
        name = "Saint Bandage",
        rarity = "rare",
        trigger = "elite_win",
        effectType = "team_heal_pct",
        params = {
            value = 0.12,
        },
    },
    [101004] = {
        id = 101004,
        code = "warbanner_hook",
        name = "Warbanner Hook",
        rarity = "rare",
        trigger = "battle_start",
        effectType = "class_attack_pct",
        params = {
            classIds = { 1, 3, 4 },
            value = 0.12,
        },
    },
    [101005] = {
        id = 101005,
        code = "frostward_charm",
        name = "Frostward Charm",
        rarity = "boss",
        trigger = "battle_start",
        effectType = "team_shield_pct_max_hp",
        params = {
            value = 0.10,
        },
    },
    [101006] = {
        id = 101006,
        code = "last_flame_censer",
        name = "Last Flame Censer",
        rarity = "boss",
        trigger = "ally_die",
        effectType = "team_attack_stack_pct",
        params = {
            value = 0.10,
            maxStacks = 2,
        },
    },
}

function RunRelicConfig.GetRelic(relicId)
    return RunRelicConfig.RELICS[relicId]
end

return RunRelicConfig
