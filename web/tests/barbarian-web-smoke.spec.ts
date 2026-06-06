import { expect, test } from "playwright/test";

import {
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("barbarian smoke shows rage, heavy strike and berserk pipeline", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900010&enemies=910003,910003,910003&level=5&seed=101001");
  await expectBattleBoot(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("重击");
  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("狂暴");

  const logs = await readBattleLogs(page);
  expect(logs.some((line) => line.includes("重击"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发被动 狂暴"))).toBeTruthy();
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});

test("barbarian rage recovery logs heal on berserk entry", async ({ page }) => {
  test.setTimeout(60_000);
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900010&enemies=910003,910003,910003&level=5&buildFeats=2310002&seed=101001",
  );
  await expectBattleBoot(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30_000 })
    .toContain("狂暴恢复");

  const logs = await readBattleLogs(page);
  expect(logs.some((line) => line.includes("狂暴恢复") && line.includes("回复"))).toBeTruthy();
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
