import { expect, test } from "playwright/test";
import { createFloatingText } from "../app/render/animations";
import { BattleScene } from "../app/render/BattleScene";
import { BattleStore } from "../app/state/battleStore";
import { normalizeTopBarCheckText, splitRollBriefDisplay } from "../app/state/rollFormat";
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
        skillName: "偷袭",
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
        skillName: "偷袭",
      },
    },
  ]);

  expect(store["state"].animations).toEqual([
    {
      type: "damage",
      heroId: "target-1",
      attackerId: "hero-1",
      skillName: "偷袭",
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

test("normalizeTopBarCheckText detects nat20 crit from combat log", () => {
  expect(normalizeTopBarCheckText("攻击检定 d20 20+5=25 vs AC 14")).toBe(
    "攻击检定 d20+5 vs AC14 [20]+5 =25 成功 暴击",
  );
  expect(normalizeTopBarCheckText("攻击检定 d20 4+5=9 vs AC 14")).toBe(
    "攻击检定 d20+5 vs AC14 [4]+5 =9 失败",
  );
});

test("splitRollBriefDisplay keeps dice icon before rolled values", () => {
  expect(splitRollBriefDisplay("伤害骰 1d6+2 [4]+2=6")).toEqual({
    prefix: "伤害骰 1d6+2",
    rollText: "[4]+2=6",
  });
  expect(splitRollBriefDisplay("冻结新星 反射豁免 d20-2 vs DC13 [3]-2 =1 失败")).toEqual({
    prefix: "冻结新星 反射豁免 d20-2 vs DC13",
    rollText: "[3]-2 =1 失败",
  });
});

test("skill cast shows casting label until roll resolves", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "skill_cast_started",
      ts: 1,
      payload: {
        heroId: "hero-1",
        heroName: "法师(冰)",
        skillName: "冻结新星",
        skillType: 2,
      },
    },
  ]);

  expect(store.getState().skillCasting).toBe(true);
  expect(store.getState().skillBrief).toBe("冻结新星 释放中");
  expect(store.getState().damageBrief).toBeNull();
});

test("heal_received clears casting label and shows heal brief", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "skill_cast_started",
      ts: 1,
      payload: {
        heroId: "hero-3",
        heroName: "牧师",
        skillName: "神圣火花",
        skillType: 2,
      },
    },
    {
      type: "heal_received",
      ts: 2,
      payload: {
        healerId: "hero-3",
        healerName: "牧师",
        targetId: "hero-1",
        targetName: "战士",
        healAmount: 12,
        skillName: "神圣火花",
      },
    },
  ]);

  expect(store.getState().skillCasting).toBe(false);
  expect(store.getState().skillBrief).toBe("神圣火花 治疗 +12");
  expect(store.getState().skillBrief).not.toContain("释放中");
  expect(store.getState().damageBrief).toBeNull();
});

test("passive_skill_triggered shows skill name without casting phase", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "skill_cast_started",
      ts: 1,
      payload: {
        heroId: "hero-2",
        heroName: "战士",
        skillName: "破邪斩",
        skillType: 2,
      },
    },
    {
      type: "passive_skill_triggered",
      ts: 2,
      payload: {
        heroId: "hero-1",
        heroName: "战士",
        skillName: "反击",
        triggerType: "登记反击",
        extraInfo: "将对 兽人 发动反击",
      },
    },
  ]);

  expect(store.getState().skillCasting).toBe(false);
  expect(store.getState().skillBrief).toBe("反击");
  expect(store.getState().skillBrief).not.toContain("释放中");
  expect(store.getState().damageBrief).toBeNull();
});

test("aoe damage_dealt annotates multi-target hit index on skill brief", () => {
  const store = new BattleStore();
  const saveRoll = { roll: 3, bonus: -2, total: 1, dc: 13, success: false };
  const damageRoll = { expr: "1d6+2", parts: [{ rolls: [4], bonus: 2 }], total: 6 };

  store.appendEvents([
    {
      type: "skill_cast_started",
      ts: 1,
      payload: {
        heroId: "hero-1",
        heroName: "法师(冰)",
        skillName: "冻结新星",
        skillType: 2,
      },
    },
    {
      type: "damage_dealt",
      ts: 2,
      payload: {
        attackerId: "hero-1",
        attackerName: "法师(冰)",
        targetId: "enemy-1",
        targetName: "骷髅兵",
        damage: 4,
        skillName: "冻结新星",
        saveType: "ref",
        onSaveSuccess: "half",
        saveRoll,
        damageRoll,
      },
    },
    {
      type: "damage_dealt",
      ts: 3,
      payload: {
        attackerId: "hero-1",
        attackerName: "法师(冰)",
        targetId: "enemy-2",
        targetName: "哥布林",
        damage: 3,
        skillName: "冻结新星",
        saveType: "ref",
        onSaveSuccess: "half",
        saveRoll: { roll: 8, bonus: -2, total: 6, dc: 13, success: true },
        damageRoll: { expr: "1d6+2", parts: [{ rolls: [2], bonus: 2 }], total: 4 },
      },
    },
  ]);

  expect(store.getState().skillBrief).toBe("冻结新星 ·2 反射豁免 d20-2 vs DC13 [8]-2 =6 成功（半伤）");
  expect(store.getState().damageBrief).toContain("伤害骰");
});

