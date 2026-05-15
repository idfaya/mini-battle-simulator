import { expect, test } from "playwright/test";

async function collectClientErrors(page: import("playwright/test").Page) {
  const pageErrors: string[] = [];
  const consoleErrors: string[] = [];

  page.on("pageerror", (error) => {
    pageErrors.push(error.message);
  });
  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
  });

  return { pageErrors, consoleErrors };
}

function filterKnownNoise(errors: string[]) {
  return errors.filter(
    (message) => !message.includes("ERR_CONNECTION_REFUSED") && !message.includes("ERR_NETWORK_CHANGED"),
  );
}

function findLineIndex(logs: string[], matcher: (line: string) => boolean, startIndex = 0) {
  for (let index = startIndex; index < logs.length; index += 1) {
    if (matcher(logs[index])) {
      return index;
    }
  }
  return -1;
}

async function waitForReactionOverlap(page: import("playwright/test").Page, kind: "counter" | "guard") {
  return page.evaluate(async (reactionKind: "counter" | "guard") => {
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

async function waitForCounterSourceQuickReturn(page: import("playwright/test").Page, timeoutMs = 1200) {
  return page.evaluate(async (trackedTimeoutMs: number) => {
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    const runtime = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState: () => {
          unitLayouts?: Array<{ id: string; x: number; y: number; baseX: number; baseY: number }>;
          meleeClashes?: Array<{
            attackerId: string;
            targetIds: string[];
            reactionBindings?: Array<{
              reactorId: string;
              sourceAttackerId: string;
              cueKind: "counter" | "guard";
            }>;
          }>;
        };
      };
    };
    const renderer = runtime.__miniBattleRenderer;
    if (!renderer) {
      return false;
    }
    const attempts = Math.max(1, Math.ceil(trackedTimeoutMs / 40));
    let trackedSourceAttackerId = "";
    let sawDisplacedSource = false;
    for (let attempt = 0; attempt < attempts; attempt += 1) {
      await sleep(40);
      const state = renderer.getBattleDebugState();
      const layouts = new Map((state.unitLayouts ?? []).map((layout) => [layout.id, layout]));
      const clashes = state.meleeClashes ?? [];
      if (trackedSourceAttackerId === "") {
        for (const clash of clashes) {
          const counterBinding = (clash.reactionBindings ?? []).find((binding) => binding.cueKind === "counter");
          if (!counterBinding) {
            continue;
          }
          trackedSourceAttackerId = counterBinding.sourceAttackerId;
          break;
        }
      }
      if (trackedSourceAttackerId === "") {
        continue;
      }
      const sourceLayout = layouts.get(trackedSourceAttackerId);
      if (!sourceLayout) {
        return true;
      }
      const sourceShift = Math.hypot(sourceLayout.x - sourceLayout.baseX, sourceLayout.y - sourceLayout.baseY);
      if (sourceShift > 8) {
        sawDisplacedSource = true;
      }
      if (!sawDisplacedSource) {
        continue;
      }
      if (sourceShift < 6) {
        return true;
      }
    }
    return false;
  }, timeoutMs);
}

async function waitForGuardInterceptMotion(page: import("playwright/test").Page) {
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
      return false;
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
          return true;
        }
      }
    }
    return false;
  });
}

async function waitForGuardInterceptStationaryProtected(page: import("playwright/test").Page) {
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
      return false;
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
        const protectedTarget = layouts.get(clash.interceptedTargetId);
        if (!attacker || !interceptor || !protectedTarget) {
          continue;
        }
        const attackerShift = Math.hypot(attacker.x - attacker.baseX, attacker.y - attacker.baseY);
        const interceptorShift = Math.hypot(interceptor.x - interceptor.baseX, interceptor.y - interceptor.baseY);
        const protectedShift = Math.hypot(protectedTarget.x - protectedTarget.baseX, protectedTarget.y - protectedTarget.baseY);
        if (attackerShift > 8 && interceptorShift > 8 && protectedShift < 3) {
          return true;
        }
      }
    }
    return false;
  });
}

