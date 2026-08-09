import { expect, test, type Page } from "playwright/test";
import { collectClientErrors, filterKnownNoise } from "./helpers/client-errors";

type RunSnapshotForTest = {
  phase?: string;
  cardBattle?: {
    phase?: string;
    teamEnergy?: number;
    maxEnergy?: number;
    hand?: Array<{
      uid: string;
      name?: string;
      type?: string;
      targetSide?: string;
      disabled?: boolean;
      cost?: number;
    }>;
    discardPileCount?: number;
    drawPileCount?: number;
    enemyIntents?: Array<unknown>;
  } | null;
  battleSnapshot?: {
    leftTeam?: Array<{ id: string; name?: string; isAlive?: boolean; hp?: number }>;
    rightTeam?: Array<{ id: string; name?: string; isAlive?: boolean; hp?: number }>;
  } | null;
  map?: {
    nodes?: Array<{
      id: number;
      nodeType?: string;
      selectable?: boolean;
      visited?: boolean;
      current?: boolean;
      floor?: number;
      lane?: number;
      gridX?: number;
      gridY?: number;
    }>;
  } | null;
  eventState?: {
    result?: unknown;
    options?: Array<{ id?: number; zeroRisk?: boolean }>;
  } | null;
  campState?: {
    actions?: Array<{ id?: number; available?: boolean }>;
  } | null;
  rewardState?: {
    options?: Array<unknown>;
  } | null;
};

async function getRunSnapshot(page: Page): Promise<RunSnapshotForTest> {
  return page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<RunSnapshotForTest>;
      };
    };
    const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
    if (!snapshot) {
      throw new Error("run snapshot is not ready");
    }
    return snapshot;
  });
}

async function waitForRunReady(page: Page) {
  await expect
    .poll(
      async () =>
        page.evaluate(async () => {
          const runtime = window as typeof window & {
            __miniBattleHost?: {
              getRunSnapshot: () => Promise<RunSnapshotForTest>;
            };
          };
          const snapshot = await runtime.__miniBattleHost?.getRunSnapshot().catch(() => null);
          return snapshot?.phase ?? "";
        }),
      { timeout: 20000 },
    )
    .not.toBe("");
}

async function driveToFirstCardBattle(page: Page) {
  for (let guard = 0; guard < 30; guard += 1) {
    const snapshot = await getRunSnapshot(page);
    if (snapshot.phase === "battle") {
      await expect(page.locator(".hud-status")).toContainText("牌局:", { timeout: 15000 });
      return;
    }
    if (snapshot.phase === "map") {
      const clickSlot = await page.evaluate(async () => {
        const runtime = window as typeof window & {
          __miniBattleHost?: {
            getRunSnapshot: () => Promise<RunSnapshotForTest>;
          };
        };
        const latest = await runtime.__miniBattleHost?.getRunSnapshot();
        const nodes = latest?.map?.nodes ?? [];
        const current = nodes.find((node) => node.current) ?? null;
        const selectable = nodes
          .filter((node) => node.selectable)
          .sort((a, b) => {
            if ((a.floor ?? 0) !== (b.floor ?? 0)) {
              return (a.floor ?? 0) - (b.floor ?? 0);
            }
            return (a.lane ?? 0) - (b.lane ?? 0);
          });
        const target =
          selectable.find((candidate) => !candidate.visited && candidate.nodeType === "battle_normal") ??
          selectable.find((candidate) => !candidate.visited && candidate.nodeType === "battle_elite") ??
          selectable[0];
        if (!target) {
          return "";
        }
        if (!current || current.gridX == null || current.gridY == null || target.gridX == null || target.gridY == null) {
          return "free";
        }
        const dx = target.gridX - current.gridX;
        const dy = target.gridY - current.gridY;
        if (dx === 0 && dy < 0) return "up";
        if (dx === 0 && dy > 0) return "down";
        if (dy === 0 && dx < 0) return "left";
        if (dy === 0 && dx > 0) return "right";
        return "free";
      });
      const button =
        clickSlot && clickSlot !== "free"
          ? page.locator(`.run-direction-cell--${clickSlot} .run-direction-button`).first()
          : page.locator(".run-direction-button").first();
      await expect(button).toBeVisible({ timeout: 10000 });
      await button.click();
      await page.waitForTimeout(250);
      continue;
    }
    if (snapshot.phase === "event") {
      const button = page.locator(".run-stage-modal button").first();
      await expect(button).toBeVisible({ timeout: 10000 });
      await button.click();
      await page.waitForTimeout(250);
      continue;
    }
    if (snapshot.phase === "reward") {
      const button = page.locator(".run-stage-modal button").first();
      await expect(button).toBeVisible({ timeout: 10000 });
      await button.click();
      await page.waitForTimeout(250);
      continue;
    }
    if (snapshot.phase === "shop") {
      const leave = page.getByRole("button", { name: "离开商店" });
      await expect(leave).toBeVisible({ timeout: 10000 });
      await leave.click();
      await page.waitForTimeout(250);
      continue;
    }
    if (snapshot.phase === "camp") {
      const button = page.locator(".run-stage-modal button").first();
      await expect(button).toBeVisible({ timeout: 10000 });
      await button.click();
      await page.waitForTimeout(250);
      continue;
    }
    if (snapshot.phase === "stair") {
      const button = page.locator(".run-direction-button").first();
      await expect(button).toBeVisible({ timeout: 10000 });
      await button.click();
      await page.waitForTimeout(250);
      continue;
    }
    throw new Error(`unexpected phase before battle: ${snapshot.phase ?? ""}`);
  }
  throw new Error("failed to enter battle");
}

