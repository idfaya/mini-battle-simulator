import { expect, test } from "playwright/test";
import { collectClientErrors, filterKnownNoise } from "./helpers/client-errors";
import { findLineIndex } from "./helpers/battle-log";
import { waitForUnitsReturnToBase } from "./helpers/battle-runtime";
import {
  waitForGuardHoldRelease,
  waitForGuardInterceptParticipants,
  waitForReactionOverlap,
} from "./helpers/reaction-holds";

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
        const protectedTarget = layouts.get(clash.interceptedTargetId);
        if (!attacker || !interceptor || !protectedTarget) {
          continue;
        }
        const attackerShift = Math.hypot(attacker.x - attacker.baseX, attacker.y - attacker.baseY);
        const interceptorShiftX = Math.abs(interceptor.x - interceptor.baseX);
        const interceptorShiftY = Math.abs(interceptor.y - interceptor.baseY);
        const attackerShiftX = attacker.x - attacker.baseX;
        const attackerTowardProtectedX = protectedTarget.baseX - attacker.baseX;
        const attackerTracksProtectedColumn =
          Math.abs(attackerTowardProtectedX) <= 4 ||
          (Math.abs(attackerShiftX) > 4 && Math.sign(attackerShiftX) === Math.sign(attackerTowardProtectedX));
        if (attackerShift > 8 && interceptorShiftX > 8 && interceptorShiftY < 3 && attackerTracksProtectedColumn) {
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

async function waitForNoInterceptOnGuardOwners(page: import("playwright/test").Page, targetPositions: number[], timeoutMs = 2500) {
  return page.evaluate(
    async ({ trackedPositions, trackedTimeoutMs }: { trackedPositions: number[]; trackedTimeoutMs: number }) => {
      const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
      const runtime = window as typeof window & {
        __miniBattleHost?: {
          callApi?: <T>(name: string, payload?: unknown) => T;
        };
        __miniBattleRenderer?: {
          getBattleDebugState: () => {
            meleeClashes?: Array<{
              interceptorId?: string;
              interceptedTargetId?: string;
            }>;
          };
        };
      };
      const host = runtime.__miniBattleHost;
      const renderer = runtime.__miniBattleRenderer;
      if (!host || typeof host.callApi !== "function" || !renderer) {
        return false;
      }
      const snapshot = host.callApi<{
        leftTeam?: Array<{ id: string; position: number }>;
      }>("get_snapshot");
      const trackedIds = new Set(
        (snapshot.leftTeam ?? [])
          .filter((unit) => trackedPositions.includes(unit.position))
          .map((unit) => unit.id),
      );
      if (trackedIds.size === 0) {
        return false;
      }
      const attempts = Math.max(1, Math.ceil(trackedTimeoutMs / 40));
      for (let attempt = 0; attempt < attempts; attempt += 1) {
        await sleep(40);
        const hasInterceptedGuardOwner = (renderer.getBattleDebugState().meleeClashes ?? []).some(
          (clash) => Boolean(clash.interceptedTargetId) && trackedIds.has(String(clash.interceptedTargetId)),
        );
        if (hasInterceptedGuardOwner) {
          return false;
        }
      }
      return true;
    },
    { trackedPositions: targetPositions, trackedTimeoutMs: timeoutMs },
  );
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

test("fighter web flow follows second wind -> counter -> guard progression", async ({ page }) => {
  test.setTimeout(60_000);
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=3&seed=101001");
  await page.waitForTimeout(3500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 20_000 })
    .toContain("战士 触发被动 反击：登记反击");

  const level3LogLines = await page.locator(".battle-log li").allTextContents();
  const level3Logs = level3LogLines.join("\n");
  expect(level3Logs).toContain("反击");
  expect(level3Logs).not.toContain("战士 使用 护卫架势");
  expect(level3Logs).not.toContain("盾击");
  expect(level3Logs).not.toContain("顺劈");
  expect(level3Logs).not.toContain("旋风");

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=5&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 使用 护卫架势");
  const level5Logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(level5Logs).toContain("护卫架势");

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910004&level=1&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("战士 的 基础武器攻击 对");
  const level1Logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(level1Logs).toContain("基础武器攻击");
  expect(level1Logs).not.toContain("战士 触发被动 反击：登记反击");
  expect(level1Logs).not.toContain("战士 使用 护卫架势");
  expect(level1Logs).not.toContain("盾击");
  expect(level1Logs).not.toContain("顺劈");
  expect(level1Logs).not.toContain("旋风");

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-web-smoke.png", fullPage: true });
});

test("fighter low tier keeps second wind instead of old extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=1&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 的 回气 治疗 战士");
  const logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(logs).not.toContain("战士 触发被动 反击：登记反击");
  expect(logs).not.toContain("触发额外攻击：对同一目标");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter guard stance logs protection in the high tier", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=5&seed=101001");
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

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=4&fighterFeats=2100402&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 触发被动 反击：登记反击 将对 兽人 发动反击");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 的 基础武器攻击 对 兽人");

  const logs = await page.locator(".battle-log li").allTextContents();
  const attackIndex = findLineIndex(logs, (line) => line.includes("兽人 的 基础武器攻击 对 战士"));
  const queueIndex = findLineIndex(logs, (line) => line.includes("战士 触发被动 反击：登记反击 将对 兽人 发动反击"));
  const counterIndex = findLineIndex(logs, (line) => line.includes("战士 的 基础武器攻击 对 兽人"), queueIndex + 1);

  expect(attackIndex).toBeGreaterThanOrEqual(0);
  expect(queueIndex).toBeGreaterThan(attackIndex);
  expect(counterIndex).toBeGreaterThan(queueIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-counter-queued-log.png", fullPage: true });
});

