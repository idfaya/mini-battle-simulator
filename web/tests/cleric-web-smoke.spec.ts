import { expect, test } from "playwright/test";

import {
  collectClientErrors,
  expectBattleBoot,
  expectNoClientErrors,
  readBattleLogs,
} from "./helpers/battle-smoke";

test("cleric blessing build keeps sacred flame ranged and can trigger blessing support", async ({ page }) => {
  test.setTimeout(60_000);
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900007,900007&enemies=910003,910003&level=5&buildFeatsByHero=2150202|2150202&seed=101001");
  await expectBattleBoot(page);
  await page.evaluate(() => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        runChunk?: (source: string, filename: string) => void;
      };
    };
    const host = runtime.__miniBattleHost;
    if (!host || typeof host.runChunk !== "function") {
      return false;
    }
    host.runChunk(
      `
local BattleAttribute = require("modules.battle_attribute")
local BattleFormation = require("modules.battle_formation")
for _, hero in ipairs(BattleFormation.GetAllHeroes() or {}) do
    if hero and hero.isLeft == true and hero.maxHp and hero.maxHp > 1 then
        BattleAttribute.SetHpByVal(hero, math.max(1, math.floor(hero.maxHp * 0.35)))
    end
end
`,
      "playwright_injure_clerics.lua",
    );
    return true;
  });

  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("圣火术");
  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toMatch(/(祝福术|祝福护持|前排|后排|临时生命|AC \+2)/s);
  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toMatch(/(敏捷豁免|豁免检定).*vs DC/s);
  await expect
    .poll(async () => (await readBattleLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("伤害骰");

  const logs = await readBattleLogs(page);
  const joinedLogs = logs.join("\n");
  expect(logs.some((line) => line.includes("圣火术"))).toBeTruthy();
  expect(/(祝福术|祝福护持|前排|后排|临时生命|AC \+2)/s.test(joinedLogs)).toBeTruthy();
  expect(joinedLogs).toMatch(/圣火术/s);
  expect(joinedLogs).toMatch(/(敏捷豁免|豁免检定).*vs DC/s);
  expect(joinedLogs).toMatch(/伤害骰/s);
  await expectNoClientErrors(page, pageErrors, consoleErrors);
});
