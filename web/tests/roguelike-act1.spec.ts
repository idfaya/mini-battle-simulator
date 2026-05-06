import { expect, test } from "playwright/test";

function filterKnownNoise(errors: string[]) {
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

async function driveBattleUntilResolved(page: import("playwright/test").Page, timeout = 60000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    await page.evaluate(async () => {
      const runtime = window as typeof window & {
        __miniBattleHost?: {
          getRunSnapshot: () => Promise<{
            battleSnapshot?: {
              pendingCommands: number;
              leftTeam: Array<{ id: string; isAlive: boolean; ultimateReady: boolean; ultimateSkillName?: string }>;
            };
          }>;
          queueRunBattleCommand: (command: { type: "cast_ultimate"; heroId: string }) => Promise<boolean>;
        };
      };
      const host = runtime.__miniBattleHost;
      if (!host) {
        return;
      }
      const snapshot = await host.getRunSnapshot();
      const battle = snapshot.battleSnapshot;
      if (!battle || battle.pendingCommands !== 0) {
        return;
      }
      const outputUnit = battle.leftTeam.find((unit) => {
        if (!unit.isAlive || unit.ultimateReady !== true) {
          return false;
        }
        const skillName = unit.ultimateSkillName || "";
        return !/heal|healing|revive|复活|治疗/i.test(skillName);
      });
      if (outputUnit) {
        await host.queueRunBattleCommand({ type: "cast_ultimate", heroId: outputUnit.id });
      }
    });
    const hasRewardButton = await page.getByRole("button", { name: /查看\s*奖励/ }).first().isVisible().catch(() => false);
    const hasRestartButton = await page.getByRole("button", { name: "重新开始第一章" }).isVisible().catch(() => false);
    if (hasRewardButton || hasRestartButton) {
      return;
    }
    await page.waitForTimeout(250);
  }
  throw new Error("battle did not resolve in time");
}

async function chooseRewardIndex(page: import("playwright/test").Page) {
  return page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<{
          rewardState?: { kind?: string; options?: Array<{ heroName?: string; label?: string; rewardType?: string }> };
          team?: Array<{ name?: string }>;
          bench?: Array<{ name?: string }>;
        }>;
      };
    };
    const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
    const reward = snapshot?.rewardState;
    if (!reward?.options?.length) {
      return 0;
    }
    if (reward.kind === "node_recruit") {
      const existing = new Set<string>();
      for (const hero of snapshot?.team ?? []) {
        if (hero.name) {
          existing.add(hero.name);
        }
      }
      for (const hero of snapshot?.bench ?? []) {
        if (hero.name) {
          existing.add(hero.name);
        }
      }
      const uniqueIndex = reward.options.findIndex((option) => {
        const heroName = (option.heroName ?? option.label ?? "").replace(/^招募\s+/, "");
        return heroName !== "" && !existing.has(heroName);
      });
      if (uniqueIndex >= 0) {
        return uniqueIndex;
      }
    }
    return 0;
  });
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

  await page.goto("/?seed=10102");
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
    await page.evaluate(() => {
      const rewardButton = Array.from(document.querySelectorAll("button")).find((button) =>
        /查看\s*奖励/.test(button.textContent || ""),
      );
      rewardButton?.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));
    });
  };

  const resolveRewardChain = async (titlePattern: RegExp) => {
    for (let guard = 0; guard < 4; guard += 1) {
      const status = (await page.locator(".hud-status").textContent()) ?? "";
      if (status.includes("阶段: map") || status.includes("阶段: chapter_result")) {
        return;
      }
      await expect
        .poll(async () => {
          await leaveBattleResultIfNeeded();
          return (await page.locator(".hud-status").textContent()) ?? "";
        }, { timeout: 15000 })
        .not.toContain("阶段: failed");
      const currentStatus = (await page.locator(".hud-status").textContent()) ?? "";
      if (currentStatus.includes("阶段: map") || currentStatus.includes("阶段: chapter_result")) {
        return;
      }
      expect(currentStatus).toContain("阶段: reward");
      await page.getByRole("button", { name: "信息" }).click();
      await expect(page.locator(".run-info-panel .panel-title").filter({ hasText: titlePattern })).toBeVisible({
        timeout: 15000,
      });
      const rewardIndex = await chooseRewardIndex(page);
      const rewardCard = page.locator(".run-info-panel .reward-card").nth(rewardIndex);
      if (await rewardCard.isVisible().catch(() => false)) {
        await rewardCard.click();
      } else {
        await page.locator(".run-info-panel button").nth(rewardIndex).click();
      }
    }
  };

  await clickNodeAndEnter("Frontier Scouts");
  await driveBattleUntilResolved(page);
  await resolveRewardChain(/选择升级|选择奖励/);
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Broken Caravan");
  await resolveRewardChain(/选择招募/);
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Frostbite Raid");
  await driveBattleUntilResolved(page);
  await resolveRewardChain(/选择升级|选择奖励/);
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Campfire Shrine");
  await expect(page.getByRole("button", { name: "Sharpen" })).toBeVisible();
  await page.getByRole("button", { name: "Sharpen" }).click();

  await clickNodeAndEnter("Ember Ambush");
  await driveBattleUntilResolved(page);
  await resolveRewardChain(/选择升级|选择奖励/);
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Stranded Allies");
  await resolveRewardChain(/选择招募/);
  await expect.poll(async () => page.locator(".hud-status").textContent(), { timeout: 15000 }).toContain("阶段: map");

  await clickNodeAndEnter("Frozen Gate");
  await driveBattleUntilResolved(page, 80000);
  await resolveRewardChain(/选择升级|选择奖励/);
  await expect(page.getByRole("button", { name: "重新开始第一章" })).toBeVisible({ timeout: 20000 });

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
