import type { RunSnapshot } from "../types/roguelike";

export type RunStoreState = {
  snapshot: RunSnapshot | null;
  logs: string[];
};

type Listener = (state: RunStoreState) => void;

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

