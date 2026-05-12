import { expect, test } from "playwright/test";

function filterKnownNoise(errors: string[]) {
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

async function driveBattleUntilResolved(page: import("playwright/test").Page, timeout = 90000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const phase = await page.evaluate(async () => {
      const runtime = window as typeof window & {
        __miniBattleHost?: {
          tickRun: (deltaMs: number) => Promise<{
            snapshot: {
              phase?: string;
              battleSnapshot?: {
                pendingCommands: number;
                leftTeam: Array<{ id: string; isAlive: boolean; ultimateReady: boolean; ultimateSkillName?: string }>;
              };
            };
          }>;
          getRunSnapshot: () => Promise<{
            phase?: string;
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
        return "missing_host";
      }
      const ticked = await host.tickRun(600);
      const snapshot = ticked?.snapshot ?? (await host.getRunSnapshot());
      if (snapshot.phase && snapshot.phase !== "battle") {
        return snapshot.phase;
      }
      const battle = snapshot.battleSnapshot;
      if (!battle || battle.pendingCommands !== 0) {
        return snapshot.phase ?? "battle";
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
      return snapshot.phase ?? "battle";
    });
    if (phase && phase !== "battle") {
      return;
    }
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
    const heroQuality: Record<number, number> = {
      900001: 3,
      900002: 4,
      900003: 4,
      900004: 4,
      900005: 5,
      900006: 3,
      900007: 4,
      900008: 4,
      900009: 4,
      900010: 4,
    };
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<{
          rewardState?: { kind?: string; options?: Array<{ heroName?: string; label?: string; rewardType?: string; refId?: number }> };
          team?: Array<{ name?: string; heroId?: number }>;
          bench?: Array<{ name?: string; heroId?: number }>;
          maxHeroCount?: number;
        }>;
      };
    };
    const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
    const reward = snapshot?.rewardState;
    if (!reward?.options?.length) {
      return 0;
    }
    if (reward.kind === "node_recruit") {
      const existing = new Set<number>();
      for (const hero of snapshot?.team ?? []) {
        if (hero.heroId) {
          existing.add(hero.heroId);
        }
      }
      for (const hero of snapshot?.bench ?? []) {
        if (hero.heroId) {
          existing.add(hero.heroId);
        }
      }
      let bestIndex = -1;
      let bestQuality = -1;
      reward.options.forEach((option, index) => {
        const heroId = option.refId ?? 0;
        if (!heroId || existing.has(heroId)) {
          return;
        }
        const quality = heroQuality[heroId] ?? 1;
        if (quality > bestQuality) {
          bestIndex = index;
          bestQuality = quality;
        }
      });
      if (bestIndex >= 0) {
        return bestIndex;
      }
    }
    return 0;
  });
}

async function autoPromoteBench(page: import("playwright/test").Page) {
  await page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<{
          team?: Array<{ rosterId?: number }>;
          bench?: Array<{ rosterId?: number }>;
          maxHeroCount?: number;
        }>;
        promoteBenchHero: (benchRosterId: number) => Promise<{ accepted?: boolean }>;
      };
    };
    const host = runtime.__miniBattleHost;
    if (!host) {
      return;
    }
    let snapshot = await host.getRunSnapshot();
    while ((snapshot.bench?.length ?? 0) > 0 && (snapshot.team?.length ?? 0) < (snapshot.maxHeroCount ?? 5)) {
      const benchHero = snapshot.bench?.[0];
      if (!benchHero?.rosterId) {
        break;
      }
      await host.promoteBenchHero(benchHero.rosterId);
      snapshot = await host.getRunSnapshot();
    }
  });
}

async function chooseCampAction(page: import("playwright/test").Page) {
  return page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<{
          team?: Array<{ hp?: number; isDead?: boolean }>;
          campState?: { actions?: Array<{ id?: number; available?: boolean }> };
        }>;
      };
    };
    const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
    const hasDeadHero = (snapshot?.team ?? []).some((hero) => hero.isDead === true || (hero.hp ?? 0) <= 0);
    const actions = snapshot?.campState?.actions ?? [];
    if (hasDeadHero) {
      const rescue = actions.find((action) => action.id === 1 && action.available !== false);
      if (rescue?.id) {
        return rescue.id;
      }
    }
    const sharpen = actions.find((action) => action.id === 2 && action.available !== false);
    if (sharpen?.id) {
      return sharpen.id;
    }
    return actions.find((action) => action.available !== false)?.id ?? 1;
  });
}

async function applyCampAction(page: import("playwright/test").Page, actionId: number) {
  await page.evaluate(async (selectedActionId) => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        campChoose: (actionId: number) => Promise<{ accepted?: boolean }>;
      };
    };
    await runtime.__miniBattleHost?.campChoose(selectedActionId);
  }, actionId);
}

async function getRunPhase(page: import("playwright/test").Page) {
  return page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<{ phase?: string }>;
      };
    };
    const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
    return snapshot?.phase ?? "";
  });
}

async function applyRewardChoice(page: import("playwright/test").Page, rewardIndex: number) {
  await page.evaluate(async (selectedRewardIndex) => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        chooseReward: (index: number) => Promise<{ accepted?: boolean }>;
      };
    };
    await runtime.__miniBattleHost?.chooseReward(selectedRewardIndex);
  }, rewardIndex + 1);
}

