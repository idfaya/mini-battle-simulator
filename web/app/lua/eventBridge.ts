import type { BattleEvent } from "../types/battle";

const TYPE_MAP: Record<string, string> = {
  BattleStarted: "battle_started",
  BattleEnded: "battle_ended",
  TurnStarted: "turn_started",
  TurnEnded: "turn_ended",
  SkillCastStarted: "skill_cast_started",
  SkillCastCompleted: "skill_cast_completed",
  SkillTimelineStarted: "skill_timeline_started",
  SkillTimelineFrame: "skill_timeline_frame",
  SkillTimelineCompleted: "skill_timeline_completed",
  DamageDealt: "damage_dealt",
  HealReceived: "heal_received",
  BuffAdded: "buff_added",
  BuffRemoved: "buff_removed",
  BuffStackChanged: "buff_stack_changed",
  HeroStateChanged: "hero_state_changed",
  HeroDied: "hero_died",
  HeroRevived: "hero_revived",
  EnergyChanged: "energy_changed",
  ActionOrderChanged: "action_order_changed",
  Dodge: "dodge",
  Miss: "miss",
  Block: "block",
  Crit: "crit",
  Victory: "victory",
  Draw: "draw",
  Defeat: "defeat",
};

export function normalizeEvent(event: BattleEvent): BattleEvent {
  return {
    ...event,
    type: TYPE_MAP[event.type] ?? event.type,
  };
}
