import type { BattleEvent } from "../types/battle";

const TYPE_MAP: Record<string, string> = {
  BattleStarted: "battle_started",
  BattleEnded: "battle_ended",
  TurnStarted: "turn_started",
  TurnEnded: "turn_ended",
  TurnSkipped: "turn_skipped",
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
  CombatLog: "combat_log",
  PassiveSkillTriggered: "passive_skill_triggered",
};

export function normalizeEvent(event: BattleEvent): BattleEvent {
  // #region debug-point B:event-bridge
  if (event.type === "DamageDealt" || event.type === "PassiveSkillTriggered" || event.type === "CombatLog") {
    fetch("http://127.0.0.1:7777/event", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sessionId: "cleric-shelter-damage",
        runId: "pre-fix",
        hypothesisId: "B",
        location: "web/app/lua/eventBridge.ts:normalizeEvent",
        msg: "[DEBUG] normalizeEvent received battle event",
        data: {
          rawType: event.type,
          mappedType: TYPE_MAP[event.type] ?? event.type,
          skillId: (event.payload as { skillId?: unknown } | undefined)?.skillId ?? null,
          skillName: (event.payload as { skillName?: unknown } | undefined)?.skillName ?? null,
          heroName: (event.payload as { heroName?: unknown } | undefined)?.heroName ?? null,
          attackerName: (event.payload as { attackerName?: unknown } | undefined)?.attackerName ?? null,
          targetName: (event.payload as { targetName?: unknown } | undefined)?.targetName ?? null,
          damage: (event.payload as { damage?: unknown } | undefined)?.damage ?? null,
          message: (event.payload as { message?: unknown } | undefined)?.message ?? null,
        },
        ts: Date.now(),
      }),
    }).catch(() => {});
  }
  // #endregion
  return {
    ...event,
    type: TYPE_MAP[event.type] ?? event.type,
  };
}