test("damage_dealt updates battlefield skill brief without attacker or target names", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "skill_cast_started",
      ts: 1,
      payload: {
        heroId: "hero-1",
        heroName: "法师(冰)",
        skillName: "冻结新星",
        skillType: 2,
      },
    },
    {
      type: "damage_dealt",
      ts: 2,
      payload: {
        attackerId: "hero-1",
        attackerName: "法师(冰)",
        targetId: "enemy-1",
        targetName: "骷髅兵",
        damage: 4,
        skillName: "冻结新星",
        saveType: "ref",
        onSaveSuccess: "half",
        saveRoll: { roll: 3, bonus: -2, total: 1, dc: 13, success: false },
        damageRoll: { expr: "1d6+2", parts: [{ rolls: [4], bonus: 2 }], total: 6 },
      },
    },
  ]);

  expect(store.getState().skillCasting).toBe(false);
  expect(store.getState().skillBrief).toBe("冻结新星 反射豁免 d20-2 vs DC13 [3]-2 =1 失败");
  expect(store.getState().skillBrief).not.toMatch(/[（）]/);
  expect(store.getState().skillBrief).not.toContain("释放中");
  expect(store.getState().skillBrief).not.toContain("伤害骰");
  expect(store.getState().skillBrief).not.toContain("法师");
  expect(store.getState().skillBrief).not.toContain("骷髅兵");
  expect(store.getState().damageBrief).toContain("伤害骰");
  expect(store.getState().damageBrief).toContain("1d6+2");
});

test("attack roll shows hit outcome on top bar", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "damage_dealt",
      ts: 1,
      payload: {
        attackerId: "hero-2",
        attackerName: "法师(冰)",
        targetId: "enemy-1",
        targetName: "骷髅兵",
        damage: 8,
        skillName: "寒霜射线",
        attackRoll: { roll: 20, bonus: 5, total: 25, targetAC: 14, hit: true, crit: true, nat20: true },
        damageRoll: { expr: "1d8", parts: [{ rolls: [6], bonus: 0 }], total: 6 },
        isCrit: true,
      },
    },
    {
      type: "miss",
      ts: 2,
      payload: {
        attackerId: "hero-2",
        attackerName: "法师(冰)",
        targetId: "enemy-2",
        targetName: "哥布林",
        skillName: "寒霜射线",
        attackRoll: { roll: 4, bonus: 5, total: 9, targetAC: 14, hit: false },
      },
    },
  ]);

  expect(store.getState().skillBrief).toBe("寒霜射线 ·2 攻击检定 d20+5 vs AC14 [4]+5 =9 失败");
});

test("attack roll shows crit on successful natural 20", () => {
  const store = new BattleStore();
  store.appendEvents([
    {
      type: "damage_dealt",
      ts: 1,
      payload: {
        attackerId: "hero-2",
        attackerName: "战士",
        targetId: "enemy-1",
        targetName: "骷髅兵",
        damage: 18,
        isCrit: true,
        skillName: "重击",
        attackRoll: { roll: 20, bonus: 6, total: 26, targetAC: 15, hit: true, crit: true },
        damageRoll: { expr: "1d12", parts: [{ rolls: [8, 3], bonus: 0 }], total: 11 },
      },
    },
  ]);

  expect(store.getState().skillBrief).toContain("成功 暴击");
  expect(store.getState().skillBrief).toContain("[20]");
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
  expect(store["state"].log).toContain("Hero 对 Target 造成 暴击，18 伤害");
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
      if (state.entranceStartedCount > 0) {
        return state;
      }
    }
    return renderer.getBattleDebugState();
  });
  expect(battleDebugState).not.toBeNull();
  expect(battleDebugState?.entranceStartedCount ?? 0).toBeGreaterThan(0);
  expect(pageErrors).toEqual([]);
  expect(filterKnownNoise(consoleErrors)).toEqual([]);

  await page.screenshot({ path: "test-results/battle-smoke.png", fullPage: true });
});
