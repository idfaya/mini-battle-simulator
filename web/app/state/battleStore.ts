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

function formatSigned(value: number) {
  return value >= 0 ? `+${value}` : String(value);
}

function readNumber(value: unknown, fallback = 0) {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : fallback;
}

function readRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null ? (value as Record<string, unknown>) : null;
}

function formatCheckRoll(value: unknown) {
  const roll = readRecord(value);
  if (!roll) {
    return null;
  }

  const d20 = readNumber(roll.roll);
  const bonus = readNumber(roll.bonus);
  const total = readNumber(roll.total);
  if ("targetAC" in roll) {
    return `攻击检定 d20 ${d20}${formatSigned(bonus)}=${total} vs AC ${readNumber(roll.targetAC)}`;
  }
  if ("dc" in roll) {
    return `豁免检定 d20 ${d20}${formatSigned(bonus)}=${total} vs DC ${readNumber(roll.dc)}`;
  }
  return null;
}

function formatDamageRoll(value: unknown) {
  const roll = readRecord(value);
  if (!roll) {
    return null;
  }

  const parts = Array.isArray(roll.parts) ? roll.parts : [];
  const partText = parts
    .map((part) => {
      const partRecord = readRecord(part);
      if (!partRecord) {
        return "";
      }
      const rolls = Array.isArray(partRecord.rolls) ? partRecord.rolls.map((item) => String(item)).join(",") : "";
      const bonus = readNumber(partRecord.bonus);
      return `[${rolls}]${bonus !== 0 ? formatSigned(bonus) : ""}`;
    })
    .filter(Boolean)
    .join(";");
  const expr = String(roll.expr ?? "dice");
  const total = readNumber(roll.total);
  return `伤害骰 ${expr}${partText ? ` ${partText}` : ""}=${total}`;
}

function formatRollSuffix(payload: Record<string, unknown>, includeDamage: boolean) {
  const parts = [
    formatCheckRoll(payload.attackRoll) ?? formatCheckRoll(payload.saveRoll),
    includeDamage ? formatDamageRoll(payload.damageRoll) : null,
  ].filter((part): part is string => Boolean(part));
  return parts.length > 0 ? `（${parts.join("；")}）` : "";
}

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
  private pendingCastResults = new Map<string, boolean>();

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
    const appendLog = (message: string) => {
      log.push(message);
    };
    const animations: AnimationEvent[] = [];
    let flashUntil = this.state.flashUntil;
    let banner = this.state.banner;

    for (const event of events) {
      switch (event.type) {
        case "turn_started":
          appendLog(
            `回合 ${String(event.payload.round ?? "")} - ${String(event.payload.heroName ?? "")} 行动（先攻骰 d20 ${readNumber(event.payload.initiativeRoll)}${formatSigned(readNumber(event.payload.initiativeMod))}=${readNumber(event.payload.initiativeTotal)}）`,
          );
          break;
        case "damage_dealt":
          this.markCastResult(event.payload.attackerId);
          appendLog(
            `${String(event.payload.attackerName ?? "")}${event.payload.skillName ? ` 的 ${String(event.payload.skillName)}` : ""} 对 ${String(event.payload.targetName ?? "")} 造成 ${String(event.payload.damage ?? 0)} 伤害${formatRollSuffix(event.payload, true)}`,
          );
          animations.push({
            type: "damage",
            heroId: String(event.payload.targetId ?? ""),
            value: Number(event.payload.damage ?? 0),
            critical: Boolean(event.payload.isCrit),
          });
          break;
        case "heal_received":
          this.markCastResult(event.payload.healerId);
          appendLog(`${String(event.payload.healerName ?? "")} 治疗 ${String(event.payload.targetName ?? "")} ${String(event.payload.healAmount ?? 0)}`);
          animations.push({
            type: "heal",
            heroId: String(event.payload.targetId ?? ""),
            value: Number(event.payload.healAmount ?? 0),
          });
          break;
        case "miss":
          this.markCastResult(event.payload.attackerId);
          appendLog(
            `${String(event.payload.attackerName ?? "")}${event.payload.skillName ? ` 的 ${String(event.payload.skillName)}` : ""} 对 ${String(event.payload.targetName ?? "")} 未命中${formatRollSuffix(event.payload, false)}`,
          );
          animations.push({
            type: "miss",
            heroId: String(event.payload.targetId ?? ""),
            text: "MISS",
          });
          break;
        case "dodge":
          this.markCastResult(event.payload.attackerId);
          appendLog(
            `${String(event.payload.targetName ?? "")} 闪避了 ${String(event.payload.attackerName ?? "")} 的攻击${formatRollSuffix(event.payload, false)}`,
          );
          animations.push({
            type: "miss",
            heroId: String(event.payload.targetId ?? ""),
            text: "DODGE",
          });
          break;
        case "skill_cast_started":
          this.pendingCastResults.set(String(event.payload.heroId ?? ""), false);
          appendLog(`${String(event.payload.heroName ?? "")} 使用 ${String(event.payload.skillName ?? "")}`);
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
          if (!this.pendingCastResults.get(String(event.payload.heroId ?? ""))) {
            appendLog(`${String(event.payload.heroName ?? "")} 的 ${String(event.payload.skillName ?? "")} 未产生效果`);
          }
          this.pendingCastResults.delete(String(event.payload.heroId ?? ""));
          break;
        case "ultimate_ready":
          appendLog(`${String(event.payload.heroName ?? "")} 大招已就绪`);
          break;
        case "ultimate_cast_queued":
          appendLog(`已下达大招指令: ${String(event.payload.heroId ?? "")}`);
          break;
        case "command_rejected":
          appendLog(`指令失效: ${String(event.payload.reason ?? "unknown")}`);
          break;
        case "battle_ended":
          appendLog(`战斗结束: ${String(event.payload.reason ?? "")}`);
          break;
        default:
          break;
      }
    }

    this.state = {
      ...this.state,
      log,
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

  private markCastResult(heroId: unknown) {
    const key = String(heroId ?? "");
    if (key !== "" && this.pendingCastResults.has(key)) {
      this.pendingCastResults.set(key, true);
    }
  }
}
