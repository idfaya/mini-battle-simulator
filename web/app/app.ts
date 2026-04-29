import { LuaBattleHost } from "./lua/LuaBattleHost";
import { CanvasRenderer } from "./render/CanvasRenderer";
import { BattleStore } from "./state/battleStore";
import { RunStore } from "./state/runStore";
import type { BattleSetup } from "./types/battle";
import type { RunSnapshot } from "./types/roguelike";
import { createControls, renderControls } from "./ui/domControls";
import { createRunControls, renderRunControls } from "./ui/runControls";

export async function bootstrapApp(container: HTMLElement) {
  const shell = document.createElement("div");
  shell.className = "shell";

  const stage = document.createElement("div");
  stage.className = "stage";

  const diagnostics = document.createElement("pre");
  diagnostics.className = "diagnostics";
  diagnostics.textContent = "正在初始化 Roguelike 第一章运行时...";
  stage.append(diagnostics);

  const panelHost = document.createElement("div");
  panelHost.className = "hud";

  shell.append(stage, panelHost);
  container.replaceChildren(shell);

  const host = await LuaBattleHost.create();
  const renderer = new CanvasRenderer();
  const battleStore = new BattleStore();
  const runStore = new RunStore();
  const params = new URLSearchParams(window.location.search);
  const mode = params.get("mode");
  const standaloneBattleMode = mode === "battle";
  const singleBattleMode = mode === "single-battle" || mode === "single";

  diagnostics.remove();
  stage.append(renderer.canvas);

  if (standaloneBattleMode || singleBattleMode) {
    await bootstrapStandaloneBattle(host, renderer, panelHost, battleStore, {
      singleBattleMode,
      params,
    });
    return;
  }

  await bootstrapRunMode(host, renderer, panelHost, battleStore, runStore);
}

async function bootstrapStandaloneBattle(
  host: LuaBattleHost,
  renderer: CanvasRenderer,
  panelHost: HTMLDivElement,
  store: BattleStore,
  options?: {
    singleBattleMode?: boolean;
    params?: URLSearchParams;
  },
) {
  const readIdList = (value: string | null): number[] =>
    (value ?? "")
      .split(/[,\s]+/)
      .map((part) => Number(part.trim()))
      .filter((value) => Number.isFinite(value) && value > 0)
      .slice(0, 6);
  const readNestedIdList = (value: string | null): number[][] =>
    (value ?? "")
      .split("|")
      .map((group) =>
        group
          .split(/[,\s]+/)
          .map((part) => Number(part.trim()))
          .filter((entry) => Number.isFinite(entry) && entry > 0)
          .slice(0, 12),
      )
      .filter((group) => group.length > 0)
      .slice(0, 6);

  const queryHeroIds = readIdList(options?.params?.get("heroes") ?? null);
  const queryEnemyIds = readIdList(options?.params?.get("enemies") ?? null);
  const fighterBuildFeatIds = readIdList(options?.params?.get("fighterFeats") ?? null);
  const fighterBuildFeatIdsByHero = readNestedIdList(options?.params?.get("fighterFeatsByHero") ?? null);
  const singleHeroIds = queryHeroIds.length > 0 ? queryHeroIds : [900005, 900007, 900002];
  const singleEnemyIds = queryEnemyIds.length > 0 ? queryEnemyIds : [910004, 910002, 910003];
  const setup: BattleSetup = {
    level: Number(options?.params?.get("level")) || 1,
    heroCount: options?.singleBattleMode ? singleHeroIds.length : 6,
    enemyCount: options?.singleBattleMode ? singleEnemyIds.length : 6,
    initialEnergy: options?.singleBattleMode ? 90 : 80,
    speed: 1,
    heroIds: options?.singleBattleMode ? singleHeroIds : undefined,
    enemyIds: options?.singleBattleMode ? singleEnemyIds : undefined,
    fighterBuildFeatIds: options?.singleBattleMode && fighterBuildFeatIds.length > 0 ? fighterBuildFeatIds : undefined,
    fighterBuildFeatIdsByHero:
      options?.singleBattleMode && fighterBuildFeatIdsByHero.length > 0 ? fighterBuildFeatIdsByHero : undefined,
    seed: options?.singleBattleMode ? Number(options?.params?.get("seed")) || 101001 : undefined,
  };
  let speed = setup.speed;
  let autoUltimate = options?.singleBattleMode === true;

  const toRuntimeConfig = (nextSetup: BattleSetup) => ({
    level: nextSetup.level,
    heroCount: nextSetup.heroCount,
    enemyCount: nextSetup.enemyCount,
    initialEnergy: nextSetup.initialEnergy,
    heroIds: nextSetup.heroIds,
    enemyIds: nextSetup.enemyIds,
    fighterBuildFeatIds: nextSetup.fighterBuildFeatIds,
    fighterBuildFeatIdsByHero: nextSetup.fighterBuildFeatIdsByHero,
    seed: nextSetup.seed,
    seedArray: nextSetup.seedArray,
  });

  const castUltimate = async (heroId: string) => {
    await host.queueCommand({ type: "cast_ultimate", heroId });
  };

  const controls = createControls(
    castUltimate,
    async (nextSetup) => {
      Object.assign(setup, nextSetup);
      speed = setup.speed;
      const snapshot = await host.restart(toRuntimeConfig(setup));
      store.setSnapshot(snapshot);
    },
    (nextSpeed) => {
      speed = nextSpeed;
      setup.speed = nextSpeed;
    },
    (enabled) => {
      autoUltimate = enabled;
    },
    setup,
    autoUltimate,
  );
  panelHost.replaceChildren(controls.root);

  const initialSnapshot = await host.initBattle(toRuntimeConfig(setup));
  store.setSnapshot(initialSnapshot);

  let lastFrame = performance.now();
  let inFlight = false;
  const frame = async (now: number) => {
    const delta = Math.min(120, now - lastFrame);
    lastFrame = now;
    if (!inFlight) {
      inFlight = true;
      const { events, snapshot } = await host.tick(delta * speed);
      inFlight = false;
      store.appendEvents(events);
      store.setSnapshot(snapshot);
      if (autoUltimate && !snapshot.result && snapshot.pendingCommands === 0 && !snapshot.activeHeroId) {
        const readyUnit = snapshot.leftTeam.find((unit) => unit.isAlive && unit.ultimateReady);
        if (readyUnit) {
          await castUltimate(readyUnit.id);
        }
      }
    }
    renderer.renderBattle(store.getState(), now);
    renderControls(controls, store.getState().snapshot, store.getState().log, castUltimate);
    store.clearTransient(now);
    requestAnimationFrame(frame);
  };

  renderer.renderBattle(store.getState(), performance.now());
  renderControls(controls, store.getState().snapshot, store.getState().log, castUltimate);
  requestAnimationFrame(frame);
}

