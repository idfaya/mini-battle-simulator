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

test("barbarian smoke shows rage, heavy strike and berserk pipeline", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?mode=single-battle&heroes=900010&enemies=910003,910003,910003&level=5&seed=101001");

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);

  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("重击");
  await expect
    .poll(async () => (await readLogs(page)).join("\n"), { timeout: 15000 })
    .toContain("狂怒");

  const logs = await readLogs(page);
  expect(logs.some((line) => line.includes("重击"))).toBeTruthy();
  expect(logs.some((line) => line.includes("触发被动 狂怒"))).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
