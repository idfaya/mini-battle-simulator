import type { AnimationEvent, BattleEvent, BattleSnapshot } from "../types/battle";
import {
  formatRollSuffix,
  formatSigned,
  isSkillColoredDamagePayload,
  mergeDamageEventPayload,
  readNumber,
  shouldMergeDamagePayload,
} from "./rollFormat";
import {
  buildTopBarBriefsFromPayload,
  extractTopBarBriefsFromCombatLog,
  withMultiTargetAnnotation,
} from "./skillBrief";

export type BattleStoreState = {
  snapshot: BattleSnapshot | null;
  log: string[];
  animations: AnimationEvent[];
  flashUntil: number;
  skillCasting: boolean;
  skillBrief: string | null;
  damageBrief: string | null;
  runContext: {
    chapterLabel: string;
    nodeTitle: string;
    gold: number;
    equipmentCount: number;
    blessingCount: number;
  } | null;
};

type Listener = (state: BattleStoreState) => void;

const SKILL_BRIEF_HOLD_MS = 3200;
const SKILL_CASTING_HOLD_MS = 6000;

function buildCastingBrief(skillName: unknown) {
  const name = String(skillName ?? "").trim();
  return name ? `${name} 释放中` : "释放中";
}

function isDamageAnimation(event: AnimationEvent | undefined): event is Extract<AnimationEvent, { type: "damage" }> {
  return event?.type === "damage";
}

function shouldMergeBasicAttackSkillDamage(
  previous: AnimationEvent | undefined,
  current: Extract<AnimationEvent, { type: "damage" }>,
) {
  if (!isDamageAnimation(previous)) {
    return false;
  }
  return shouldMergeDamagePayload(
    {
      targetId: previous.heroId,
      attackerId: previous.attackerId,
      isBasicAttack: previous.basicAttack === true,
      preferSkillColor: previous.preferSkillColor === true,
    },
    {
      targetId: current.heroId,
      attackerId: current.attackerId,
      isBasicAttack: current.basicAttack === true,
      preferSkillColor: current.preferSkillColor === true,
    },
  );
}

function pushAnimationEvent(animations: AnimationEvent[], event: AnimationEvent) {
  if (event.type === "damage" && shouldMergeBasicAttackSkillDamage(animations[animations.length - 1], event)) {
    const previous = animations[animations.length - 1] as Extract<AnimationEvent, { type: "damage" }>;
    previous.value += event.value;
    previous.critical = previous.critical || event.critical;
    previous.preferSkillColor = true;
    if (!previous.skillName && event.skillName) {
      previous.skillName = event.skillName;
    }
    return;
  }
  animations.push(event);
}

export class BattleStore {
  private state: BattleStoreState = {
    snapshot: null,
    log: [],
    animations: [],
    flashUntil: 0,
    skillCasting: false,
    skillBrief: null,
    damageBrief: null,
    runContext: null,
  };

  private listeners = new Set<Listener>();
  private pendingCastResults = new Map<string, boolean>();
  private pendingCastLogIndex = new Map<string, number>();

  subscribe(listener: Listener) {
    this.listeners.add(listener);
    listener(this.state);
    return () => this.listeners.delete(listener);
  }

  getState() {
    return this.state;
  }

