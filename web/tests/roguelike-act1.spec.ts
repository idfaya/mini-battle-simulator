import { expect, test } from "playwright/test";

test("roguelike act1 boots into map and can finish the chapter flow", async ({ page }) => {
  test.setTimeout(120000);
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
  await page.waitForTimeout(1500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator(".panel-title").first()).toContainText("第一章");

  const clickNodeAndEnter = async (nodeTitle: string) => {
    await page.getByRole("button", { name: new RegExp(nodeTitle) }).click();
    await page.getByRole("button", { name: "进入当前选择节点" }).click();
  };

  await clickNodeAndEnter("Frontier Scouts");
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toMatch(/battle|reward/);
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 60000 }).toContain("reward");
  await page.locator(".ult-panel button").first().click();

  await clickNodeAndEnter("Broken Caravan");
  await expect(page.getByRole("button", { name: "Salvage the crates" })).toBeVisible();
  await page.getByRole("button", { name: "Salvage the crates" }).click();

  await clickNodeAndEnter("Ash Merchant");
  await page.getByRole("button", { name: /recruit .*900001.*96/i }).click();
  await expect(page.getByText("候补编成")).toBeVisible();
  await page.getByRole("button", { name: "选择候补" }).first().click();
  await page.getByRole("button", { name: "替换上阵" }).first().click();
  await expect(page.getByRole("button", { name: "离开商店" })).toBeVisible();
  await page.getByRole("button", { name: "离开商店" }).click();

  await clickNodeAndEnter("Campfire Shrine");
  await expect(page.getByRole("button", { name: "Rest" })).toBeVisible();
  await page.getByRole("button", { name: "Rest" }).click();

  await clickNodeAndEnter("Ember Shrine");
  await expect(page.getByRole("button", { name: "Pray for recovery" })).toBeVisible();
  await page.getByRole("button", { name: "Pray for recovery" }).click();

  await clickNodeAndEnter("Quartermaster Halt");
  await expect(page.getByRole("button", { name: "离开商店" })).toBeVisible();
  await page.getByRole("button", { name: "离开商店" }).click();

  await clickNodeAndEnter("Frozen Gate");
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 20000 }).toMatch(/battle|reward|chapter_result/);
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 80000 }).toMatch(/reward|chapter_result/);
  const status = await page.locator(".hud-status").textContent();
  if (status?.includes("reward")) {
    await page.locator(".ult-panel button").first().click();
  }
  await expect(page.getByRole("button", { name: "重新开始第一章" })).toBeVisible({ timeout: 20000 });

  expect(pageErrors).toEqual([]);
  expect(consoleErrors).toEqual([]);
});
