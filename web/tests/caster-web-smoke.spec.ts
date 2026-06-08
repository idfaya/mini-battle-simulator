import { expect, test } from "playwright/test";

import {
  captureAnimationSummary,
  captureTopBarSummary,
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

const projectileCases = [
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

for (const entry of projectileCases) {
  test(entry.name, async ({ page }) => {
    const { pageErrors, consoleErrors } = await collectClientErrors(page);

    await page.goto(entry.url);
    await expectBattleBoot(page);

    const animationSummary = await captureAnimationSummary(page);

    await expect
      .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
      .toContain(entry.logKeyword);

    expect(animationSummary.maxProjectileCount).toBeGreaterThan(0);
    expect(animationSummary.observedProjectileKinds).toContain(entry.projectileKind);
    await expectNoClientErrors(page, pageErrors, consoleErrors);
  });
}

test("wizard freezing nova log shows reflex save rolls", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900003&enemies=910004,910002&level=5&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  const topBarSummary = await captureTopBarSummary(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30000 })
    .toMatch(/冻结新星.*(敏捷豁免|豁免检定).*vs DC.*伤害骰/s);

  const logs = await readBattleLogs(page);
  const joinedLogs = logs.join("\n");
  expect(
    logs.some(
      (line) =>
        line.includes("冻结新星") &&
        (line.includes("敏捷豁免") || line.includes("豁免检定")) &&
        line.includes("vs DC") &&
        line.includes("伤害骰"),
    ),
  ).toBeTruthy();
  expect(joinedLogs).toMatch(/冻结新星.*(敏捷豁免|豁免检定).*vs DC.*伤害骰/s);
  expect(topBarSummary.sawSaveRoll || topBarSummary.sawDamageRoll).toBeTruthy();
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
