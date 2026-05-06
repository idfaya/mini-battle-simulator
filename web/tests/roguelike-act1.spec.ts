import { expect, test } from "playwright/test";

function filterKnownNoise(errors: string[]) {
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

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
  await expect(page.locator(".panel-title").filter({ hasText: "选择下一个节点" }).first()).toBeVisible();
  await page.getByRole("button", { name: "队伍" }).click();
  await expect(page.locator(".run-team-card").first()).toContainText("Fighter");
  await expect(page.locator(".run-team-card").first()).toContainText("构筑: 战士训练 / 二次生命");
  await page.getByRole("button", { name: "地图" }).click();

  const clickNodeAndEnter = async (nodeTitle: string) => {
    await page.getByRole("button", { name: new RegExp(nodeTitle) }).click();
  };

  const leaveBattleResultIfNeeded = async () => {
    const rewardButton = page.getByRole("button", { name: /查看\s*奖励/ }).first();
    if (await rewardButton.isVisible().catch(() => false)) {
      await rewardButton.dispatchEvent("pointerdown");
    }
  };

  const chooseFirstReward = async () => {
    await expect(page.locator(".hud-status")).toContainText("阶段: reward", { timeout: 15000 });
    await page.getByRole("button", { name: "信息" }).click();
    await expect(page.locator(".run-info-panel .panel-title").filter({ hasText: /选择升级|选择奖励/ })).toBeVisible({
      timeout: 15000,
    });
    const rewardCard = page.locator(".run-info-panel .reward-card").first();
    if (await rewardCard.isVisible().catch(() => false)) {
      await rewardCard.click();
      return;
    }
    await page.locator(".run-info-panel button").first().click();
  };

  await clickNodeAndEnter("Frontier Scouts");
  await expect
    .poll(
      async () => ({
        status: (await page.locator(".hud-status").textContent()) ?? "",
        hasRewardButton: await page.getByRole("button", { name: /查看\s*奖励/ }).first().isVisible().catch(() => false),
      }),
      { timeout: 60000 },
    )
    .toEqual(expect.objectContaining({ hasRewardButton: true }));
  await leaveBattleResultIfNeeded();
  await chooseFirstReward();
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Broken Caravan");
  await page.getByRole("button", { name: "信息" }).click();
  await expect(page.locator(".run-info-panel .panel-title").filter({ hasText: "选择招募" })).toBeVisible();
  await page.locator(".run-info-panel button").first().click();

  await clickNodeAndEnter("Frostbite Raid");
  await expect
    .poll(
      async () => ({
        status: (await page.locator(".hud-status").textContent()) ?? "",
        hasRewardButton: await page.getByRole("button", { name: /查看\s*奖励/ }).first().isVisible().catch(() => false),
      }),
      { timeout: 60000 },
    )
    .toEqual(expect.objectContaining({ hasRewardButton: true }));
  await leaveBattleResultIfNeeded();
  await chooseFirstReward();
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Campfire Shrine");
  await expect(page.getByRole("button", { name: "Sharpen" })).toBeVisible();
  await page.getByRole("button", { name: "Sharpen" }).click();

  await clickNodeAndEnter("Ember Ambush");
  await expect
    .poll(
      async () => ({
        status: (await page.locator(".hud-status").textContent()) ?? "",
        hasRewardButton: await page.getByRole("button", { name: /查看\s*奖励/ }).first().isVisible().catch(() => false),
      }),
      { timeout: 60000 },
    )
    .toEqual(expect.objectContaining({ hasRewardButton: true }));
  await leaveBattleResultIfNeeded();
  await chooseFirstReward();
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Stranded Allies");
  await page.getByRole("button", { name: "信息" }).click();
  await expect(page.locator(".run-info-panel .panel-title").filter({ hasText: "选择招募" })).toBeVisible();
  await page.locator(".run-info-panel button").first().click();

  await clickNodeAndEnter("Frozen Gate");
  await expect
    .poll(
      async () => ({
        status: (await page.locator(".hud-status").textContent()) ?? "",
        hasRewardButton: await page.getByRole("button", { name: /查看\s*奖励/ }).first().isVisible().catch(() => false),
      }),
      { timeout: 80000 },
    )
    .toEqual(
      expect.objectContaining({
        hasRewardButton: true,
      }),
    );
  await leaveBattleResultIfNeeded();
  await chooseFirstReward();
  await expect(page.getByRole("button", { name: "重新开始第一章" })).toBeVisible({ timeout: 20000 });

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
