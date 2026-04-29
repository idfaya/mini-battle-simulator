import { expect, test } from "playwright/test";

async function collectClientErrors(page: import("playwright/test").Page) {
  const pageErrors: string[] = [];
  const consoleErrors: string[] = [];

  page.on("pageerror", (error) => {
    pageErrors.push(error.message);
  });
  page.on("console", (message) => {
    if (message.type() === "error") {
      consoleErrors.push(message.text());
    }
  });

  return { pageErrors, consoleErrors };
}

test("fighter web flow shows rebuilt names and can cast action surge", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910004&level=3&fighterFeats=2100201,2100301&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(1);
  await expect(page.locator(".ult-button-name")).toHaveText("Tank");
  await expect(page.locator(".ult-button-charges")).toContainText("1/1");

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("Tank 使用 动作激增");

  const level3Logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(level3Logs).toContain("动作激增");
  expect(level3Logs).not.toContain("盾击");
  expect(level3Logs).not.toContain("顺劈");
  expect(level3Logs).not.toContain("旋风");

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910004&level=1&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("Tank 使用 基础武器攻击");
  const level1Logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(level1Logs).toContain("基础武器攻击");
  expect(level1Logs).not.toContain("盾击");
  expect(level1Logs).not.toContain("顺劈");
  expect(level1Logs).not.toContain("旋风");

  expect(pageErrors).toEqual([]);
  expect(consoleErrors).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-web-smoke.png", fullPage: true });
});

test("fighter counter reaction logs when reaction is queued", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=2&fighterFeats=2100101,2100102,2100203&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("Tank 触发被动 反击战法：登记反击 将对 Orc 发动反击");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("Tank 使用 基础武器攻击");

  const logs = await page.locator(".battle-log li").allTextContents();
  const attackIndex = logs.findIndex((line) => line.includes("Orc 使用 基础武器攻击"));
  const queueIndex = logs.findIndex((line) => line.includes("Tank 触发被动 反击战法：登记反击 将对 Orc 发动反击"));
  const resultIndex = logs.findIndex((line) => line.includes("Orc 的 基础武器攻击 对 Tank"));
  const counterIndex = logs.findIndex((line) => line.includes("Tank 使用 基础武器攻击"));

  expect(attackIndex).toBeGreaterThanOrEqual(0);
  expect(queueIndex).toBeGreaterThan(attackIndex);
  expect(resultIndex).toBeGreaterThan(queueIndex);
  expect(counterIndex).toBeGreaterThan(resultIndex);
  expect(pageErrors).toEqual([]);
  expect(consoleErrors).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-counter-queued-log.png", fullPage: true });
});

test("fighter guard reaction logs when ally attack queues guard counter", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  const perHeroBuilds = "2100201,2100303|2100201,2100301|2100203,2100302";
  await page.goto(
    `/?mode=single-battle&heroes=900005,900005,900005&enemies=910003,910003,910003&level=3&fighterFeatsByHero=${perHeroBuilds}&seed=101001`,
  );
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("Tank 使用 护卫架势");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("Tank 的 护卫架势 未产生效果");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("Tank 触发被动 护卫架势：登记护卫反击 将对 Orc 发动护卫反击");

  const logs = await page.locator(".battle-log li").allTextContents();
  const stanceIndex = logs.findIndex((line) => line.includes("Tank 使用 护卫架势"));
  const queueIndex = logs.findIndex((line) => line.includes("Tank 触发被动 护卫架势：登记护卫反击 将对 Orc 发动护卫反击"));
  const resultIndex = logs.findIndex(
    (line, index) => index > queueIndex && line.includes("Orc 的 基础武器攻击 对 Tank"),
  );

  expect(stanceIndex).toBeGreaterThanOrEqual(0);
  expect(queueIndex).toBeGreaterThan(stanceIndex);
  expect(resultIndex).toBeGreaterThan(queueIndex);
  expect(pageErrors).toEqual([]);
  expect(consoleErrors).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-guard-queued-log.png", fullPage: true });
});
