import { expect, test } from "playwright/test";

import {
  captureAnimationSummary,
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("ranger smoke shows hunter mark, double shot and arrow rain", async ({ page }) => {
  test.setTimeout(60_000);
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900008&enemies=910003,910003&level=5&seed=101001");
  await expectBattleBoot(page);

  const animationSummary = await captureAnimationSummary(page, 8000);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30_000 })
    .toContain("施加猎人印记");

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30_000 })
    .toContain("发动箭雨");

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30_000 })
    .toContain("二连射");

  const logs = await readBattleLogs(page);
  expect(logs.some((line) => line.includes("猎人印记"))).toBeTruthy();
  expect(logs.some((line) => line.includes("施加猎人印记"))).toBeTruthy();
  expect(logs.some((line) => line.includes("发动箭雨"))).toBeTruthy();
  expect(logs.some((line) => line.includes("箭雨第"))).toBeTruthy();
  expect(logs.some((line) => line.includes("二连射"))).toBeTruthy();
  expect(animationSummary.maxProjectileCount).toBeGreaterThan(0);
  expect(animationSummary.observedProjectileKinds).toContain("arrow");
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});

test("ranger defense stance logs ac and damage reduction after being hit", async ({ page }) => {
  test.setTimeout(60_000);
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900008&enemies=910006&level=6&buildFeats=2305005,2305006,2305007&seed=101001",
  );
  await expectBattleBoot(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30_000 })
    .toContain("触发防守熟练");

  const logs = await readBattleLogs(page);
  expect(logs.some((line) => line.includes("触发防守熟练") && line.includes("AC +"))).toBeTruthy();
  expect(
    logs.some(
      (line) =>
        line.includes("触发防守精通") &&
        (line.includes("伤害减免") || line.includes("伤害 -")),
    ),
  ).toBeTruthy();
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