async function waitForNoSelfGuardIntercept(page: import("playwright/test").Page, timeoutMs = 2000) {
  return page.evaluate(async (trackedTimeoutMs: number) => {
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    const runtime = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState: () => {
          meleeClashes?: Array<{
            interceptorId?: string;
            interceptedTargetId?: string;
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
      const hasSelfIntercept = (renderer.getBattleDebugState().meleeClashes ?? []).some(
        (clash) =>
          Boolean(clash.interceptorId) &&
          Boolean(clash.interceptedTargetId) &&
          clash.interceptorId === clash.interceptedTargetId,
      );
      if (hasSelfIntercept) {
        return false;
      }
    }
    return true;
  }, timeoutMs);
}

async function waitForNoForwardLungeOnDirectHit(
  page: import("playwright/test").Page,
  targetName: string,
  timeoutMs = 2500,
) {
  return page.evaluate(async ({ trackedTargetName, trackedTimeoutMs }: { trackedTargetName: string; trackedTimeoutMs: number }) => {
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        callApi?: <T>(name: string, payload?: unknown) => T;
      };
      __miniBattleRenderer?: {
        getBattleDebugState: () => {
          unitLayouts?: Array<{ id: string; x: number; y: number; baseX: number; baseY: number }>;
          meleeClashes?: Array<{
            attackerId: string;
            interceptorId?: string;
            targetIds: string[];
          }>;
        };
      };
    };
    const renderer = runtime.__miniBattleRenderer;
    const host = runtime.__miniBattleHost;
    if (!renderer || !host || typeof host.callApi !== "function") {
      return false;
    }
    const snapshot = host.callApi<{
      leftTeam?: Array<{ id: string; name: string }>;
      rightTeam?: Array<{ id: string; name: string }>;
    }>("get_snapshot");
    const trackedTargetId =
      [...(snapshot.leftTeam ?? []), ...(snapshot.rightTeam ?? [])].find((unit) => unit.name === trackedTargetName)?.id ?? "";
    if (!trackedTargetId) {
      return false;
    }
    const attempts = Math.max(1, Math.ceil(trackedTimeoutMs / 40));
    for (let attempt = 0; attempt < attempts; attempt += 1) {
      await sleep(40);
      const state = renderer.getBattleDebugState();
      const layouts = new Map((state.unitLayouts ?? []).map((layout) => [layout.id, layout]));
      for (const clash of state.meleeClashes ?? []) {
        if (clash.interceptorId || clash.targetIds.length !== 1 || clash.targetIds[0] !== trackedTargetId) {
          continue;
        }
        const attacker = layouts.get(clash.attackerId);
        const target = layouts.get(clash.targetIds[0]);
        if (!attacker || !target) {
          continue;
        }
        const attackVectorX = attacker.baseX - target.baseX;
        const attackVectorY = attacker.baseY - target.baseY;
        const attackDistance = Math.hypot(attackVectorX, attackVectorY);
        if (attackDistance < 1) {
          continue;
        }
        const forwardUnitX = attackVectorX / attackDistance;
        const forwardUnitY = attackVectorY / attackDistance;
        const targetOffsetX = target.x - target.baseX;
        const targetOffsetY = target.y - target.baseY;
        const forwardProjection = targetOffsetX * forwardUnitX + targetOffsetY * forwardUnitY;
        const attackerShift = Math.hypot(attacker.x - attacker.baseX, attacker.y - attacker.baseY);
        if (attackerShift > 8) {
          return forwardProjection < 8;
        }
      }
    }
    return false;
  }, { trackedTargetName: targetName, trackedTimeoutMs: timeoutMs });
}

async function waitForGuardInterceptParticipants(page: import("playwright/test").Page) {
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

async function getAliveUnitIdByName(page: import("playwright/test").Page, name: string) {
  return page.evaluate((unitName: string) => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        callApi?: <T>(name: string, payload?: unknown) => T;
      };
    };
    const host = runtime.__miniBattleHost;
    if (!host || typeof host.callApi !== "function") {
      return "";
    }
    const snapshot = host.callApi<{
      leftTeam?: Array<{ id: string; name: string; isAlive: boolean }>;
      rightTeam?: Array<{ id: string; name: string; isAlive: boolean }>;
    }>("get_snapshot");
    const unit = [...(snapshot.leftTeam ?? []), ...(snapshot.rightTeam ?? [])].find(
      (candidate) => candidate.name === unitName && candidate.isAlive,
    );
    return unit?.id ?? "";
  }, name);
}

