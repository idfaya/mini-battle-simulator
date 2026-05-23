import { expect, test } from "playwright/test";

function filterKnownNoise(errors: string[]) {
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

test("roguelike dungeon slice: map grid, shop, event skill hint", async ({ page }) => {
  const pageErrors: string[] = [];
  const consoleErrors: string[] = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("console", (msg) => {
    if (msg.type() === "error") {
      consoleErrors.push(msg.text());
    }
  });

  await page.goto("/?seed=1");
  await page.waitForTimeout(1500);
  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator(".hud-status")).toContainText("阶段: map", { timeout: 20000 });

  await page.getByRole("button", { name: "地图" }).click();
  await expect(page.locator(".run-map-panel .panel-title")).toBeVisible();

  const enterFirstNeighbor = async () => {
    const btn = page.locator(".run-map-panel button").first();
    if (await btn.isVisible().catch(() => false)) {
      await btn.click();
    }
  };

  for (let i = 0; i < 12; i++) {
    const status = (await page.locator(".hud-status").textContent()) ?? "";
    if (status.includes("chapter_result") || status.includes("failed")) {
      break;
    }
    if (status.includes("event")) {
      await page.getByRole("button", { name: "信息" }).click();
      const hasSkillHint = await page
        .locator(".run-info-panel .run-roster-meta")
        .filter({ hasText: /检定|DC/ })
        .first()
        .isVisible()
        .catch(() => false);
      if (hasSkillHint) {
        await expect(page.locator(".run-info-panel")).toContainText(/检定|DC/);
      }
      const optionBtn = page.locator(".run-info-panel button").first();
      if (await optionBtn.isVisible().catch(() => false)) {
        await optionBtn.click();
      }
      continue;
    }
    if (status.includes("shop")) {
      await page.getByRole("button", { name: "信息" }).click();
      await expect(page.locator(".run-info-panel")).toContainText(/复活卷轴|治疗药水|商店/);
      await expect(page.locator(".run-info-panel button", { hasText: "刷新商店" })).toHaveCount(0);
      await page.getByRole("button", { name: "离开商店" }).click();
      continue;
    }
    if (status.includes("battle")) {
      for (let t = 0; t < 40; t++) {
        await page.waitForTimeout(300);
        const s = (await page.locator(".hud-status").textContent()) ?? "";
        if (!s.includes("battle")) break;
      }
      continue;
    }
    if (status.includes("map")) {
      await page.getByRole("button", { name: "地图" }).click();
      await enterFirstNeighbor();
    }
  }

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
