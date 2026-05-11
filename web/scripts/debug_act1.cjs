// 用法: 先 `npm --prefix web run dev`，再 `node web/scripts/debug_act1.cjs`
// 作用: 自动驱动 Act1，沿途打印每个节点的 phase / reward / chapterResult，
// 用于在排查"章节结算/奖励链"问题时收集运行时证据，避免反复手点。

const path = require("node:path");
const { chromium } = require(path.join(__dirname, "..", "node_modules", "playwright"));

const TARGET_URL = process.env.MINI_BATTLE_URL || "http://127.0.0.1:4173/?seed=10102";

async function snapshot(page) {
  return page.evaluate(async () => {
    const s = await window.__miniBattleHost.getRunSnapshot();
    return {
      phase: s.phase,
      currentNodeId: s.currentNodeId,
      rewardKind: s.rewardState?.kind || null,
      rewardOptions: (s.rewardState?.options || []).map((o) => ({
        label: o.label,
        type: o.rewardType,
        refId: o.refId,
      })),
      chapterResult: s.chapterResult || null,
      selectable: (s.map?.nodes || [])
        .filter((n) => n.selectable)
        .map((n) => ({ id: n.id, type: n.nodeType, title: n.title })),
      team: (s.team || []).map((m) => ({
        name: m.name,
        hp: m.hp,
        dead: m.isDead,
        build: m.buildSummary,
      })),
      lastActionMessage: s.lastActionMessage,
    };
  });
}

async function chooseNodeAndEnter(page, preferredTypes) {
  return page.evaluate(async (types) => {
    const host = window.__miniBattleHost;
    const s = await host.getRunSnapshot();
    const selectable = (s.map?.nodes || []).filter((n) => n.selectable);
    const selected =
      types.map((t) => selectable.find((n) => n.nodeType === t)).find(Boolean) ||
      selectable[0] ||
      null;
    if (!selected) return null;
    await host.choosePath(selected.id);
    await host.enterNode();
    return { id: selected.id, type: selected.nodeType, title: selected.title };
  }, preferredTypes);
}

async function driveBattleUntilResolved(page, timeout = 90000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const phase = await page.evaluate(async () => {
      const host = window.__miniBattleHost;
      const ticked = await host.tickRun(600);
      const s = ticked?.snapshot ?? (await host.getRunSnapshot());
      if (s.phase && s.phase !== "battle") return s.phase;
      const battle = s.battleSnapshot;
      if (battle && battle.pendingCommands === 0) {
        const outputUnit = (battle.leftTeam || []).find(
          (u) =>
            u.isAlive &&
            u.ultimateReady === true &&
            !/heal|healing|revive|复活|治疗/i.test(u.ultimateSkillName || ""),
        );
        if (outputUnit) {
          await host.queueRunBattleCommand({ type: "cast_ultimate", heroId: outputUnit.id });
        }
      }
      return s.phase || "battle";
    });
    if (phase && phase !== "battle") return phase;
    await page.waitForTimeout(200);
  }
  throw new Error("battle did not resolve");
}

async function chooseReward(page) {
  return page.evaluate(async () => {
    const host = window.__miniBattleHost;
    const s = await host.getRunSnapshot();
    if (!s.rewardState?.options?.length) return false;
    await host.chooseReward(0);
    return true;
  });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(TARGET_URL);
  await page.waitForTimeout(1500);
  console.log("start", JSON.stringify(await snapshot(page), null, 2));

  for (let step = 1; step <= 20; step += 1) {
    const snap = await snapshot(page);
    if (snap.phase === "chapter_result" || snap.phase === "failed") {
      console.log("end", step, JSON.stringify(snap, null, 2));
      break;
    }
    if (snap.phase === "map") {
      const chosen = await chooseNodeAndEnter(page, [
        "boss",
        "battle_elite",
        "battle_normal",
        "recruit",
        "camp",
        "shop",
        "event",
      ]);
      console.log("choose", step, chosen);
      const afterEnter = await snapshot(page);
      if (afterEnter.phase === "battle") {
        const endPhase = await driveBattleUntilResolved(page, 80000);
        const afterBattle = await snapshot(page);
        console.log(
          "afterBattle",
          step,
          endPhase,
          JSON.stringify(
            {
              phase: afterBattle.phase,
              rewardKind: afterBattle.rewardKind,
              chapterResult: afterBattle.chapterResult,
              lastActionMessage: afterBattle.lastActionMessage,
            },
            null,
            2,
          ),
        );
      }
      if ((await snapshot(page)).phase === "reward") {
        await chooseReward(page);
      }
      continue;
    }
    if (snap.phase === "reward") {
      await chooseReward(page);
      continue;
    }
    if (snap.phase === "camp") {
      await page.evaluate(async () => {
        const s = await window.__miniBattleHost.getRunSnapshot();
        const id = s.campState?.actions?.find((a) => a.available !== false)?.id || 1;
        await window.__miniBattleHost.campChoose(id);
      });
      continue;
    }
    if (snap.phase === "shop") {
      await page.evaluate(async () => window.__miniBattleHost.shopLeave());
      continue;
    }
    if (snap.phase === "event") {
      await page.evaluate(async () => {
        const s = await window.__miniBattleHost.getRunSnapshot();
        const id = s.eventState?.options?.[0]?.id || 1;
        await window.__miniBattleHost.chooseEventOption(id);
      });
      continue;
    }
  }

  await browser.close();
})();