async function forceKillRuntimeUnit(page: import("playwright/test").Page, unitId: string) {
  return page.evaluate((targetUnitId: string) => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        runChunk?: (source: string, filename: string) => void;
      };
    };
    const host = runtime.__miniBattleHost;
    if (!host || typeof host.runChunk !== "function") {
      return false;
    }
    const chunk = `
local BattleAttribute = require("modules.battle_attribute")
local BattleFormation = require("modules.battle_formation")
for _, hero in ipairs(BattleFormation.GetAllHeroes() or {}) do
    local heroId = tostring(hero.instanceId or hero.id or "")
    if heroId == ${JSON.stringify(targetUnitId)} then
        BattleAttribute.SetHpByVal(hero, 0)
        break
    end
end
`;
    host.runChunk(chunk, "playwright_force_kill_guard.lua");
    return true;
  }, unitId);
}

async function waitForUnitsReturnToBase(
  page: import("playwright/test").Page,
  unitIds: string[],
  timeoutMs = 700,
) {
  return page.evaluate(
    async ({ trackedUnitIds, trackedTimeoutMs }: { trackedUnitIds: string[]; trackedTimeoutMs: number }) => {
      const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
      const runtime = window as typeof window & {
        __miniBattleRenderer?: {
          getBattleDebugState: () => {
            unitLayouts?: Array<{ id: string; x: number; y: number; baseX: number; baseY: number }>;
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
        const layouts = new Map((renderer.getBattleDebugState().unitLayouts ?? []).map((layout) => [layout.id, layout]));
        const settled = trackedUnitIds.every((unitId) => {
          const layout = layouts.get(unitId);
          if (!layout) {
            return true;
          }
          return Math.hypot(layout.x - layout.baseX, layout.y - layout.baseY) < 4;
        });
        if (settled) {
          return true;
        }
      }
      return false;
    },
    { trackedUnitIds: unitIds, trackedTimeoutMs: timeoutMs },
  );
}

async function waitForGuardHoldRelease(
  page: import("playwright/test").Page,
  attackerId: string,
  guardId: string,
  timeoutMs = 400,
) {
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
              reactionBindings?: Array<{ reactorId: string; cueKind: "counter" | "guard"; holdUntil: number }>;
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
          if (clash.attackerId !== trackedAttackerId || clash.interceptorId !== trackedGuardId) {
            return false;
          }
          const guardBinding = (clash.reactionBindings ?? []).find(
            (binding) => binding.reactorId === trackedGuardId && binding.cueKind === "guard",
          );
          if (!guardBinding) {
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

test("fighter web flow shows guard stance in the three-tier build", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910006&level=3&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("战士 使用 护卫架势");

  const level3LogLines = await page.locator(".battle-log li").allTextContents();
  const level3Logs = level3LogLines.join("\n");
  expect(level3Logs).toContain("护卫架势");
  expect(level3Logs).not.toContain("盾击");
  expect(level3Logs).not.toContain("顺劈");
  expect(level3Logs).not.toContain("旋风");

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910004&level=1&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("战士 使用 基础武器攻击");
  const level1Logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(level1Logs).toContain("基础武器攻击");
  expect(level1Logs).not.toContain("盾击");
  expect(level1Logs).not.toContain("顺劈");
  expect(level1Logs).not.toContain("旋风");

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-web-smoke.png", fullPage: true });
});

test("fighter low tier keeps counter instead of old extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=1&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 触发被动 反击：登记反击");
  const logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(logs).not.toContain("触发额外攻击：对同一目标");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter guard stance logs protection in the mid tier", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=3&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 使用 护卫架势");
  const logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(logs).toContain("护卫");
  expect(await waitForNoForwardLungeOnDirectHit(page, "战士")).toBe(true);
  expect(await waitForNoSelfGuardIntercept(page)).toBe(true);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter counter reaction logs when reaction is queued", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=4&fighterFeats=2100302,2100402&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 触发被动 反击：登记反击 将对 兽人 发动反击");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 使用 基础武器攻击");

  const logs = await page.locator(".battle-log li").allTextContents();
  const attackIndex = findLineIndex(logs, (line) => line.includes("兽人 使用 基础武器攻击"));
  const queueIndex = findLineIndex(logs, (line) => line.includes("战士 触发被动 反击：登记反击 将对 兽人 发动反击"));
  const resultIndex = findLineIndex(logs, (line) => line.includes("兽人 的 基础武器攻击 对 战士"), queueIndex + 1);
  const counterIndex = findLineIndex(logs, (line) => line.includes("战士 使用 基础武器攻击"), resultIndex + 1);

  expect(attackIndex).toBeGreaterThanOrEqual(0);
  expect(queueIndex).toBeGreaterThan(attackIndex);
  expect(resultIndex).toBeGreaterThan(queueIndex);
  expect(counterIndex).toBeGreaterThan(resultIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-counter-queued-log.png", fullPage: true });
});

