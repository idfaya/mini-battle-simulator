import { expect, test } from "playwright/test";

import {
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("paladin smoke shows smite rotation and limited lay on hands kit", async ({ page }) => {
  test.setTimeout(60_000);
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900009&enemies=910003,910003&level=5&seed=101001");
  await expectBattleBoot(page);

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30_000 })
    .toContain("破邪斩");
  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 30_000 })
    .toContain("圣武打击");

  const rotationText = (await readBattleLogs(page)).join("\n");
  expect(rotationText).toContain("破邪斩");
  expect(rotationText).toContain("圣武打击");
  expect(rotationText).toContain("大招已就绪");
  expect(rotationText).not.toContain("发动圣疗");
  expect(rotationText).not.toContain("展开守护灵光");
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
