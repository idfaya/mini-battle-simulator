import { expect, test } from "playwright/test";
import { createFloatingText } from "../app/render/animations";
import { BattleScene } from "../app/render/BattleScene";
import { BattleStore } from "../app/state/battleStore";
import type { AnimationEvent, UnitState } from "../app/types/battle";

function filterKnownNoise(errors: string[]) {
  return errors.filter((message) => !message.includes("ERR_CONNECTION_REFUSED"));
}

const mockUnit: UnitState = {
  id: "hero-1",
  name: "Hero",
  team: "left",
  position: 1,
  classId: 1,
  className: "盗贼",
  classIcon: "S",
  hp: 10,
  maxHp: 10,
  speed: 10,
  initiativeRoll: 10,
  initiativeMod: 2,
  initiative: 12,
  ac: 15,
  hit: 5,
  spellDC: 12,
  saveFort: 2,
  saveRef: 1,
  saveWill: 0,
  energy: 0,
  maxEnergy: 100,
  ultimateCharges: 0,
  ultimateChargesMax: 100,
  isAlive: true,
  isChanting: false,
  pendingSkillName: null,
  isConcentrating: false,
  concentrationSkillId: null,
  concentrationSkillName: null,
  buffs: [],
  actionBar: 0,
  actionBarMax: 1000,
  ultimateReady: false,
  ultimateSkillName: "爆发",
};

test("floating text styles cover basic white skill yellow crit red heal and miss", () => {
  const now = 1000;
  const cases: Array<{
    event: AnimationEvent;
    expectedKind: "damage" | "critical" | "heal" | "miss";
    expectedColor?: string;
  }> = [
    {
      event: {
        type: "damage",
        heroId: "target",
        attackerId: "hero-1",
        skillName: "",
        value: 18,
        critical: false,
        basicAttack: true,
      },
      expectedKind: "damage",
      expectedColor: "#f8f9fa",
    },
    {
      event: {
        type: "damage",
        heroId: "target",
        attackerId: "hero-1",
        skillName: "火球术",
        value: 24,
        critical: false,
        basicAttack: false,
      },
      expectedKind: "damage",
      expectedColor: "#ffd166",
    },
    {
      event: {
        type: "damage",
        heroId: "target",
        attackerId: "hero-1",
        skillName: "伏击",
        value: 12,
        critical: false,
        basicAttack: true,
        preferSkillColor: true,
      },
      expectedKind: "damage",
      expectedColor: "#ffd166",
    },
    {
      event: {
        type: "damage",
        heroId: "target",
        attackerId: "hero-1",
        skillName: "",
        value: 42,
        critical: true,
        basicAttack: true,
      },
      expectedKind: "critical",
      expectedColor: "#ff5a5f",
    },
    {
      event: {
        type: "heal",
        heroId: "hero-1",
        value: 12,
      },
      expectedKind: "heal",
    },
    {
      event: {
        type: "miss",
        heroId: "target",
        text: "MISS",
      },
      expectedKind: "miss",
    },
  ];

  for (const testCase of cases) {
    const text = createFloatingText(testCase.event, mockUnit, now);
    expect(text?.kind).toBe(testCase.expectedKind);
    if (testCase.expectedColor) {
      expect(text?.color).toBe(testCase.expectedColor);
    }
  }
});

test("basic attack damage merges with attached skill damage into one yellow number", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "damage_dealt",
      ts: 1,
      payload: {
        attackerId: "hero-1",
        attackerName: "Hero",
        targetId: "target-1",
        targetName: "Target",
        damage: 12,
        isCrit: false,
        isBasicAttack: true,
        preferSkillColor: false,
        skillName: "",
      },
    },
    {
      type: "damage_dealt",
      ts: 2,
      payload: {
        attackerId: "hero-1",
        attackerName: "Hero",
        targetId: "target-1",
        targetName: "Target",
        damage: 8,
        isCrit: false,
        isBasicAttack: false,
        preferSkillColor: true,
        skillName: "伏击",
      },
    },
  ]);

  expect(store["state"].animations).toEqual([
    {
      type: "damage",
      heroId: "target-1",
      attackerId: "hero-1",
      skillName: "伏击",
      value: 20,
      critical: false,
      basicAttack: true,
      preferSkillColor: true,
    },
  ]);

  const merged = createFloatingText(store["state"].animations[0] as AnimationEvent, mockUnit, 1000);
  expect(merged?.color).toBe("#ffd166");
  expect(merged?.text).toBe("20");
});