async function bootstrapRunMode(
  host: LuaBattleHost,
  renderer: CanvasRenderer,
  panelHost: HTMLDivElement,
  battleStore: BattleStore,
  runStore: RunStore,
) {
  // Disable auto-ultimate by default in roguelike mode to keep early battles stable and reproducible.
  let autoUltimate = false;
  let battleSpeed = 4;
  let runSnapshot: RunSnapshot | null = null;
  let deferredPostBattleSnapshot: RunSnapshot | null = null;
  let holdBattleResultScene = false;
  let runUiDirty = true;

  const syncRunSnapshot = (snapshot: RunSnapshot) => {
    runSnapshot = snapshot;
    runStore.setSnapshot(snapshot);
    runUiDirty = true;
    if (snapshot.battleSnapshot) {
      battleStore.setSnapshot(snapshot.battleSnapshot);
      battleStore.setRunContext({
        chapterLabel: `Act 1`,
        nodeTitle:
          snapshot.map?.nodes.find((node) => node.id === snapshot.currentNodeId)?.title ?? `Node ${snapshot.currentNodeId ?? "-"}`,
        gold: snapshot.gold,
        relicCount: snapshot.relics.length,
        blessingCount: snapshot.blessings.length,
      });
    } else {
      battleStore.setRunContext(null);
    }
  };

  const castRunUltimate = async (heroId: string) => {
    await host.queueRunBattleCommand({ type: "cast_ultimate", heroId });
  };

  const exitBattleScene = () => {
    if (!deferredPostBattleSnapshot) {
      return;
    }
    const nextSnapshot = deferredPostBattleSnapshot;
    deferredPostBattleSnapshot = null;
    holdBattleResultScene = false;
    syncRunSnapshot(nextSnapshot);
  };

  const battleControls = createControls(
    castRunUltimate,
    async () => {},
    (nextSpeed) => {
      battleSpeed = nextSpeed;
    },
    (enabled) => {
      autoUltimate = enabled;
    },
    {
      level: 1,
      heroCount: 3,
      enemyCount: 3,
      initialEnergy: 40,
      speed: 4,
    },
    autoUltimate,
    { showSetupPanel: false },
  );

  const runControls = createRunControls({
    onChooseNode: async (nodeId) => {
      await host.choosePath(nodeId);
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onEnterNode: async () => {
      await host.enterNode();
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onChooseEventOption: async (optionId) => {
      await host.chooseEventOption(optionId);
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onChooseReward: async (index) => {
      await host.chooseReward(index);
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onShopBuy: async (goodsId) => {
      await host.shopBuy(goodsId);
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onShopRefresh: async () => {
      await host.shopRefresh();
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onShopLeave: async () => {
      await host.shopLeave();
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onPromoteBenchHero: async (benchRosterId) => {
      await host.promoteBenchHero(benchRosterId);
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onSwapBenchWithTeam: async (benchRosterId, teamRosterId) => {
      await host.swapBenchWithTeam(benchRosterId, teamRosterId);
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onCampChoose: async (actionId) => {
      await host.campChoose(actionId);
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onRestart: async () => {
      syncRunSnapshot(await host.restartRun({ chapterId: 101, starterHeroIds: [900005, 900007, 900002] }));
    },
  });

  syncRunSnapshot(await host.startRun({ chapterId: 101, starterHeroIds: [900005, 900007, 900002] }));

  let lastFrame = performance.now();
  let inFlight = false;
  const frame = async (now: number) => {
    const delta = Math.min(120, now - lastFrame);
    lastFrame = now;

    if (runSnapshot?.phase === "battle" && !inFlight) {
      inFlight = true;
      const previousPhase = runSnapshot.phase;
      const previousBattleSnapshot = battleStore.getState().snapshot;
      const { events, snapshot } = await host.tickRun(delta * battleSpeed);
      inFlight = false;

      if (previousPhase === "battle" && snapshot.phase !== "battle") {
        runSnapshot = snapshot;
        deferredPostBattleSnapshot = snapshot;
        holdBattleResultScene = true;
        if (previousBattleSnapshot) {
          battleStore.setSnapshot({
            ...previousBattleSnapshot,
            phase: "ended",
            pendingCommands: 0,
            result:
              previousBattleSnapshot.result ??
              {
                winner: snapshot.phase === "failed" ? "right" : "left",
                reason: snapshot.lastActionMessage || (snapshot.phase === "failed" ? "battle_failed" : "battle_resolved"),
              },
          });
        }
      } else {
        syncRunSnapshot(snapshot);
      }
      battleStore.appendEvents(events);

      const battleSnapshot = snapshot.battleSnapshot;
      if (autoUltimate && battleSnapshot && !battleSnapshot.result && battleSnapshot.pendingCommands === 0) {
        const readyUnit = battleSnapshot.leftTeam.find((unit) => unit.isAlive && unit.ultimateReady);
        if (readyUnit) {
          await castRunUltimate(readyUnit.id);
        }
      }
    }

    const shouldRenderBattle = holdBattleResultScene || (runSnapshot?.phase === "battle" && runSnapshot.battleSnapshot);
    if (shouldRenderBattle && battleStore.getState().snapshot) {
      if (panelHost.firstChild !== battleControls.root) {
        panelHost.replaceChildren(battleControls.root);
        // 切换到战斗 HUD 时，把当前 hud 的 screen 同步到 shell，避免 CSS 失配
        const currentScreen = battleControls.root.dataset.screen ?? "battle";
        panelHost.closest(".shell")?.setAttribute("data-screen", currentScreen);
      }
      battleControls.root.classList.toggle("battle-ended", holdBattleResultScene);
      renderer.renderBattle(battleStore.getState(), now);
      renderControls(battleControls, battleStore.getState().snapshot, battleStore.getState().log, castRunUltimate, {
        extraActions: holdBattleResultScene
          ? [
              {
                label: "查看奖励",
                onClick: exitBattleScene,
              },
            ]
          : [],
      });
      battleStore.clearTransient(now);
    } else {
      if (panelHost.firstChild !== runControls.root) {
        panelHost.replaceChildren(runControls.root);
        // 切到 Roguelike HUD 时，把 runControls 当前 screen 同步到 shell，手机上 CSS 才会正确隐藏 stage
        const runScreen = runControls.root.dataset.screen ?? "map";
        panelHost.closest(".shell")?.setAttribute("data-screen", `run-${runScreen}`);
        runUiDirty = true;
      }
      renderer.renderMap(runSnapshot);
      if (runUiDirty) {
        renderRunControls(runControls, runStore.getState().snapshot, runStore.getState().logs);
        runUiDirty = false;
      }
    }

    requestAnimationFrame(frame);
  };

  renderer.renderMap(runSnapshot);
  renderRunControls(runControls, runStore.getState().snapshot, runStore.getState().logs);
  requestAnimationFrame(frame);
}
