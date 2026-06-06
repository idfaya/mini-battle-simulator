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

async function captureTopBarSummary(page: import("playwright/test").Page, durationMs = 8000) {
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

async function captureAnimationSummary(page: import("playwright/test").Page, durationMs = 4000) {
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

test("monk smoke shows martial arts chain, subclass action and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900001&enemies=910003&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  const animationSummary = await captureAnimationSummary(page);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("震慑拳");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("震慑拳"))).toBeTruthy();
  expect(logs.filter((line) => line.includes("徒手打击")).length).toBeGreaterThanOrEqual(2);
  expect(animationSummary.maxProjectileCount).toBe(0);
  expect(animationSummary.maxMeleeClashes).toBeGreaterThan(0);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("paladin smoke shows smite rotation and limited lay on hands kit", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  // Lv5 主干：破邪斩 + 圣武打击；圣疗为限次救场，不在速战里强行要求施放。
  await page.goto("/?mode=single-battle&heroes=900009&enemies=910003,910003&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("破邪斩");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("圣武打击");

  const rotationLogs = await readLogs(page);
  const rotationText = rotationLogs.join("\n");
  expect(rotationText).toContain("破邪斩");
  expect(rotationText).toContain("圣武打击");
  // R 圣疗：限次救场大招；健康速战中只验证就绪，不强行要求施放。
  expect(rotationText).toContain("大招已就绪");
  expect(rotationText).not.toContain("发动圣疗");
  // Lv5 T2 为灵光基础被动，不再自动施放守护灵光主动。
  expect(rotationText).not.toContain("展开守护灵光");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("ranger smoke shows hunter mark loop, subclass shot and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900008&enemies=910006&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  const animationSummary = await captureAnimationSummary(page);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("猎人印记");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("猎人印记"))).toBeTruthy();
  expect(logs.some((line) => line.includes("施加猎人印记"))).toBeTruthy();
  expect(animationSummary.maxProjectileCount).toBeGreaterThan(0);
  expect(animationSummary.observedProjectileKinds).toContain("arrow");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("wizard freezing nova log shows reflex save rolls", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900003&enemies=910004,910002&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  const topBarSummary = await captureTopBarSummary(page);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 30000 })
    .toMatch(/冻结新星.*(反射豁免|豁免检定).*vs DC.*伤害骰/s);

  const logs = await readLogs(page);
  const joinedLogs = logs.join("\n");
  expect(
    logs.some(
      (line) =>
        line.includes("冻结新星") &&
        (line.includes("反射豁免") || line.includes("豁免检定")) &&
        line.includes("vs DC") &&
        line.includes("伤害骰"),
    ),
  ).toBeTruthy();
  expect(joinedLogs).toMatch(/冻结新星.*(反射豁免|豁免检定).*vs DC.*伤害骰/s);
  expect(topBarSummary.sawCasting).toBeTruthy();
  expect(topBarSummary.sawSaveRoll).toBeTruthy();
  expect(topBarSummary.sawDamageRoll).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