test("fighter counter attack starts before the enemy returns to base position", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  // 单兽人时战士先攻会先触发兽人反击被动；三兽人 + seed 101001 与 queued 用例一致，保证战士登记反击。
  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=4&fighterFeats=2100402&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  const overlapCheck = waitForReactionOverlap(page, "counter");
  const quickReturnCheck = waitForCounterSourceQuickReturn(page, 15000);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 触发被动 反击：登记反击");

  expect(await overlapCheck).toBe(true);
  expect(await quickReturnCheck).toBe(true);

  const logs = await page.locator(".battle-log li").allTextContents();
  const queueIndex = findLineIndex(logs, (line) => line.includes("战士 触发被动 反击：登记反击"));
  const counterIndex = findLineIndex(logs, (line) => line.includes("战士 的 基础武器攻击 对"), queueIndex + 1);
  expect(queueIndex).toBeGreaterThanOrEqual(0);
  expect(counterIndex).toBeGreaterThan(queueIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter guard counter starts before the enemy returns to base position", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  // 哥布林无护卫；勿带术士(火)（烈焰风暴会提前清场）；显式 fighterFeats 保证 Lv5 反击 + 护卫。
  await page.goto(
    "/?mode=single-battle&heroes=900005,900001&enemies=910002,910002,910002&level=5&fighterFeats=2100402,2100302&seed=100003",
  );
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  // 护卫位移/站桩只在动画窗口内可观测，须与战斗并行轮询，不能等日志出现后再查。
  const motionCheck = waitForGuardInterceptMotion(page);
  const stationaryCheck = waitForGuardInterceptStationaryProtected(page);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 触发被动 护卫架势：登记护卫反击");

  const intercept = await waitForGuardInterceptParticipants(page);
  expect(intercept).not.toBeNull();
  const holdReleaseCheck = waitForGuardHoldRelease(page, intercept!.attackerId, intercept!.guardId, 4000);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 15000 })
    .toContain("战士 的 基础武器攻击 对");

  expect(await motionCheck).toBe(true);
  expect(await stationaryCheck).toBe(true);
  expect(await holdReleaseCheck).toBe(true);
  expect(await waitForUnitsReturnToBase(page, [intercept!.guardId], 1200)).toBe(true);

  const logs = await page.locator(".battle-log li").allTextContents();
  const stanceIndex = findLineIndex(logs, (line) => line.includes("战士 使用 护卫架势"));
  const queueIndex = findLineIndex(logs, (line) => line.includes("战士 触发被动 护卫架势：登记护卫反击"));
  const counterIndex = findLineIndex(logs, (line) => line.includes("战士 的 基础武器攻击 对"), queueIndex + 1);
  const redirectedHitIndex = findLineIndex(logs, (line) => line.includes("哥布林 的 基础武器攻击 对 战士"), stanceIndex + 1);
  expect(stanceIndex).toBeGreaterThanOrEqual(0);
  expect(queueIndex).toBeGreaterThanOrEqual(0);
  expect(redirectedHitIndex).toBeGreaterThan(stanceIndex);
  expect(counterIndex).toBeGreaterThan(queueIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter high tier keeps guard after the progression shift", async ({ page }) => {
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

test("fighter guard owners are not intercepted by another fighter guard owner", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005,900005&enemies=910003,910003,910003&level=5&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 使用 护卫架势");

  expect(await waitForNoInterceptOnGuardOwners(page, [1, 2])).toBe(true);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
