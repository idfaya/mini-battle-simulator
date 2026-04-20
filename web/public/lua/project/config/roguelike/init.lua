local RoguelikeConfig = {
    Chapter = require("config.roguelike.run_chapter_config"),
    Nodes = require("config.roguelike.run_node_pool"),
    Encounters = require("config.roguelike.run_encounter_group"),
    Rewards = require("config.roguelike.run_reward_pool"),
    Relics = require("config.roguelike.run_relic_config"),
    Blessings = require("config.roguelike.run_blessing_config"),
    Events = require("config.roguelike.run_event_config"),
    Shop = require("config.roguelike.run_shop_goods"),
    Camp = require("config.roguelike.run_camp_config"),
    BossPhases = require("config.roguelike.run_boss_phase"),
}

return RoguelikeConfig
