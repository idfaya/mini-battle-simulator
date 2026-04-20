import type { AnimationEvent, BattleEvent, BattleSnapshot } from "../types/battle";

export type BattleStoreState = {
  snapshot: BattleSnapshot | null;
  log: string[];
  animations: AnimationEvent[];
  flashUntil: number;
  banner: string | null;
  runContext: {
    chapterLabel: string;
    nodeTitle: string;
    gold: number;
    relicCount: number;
    blessingCount: number;
  } | null;
};

type Listener = (state: BattleStoreState) => void;

export class BattleStore {
  private state: BattleStoreState = {
    snapshot: null,
    log: [],
    animations: [],
    flashUntil: 0,
    banner: null,
    runContext: null,
  };

  private listeners = new Set<Listener>();

  subscribe(listener: Listener) {
    this.listeners.add(listener);
    listener(this.state);
    return () => this.listeners.delete(listener);
  }

  getState() {
    return this.state;
  }

  setSnapshot(snapshot: BattleSnapshot) {
    this.state = { ...this.state, snapshot };
    this.emit();
  }

  setRunContext(runContext: BattleStoreState["runContext"]) {
    this.state = { ...this.state, runContext };
    this.emit();
  }

  appendEvents(events: BattleEvent[]) {
    if (events.length === 0) {
      return;
    }

    const log = [...this.state.log];
    const animations: AnimationEvent[] = [];
    let flashUntil = this.state.flashUntil;
    let banner = this.state.banner;

    for (const event of events) {
      switch (event.type) {
        case "turn_started":
          log.unshift(`回合 ${String(event.payload.round ?? "")} - ${String(event.payload.heroName ?? "")} 行动`);
          break;
        case "damage_dealt":
          log.unshift(`${String(event.payload.attackerName ?? "")} 对 ${String(event.payload.targetName ?? "")} 造成 ${String(event.payload.damage ?? 0)} 伤害`);
          animations.push({
            type: "damage",
            heroId: String(event.payload.targetId ?? ""),
            value: Number(event.payload.damage ?? 0),
            critical: Boolean(event.payload.isCrit),
          });
          break;
        case "heal_received":
          log.unshift(`${String(event.payload.healerName ?? "")} 治疗 ${String(event.payload.targetName ?? "")} ${String(event.payload.healAmount ?? 0)}`);
          animations.push({
            type: "heal",
            heroId: String(event.payload.targetId ?? ""),
            value: Number(event.payload.healAmount ?? 0),
          });
          break;
        case "skill_cast_started":
          banner = `${String(event.payload.heroName ?? "")} · ${String(event.payload.skillName ?? "")}`;
          flashUntil = performance.now() + 200;
          break;
        case "skill_timeline_started":
          animations.push({
            type: "timeline_started",
            heroId: String(event.payload.heroId ?? ""),
            heroName: String(event.payload.heroName ?? ""),
            skillName: String(event.payload.skillName ?? ""),
            totalFrames: Number(event.payload.totalFrames ?? 0),
          });
          log.unshift(`${String(event.payload.heroName ?? "")} 开始演出 ${String(event.payload.skillName ?? "")}`);
          break;
        case "skill_timeline_frame":
          animations.push({
            type: "timeline_frame",
            heroId: String(event.payload.heroId ?? ""),
            heroName: String(event.payload.heroName ?? ""),
            skillName: String(event.payload.skillName ?? ""),
            frame: Number(event.payload.frame ?? 0),
            frameIndex: Number(event.payload.frameIndex ?? 0),
            op: String(event.payload.op ?? ""),
            effect: String(event.payload.effect ?? ""),
            targetIds: Array.isArray(event.payload.targets)
              ? event.payload.targets
                  .map((target) =>
                    typeof target === "object" && target !== null && "id" in target
                      ? String((target as { id?: unknown }).id ?? "")
                      : "",
                  )
                  .filter((id) => id !== "")
              : [],
          });
          break;
        case "skill_timeline_completed":
          animations.push({
            type: "timeline_completed",
            heroId: String(event.payload.heroId ?? ""),
            heroName: String(event.payload.heroName ?? ""),
            skillName: String(event.payload.skillName ?? ""),
            totalFrames: Number(event.payload.totalFrames ?? 0),
            totalDamage: Number(event.payload.totalDamage ?? 0),
            succeeded: Boolean(event.payload.succeeded),
          });
          log.unshift(`${String(event.payload.heroName ?? "")} 完成演出 ${String(event.payload.skillName ?? "")}`);
          break;
        case "ultimate_ready":
          log.unshift(`${String(event.payload.heroName ?? "")} 大招已就绪`);
          break;
        case "ultimate_cast_queued":
          log.unshift(`已下达大招指令: ${String(event.payload.heroId ?? "")}`);
          break;
        case "command_rejected":
          log.unshift(`指令失效: ${String(event.payload.reason ?? "unknown")}`);
          break;
        case "battle_ended":
          log.unshift(`战斗结束: ${String(event.payload.reason ?? "")}`);
          break;
        default:
          break;
      }
    }

    this.state = {
      ...this.state,
      log: log.slice(0, 16),
      animations,
      flashUntil,
      banner,
    };
    this.emit();
  }

  clearTransient(now: number) {
    const banner = this.state.flashUntil > now ? this.state.banner : null;
    this.state = {
      ...this.state,
      banner,
      animations: [],
    };
  }

  private emit() {
    for (const listener of this.listeners) {
      listener(this.state);
    }
  }
}
