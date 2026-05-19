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
          projectileCount?: number;
          projectileKinds?: string[];
        };
      };
    };
    const sleep = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));
    let maxProjectileCount = 0;
    const observedProjectileKinds = new Set<string>();
    const deadline = performance.now() + sampleMs;

    while (performance.now() < deadline) {
      const debugState = win.__miniBattleRenderer?.getBattleDebugState?.() ?? {};
      maxProjectileCount = Math.max(maxProjectileCount, typeof debugState.projectileCount === "number" ? debugState.projectileCount : 0);
      for (const kind of Array.isArray(debugState.projectileKinds) ? debugState.projectileKinds : []) {
        if (typeof kind === "string" && kind) {
          observedProjectileKinds.add(kind);
        }
      }
      await sleep(50);
    }

    return { maxProjectileCount, observedProjectileKinds: [...observedProjectileKinds] };
  }, { durationMs });
}

const cases = [
  {
    name: "sorcerer smoke keeps fire projectiles",
    url: "/?mode=single-battle&heroes=900002&enemies=910006&level=5&seed=101001",
    logKeyword: "火焰弹",
    projectileKind: "orb",
  },
  {
    name: "wizard smoke keeps frost projectiles",
    url: "/?mode=single-battle&heroes=900003&enemies=910006&level=5&seed=101001",
    logKeyword: "寒霜射线",
    projectileKind: "shard",
  },
  {
    name: "warlock smoke keeps lightning projectiles",
    url: "/?mode=single-battle&heroes=900004&enemies=910006&level=5&seed=101001",
    logKeyword: "邪能冲击",
    projectileKind: "lightning",
  },
];

for (const entry of cases) {
  test(entry.name, async ({ page }) => {
    const { pageErrors, consoleErrors } = await collectClientErrors(page);

    await page.goto(entry.url);

    await expect(page.locator(".fatal-error")).toHaveCount(0);
    await expect(page.locator("canvas")).toHaveCount(1);

    const animationSummary = await captureAnimationSummary(page);

    await expect
      .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
      .toContain(entry.logKeyword);

    expect(animationSummary.maxProjectileCount).toBeGreaterThan(0);
    expect(animationSummary.observedProjectileKinds).toContain(entry.projectileKind);
    expect(pageErrors).toEqual([]);
    expect(filterKnownNoise(consoleErrors)).toEqual([]);
  });
}
