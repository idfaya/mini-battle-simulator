import { expect, test } from "playwright/test";

import {
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("cleric base route keeps holy spark ranged and shelter active", async ({ page }) => {
  test.setTimeout(60_000);
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900007&enemies=910008&level=5&seed=101002");
  await expectBattleBoot(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("神圣火花");
  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("神恩庇护");

  const logs = await readBattleLogs(page);
  const joinedLogs = logs.join("\n");
  expect(logs.some((line) => line.includes("神圣火花"))).toBeTruthy();
  expect(logs.some((line) => line.includes("神恩庇护"))).toBeTruthy();
  expect(
    logs.some(
      (line) =>
        line.includes("神圣火花") &&
        (line.includes("意志豁免") || line.includes("豁免检定")) &&
        line.includes("vs DC") &&
        line.includes("伤害骰"),
    ),
  ).toBeTruthy();
  expect(joinedLogs).toMatch(/神圣火花.*(意志豁免|豁免检定).*vs DC.*伤害骰/s);
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
