/**
 * 反应技 hold 死亡释放回归。
 * 规则：反击/护卫 reactor 死亡后，source 攻击者须立即解除 hold；死亡单位不参与 clash 位移。
 * 实现：`web/app/render/BattleScene.ts` → `releaseDeadReactionHolds`
 * 文档：`docs/implementation_guidelines.md` §6.1
 */
import { expect, test } from "playwright/test";
import { collectClientErrors, filterKnownNoise } from "./helpers/client-errors";
import { forceKillRuntimeUnit, getAliveUnitIdByName } from "./helpers/battle-runtime";
import {
  waitForCounterHoldRelease,
  waitForCounterParticipants,
  waitForGuardHoldRelease,
  waitForGuardInterceptParticipants,
} from "./helpers/reaction-holds";

test("dead counter-attacker releases attacker hold immediately", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=4&fighterFeats=2100402&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  const participantsPromise = waitForCounterParticipants(page);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 触发被动 反击：登记反击");

  const participants = await participantsPromise;
  expect(participants).not.toBeNull();

  const fighterId = await getAliveUnitIdByName(page, "战士");
  expect(fighterId).not.toBe("");
  expect(await forceKillRuntimeUnit(page, fighterId)).toBe(true);

  expect(await waitForCounterHoldRelease(page, participants!.attackerId, participants!.reactorId, 400)).toBe(true);
  await expect.poll(async () => getAliveUnitIdByName(page, "战士"), { timeout: 1200 }).toBe("");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("dead guard skips guard counter and releases the intercept hold immediately", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005,900001&enemies=910002,910002,910002&level=5&seed=100003");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 触发被动 护卫架势：登记护卫反击");

  const intercept = await waitForGuardInterceptParticipants(page);
  expect(intercept).not.toBeNull();

  const guardId = await getAliveUnitIdByName(page, "战士");
  expect(guardId).not.toBe("");
  expect(await forceKillRuntimeUnit(page, guardId)).toBe(true);

  expect(await waitForGuardHoldRelease(page, intercept!.attackerId, intercept!.guardId, 400)).toBe(true);
  await expect.poll(async () => getAliveUnitIdByName(page, "战士"), { timeout: 1200 }).toBe("");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
