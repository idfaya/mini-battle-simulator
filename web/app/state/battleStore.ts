import type { AnimationEvent, BattleEvent, BattleSnapshot } from "../types/battle";

export type BattleStoreState = {
  snapshot: BattleSnapshot | null;
  log: string[];
  animations: AnimationEvent[];
  flashUntil: number;
  banner: string | null;
};

type Listener = (state: BattleStoreState) => void;

export class BattleStore {
  private state: BattleStoreState = {
    snapshot: null,
    log: [],
    animations: [],
    flashUntil: 0,
    banner: null,
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
