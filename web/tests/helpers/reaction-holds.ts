import type { Page } from "playwright/test";

type ReactionCueKind = "counter" | "guard";

export async function waitForReactionOverlap(page: Page, kind: ReactionCueKind) {
  return page.evaluate(async (reactionKind: ReactionCueKind) => {
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    const runtime = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState: () => {
          observedCounterOverlapKeys?: string[];
          observedGuardCounterOverlapKeys?: string[];
        };
      };
    };
    const renderer = runtime.__miniBattleRenderer;
    if (!renderer) {
      return false;
    }
    for (let attempt = 0; attempt < 180; attempt += 1) {
      await sleep(40);
      const state = renderer.getBattleDebugState();
      const overlaps =
        reactionKind === "guard"
          ? (state.observedGuardCounterOverlapKeys?.length ?? 0)
          : (state.observedCounterOverlapKeys?.length ?? 0);
      if (overlaps > 0) {
        return true;
      }
    }
    return false;
  }, kind);
}

export async function waitForCounterParticipants(page: Page) {
  return page.evaluate(async () => {
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    const runtime = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState: () => {
          meleeClashes?: Array<{
            attackerId: string;
            reactionBindings?: Array<{
              reactorId: string;
              sourceAttackerId: string;
              cueKind: ReactionCueKind;
              holdUntil: number;
            }>;
            holdUntil?: number;
          }>;
        };
      };
    };
    const renderer = runtime.__miniBattleRenderer;
    if (!renderer) {
      return null;
    }
    for (let attempt = 0; attempt < 180; attempt += 1) {
      await sleep(40);
      const now = performance.now();
      for (const clash of renderer.getBattleDebugState().meleeClashes ?? []) {
        const counterBinding = (clash.reactionBindings ?? []).find(
          (binding) => binding.cueKind === "counter" && binding.holdUntil > now,
        );
        if (!counterBinding) {
          continue;
        }
        return {
          attackerId: counterBinding.sourceAttackerId,
          reactorId: counterBinding.reactorId,
        };
      }
    }
    return null;
  });
}

export async function waitForGuardInterceptParticipants(page: Page) {
  return page.evaluate(async () => {
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    const runtime = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState: () => {
          unitLayouts?: Array<{ id: string; x: number; y: number; baseX: number; baseY: number }>;
          meleeClashes?: Array<{
            attackerId: string;
            interceptorId?: string;
            interceptedTargetId?: string;
            targetIds: string[];
          }>;
        };
      };
    };
    const renderer = runtime.__miniBattleRenderer;
    if (!renderer) {
      return null;
    }
    for (let attempt = 0; attempt < 180; attempt += 1) {
      await sleep(40);
      const state = renderer.getBattleDebugState();
      const layouts = new Map((state.unitLayouts ?? []).map((layout) => [layout.id, layout]));
      for (const clash of state.meleeClashes ?? []) {
        if (!clash.interceptorId || !clash.interceptedTargetId || !clash.targetIds.includes(clash.interceptorId)) {
          continue;
        }
        const attacker = layouts.get(clash.attackerId);
        const interceptor = layouts.get(clash.interceptorId);
        if (!attacker || !interceptor) {
          continue;
        }
        const attackerShift = Math.hypot(attacker.x - attacker.baseX, attacker.y - attacker.baseY);
        const interceptorShift = Math.hypot(interceptor.x - interceptor.baseX, interceptor.y - interceptor.baseY);
        if (attackerShift > 8 && interceptorShift > 8) {
          return {
            attackerId: clash.attackerId,
            guardId: clash.interceptorId,
          };
        }
      }
    }
    return null;
  });
}

export async function waitForCounterHoldRelease(
  page: Page,
  attackerId: string,
  reactorId: string,
  timeoutMs = 400,
) {
  return page.evaluate(
    async ({
      trackedAttackerId,
      trackedReactorId,
      trackedTimeoutMs,
    }: {
      trackedAttackerId: string;
      trackedReactorId: string;
      trackedTimeoutMs: number;
    }) => {
      const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
      const runtime = window as typeof window & {
        __miniBattleRenderer?: {
          getBattleDebugState: () => {
            meleeClashes?: Array<{
              attackerId: string;
              reactionBindings?: Array<{ reactorId: string; cueKind: ReactionCueKind; holdUntil: number }>;
              holdUntil?: number;
            }>;
          };
        };
      };
      const renderer = runtime.__miniBattleRenderer;
      if (!renderer) {
        return false;
      }
      const attempts = Math.max(1, Math.ceil(trackedTimeoutMs / 40));
      for (let attempt = 0; attempt < attempts; attempt += 1) {
        await sleep(40);
        const now = performance.now();
        const clashes = renderer.getBattleDebugState().meleeClashes ?? [];
        const activeCounterHold = clashes.some((clash) => {
          if (clash.attackerId !== trackedAttackerId) {
            return false;
          }
          const counterBinding = (clash.reactionBindings ?? []).find(
            (binding) => binding.reactorId === trackedReactorId && binding.cueKind === "counter",
          );
          if (!counterBinding) {
            return false;
          }
          return (clash.holdUntil ?? counterBinding.holdUntil) > now;
        });
        if (!activeCounterHold) {
          return true;
        }
      }
      return false;
    },
    { trackedAttackerId: attackerId, trackedReactorId: reactorId, trackedTimeoutMs: timeoutMs },
  );
}

export async function waitForGuardHoldRelease(page: Page, attackerId: string, guardId: string, timeoutMs = 400) {
  return page.evaluate(
    async ({
      trackedAttackerId,
      trackedGuardId,
      trackedTimeoutMs,
    }: {
      trackedAttackerId: string;
      trackedGuardId: string;
      trackedTimeoutMs: number;
    }) => {
      const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
      const runtime = window as typeof window & {
        __miniBattleRenderer?: {
          getBattleDebugState: () => {
            meleeClashes?: Array<{
              attackerId: string;
              interceptorId?: string;
              reactionBindings?: Array<{ reactorId: string; cueKind: ReactionCueKind; holdUntil: number }>;
              holdUntil?: number;
            }>;
          };
        };
      };
      const renderer = runtime.__miniBattleRenderer;
      if (!renderer) {
        return false;
      }
      const attempts = Math.max(1, Math.ceil(trackedTimeoutMs / 40));
      for (let attempt = 0; attempt < attempts; attempt += 1) {
        await sleep(40);
        const now = performance.now();
        const clashes = renderer.getBattleDebugState().meleeClashes ?? [];
        const activeGuardHold = clashes.some((clash) => {
          const guardBinding = (clash.reactionBindings ?? []).find(
            (binding) =>
              binding.reactorId === trackedGuardId &&
              binding.cueKind === "guard" &&
              binding.sourceAttackerId === trackedAttackerId,
          );
          if (!guardBinding) {
            return false;
          }
          if (clash.attackerId !== trackedAttackerId) {
            return false;
          }
          return (clash.holdUntil ?? guardBinding.holdUntil) > now;
        });
        if (!activeGuardHold) {
          return true;
        }
      }
      return false;
    },
    { trackedAttackerId: attackerId, trackedGuardId: guardId, trackedTimeoutMs: timeoutMs },
  );
}
