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
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

async function readLogs(page: import("playwright/test").Page) {
  return page.locator(".battle-log li").allTextContents();
}

test("monk smoke shows martial arts chain, subclass action and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900001&enemies=910006&level=5&buildFeats=2110203,2110302,2110402,2110502&seed=101001",
  );

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button-name")).toHaveText("Monk");

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("武艺");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("影步连打");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("触发额外攻击：对同一目标");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("触发武艺："))).toBeTruthy();
  expect(logs.some((line) => line.includes("使用 影步连打"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发额外攻击：对同一目标"))).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("paladin smoke shows judgement prayer, divine smite and oath action", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900009&enemies=910006&level=5&buildFeats=2120203,2120302,2120401,2120501&seed=101001",
  );

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button-name")).toHaveText("Paladin");

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("复仇裁击");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("触发裁决祷法：");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("触发神圣惩击：");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("触发额外攻击：对同一目标");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("使用 复仇裁击"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发裁决祷法："))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发神圣惩击："))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发额外攻击：对同一目标"))).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});

test("ranger smoke shows hunter mark loop, subclass shot and extra attack", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900008&enemies=910006&level=5&buildFeats=2130202,2130301,2130401,2130501&seed=101001",
  );

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button-name")).toHaveText("Ranger");

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("猎人印记");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("猎杀箭");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("触发额外攻击：对同一目标");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("施加猎人印记"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发猎人印记："))).toBeTruthy();
  expect(logs.some((line) => line.includes("使用 猎杀箭"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发额外攻击：对同一目标"))).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