test("roguelike card battle supports real hand click, target click, and end turn", async ({ page }) => {
  const { pageErrors, consoleErrors } = await collectClientErrors(page);

  await page.goto("/?seed=1");
  await page.waitForLoadState("networkidle");
  await waitForRunReady(page);
  await expect(page.locator(".hud-status")).toContainText("阶段: map", { timeout: 10000 });
  await expect(page.locator(".fatal-error")).toHaveCount(0);

  await driveToFirstCardBattle(page);

  await expect(page.locator(".battle-card-button").first()).toBeVisible({ timeout: 15000 });
  await expect(page.locator(".battle-card-missing")).toHaveCount(0);
  await expect(page.locator(".hud-status")).toContainText("牌局: player");

  const before = await getRunSnapshot(page);
  expect(before.cardBattle?.phase).toBe("player");
  expect(before.cardBattle?.hand?.length ?? 0).toBeGreaterThan(0);
  expect(before.cardBattle?.enemyIntents?.length ?? 0).toBeGreaterThan(0);
  expect(before.battleSnapshot?.rightTeam?.some((unit) => unit.isAlive !== false && (unit.hp ?? 0) > 0)).toBe(true);

  const playableCard = page.locator(".battle-card-button.ready[data-target-side='enemy']").first();
  await expect(playableCard).toBeVisible();
  const beforeHandCount = before.cardBattle?.hand?.length ?? 0;
  const beforeEnergy = before.cardBattle?.teamEnergy ?? 0;
  await page.evaluate(() => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        playCard: (cardUid: string, targetId?: string) => Promise<{ events?: Array<{ type?: string }> }>;
      };
      __lastPlayCardEventTypes?: string[];
    };
    const host = runtime.__miniBattleHost;
    if (!host || runtime.__lastPlayCardEventTypes) {
      return;
    }
    const originalPlayCard = host.playCard.bind(host);
    host.playCard = async (cardUid: string, targetId?: string) => {
      const response = await originalPlayCard(cardUid, targetId);
      runtime.__lastPlayCardEventTypes = (response.events ?? []).map((event) => String(event.type ?? ""));
      return response;
    };
  });
  await playableCard.click();
  await expect(page.locator(".battle-target-button")).toHaveCount(0);

  const targetPoint = await page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<RunSnapshotForTest>;
      };
      __miniBattleRenderer?: {
        canvas: HTMLCanvasElement;
        pickBattleUnit: (clientX: number, clientY: number) => { id: string } | null;
      };
    };
    const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
    const renderer = runtime.__miniBattleRenderer;
    if (!snapshot?.battleSnapshot || !renderer) {
      throw new Error("battle renderer is not ready");
    }
    const aliveEnemies = (snapshot.battleSnapshot.rightTeam ?? []).filter((unit) => unit.isAlive !== false && (unit.hp ?? 0) > 0);
    const frontEnemies = aliveEnemies.filter((unit) => {
      const position = Number((unit as { position?: number }).position ?? 0);
      return position >= 1 && position <= 3;
    });
    const targetIds = new Set((frontEnemies.length > 0 ? frontEnemies : aliveEnemies).map((unit) => String(unit.id)));
    const rect = renderer.canvas.getBoundingClientRect();
    for (let y = rect.top + 20; y < rect.bottom - 20; y += 12) {
      for (let x = rect.left + 20; x < rect.right - 20; x += 12) {
        const picked = renderer.pickBattleUnit(x, y);
        if (picked && targetIds.has(String(picked.id))) {
          return { x, y };
        }
      }
    }
    throw new Error("failed to find clickable enemy on canvas");
  });
  await page.mouse.click(targetPoint.x, targetPoint.y);
  await expect
    .poll(
      () =>
        page.evaluate(() => {
          const runtime = window as typeof window & { __lastPlayCardEventTypes?: string[] };
          return runtime.__lastPlayCardEventTypes ?? [];
        }),
      { timeout: 10000 },
    )
    .toContain("skill_timeline_frame");

  await expect
    .poll(async () => {
      const snapshot = await getRunSnapshot(page);
      return {
        handCount: snapshot.cardBattle?.hand?.length ?? 0,
        teamEnergy: snapshot.cardBattle?.teamEnergy ?? 0,
        discardPileCount: snapshot.cardBattle?.discardPileCount ?? 0,
      };
    }, { timeout: 10000 })
    .toMatchObject({
      handCount: beforeHandCount - 1,
    });

  const afterPlay = await getRunSnapshot(page);
  expect(afterPlay.cardBattle?.phase).toBe("player");
  expect(afterPlay.cardBattle?.teamEnergy ?? beforeEnergy).toBeLessThanOrEqual(beforeEnergy);

  const endTurn = page.locator("button.battle-end-turn-button:visible").first();
  await expect(endTurn).toBeVisible();
  await endTurn.click();

  await expect
    .poll(async () => {
      const snapshot = await getRunSnapshot(page);
      return {
        phase: snapshot.phase,
        cardPhase: snapshot.cardBattle?.phase,
        handCount: snapshot.cardBattle?.hand?.length ?? 0,
      };
    }, { timeout: 15000 })
    .toMatchObject({
      phase: "battle",
      cardPhase: "player",
    });

  const afterEndTurn = await getRunSnapshot(page);
  expect(afterEndTurn.cardBattle?.hand?.length ?? 0).toBeGreaterThan(0);
  expect(afterEndTurn.cardBattle?.teamEnergy).toBe(afterEndTurn.cardBattle?.maxEnergy);

  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
