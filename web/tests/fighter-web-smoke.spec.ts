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

function filterKnownNoise(errors: string[]) {
  return errors.filter(
    (message) => !message.includes("ERR_CONNECTION_REFUSED") && !message.includes("ERR_NETWORK_CHANGED"),
  );
}

function findLineIndex(logs: string[], matcher: (line: string) => boolean, startIndex = 0) {
  for (let index = startIndex; index < logs.length; index += 1) {
    if (matcher(logs[index])) {
      return index;
    }
  }
  return -1;
}

test("fighter web flow shows guard stance in the three-tier build", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910006&level=3&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("战士 使用 护卫架势");

  const level3LogLines = await page.locator(".battle-log li").allTextContents();
  const level3Logs = level3LogLines.join("\n");
  expect(level3Logs).toContain("护卫架势");
  expect(level3Logs).not.toContain("盾击");
  expect(level3Logs).not.toContain("顺劈");
  expect(level3Logs).not.toContain("旋风");

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910004&level=1&seed=101001");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("战士 使用 基础武器攻击");
  const level1Logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(level1Logs).toContain("基础武器攻击");
  expect(level1Logs).not.toContain("盾击");
  expect(level1Logs).not.toContain("顺劈");
  expect(level1Logs).not.toContain("旋风");

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-web-smoke.png", fullPage: true });
});

test("fighter low tier keeps counter instead of old extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=1&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 触发被动 反击：登记反击");
  const logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(logs).not.toContain("触发额外攻击：对同一目标");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter guard stance logs protection in the mid tier", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=3&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 使用 护卫架势");
  const logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(logs).toContain("护卫");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("fighter counter reaction logs when reaction is queued", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=4&fighterFeats=2100302,2100402&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 触发被动 反击：登记反击 将对 Orc 发动反击");
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 10000 })
    .toContain("战士 使用 基础武器攻击");

  const logs = await page.locator(".battle-log li").allTextContents();
  const attackIndex = logs.findIndex((line) => line.includes("Orc 使用 基础武器攻击"));
  const queueIndex = logs.findIndex((line) => line.includes("战士 触发被动 反击：登记反击 将对 Orc 发动反击"));
  const resultIndex = logs.findIndex((line) => line.includes("Orc 的 基础武器攻击 对 战士"));
  const counterIndex = logs.findIndex((line) => line.includes("战士 使用 基础武器攻击"));

  expect(attackIndex).toBeGreaterThanOrEqual(0);
  expect(queueIndex).toBeGreaterThan(attackIndex);
  expect(resultIndex).toBeGreaterThan(queueIndex);
  expect(counterIndex).toBeGreaterThan(resultIndex);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/fighter-counter-queued-log.png", fullPage: true });
});

test("fighter high tier keeps indomitable wind in the build", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=5&seed=101001");
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);

  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 12000 })
    .toContain("战士 使用 护卫架势");
  const logs = (await page.locator(".battle-log li").allTextContents()).join("\n");
  expect(logs).not.toContain("二次生命");
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