test("fighter counter attack starts before the enemy returns to base position", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003&level=4&fighterFeats=2100302,2100402&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 触发被动 反击：登记反击");

  expect(await waitForReactionOverlap(page, "counter")).toBe(true);
  expect(await waitForCounterSourceQuickReturn(page)).toBe(true);

  const logs = await page.locator(".battle-log li").allTextContents();
  const queueIndex = findLineIndex(logs, (line) => line.includes("战士 触发被动 反击：登记反击"));
  const counterIndex = findLineIndex(logs, (line) => line.includes("战士 使用 基础武器攻击"), queueIndex + 1);
  expect(queueIndex).toBeGreaterThanOrEqual(0);
  expect(counterIndex).toBeGreaterThan(queueIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter guard counter starts before the enemy returns to base position", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005,900001,900002&enemies=910003,910003,910003&level=3&seed=100003");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 触发被动 护卫架势：登记护卫反击");

  expect(await waitForGuardInterceptMotion(page)).toBe(true);
  expect(await waitForGuardInterceptStationaryProtected(page)).toBe(true);
  expect(await waitForReactionOverlap(page, "guard")).toBe(true);

  const logs = await page.locator(".battle-log li").allTextContents();
  const queueIndex = findLineIndex(logs, (line) => line.includes("战士 触发被动 护卫架势：登记护卫反击"));
  const counterIndex = findLineIndex(logs, (line) => line.includes("战士 使用 基础武器攻击"), queueIndex + 1);
  const redirectedHitIndex = findLineIndex(logs, (line) => line.includes("兽人 的 基础武器攻击 对 战士"), queueIndex + 1);
  expect(queueIndex).toBeGreaterThanOrEqual(0);
  expect(redirectedHitIndex).toBeGreaterThan(queueIndex);
  expect(counterIndex).toBeGreaterThan(queueIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("dead guard skips guard counter and releases the intercept hold immediately", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005,900001,900002&enemies=910003,910003,910003&level=3&seed=100003");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 触发被动 护卫架势：登记护卫反击");

  const intercept = await waitForGuardInterceptParticipants(page);
  expect(intercept).not.toBeNull();

  const guardId = await getAliveUnitIdByName(page, "战士");
  expect(guardId).not.toBe("");
  expect(await forceKillRuntimeUnit(page, guardId)).toBe(true);

  const logsBefore = await page.locator(".battle-log li").allTextContents();
  const queueIndex = findLineIndex(logsBefore, (line) => line.includes("战士 触发被动 护卫架势：登记护卫反击"));
  expect(queueIndex).toBeGreaterThanOrEqual(0);

  expect(await waitForGuardHoldRelease(page, intercept!.attackerId, intercept!.guardId, 400)).toBe(true);
  await expect.poll(async () => getAliveUnitIdByName(page, "战士"), { timeout: 1200 }).toBe("");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter high tier keeps indomitable wind in the build", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=5&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 使用 护卫架势");
  const logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(logs).not.toContain("二次生命");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
