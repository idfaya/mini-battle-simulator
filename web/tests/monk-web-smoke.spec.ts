import { expect, test } from "playwright/test";

import {
  captureAnimationSummary,
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("monk smoke shows martial arts chain, subclass action and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900001&enemies=910003&level=5&seed=101001");
  await expectBattleBoot(page);

  const animationSummary = await captureAnimationSummary(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("震慑拳");

  const logs = await readBattleLogs(page);
  expect(logs.some((line) => line.includes("震慑拳"))).toBeTruthy();
  expect(logs.filter((line) => line.includes("徒手打击")).length).toBeGreaterThanOrEqual(2);
  expect(animationSummary.maxProjectileCount).toBe(0);
  expect(animationSummary.maxMeleeClashes).toBeGreaterThan(0);
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
