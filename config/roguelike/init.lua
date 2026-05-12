local RoguelikeConfig = {
    Chapter = require("config.roguelike.run_chapter_config"),
    MapGenProfiles = require("config.roguelike.run_map_gen_profile"),
    Nodes = require("config.roguelike.run_node_pool"),
    Battles = require("config.roguelike.run_battle_config"),
    BattlePools = require("config.roguelike.run_battle_pool"),
    BattleTemplates = require("config.roguelike.run_battle_template"),
    EnemyGroups = require("config.roguelike.run_enemy_group"),
    BattleProfiles = require("config.roguelike.run_battle_profile"),
    WaveGroups = require("config.roguelike.run_wave_group_pool"),
    Formations = require("config.roguelike.run_formation_profile"),
    EnemyPickPools = require("config.roguelike.run_enemy_pick_pool"),
    Rewards = require("config.roguelike.run_reward_pool"),
    Equipments = require("config.roguelike.run_equipment_config"),
    Blessings = require("config.roguelike.run_blessing_config"),
    Events = require("config.roguelike.run_event_config"),
    Shop = require("config.roguelike.run_shop_goods"),
    Camp = require("config.roguelike.run_camp_config"),
    BossPhases = require("config.roguelike.run_boss_phase"),
}

return RoguelikeConfig
