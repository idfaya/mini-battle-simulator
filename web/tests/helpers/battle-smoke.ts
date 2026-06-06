import { expect, type Page } from "playwright/test";

import { collectClientErrors, filterKnownNoise } from "./client-errors";

export { collectClientErrors, filterKnownNoise };

export async function readBattleLogs(page: Page) {
  return page.locator(".battle-log li").allTextContents();
}

export async function expectBattleBoot(page: Page) {
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);
}

export async function expectNoClientErrors(page: Page, pageErrors: string[], consoleErrors: string[]) {
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
}

export async function captureAnimationSummary(page: Page, durationMs = 4000) {
  return page.evaluate(async ({ durationMs: sampleMs }) => {
    const win = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState?: () => {
          meleeClashes?: Array<unknown>;
          projectileCount?: number;
          projectileKinds?: string[];
        };
      };
    };
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    let maxMeleeClashes = 0;
    let maxProjectileCount = 0;
    const observedProjectileKinds = new Set<string>();
    const deadline = performance.now() + sampleMs;

    while (performance.now() < deadline) {
      const debugState = win.__miniBattleRenderer?.getBattleDebugState?.() ?? {};
      maxMeleeClashes = Math.max(maxMeleeClashes, Array.isArray(debugState.meleeClashes) ? debugState.meleeClashes.length : 0);
      maxProjectileCount = Math.max(maxProjectileCount, typeof debugState.projectileCount === "number" ? debugState.projectileCount : 0);
      for (const kind of Array.isArray(debugState.projectileKinds) ? debugState.projectileKinds : []) {
        if (typeof kind === "string" && kind) {
          observedProjectileKinds.add(kind);
        }
      }
      await sleep(50);
    }

    return { maxMeleeClashes, maxProjectileCount, observedProjectileKinds: [...observedProjectileKinds] };
  }, { durationMs });
}

export async function captureTopBarSummary(page: Page, durationMs = 8000) {
  return page.evaluate(async ({ durationMs: sampleMs }) => {
    const win = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState?: () => {
          topBar?: {
            skillCasting?: boolean;
            skillBrief?: string | null;
            damageBrief?: string | null;
          };
        };
      };
    };
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    let sawCasting = false;
    let sawSaveRoll = false;
    let sawDamageRoll = false;
    const deadline = performance.now() + sampleMs;

    while (performance.now() < deadline) {
      const topBar = win.__miniBattleRenderer?.getBattleDebugState?.().topBar ?? {};
      const skillBrief = typeof topBar.skillBrief === "string" ? topBar.skillBrief : "";
      const damageBrief = typeof topBar.damageBrief === "string" ? topBar.damageBrief : "";
      if (topBar.skillCasting === true || skillBrief.includes("释放中")) {
        sawCasting = true;
      }
      if (skillBrief.includes("反射豁免") || skillBrief.includes("强韧豁免") || skillBrief.includes("意志豁免")) {
        sawSaveRoll = true;
      }
      if (damageBrief.includes("伤害骰")) {
        sawDamageRoll = true;
      }
      await sleep(50);
    }

    return { sawCasting, sawSaveRoll, sawDamageRoll };
  }, { durationMs });
}
