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

test("cleric light route shows holy verdict and blessed strikes", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto(
    "/?mode=single-battle&heroes=900007&enemies=910005&level=5&buildFeats=2150201,2150302,2150401,2150501&seed=101002",
  );

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button-name")).toHaveText("Cleric");

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("基础神术");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("圣焰裁决");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("Blessed Strikes");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("基础神术"))).toBeTruthy();
  expect(logs.some((line) => line.includes("圣焰裁决"))).toBeTruthy();
  expect(logs.some((line) => line.includes("Blessed Strikes"))).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