test("roguelike act1 boots into map and can finish the chapter flow", async ({ page }) => {
  test.setTimeout(180000);
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
  await expect(page.locator(".run-team-card").first()).toContainText("战士");
  await expect(page.locator(".run-team-card").first()).toContainText("构筑: 战士训练 / 反击");
  await page.getByRole("button", { name: "地图" }).click();

  const chooseNodeAndEnter = async (preferredTypes: string[]) => {
    const chosen = await page.evaluate(async (types) => {
      const runtime = window as typeof window & {
        __miniBattleHost?: {
          getRunSnapshot: () => Promise<{
            map?: {
              nodes?: Array<{ id: number; nodeType?: string; title?: string; selectable?: boolean }>;
            };
          }>;
          choosePath: (nodeId: number) => Promise<boolean>;
          enterNode: () => Promise<boolean>;
        };
      };
      const host = runtime.__miniBattleHost;
      if (!host) {
        return null;
      }
      const snapshot = await host.getRunSnapshot();
      const selectable = (snapshot.map?.nodes ?? []).filter((node) => node.selectable);
      const selected =
        types
          .map((type) => selectable.find((node) => node.nodeType === type))
          .find((node) => Boolean(node)) ?? selectable[0] ?? null;
      if (!selected) {
        return null;
      }
      await host.choosePath(selected.id);
      await host.enterNode();
      return {
        id: selected.id,
        nodeType: selected.nodeType ?? "",
        title: selected.title ?? "",
      };
    }, preferredTypes);
    expect(chosen).not.toBeNull();
    return chosen;
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
    const getSnapshotPhase = async () =>
      page.evaluate(async () => {
        const runtime = window as typeof window & {
          __miniBattleHost?: {
            getRunSnapshot: () => Promise<{ phase?: string }>;
          };
        };
        const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
        return snapshot?.phase ?? "";
      });
    for (let guard = 0; guard < 4; guard += 1) {
      const phase = await getSnapshotPhase();
      if (phase === "map" || phase === "chapter_result" || phase === "failed") {
        return;
      }
      await expect
        .poll(async () => {
          await leaveBattleResultIfNeeded();
          return getSnapshotPhase();
        }, { timeout: 15000 })
        .not.toBe("failed");
      const currentPhase = await getSnapshotPhase();
      if (currentPhase === "map" || currentPhase === "chapter_result" || currentPhase === "failed") {
        return;
      }
      expect(currentPhase).toBe("reward");
      await page.getByRole("button", { name: "信息" }).click();
      const title = page.locator(".run-info-panel .panel-title").filter({ hasText: titlePattern });
      const hasExpectedTitle = await title.isVisible({ timeout: 1500 }).catch(() => false);
      if (!hasExpectedTitle) {
        const status = (await page.locator(".hud-status").textContent()) ?? "";
        if (status.includes("阶段: map") || status.includes("阶段: chapter_result")) {
          return;
        }
        await expect(title).toBeVisible({ timeout: 15000 });
      }
      const rewardIndex = await chooseRewardIndex(page);
      await applyRewardChoice(page, rewardIndex);
      await autoPromoteBench(page);
    }
  };

  for (let guard = 0; guard < 24; guard += 1) {
    const phase = await getRunPhase(page);
    if (phase === "chapter_result" || phase === "failed") {
      break;
    }
    if (phase === "map") {
      await chooseNodeAndEnter(["recruit", "camp", "shop", "event", "battle_normal", "battle_elite", "boss"]);
      continue;
    }
    if (phase === "battle") {
      await driveBattleUntilResolved(page, 80000);
      continue;
    }
    if (phase === "reward") {
      await resolveRewardChain(/选择职业卡|选择升级|选择奖励|选择招募/);
      continue;
    }
    if (phase === "camp") {
      const campActionId = await chooseCampAction(page);
      await applyCampAction(page, campActionId);
      continue;
    }
    if (phase === "shop") {
      await page.evaluate(async () => {
        await (window as typeof window & {
          __miniBattleHost?: { shopLeave: () => Promise<{ accepted?: boolean }> };
        }).__miniBattleHost?.shopLeave();
      });
      continue;
    }
    if (phase === "event") {
      await page.evaluate(async () => {
        const runtime = window as typeof window & {
          __miniBattleHost?: {
            getRunSnapshot: () => Promise<{ eventState?: { options?: Array<{ id?: number }> } }>;
            chooseEventOption: (optionId: number) => Promise<{ accepted?: boolean }>;
          };
        };
        const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
        const optionId = snapshot?.eventState?.options?.[0]?.id ?? 1;
        await runtime.__miniBattleHost?.chooseEventOption(optionId);
      });
      continue;
    }
  }
  await expect
    .poll(async () => getRunPhase(page), { timeout: 20000 })
    .toMatch(/chapter_result|failed/);
  await page.getByRole("button", { name: "信息" }).click();
  await expect(page.getByRole("button", { name: "重新开始第一章" })).toBeVisible({ timeout: 20000 });

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
