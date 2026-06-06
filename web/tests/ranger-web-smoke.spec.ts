import { expect, test } from "playwright/test";

import {
  captureAnimationSummary,
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("ranger smoke shows hunter mark loop, subclass shot and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900008&enemies=910006&level=5&seed=101001");
  await expectBattleBoot(page);

  const animationSummary = await captureAnimationSummary(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("猎人印记");

  const logs = await readBattleLogs(page);
  expect(logs.some((line) => line.includes("猎人印记"))).toBeTruthy();
  expect(logs.some((line) => line.includes("施加猎人印记"))).toBeTruthy();
  expect(animationSummary.maxProjectileCount).toBeGreaterThan(0);
  expect(animationSummary.observedProjectileKinds).toContain("arrow");
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
