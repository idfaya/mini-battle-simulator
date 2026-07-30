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

  await page.getByRole("button", { name: "地图" }).click();
  await expect(page.locator(".run-map-overlay.is-active .run-direction-pad")).toBeVisible();
  await expect(page.locator(".run-team-card")).toHaveCount(4);
  await expect(page.locator("canvas")).toBeVisible();
  const mapDebugState = await page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        getRunSnapshot: () => Promise<{
          currentFloorDepth?: number | null;
          map?: {
            nodes?: Array<{ floor?: number; revealed?: boolean }>;
          };
        }>;
      };
      __miniBattleRenderer?: {
        getRunMapDebugState?: () => {
          totalNodes: number;
          revealedNodes: number;
          hiddenNodes: number;
          drawnRooms: number;
          drawnFogRooms: number;
          drawnEdges: number;
        };
      };
    };
    const snapshot = await runtime.__miniBattleHost?.getRunSnapshot();
    const currentFloor = snapshot?.currentFloorDepth ?? 1;
    const floorNodes = (snapshot?.map?.nodes ?? []).filter((node) => (node.floor ?? 1) === currentFloor);
    return {
      hiddenInSnapshot: floorNodes.filter((node) => node.revealed !== true).length,
      renderer: runtime.__miniBattleRenderer?.getRunMapDebugState?.() ?? null,
    };
  });
  expect(mapDebugState.hiddenInSnapshot).toBeGreaterThan(0);
  expect(mapDebugState.renderer).not.toBeNull();
  expect(mapDebugState.renderer?.hiddenNodes).toBeGreaterThan(0);
  expect(mapDebugState.renderer?.drawnFogRooms).toBeGreaterThan(0);
  expect((mapDebugState.renderer?.drawnRooms ?? 0) + (mapDebugState.renderer?.drawnFogRooms ?? 0)).toBeLessThanOrEqual(
    mapDebugState.renderer?.totalNodes ?? 0,
  );
  expect(mapDebugState.renderer?.drawnRooms).toBe(mapDebugState.renderer?.revealedNodes);

  const enterFirstNeighbor = async () => {
    const btn = page.locator(".run-map-overlay.is-active .run-direction-button").first();
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
      const modal = page.locator(".run-stage-modal");
      await expect(modal).toBeVisible();
      const hasSkillHint = await page
        .locator(".run-stage-modal")
        .filter({ hasText: /检定|DC/ })
        .first()
        .isVisible()
        .catch(() => false);
      if (hasSkillHint) {
        await expect(modal).toContainText(/检定|DC/);
      }
      const optionBtn = page.locator(".run-stage-modal button").first();
      if (await optionBtn.isVisible().catch(() => false)) {
        await optionBtn.click();
      }
      continue;
    }
    if (status.includes("shop")) {
      const shopModal = page.locator(".run-stage-modal--shop");
      await expect(shopModal).toBeVisible();
      await expect(shopModal).toContainText(/复活卷轴|治疗药水|商店/);
      await expect(shopModal.locator("button", { hasText: "刷新商店" })).toHaveCount(0);
      await shopModal.getByRole("button", { name: "离开商店" }).click();
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

test("roguelike mobile portrait keeps stage, formation, and bottom menu", async ({ page }) => {
  const consoleErrors: string[] = [];
  page.on("console", (msg) => {
    if (msg.type() === "error") {
      consoleErrors.push(msg.text());
    }
  });

  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/?seed=1");
  await page.waitForTimeout(1500);
  await expect(page.locator(".fatal-error")).toHaveCount(0);

  await expect(page.locator("canvas")).toBeVisible();
  await expect(page.locator(".run-map-overlay.is-active .run-direction-pad")).toBeVisible();
  await expect(page.getByRole("button", { name: "地图" })).toBeVisible();
  await expect(page.getByRole("button", { name: "队伍" })).toBeVisible();
  await expect(page.getByRole("button", { name: "信息" })).toBeVisible();
  await expect(page.getByRole("button", { name: "日志" })).toBeVisible();
  await expect(page.locator(".hud[data-screen='map'] .run-team-card").first()).toBeHidden();

  const debugState = await page.evaluate(() => {
    const runtime = window as typeof window & {
      __miniBattleRenderer?: {
        getRunMapDebugState?: () => {
          totalNodes: number;
          drawnRooms: number;
          drawnFogRooms: number;
        };
        getBattleDebugState?: () => {
          unitLayouts?: Array<{ id: string; team: string; isAlive: boolean }>;
        };
      };
    };
    return {
      map: runtime.__miniBattleRenderer?.getRunMapDebugState?.() ?? null,
      battle: runtime.__miniBattleRenderer?.getBattleDebugState?.() ?? null,
    };
  });
  expect(debugState.map).not.toBeNull();
  expect((debugState.map?.drawnRooms ?? 0) + (debugState.map?.drawnFogRooms ?? 0)).toBeGreaterThan(0);
  expect(debugState.battle?.unitLayouts?.filter((layout) => layout.team === "left")).toHaveLength(4);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);
});