  resetBattleState() {
    this.pendingCastResults.clear();
    this.pendingCastLogIndex.clear();
    this.state = {
      ...this.state,
      log: [],
      animations: [],
      flashUntil: 0,
      skillCasting: false,
      skillBrief: null,
      damageBrief: null,
    };
    this.emit();
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
    const replaceCastOrAppend = (heroId: unknown, message: string) => {
      const key = String(heroId ?? "");
      if (key !== "") {
        const index = this.pendingCastLogIndex.get(key);
        if (index !== undefined && index >= 0 && index < log.length) {
          log[index] = message;
          this.pendingCastLogIndex.delete(key);
          return;
        }
        this.pendingCastLogIndex.delete(key);
      }
      log.push(message);
    };
    const animations: AnimationEvent[] = [];
    let flashUntil = this.state.flashUntil;
    let skillCasting = this.state.skillCasting;
    let skillBrief = this.state.skillBrief;
    let damageBrief = this.state.damageBrief;
    let topBarResolveIndex = 0;
    let pendingMergedDamagePayload: Record<string, unknown> | null = null;

    const resetTopBarResolveIndex = () => {
      topBarResolveIndex = 0;
    };

    const buildResolveTopBarBriefs = (
      payload: Record<string, unknown>,
      options?: { includeDamage?: boolean },
    ) => {
      topBarResolveIndex += 1;
      return withMultiTargetAnnotation(buildTopBarBriefsFromPayload(payload, options), topBarResolveIndex);
    };

    const beginSkillCast = (skillName: unknown, holdMs = SKILL_CASTING_HOLD_MS) => {
      skillCasting = true;
      skillBrief = buildCastingBrief(skillName);
      damageBrief = null;
      resetTopBarResolveIndex();
      flashUntil = Math.max(flashUntil, performance.now() + holdMs);
    };

    const touchTopBarBriefs = (
      nextBriefs: { skillBrief?: string | null; damageBrief?: string | null },
      holdMs = SKILL_BRIEF_HOLD_MS,
    ) => {
      skillCasting = false;
      if (nextBriefs.skillBrief !== undefined) {
        skillBrief = nextBriefs.skillBrief;
      } else if (nextBriefs.damageBrief && skillBrief?.endsWith(" 释放中")) {
        skillBrief = null;
      }
      if (nextBriefs.damageBrief !== undefined) {
        damageBrief = nextBriefs.damageBrief;
      }
      if (nextBriefs.skillBrief || nextBriefs.damageBrief) {
        flashUntil = Math.max(flashUntil, performance.now() + holdMs);
      }
    };

    for (const event of events) {
      if (event.type === "DebugCounterTiming") {
        const stage = String(event.payload.stage ?? "");
        const debugData =
          typeof event.payload.data === "object" && event.payload.data !== null
            ? (event.payload.data as Record<string, unknown>)
            : null;
        const reactorId = String(debugData?.reactorId ?? "");
        const guardId = String(debugData?.guardId ?? "");
        const attackerId = String(debugData?.attackerId ?? "");
        if (stage === "queue_counter_basic" && reactorId !== "" && attackerId !== "") {
          animations.push({
            type: "combat_cue",
            heroId: reactorId,
            targetId: attackerId,
            cue: "counter_queue",
          });
        } else if (stage === "queue_guard_counter" && guardId !== "" && attackerId !== "") {
          animations.push({
            type: "combat_cue",
            heroId: guardId,
            targetId: attackerId,
            sourceTargetId: String(debugData?.defenderId ?? ""),
            cue: "guard_counter_queue",
          });
        }
      }
      switch (event.type) {
        case "battle_started":
          this.pendingCastResults.clear();
          this.pendingCastLogIndex.clear();
          log.length = 0;
          animations.length = 0;
          flashUntil = 0;
          skillCasting = false;
          skillBrief = null;
          damageBrief = null;
          resetTopBarResolveIndex();
          pendingMergedDamagePayload = null;
          appendLog("战斗开始");
          break;
        case "combat_log":
          if (typeof event.payload.message === "string" && event.payload.message !== "") {
            appendLog(event.payload.message);
            const parsedBriefs = extractTopBarBriefsFromCombatLog(event.payload.message);
            if (parsedBriefs) {
              touchTopBarBriefs(parsedBriefs);
            }
          }
          if (
            typeof event.payload.message === "string" &&
            event.payload.message.includes("触发精准攻击：") &&
            typeof event.payload.heroId !== "undefined" &&
            typeof event.payload.targetId !== "undefined"
          ) {
            animations.push({
              type: "combat_cue",
              heroId: String(event.payload.heroId ?? ""),
              targetId: String(event.payload.targetId ?? ""),
              cue: "precise_attack",
            });
          }
          break;
        case "turn_started":
          appendLog(
            `回合 ${String(event.payload.round ?? "")} - ${String(event.payload.heroName ?? "")} 行动（先攻骰 d20 ${readNumber(event.payload.initiativeRoll)}${formatSigned(readNumber(event.payload.initiativeMod))}=${readNumber(event.payload.initiativeTotal)}）`,
          );
          break;
        case "damage_dealt": {
          const incomingPayload = { ...event.payload } as Record<string, unknown>;
          let resolvedPayload = incomingPayload;
          const mergedWithPending =
            pendingMergedDamagePayload !== null &&
            shouldMergeDamagePayload(pendingMergedDamagePayload, incomingPayload);
          if (mergedWithPending) {
            resolvedPayload = mergeDamageEventPayload(pendingMergedDamagePayload, incomingPayload);
          }
          this.markCastResult(resolvedPayload.attackerId);
          const topBarBriefs = mergedWithPending
            ? buildTopBarBriefsFromPayload(resolvedPayload, { includeDamage: true })
            : buildResolveTopBarBriefs(resolvedPayload, { includeDamage: true });
          touchTopBarBriefs(topBarBriefs);
          const critMark = resolvedPayload.isCrit ? "暴击，" : "";
          const damageLogMessage = `${String(resolvedPayload.attackerName ?? "")}${resolvedPayload.skillName ? ` 的 ${String(resolvedPayload.skillName)}` : ""} 对 ${String(resolvedPayload.targetName ?? "")} 造成 ${critMark}${String(resolvedPayload.damage ?? 0)} 伤害${formatRollSuffix(resolvedPayload, true)}`;
          if (mergedWithPending && log.length > 0) {
            log[log.length - 1] = damageLogMessage;
          } else {
            replaceCastOrAppend(resolvedPayload.attackerId, damageLogMessage);
          }
          const animationCountBefore = animations.length;
          pushAnimationEvent(animations, {
            type: "damage",
            heroId: String(incomingPayload.targetId ?? ""),
            attackerId: String(incomingPayload.attackerId ?? ""),
            skillName: String(
              mergedWithPending ? resolvedPayload.skillName ?? "" : incomingPayload.skillName ?? "",
            ),
            value: Number(incomingPayload.damage ?? 0),
            critical: Boolean(incomingPayload.isCrit),
            basicAttack: Boolean(incomingPayload.isBasicAttack),
            preferSkillColor: Boolean(incomingPayload.preferSkillColor),
          });
          const mergedIntoPreviousAnimation =
            animations.length === animationCountBefore && animationCountBefore > 0;
          if (mergedIntoPreviousAnimation) {
            pendingMergedDamagePayload = null;
          } else if (
            resolvedPayload.isBasicAttack === true ||
            isSkillColoredDamagePayload(resolvedPayload)
          ) {
            pendingMergedDamagePayload = resolvedPayload;
          } else {
            pendingMergedDamagePayload = null;
          }
          break;
        }
        case "heal_received": {
          this.markCastResult(event.payload.healerId);
          const healSkillName = String(event.payload.skillName ?? "").trim();
          const healAmount = Number(event.payload.healAmount ?? 0);
          const healCritMark = event.payload.isCrit ? " 暴击" : "";
          touchTopBarBriefs({
            skillBrief: healSkillName ? `${healSkillName} 治疗 +${healAmount}${healCritMark}` : null,
            damageBrief: null,
          });
          replaceCastOrAppend(
            event.payload.healerId,
            `${String(event.payload.healerName ?? "")}${event.payload.skillName ? ` 的 ${String(event.payload.skillName)}` : ""} 治疗 ${String(event.payload.targetName ?? "")} ${String(event.payload.healAmount ?? 0)}`,
          );
          animations.push({
            type: "heal",
            heroId: String(event.payload.targetId ?? ""),
            value: Number(event.payload.healAmount ?? 0),
          });
          break;
        }
        case "miss":
          this.markCastResult(event.payload.attackerId);
          touchTopBarBriefs(buildResolveTopBarBriefs(event.payload, { includeDamage: false }));
          replaceCastOrAppend(
            event.payload.attackerId,
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
          touchTopBarBriefs(buildResolveTopBarBriefs(event.payload, { includeDamage: false }));
          replaceCastOrAppend(
            event.payload.attackerId,
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
          this.pendingCastLogIndex.set(String(event.payload.heroId ?? ""), log.length);
          appendLog(`${String(event.payload.heroName ?? "")} 使用 ${String(event.payload.skillName ?? "")}`);
          beginSkillCast(event.payload.skillName);
          animations.push({
            type: "skill_cast_started",
            heroId: String(event.payload.heroId ?? ""),
            heroName: String(event.payload.heroName ?? ""),
            skillName: String(event.payload.skillName ?? ""),
            skillType: Number(event.payload.skillType ?? 0),
          });
          break;
        case "skill_timeline_started":
          if (!skillCasting) {
            beginSkillCast(event.payload.skillName);
          }
          animations.push({
            type: "timeline_started",
            heroId: String(event.payload.heroId ?? ""),
            heroName: String(event.payload.heroName ?? ""),
            skillName: String(event.payload.skillName ?? ""),
            totalFrames: Number(event.payload.totalFrames ?? 0),
          });
          break;
        case "skill_timeline_frame":
          if (
            event.payload.buffId !== undefined ||
            event.payload.effectValue !== undefined ||
            event.payload.statusEffect !== undefined
          ) {
            this.markCastResult(event.payload.heroId);
          }
          animations.push({
            type: "timeline_frame",
            heroId: String(event.payload.heroId ?? ""),
            heroName: String(event.payload.heroName ?? ""),
            skillName: String(event.payload.skillName ?? ""),
            frame: Number(event.payload.frame ?? 0),
            frameIndex: Number(event.payload.frameIndex ?? 0),
            op: String(event.payload.op ?? ""),
            effect: String(event.payload.effect ?? ""),
            buffId: event.payload.buffId !== undefined ? Number(event.payload.buffId) : undefined,
            statusEffect: event.payload.statusEffect !== undefined ? String(event.payload.statusEffect) : undefined,
            effectValue: event.payload.effectValue !== undefined ? Number(event.payload.effectValue) : undefined,
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
          this.pendingCastResults.delete(String(event.payload.heroId ?? ""));
          this.pendingCastLogIndex.delete(String(event.payload.heroId ?? ""));
          if (skillCasting) {
            skillCasting = false;
            skillBrief = null;
            damageBrief = null;
          }
          break;
        case "ultimate_ready":
          appendLog(`${String(event.payload.heroName ?? "")} 大招已就绪`);
          break;
        case "ultimate_cast_queued":
          appendLog(`已下达大招指令: ${String(event.payload.heroId ?? "")}`);
          break;
        case "turn_skipped": {
          const detail = String(event.payload.detail ?? "");
          appendLog(`${String(event.payload.heroName ?? "")} 因${String(event.payload.reason ?? "状态")}跳过行动${detail ? `（${detail}）` : ""}`);
          break;
        }
        case "passive_skill_triggered": {
          const heroName = String(event.payload.heroName ?? "");
          const skillName = String(event.payload.skillName ?? "");
          const triggerType = String(event.payload.triggerType ?? "");
          const extraInfo = String(event.payload.extraInfo ?? "");
          const detail = [triggerType, extraInfo].filter((item) => item !== "").join(" ");
          appendLog(`${heroName} 触发被动 ${skillName}${detail ? `：${detail}` : ""}`);
          touchTopBarBriefs({ skillBrief: skillName, damageBrief: null }, 1800);
          flashUntil = Math.max(flashUntil, performance.now() + 1800);
          animations.push({
            type: "passive_triggered",
            heroId: String(event.payload.heroId ?? ""),
            heroName,
            skillName,
            triggerType,
            extraInfo,
          });
          break;
        }
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
      skillCasting,
      skillBrief,
      damageBrief,
    };
    this.emit();
  }

  clearTransient(now: number) {
    const keepTopBar = this.state.flashUntil > now;
    this.state = {
      ...this.state,
      skillCasting: keepTopBar ? this.state.skillCasting : false,
      skillBrief: keepTopBar ? this.state.skillBrief : null,
      damageBrief: keepTopBar ? this.state.damageBrief : null,
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
