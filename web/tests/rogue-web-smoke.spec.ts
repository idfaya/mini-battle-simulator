import { expect, test } from "playwright/test";

import {
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("rogue smoke shows sneak attack loop and subclass action", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900006&enemies=910006&level=5&seed=101001");
  await expectBattleBoot(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("诡诈打击");
  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("的 偷袭");

  const logs = await readBattleLogs(page);
  expect(logs.some((line) => line.includes("诡诈打击"))).toBeTruthy();
  expect(logs.some((line) => line.includes("的 偷袭"))).toBeTruthy();
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
