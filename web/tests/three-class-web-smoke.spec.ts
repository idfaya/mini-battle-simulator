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

async function captureAnimationSummary(page: import("playwright/test").Page, durationMs = 4000) {
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

test("monk smoke shows martial arts chain, subclass action and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900001&enemies=910003&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  const animationSummary = await captureAnimationSummary(page);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("连击");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("震劲掌");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("触发连击："))).toBeTruthy();
  expect(logs.some((line) => line.includes("使用 震劲掌"))).toBeTruthy();
  expect(animationSummary.maxProjectileCount).toBe(0);
  expect(animationSummary.maxMeleeClashes).toBeGreaterThan(0);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("paladin smoke shows judgement prayer, divine smite and oath action", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900009&enemies=910006&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("破邪斩");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("圣手");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("使用 破邪斩"))).toBeTruthy();
  expect(logs.some((line) => line.includes("使用 圣手"))).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("ranger smoke shows hunter mark loop, subclass shot and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900008&enemies=910006&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("猎人印记");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("狩猎指引");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("触发额外攻击：对同一目标");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("施加猎人印记"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发猎人印记："))).toBeTruthy();
  expect(logs.some((line) => line.includes("使用 狩猎指引"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发额外攻击：对同一目标"))).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
