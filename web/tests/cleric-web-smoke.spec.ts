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
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

async function readLogs(page: import("playwright/test").Page) {
  return page.locator(".battle-log li").allTextContents();
}

async function captureClericAnimationSummary(page: import("playwright/test").Page, durationMs = 4000) {
  return page.evaluate(async ({ durationMs: sampleMs }) => {
    const win = window as typeof window & {
      __miniBattleRenderer?: {
        getBattleDebugState?: () => {
          meleeClashes?: Array<unknown>;
          projectileCount?: number;
        };
      };
    };
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    let maxMeleeClashes = 0;
    let maxProjectileCount = 0;
    const deadline = performance.now() + sampleMs;

    while (performance.now() < deadline) {
      const debugState = win.__miniBattleRenderer?.getBattleDebugState?.() ?? {};
      maxMeleeClashes = Math.max(maxMeleeClashes, Array.isArray(debugState.meleeClashes) ? debugState.meleeClashes.length : 0);
      maxProjectileCount = Math.max(maxProjectileCount, typeof debugState.projectileCount === "number" ? debugState.projectileCount : 0);
      await sleep(50);
    }

    return { maxMeleeClashes, maxProjectileCount };
  }, { durationMs });
}

test("cleric light route shows holy spark and blessed strikes", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900007&enemies=910005&level=5&buildFeats=2150201,2150302,2150401,2150501&seed=101002",
  );

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  const animationSummary = await captureClericAnimationSummary(page);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("神圣火花");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("圣焰裁决");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("治愈之言");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("神圣火花"))).toBeTruthy();
  expect(logs.some((line) => line.includes("圣焰裁决"))).toBeTruthy();
  expect(logs.some((line) => line.includes("治愈之言"))).toBeTruthy();
  expect(animationSummary.maxMeleeClashes).toBe(0);
  expect(animationSummary.maxProjectileCount).toBeGreaterThan(0);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
