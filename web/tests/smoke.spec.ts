import { expect, test } from "playwright/test";

test("battle screen boots and renders actionable UI", async ({ page }) => {
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

  await page.goto("/");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator("#battle-level")).toHaveCount(1);
  await expect(page.locator("#battle-hero-count")).toHaveCount(1);
  await expect(page.locator("#battle-enemy-count")).toHaveCount(1);
  await expect(page.locator("#battle-speed")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(3);
  await expect
    .poll(async () => page.locator(".ult-button:not([disabled])").count(), { timeout: 6000 })
    .toBeGreaterThan(0);

  await page.locator(".ult-button:not([disabled])").first().dispatchEvent("pointerdown");
  await expect(page.locator(".battle-log li").first()).toContainText("已下达大招指令");

  const canvasReady = await page.evaluate(() => {
    const canvas = document.querySelector("canvas");
    if (!(canvas instanceof HTMLCanvasElement)) {
      return false;
    }
    const ctx = canvas.getContext("2d");
    if (!ctx) {
      return false;
    }
    const { width, height } = canvas;
    const sample = ctx.getImageData(Math.floor(width / 2), Math.floor(height / 2), 1, 1).data;
    return sample[3] > 0;
  });

  expect(canvasReady).toBeTruthy();
  expect(pageErrors).toEqual([]);
  expect(consoleErrors).toEqual([]);

  await page.screenshot({ path: "test-results/battle-smoke.png", fullPage: true });
});