test("critical basic attack damage merges with attached skill damage into one red number", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "damage_dealt",
      ts: 1,
      payload: {
        attackerId: "hero-1",
        attackerName: "Hero",
        targetId: "target-1",
        targetName: "Target",
        damage: 18,
        isCrit: true,
        isBasicAttack: true,
        preferSkillColor: false,
        skillName: "",
      },
    },
    {
      type: "damage_dealt",
      ts: 2,
      payload: {
        attackerId: "hero-1",
        attackerName: "Hero",
        targetId: "target-1",
        targetName: "Target",
        damage: 7,
        isCrit: false,
        isBasicAttack: false,
        preferSkillColor: true,
        skillName: "惩戒火花",
      },
    },
  ]);

  expect(store["state"].animations).toEqual([
    {
      type: "damage",
      heroId: "target-1",
      attackerId: "hero-1",
      skillName: "惩戒火花",
      value: 25,
      critical: true,
      basicAttack: true,
      preferSkillColor: true,
    },
  ]);

  const merged = createFloatingText(store["state"].animations[0] as AnimationEvent, mockUnit, 1000);
  expect(merged?.kind).toBe("critical");
  expect(merged?.color).toBe("#ff5a5f");
  expect(merged?.text).toBe("25");
});

test("active skill cast shows caster pulse label while basic attack does not", () => {
  const scene = new BattleScene();
  const now = 1000;
  const layout = {
    x: 0,
    y: 0,
    width: 120,
    height: 120,
    alpha: 1,
    scale: 1,
    darken: 0,
    entryGlow: 0,
    showDefeatedLabel: false,
    defeatedLabelAlpha: 0,
    unit: mockUnit,
    formationSide: "player",
    row: "front",
    column: 0,
    baseX: 0,
    baseY: 0,
  };

  (scene as unknown as { consumeAnimations: (events: AnimationEvent[], layouts: unknown[], nowValue: number) => void }).consumeAnimations(
    [
      {
        type: "skill_cast_started",
        heroId: mockUnit.id,
        heroName: mockUnit.name,
        skillName: "火球术",
        skillType: 2,
      },
      {
        type: "skill_cast_started",
        heroId: mockUnit.id,
        heroName: mockUnit.name,
        skillName: "普通攻击",
        skillType: 1,
      },
    ],
    [layout],
    now,
  );

  expect((scene as unknown as { unitPulses: Array<{ unitId: string; label?: string }> }).unitPulses).toEqual([
    expect.objectContaining({
      unitId: mockUnit.id,
      label: "火球术",
    }),
  ]);
});

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

  await page.goto("/?mode=battle");
  await page.waitForTimeout(2500);

  await expect(page.locator(".fatal-error")).toHaveCount(0);
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator("#battle-level")).toHaveCount(1);
  await expect(page.locator("#battle-hero-count")).toHaveCount(1);
  await expect(page.locator("#battle-enemy-count")).toHaveCount(1);
  await expect(page.locator("#battle-speed")).toHaveCount(1);
  await expect(page.locator(".ult-button")).toHaveCount(0);
  await expect
    .poll(async () => (await page.locator(".battle-log li").allTextContents()).join("\n"), { timeout: 6000 })
    .toContain("战斗开始");

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
  const battleDebugState = await page.evaluate(async () => {
    const runtime = window as typeof window & {
      __miniBattleHost?: {
        tick: (delta: number) => Promise<unknown>;
      };
      __miniBattleRenderer?: {
        getBattleDebugState: () => {
          entranceStartedCount: number;
          entranceActiveCount: number;
          deathStartedCount: number;
          deathActiveCount: number;
          observedFloatingTextKinds: string[];
          floatingTextKinds: string[];
        };
      };
    };
    const host = runtime.__miniBattleHost;
    const renderer = runtime.__miniBattleRenderer;
    if (!host || !renderer) {
      return null;
    }
    for (let index = 0; index < 120; index += 1) {
      await host.tick(220);
      const state = renderer.getBattleDebugState();
      if (state.entranceStartedCount > 0 && state.observedFloatingTextKinds.length > 0) {
        return state;
      }
    }
    return renderer.getBattleDebugState();
  });
  expect(battleDebugState).not.toBeNull();
  expect(battleDebugState?.entranceStartedCount ?? 0).toBeGreaterThan(0);
  expect(battleDebugState?.observedFloatingTextKinds?.length ?? 0).toBeGreaterThan(0);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/battle-smoke.png", fullPage: true });
});
