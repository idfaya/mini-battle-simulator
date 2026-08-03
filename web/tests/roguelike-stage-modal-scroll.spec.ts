import { expect, test } from "playwright/test";

test("roguelike stage modals keep scroll position across UI refreshes", async ({ page }) => {
  await page.goto("/");
  await page.waitForLoadState("networkidle");

  const result = await page.evaluate(async () => {
    const { createRunControls, renderRunControls } = await import("/app/ui/runControls.ts");

    const handlers = {
      onChooseNode: () => {},
      onEnterNode: () => {},
      onChooseEventOption: () => {},
      onContinueEvent: () => {},
      onChooseReward: () => {},
      onShopBuy: () => {},
      onShopRefresh: () => {},
      onShopLeave: () => {},
      onPromoteBenchHero: () => {},
      onSwapBenchWithTeam: () => {},
      onCampChoose: () => {},
      onStairUse: () => {},
      onStairLeave: () => {},
      onRestart: () => {},
    };

    const baseSnapshot = {
      phase: "event",
      chapterId: 101,
      currentNodeId: 1,
      maxHeroCount: 4,
      partyLevel: 1,
      partyExp: 0,
      levelProgressExp: 0,
      nextLevelExp: 100,
      gold: 100,
      food: 6,
      lastActionMessage: "",
      map: null,
      team: [],
      bench: [],
      equipments: [],
      blessings: [],
      trinkets: [],
      eventState: null,
      shopState: null,
      campState: null,
      stairState: null,
      rewardState: null,
      lastBattleSummary: null,
      battleSnapshot: null,
      chapterResult: null,
      debug: { availableNextNodeIds: [] },
    };

    const controls = createRunControls(handlers);
    document.body.append(controls.root);
    const style = document.createElement("style");
    style.textContent = ".run-stage-modal__body{max-height:72px!important;}";
    document.head.append(style);

    const eventSnapshot = {
      ...baseSnapshot,
      phase: "event",
      eventState: {
        id: 11,
        chapterId: 101,
        code: "long_event",
        title: "长事件",
        kind: "test",
        options: Array.from({ length: 8 }, (_, index) => ({
          id: index + 1,
          label: `事件选项 ${index + 1}`,
          zeroRisk: index === 0,
          skillCheck: { ability: "investigation", dc: 10 + index },
        })),
        result: null,
      },
    };

    renderRunControls(controls, eventSnapshot as never, []);
    const eventBody = controls.mapOverlay.querySelector<HTMLElement>(".run-stage-modal__body");
    if (!eventBody) {
      return { eventBefore: -1, eventAfter: -1, shopBefore: -1, shopAfter: -1, leaveBefore: false, leaveAfter: false };
    }
    eventBody.scrollTop = 999;
    const eventBefore = eventBody.scrollTop;
    renderRunControls(controls, eventSnapshot as never, []);
    const eventAfter = controls.mapOverlay.querySelector<HTMLElement>(".run-stage-modal__body")?.scrollTop ?? -1;

    const shopSnapshot = {
      ...baseSnapshot,
      phase: "shop",
      shopState: {
        shopId: 21,
        name: "长商店",
        refreshCost: 20,
        refreshCount: 0,
        maxRefresh: 1,
        goods: Array.from({ length: 9 }, (_, index) => ({
          goodsId: index + 1,
          goodsType: "item",
          name: `商品 ${index + 1}`,
          description: "很长的商品说明，用来制造滚动内容",
          price: 10,
          rarity: "common",
          sold: false,
        })),
      },
    };

    renderRunControls(controls, shopSnapshot as never, []);
    const shopGoods = controls.mapOverlay.querySelector<HTMLElement>(".run-shop-goods");
    const leaveButton = controls.mapOverlay.querySelector<HTMLButtonElement>(".run-shop-actions button:last-child");
    const leaveBefore = leaveButton
      ? (() => {
          const modalRect = controls.mapOverlay.querySelector<HTMLElement>(".run-stage-modal")?.getBoundingClientRect();
          const buttonRect = leaveButton.getBoundingClientRect();
          return !!modalRect && buttonRect.bottom <= modalRect.bottom && buttonRect.top >= modalRect.top;
        })()
      : false;
    if (!shopGoods) return { eventBefore, eventAfter, shopBefore: -1, shopAfter: -1, leaveBefore, leaveAfter: false };
    shopGoods.scrollTop = 999;
    const shopBefore = shopGoods.scrollTop;
    renderRunControls(
      controls,
      {
        ...shopSnapshot,
        gold: 90,
        shopState: {
          ...shopSnapshot.shopState,
          goods: shopSnapshot.shopState.goods.map((goods, index) =>
            index === 0 ? { ...goods, sold: true } : goods,
          ),
        },
      } as never,
      [],
    );
    const shopAfter = controls.mapOverlay.querySelector<HTMLElement>(".run-shop-goods")?.scrollTop ?? -1;
    const nextLeaveButton = controls.mapOverlay.querySelector<HTMLButtonElement>(".run-shop-actions button:last-child");
    const leaveAfter = nextLeaveButton
      ? (() => {
          const modalRect = controls.mapOverlay.querySelector<HTMLElement>(".run-stage-modal")?.getBoundingClientRect();
          const buttonRect = nextLeaveButton.getBoundingClientRect();
          return !!modalRect && buttonRect.bottom <= modalRect.bottom && buttonRect.top >= modalRect.top;
        })()
      : false;

    return { eventBefore, eventAfter, shopBefore, shopAfter, leaveBefore, leaveAfter };
  });

  expect(result.eventBefore).toBeGreaterThan(0);
  expect(result.eventAfter).toBe(result.eventBefore);
  expect(result.shopBefore).toBeGreaterThan(0);
  expect(result.shopAfter).toBe(result.shopBefore);
  expect(result.leaveBefore).toBe(true);
  expect(result.leaveAfter).toBe(true);
});
