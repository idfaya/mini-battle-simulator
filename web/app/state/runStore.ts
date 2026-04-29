import type { RunSnapshot } from "../types/roguelike";

export type RunStoreState = {
  snapshot: RunSnapshot | null;
  logs: string[];
};

type Listener = (state: RunStoreState) => void;

// #region debug-point C:report-run-snapshot
const DEBUG_COUNTER_URL = "http://127.0.0.1:7777/event";
const DEBUG_COUNTER_SESSION = "fighter-counter-timing";
function reportRunDebug(location: string, msg: string, data: Record<string, unknown>) {
  fetch(DEBUG_COUNTER_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      sessionId: DEBUG_COUNTER_SESSION,
      runId: "pre-fix",
      hypothesisId: "C",
      location,
      msg,
      data,
      ts: Date.now(),
    }),
  }).catch(() => {});
}
// #endregion

export class RunStore {
  private state: RunStoreState = {
    snapshot: null,
    logs: [],
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

  setSnapshot(snapshot: RunSnapshot) {
    // #region debug-point C:run-snapshot
    reportRunDebug("web/app/state/runStore.ts:setSnapshot", "[DEBUG] run snapshot updated", {
      phase: snapshot.phase,
      lastActionMessage: snapshot.lastActionMessage,
      team: snapshot.team.map((member) => ({
        rosterId: member.rosterId,
        heroId: member.heroId,
        name: member.name,
        level: member.level,
        buildSummary: member.buildSummary ?? [],
      })),
      rewardOptions: (snapshot.rewardState?.options ?? []).map((option) => ({
        rosterId: option.rosterId,
        heroName: option.heroName,
        featId: option.featId,
        featName: option.featName,
        label: option.label,
      })),
    });
    // #endregion
    const logs = [...this.state.logs];
    if (snapshot.lastActionMessage && snapshot.lastActionMessage.trim().length > 0) {
      logs.unshift(snapshot.lastActionMessage);
    }
    this.state = {
      snapshot,
      logs: logs.slice(0, 24),
    };
    this.emit();
  }

  pushLog(message: string) {
    if (!message || message.trim().length === 0) {
      return;
    }
    this.state = {
      ...this.state,
      logs: [message, ...this.state.logs].slice(0, 24),
    };
    this.emit();
  }

  private emit() {
    for (const listener of this.listeners) {
      listener(this.state);
    }
  }
}
