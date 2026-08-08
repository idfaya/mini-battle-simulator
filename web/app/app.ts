import { LuaBattleHost } from "./lua/LuaBattleHost";
import { CanvasRenderer } from "./render/CanvasRenderer";
import { BattleStore } from "./state/battleStore";
import { RunStore } from "./state/runStore";
import type { BattleSetup, BattleSnapshot, UnitState } from "./types/battle";
import type { RunCardState, RunSnapshot } from "./types/roguelike";
import { createControls, renderControls } from "./ui/domControls";
import { createRunControls, renderBattleResultStageOverlay, renderRunControls } from "./ui/runControls";

const BATTLE_ENTRANCE_HOLD_MS = 760;

export type AppHandle = {
  cleanup: () => void;
};

export async function bootstrapApp(container: HTMLElement): Promise<AppHandle> {
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
  if (typeof window !== "undefined") {
    (
      window as typeof window & {
        __miniBattleHost?: LuaBattleHost;
        __miniBattleRenderer?: CanvasRenderer;
      }
    ).__miniBattleHost = host;
    (window as typeof window & { __miniBattleRenderer?: CanvasRenderer }).__miniBattleRenderer = renderer;
  }
  const battleStore = new BattleStore();
  const runStore = new RunStore();
  const params = new URLSearchParams(window.location.search);
  const mode = params.get("mode");
  const standaloneBattleMode = mode === "battle";
  const singleBattleMode = mode === "single-battle" || mode === "single";

  diagnostics.remove();
  stage.append(renderer.canvas);

  const cleanupCallbacks: Array<() => void> = [];
  let cleanedUp = false;
  const isActive = () => !cleanedUp;
  const registerCleanup = (callback: () => void) => {
    cleanupCallbacks.push(callback);
  };
  const cleanup = () => {
    if (cleanedUp) {
      return;
    }
    cleanedUp = true;
    while (cleanupCallbacks.length > 0) {
      const callback = cleanupCallbacks.pop();
      callback?.();
    }
  };

  const syncMobileBattleStageHeight = () => {
    const mobilePortrait = window.matchMedia("(max-width: 720px) and (orientation: portrait)").matches;
    const shellScreen = shell.dataset.screen ?? "";
    const isBattleScreen = shellScreen === "battle";
    if (!mobilePortrait || !isBattleScreen) {
      shell.style.height = "";
      shell.style.maxHeight = "";
      stage.style.height = "";
      stage.style.maxHeight = "";
      return;
    }

    const appStyles = window.getComputedStyle(container);
    const appPaddingTop = Number.parseFloat(appStyles.paddingTop || "0") || 0;
    const appPaddingBottom = Number.parseFloat(appStyles.paddingBottom || "0") || 0;
    const viewportHeight = Math.floor(window.visualViewport?.height ?? window.innerHeight);
    const shellHeight = Math.max(160, viewportHeight - appPaddingTop - appPaddingBottom);
    const panelRect = panelHost.getBoundingClientRect();
    const shellStyles = window.getComputedStyle(shell);
    const shellGap = Number.parseFloat(shellStyles.rowGap || shellStyles.gap || "0") || 0;
    const availableHeight = Math.floor(shellHeight - panelRect.height - shellGap);
    const clampedHeight = Math.max(120, availableHeight);
    shell.style.height = `${shellHeight}px`;
    shell.style.maxHeight = `${shellHeight}px`;
    stage.style.height = `${clampedHeight}px`;
    stage.style.maxHeight = `${clampedHeight}px`;
  };

  const scheduleMobileBattleStageSync = () => {
    window.requestAnimationFrame(syncMobileBattleStageHeight);
  };

  const resizeObserver = new ResizeObserver(() => {
    scheduleMobileBattleStageSync();
  });
  resizeObserver.observe(shell);
  resizeObserver.observe(panelHost);
  registerCleanup(() => {
    resizeObserver.disconnect();
  });
  if (typeof window.visualViewport !== "undefined") {
    const viewport = window.visualViewport;
    viewport.addEventListener("resize", scheduleMobileBattleStageSync);
    viewport.addEventListener("scroll", scheduleMobileBattleStageSync);
    registerCleanup(() => {
      viewport.removeEventListener("resize", scheduleMobileBattleStageSync);
      viewport.removeEventListener("scroll", scheduleMobileBattleStageSync);
    });
  }
  window.addEventListener("resize", scheduleMobileBattleStageSync);
  registerCleanup(() => {
    window.removeEventListener("resize", scheduleMobileBattleStageSync);
  });

  try {
    if (standaloneBattleMode || singleBattleMode) {
      await bootstrapStandaloneBattle(
        host,
        renderer,
        panelHost,
        battleStore,
        shell,
        scheduleMobileBattleStageSync,
        registerCleanup,
        isActive,
        {
          singleBattleMode,
          params,
        },
      );
      return { cleanup };
    }

    await bootstrapRunMode(
      host,
      renderer,
      panelHost,
      stage,
      battleStore,
      runStore,
      shell,
      scheduleMobileBattleStageSync,
      registerCleanup,
      isActive,
      params,
    );
    return { cleanup };
  } catch (error) {
    cleanup();
    throw error;
  }
}

async function bootstrapStandaloneBattle(
  host: LuaBattleHost,
  renderer: CanvasRenderer,
  panelHost: HTMLDivElement,
  store: BattleStore,
  shell: HTMLDivElement,
  syncMobileBattleStageHeight: () => void,
  registerCleanup: (callback: () => void) => void,
  isActive: () => boolean,
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
  const queryEnemyReserveIds = readIdList(options?.params?.get("enemyReserve") ?? options?.params?.get("reserveEnemies") ?? null);
  const buildFeatIds = readIdList(options?.params?.get("buildFeats") ?? options?.params?.get("fighterFeats") ?? null);
  const buildFeatIdsByHero = readNestedIdList(options?.params?.get("buildFeatsByHero") ?? options?.params?.get("fighterFeatsByHero") ?? null);
  const singleHeroIds = queryHeroIds.length > 0 ? queryHeroIds : [900005, 900001, 900007, 900002];
  const singleEnemyIds = queryEnemyIds.length > 0 ? queryEnemyIds : [910004, 910002, 910003];
  const setup: BattleSetup = {
    level: Number(options?.params?.get("level")) || 1,
    heroCount: options?.singleBattleMode ? singleHeroIds.length : 6,
    enemyCount: options?.singleBattleMode ? singleEnemyIds.length : 6,
    initialEnergy: options?.singleBattleMode ? 90 : 80,
    speed: 1,
    heroIds: options?.singleBattleMode ? singleHeroIds : undefined,
    enemyIds: options?.singleBattleMode ? singleEnemyIds : undefined,
    enemyReserveIds: options?.singleBattleMode && queryEnemyReserveIds.length > 0 ? queryEnemyReserveIds : undefined,
    refreshTurns: options?.singleBattleMode ? Number(options?.params?.get("refreshTurns")) || undefined : undefined,
    refreshOnClear:
      options?.singleBattleMode && options?.params?.has("refreshOnClear")
        ? options?.params?.get("refreshOnClear") !== "false"
        : undefined,
    winRule: options?.singleBattleMode ? options?.params?.get("winRule") ?? undefined : undefined,
    loseRule: options?.singleBattleMode ? options?.params?.get("loseRule") ?? undefined : undefined,
    bossId: options?.singleBattleMode ? options?.params?.get("bossId") ?? undefined : undefined,
    spawnOrder: options?.singleBattleMode ? options?.params?.get("spawnOrder") ?? undefined : undefined,
    buildFeatIds: options?.singleBattleMode && buildFeatIds.length > 0 ? buildFeatIds : undefined,
    buildFeatIdsByHero:
      options?.singleBattleMode && buildFeatIdsByHero.length > 0 ? buildFeatIdsByHero : undefined,
    seed: options?.singleBattleMode ? Number(options?.params?.get("seed")) || 101001 : undefined,
  };
  let speed = setup.speed;
  let autoUltimate = options?.singleBattleMode === true;
  let battleIntroHoldUntil = performance.now() + BATTLE_ENTRANCE_HOLD_MS;

  const toRuntimeConfig = (nextSetup: BattleSetup) => ({
    level: nextSetup.level,
    heroCount: nextSetup.heroCount,
    enemyCount: nextSetup.enemyCount,
    initialEnergy: nextSetup.initialEnergy,
    heroIds: nextSetup.heroIds,
    enemyIds: nextSetup.enemyIds,
    enemyReserveIds: nextSetup.enemyReserveIds,
    refreshTurns: nextSetup.refreshTurns,
    refreshOnClear: nextSetup.refreshOnClear,
    winRule: nextSetup.winRule,
    loseRule: nextSetup.loseRule,
    bossId: nextSetup.bossId,
    spawnOrder: nextSetup.spawnOrder,
    buildFeatIds: nextSetup.buildFeatIds,
    buildFeatIdsByHero: nextSetup.buildFeatIdsByHero,
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
      battleIntroHoldUntil = performance.now() + BATTLE_ENTRANCE_HOLD_MS;
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
  shell.dataset.screen = controls.root.dataset.screen ?? "battle";
  syncMobileBattleStageHeight();

  const initialSnapshot = await host.initBattle(toRuntimeConfig(setup));
  store.setSnapshot(initialSnapshot);
  battleIntroHoldUntil = performance.now() + BATTLE_ENTRANCE_HOLD_MS;

  let rafId: number | null = null;
  let lastBattleControlsSignature = "";
  registerCleanup(() => {
    if (rafId != null) {
      cancelAnimationFrame(rafId);
      rafId = null;
    }
  });

  let lastFrame = performance.now();
  let inFlight = false;
  const frame = async (now: number) => {
    if (!isActive()) {
      return;
    }
    const delta = Math.min(120, now - lastFrame);
    lastFrame = now;
    if (now >= battleIntroHoldUntil && !inFlight) {
      inFlight = true;
      const { events, snapshot } = await host.tick(delta * speed);
      inFlight = false;
      if (!isActive()) {
        return;
      }
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
    syncMobileBattleStageHeight();
    store.clearTransient(now);
    if (isActive()) {
      rafId = requestAnimationFrame(frame);
    }
  };

  renderer.renderBattle(store.getState(), performance.now());
  renderControls(controls, store.getState().snapshot, store.getState().log, castUltimate);
  syncMobileBattleStageHeight();
  rafId = requestAnimationFrame(frame);
}

function isAliveBattleUnit(unit: UnitState): boolean {
  return unit.isAlive && unit.hp > 0;
}

function isFrontRowBattleUnit(unit: UnitState): boolean {
  return unit.position >= 1 && unit.position <= 3;
}

function getTargetableUnits(snapshot: BattleSnapshot, card: RunCardState): UnitState[] {
  if (card.targetSide === "self") {
    const owner = snapshot.leftTeam.find((unit) => unit.id === String(card.ownerInstanceId ?? ""));
    return owner && isAliveBattleUnit(owner) ? [owner] : [];
  }

  const sourcePool = card.targetSide === "ally" ? snapshot.leftTeam : snapshot.rightTeam;
  let candidates = sourcePool.filter(isAliveBattleUnit);
  if (card.targetSide !== "ally" && card.ignoreFrontProtection !== true) {
    const frontCandidates = candidates.filter(isFrontRowBattleUnit);
    if (frontCandidates.length > 0) {
      candidates = frontCandidates;
    }
  }
  return candidates;
}

async function bootstrapRunMode(
  host: LuaBattleHost,
  renderer: CanvasRenderer,
  panelHost: HTMLDivElement,
  stage: HTMLDivElement,
  battleStore: BattleStore,
  runStore: RunStore,
  shell: HTMLDivElement,
  syncMobileBattleStageHeight: () => void,
  registerCleanup: (callback: () => void) => void,
  isActive: () => boolean,
  params: URLSearchParams,
) {
  const pinnedRunSeed = Number(params.get("seed"));
  const hasPinnedRunSeed = Number.isFinite(pinnedRunSeed) && pinnedRunSeed > 0;
  const allocateRunSeed = () => Math.max(1, Math.floor(Date.now() % 2147483647));
  let runSeed = hasPinnedRunSeed ? pinnedRunSeed : allocateRunSeed();
  // Disable auto-ultimate by default in roguelike mode to keep early battles stable and reproducible.
  let autoUltimate = false;
  let battleSpeed = 1;
  let runSnapshot: RunSnapshot | null = null;
  let deferredPostBattleSnapshot: RunSnapshot | null = null;
  let holdBattleResultScene = false;
  let runUiDirty = true;
  let battleIntroHoldUntil = 0;
  let activeBattleKey = "";
  let selectedRunCardUid: string | null = null;

  const syncRunSnapshot = (snapshot: RunSnapshot) => {
    runSnapshot = snapshot;
    runStore.setSnapshot(snapshot);
    runUiDirty = true;
    if (selectedRunCardUid && !snapshot.cardBattle?.hand.some((card) => card.uid === selectedRunCardUid)) {
      selectedRunCardUid = null;
    }
    if (snapshot.battleSnapshot) {
      const battleKey = `${snapshot.currentNodeId ?? "node"}:${snapshot.battleSnapshot.leftTeam.map((unit) => unit.id).join(",")}__${snapshot.battleSnapshot.rightTeam.map((unit) => unit.id).join(",")}`;
      if (battleKey !== activeBattleKey) {
        activeBattleKey = battleKey;
        battleIntroHoldUntil = performance.now() + BATTLE_ENTRANCE_HOLD_MS;
      }
      battleStore.setSnapshot(snapshot.battleSnapshot);
      battleStore.setRunContext({
        chapterLabel: `Act 1`,
        nodeTitle:
          snapshot.map?.nodes.find((node) => node.id === snapshot.currentNodeId)?.title ?? `Node ${snapshot.currentNodeId ?? "-"}`,
        gold: snapshot.gold,
          equipmentCount: snapshot.equipments.length,
        blessingCount: snapshot.blessings.length,
      });
    } else {
      activeBattleKey = "";
      battleStore.setRunContext(null);
    }
  };

  const castRunUltimate = async (heroId: string) => {
    await host.queueRunBattleCommand({ type: "cast_ultimate", heroId });
  };

  const playRunCard = async (cardUid: string, targetId?: string) => {
    const response = await host.playCard(cardUid, targetId);
    if (response.accepted) {
      selectedRunCardUid = null;
      syncRunSnapshot(await host.getRunSnapshot());
    }
  };

  const getSelectedRunCard = () =>
    runSnapshot?.cardBattle?.hand.find((card) => card.uid === selectedRunCardUid) ?? null;

  const getSelectableTargetIds = () => {
    const card = getSelectedRunCard();
    if (!card || !runSnapshot?.battleSnapshot) {
      return [];
    }
    return getTargetableUnits(runSnapshot.battleSnapshot, card).map((unit) => unit.id);
  };

  const updateCanvasTargeting = () => {
    renderer.setSelectableTargetIds(getSelectableTargetIds());
  };

  const handleBattleCanvasPointerDown = (event: PointerEvent) => {
    const card = getSelectedRunCard();
    if (!card || !runSnapshot?.battleSnapshot || runSnapshot.phase !== "battle") {
      return;
    }
    const picked = renderer.pickBattleUnit(event.clientX, event.clientY);
    if (!picked || !getSelectableTargetIds().includes(picked.id)) {
      return;
    }
    event.preventDefault();
    void playRunCard(card.uid, picked.id);
  };
  renderer.canvas.addEventListener("pointerdown", handleBattleCanvasPointerDown);
  registerCleanup(() => {
    renderer.canvas.removeEventListener("pointerdown", handleBattleCanvasPointerDown);
  });

  const endRunTurn = async () => {
    const response = await host.endTurn();
    if (response.accepted) {
      syncRunSnapshot(await host.getRunSnapshot());
    }
  };

  let runControls!: ReturnType<typeof createRunControls>;

  const exitBattleScene = () => {
    if (!deferredPostBattleSnapshot) {
      return;
    }
    const nextSnapshot = deferredPostBattleSnapshot;
    deferredPostBattleSnapshot = null;
    holdBattleResultScene = false;
    syncRunSnapshot(nextSnapshot);
    runControls.setScreen("map");
    shell.dataset.screen = "run-map";
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
      speed: 1,
    },
    autoUltimate,
    { showSetupPanel: false },
  );

  runControls = createRunControls({
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
    onContinueEvent: async () => {
      await host.continueEvent();
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
    onStairUse: async () => {
      await host.stairUse();
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onStairLeave: async () => {
      await host.stairLeave();
      syncRunSnapshot(await host.getRunSnapshot());
    },
    onRestart: async () => {
      if (!hasPinnedRunSeed) {
        runSeed = allocateRunSeed();
      }
      syncRunSnapshot(await host.restartRun({ chapterId: 101, seed: runSeed }));
    },
  });
  stage.append(runControls.mapOverlay);

  syncRunSnapshot(await host.startRun({ chapterId: 101, seed: runSeed }));

  let rafId: number | null = null;
  registerCleanup(() => {
    if (rafId != null) {
      cancelAnimationFrame(rafId);
      rafId = null;
    }
  });

  let lastFrame = performance.now();
  let inFlight = false;
  let lastBattleControlsSignature = "";
  const frame = async (now: number) => {
    if (!isActive()) {
      return;
    }
    const delta = Math.min(120, now - lastFrame);
    lastFrame = now;

    if (runSnapshot?.phase === "battle" && now >= battleIntroHoldUntil && !inFlight) {
      inFlight = true;
      const previousPhase = runSnapshot.phase;
      const previousBattleSnapshot = battleStore.getState().snapshot;
      const { events, snapshot: liteSnapshot } = await host.tickRun(delta * battleSpeed);
      inFlight = false;
      if (!isActive()) {
        return;
      }

      if (previousPhase === "battle" && liteSnapshot.phase !== "battle") {
        // 战斗段结束：lite 快照不含 map/team/装备等字段，需要拉一次 full snapshot 给后续奖励/地图阶段使用。
        const fullSnapshot = await host.getRunSnapshot();
        if (!isActive()) {
          return;
        }
        runSnapshot = fullSnapshot;
        deferredPostBattleSnapshot = fullSnapshot;
        holdBattleResultScene = true;
        if (previousBattleSnapshot) {
          battleStore.setSnapshot({
            ...previousBattleSnapshot,
            phase: "ended",
            pendingCommands: 0,
            result:
              previousBattleSnapshot.result ??
              {
                winner: fullSnapshot.phase === "failed" ? "right" : "left",
                reason: fullSnapshot.lastActionMessage || (fullSnapshot.phase === "failed" ? "battle_failed" : "battle_resolved"),
              },
          });
        }
      } else if (runSnapshot) {
        // 战斗中：把 lite 快照合并到当前 runSnapshot，仅刷新战斗相关字段，
        // 其余 map/team/装备/事件状态保持上一帧值，避免每帧全量序列化。
        runSnapshot = {
          ...runSnapshot,
          phase: liteSnapshot.phase,
          currentNodeId: liteSnapshot.currentNodeId,
          lastActionMessage: liteSnapshot.lastActionMessage,
          battleSnapshot: liteSnapshot.battleSnapshot,
          cardLibrary: liteSnapshot.cardLibrary ?? runSnapshot.cardLibrary,
          cardBattle: liteSnapshot.cardBattle,
        };
        if (selectedRunCardUid && !runSnapshot.cardBattle?.hand.some((card) => card.uid === selectedRunCardUid)) {
          selectedRunCardUid = null;
        }
        runStore.setSnapshot(runSnapshot);
        if (liteSnapshot.battleSnapshot) {
          battleStore.setSnapshot(liteSnapshot.battleSnapshot);
        }
        runUiDirty = true;
      }
      battleStore.appendEvents(events);

      const battleSnapshot = liteSnapshot.battleSnapshot;
      if (autoUltimate && battleSnapshot && !battleSnapshot.result && battleSnapshot.pendingCommands === 0) {
        const readyUnit = battleSnapshot.leftTeam.find((unit) => unit.isAlive && unit.ultimateReady);
        if (readyUnit) {
          await castRunUltimate(readyUnit.id);
        }
      }
    }

    const shouldRenderBattle = holdBattleResultScene || (runSnapshot?.phase === "battle" && runSnapshot.battleSnapshot);
    if (shouldRenderBattle && battleStore.getState().snapshot) {
      if (holdBattleResultScene) {
        renderBattleResultStageOverlay(runControls, exitBattleScene);
        lastBattleControlsSignature = "";
      } else {
        runControls.mapOverlay.classList.remove("is-active");
        runControls.mapOverlay.classList.remove("run-map-overlay--modal");
      }
      if (panelHost.firstChild !== battleControls.root) {
        panelHost.replaceChildren(battleControls.root);
        lastBattleControlsSignature = "";
        // 切换到战斗 HUD 时，把当前 hud 的 screen 同步到 shell，避免 CSS 失配
        const currentScreen = battleControls.root.dataset.screen ?? "battle";
        shell.dataset.screen = currentScreen;
        syncMobileBattleStageHeight();
      }
      battleControls.root.classList.toggle("battle-ended", holdBattleResultScene);
      updateCanvasTargeting();
      renderer.renderBattle(battleStore.getState(), now);
      const battleSnapshot = battleStore.getState().snapshot;
      const battleLog = battleStore.getState().log;
      const cardBattle = runSnapshot?.cardBattle ?? null;
      const battleControlsSignature = JSON.stringify({
        phase: battleSnapshot?.phase,
        result: battleSnapshot?.result?.winner ?? null,
        activeHeroId: battleSnapshot?.activeHeroId ?? null,
        logCount: battleLog.length,
        selectedRunCardUid,
        cardPhase: cardBattle?.phase ?? null,
        teamEnergy: cardBattle?.teamEnergy ?? null,
        guard: cardBattle?.guard ?? null,
        drawPileCount: cardBattle?.drawPileCount ?? null,
        discardPileCount: cardBattle?.discardPileCount ?? null,
        exhaustPileCount: cardBattle?.exhaustPileCount ?? null,
        statusCreatedCount: cardBattle?.statusCreatedCount ?? null,
        hand: cardBattle?.hand.map((card) => [
          card.uid,
          card.cost,
          card.disabled,
          card.type,
          card.statusSubtype,
          card.targetSide,
          card.targetCount,
        ]) ?? [],
        intents: cardBattle?.enemyIntents?.map((intent) => [
          intent.enemyInstanceId,
          intent.skillId,
          intent.targetIds.join(","),
        ]) ?? [],
      });
      if (battleControlsSignature !== lastBattleControlsSignature) {
        renderControls(battleControls, battleSnapshot, battleLog, castRunUltimate, {
          cardBattle,
          selectedCardUid: selectedRunCardUid,
          onSelectCard: (cardUid) => {
            selectedRunCardUid = cardUid;
            lastBattleControlsSignature = "";
            updateCanvasTargeting();
          },
          onPlayCard: playRunCard,
          onEndTurn: endRunTurn,
        });
        lastBattleControlsSignature = battleControlsSignature;
      }
      syncMobileBattleStageHeight();
      battleStore.clearTransient(now);
    } else {
      if (panelHost.firstChild !== runControls.root) {
        panelHost.replaceChildren(runControls.root);
        lastBattleControlsSignature = "";
        // 切到 Roguelike HUD 时，把 runControls 当前 screen 同步到 shell，手机上 CSS 才会正确隐藏 stage
        const runScreen = runControls.root.dataset.screen ?? "map";
        shell.dataset.screen = `run-${runScreen}`;
        syncMobileBattleStageHeight();
        runUiDirty = true;
      }
      renderer.setSelectableTargetIds([]);
      renderer.renderMap(runSnapshot);
      if (runUiDirty) {
        renderRunControls(runControls, runStore.getState().snapshot, runStore.getState().logs);
        runUiDirty = false;
      }
    }

    if (isActive()) {
      rafId = requestAnimationFrame(frame);
    }
  };

  renderer.renderMap(runSnapshot);
  renderRunControls(runControls, runStore.getState().snapshot, runStore.getState().logs);
  rafId = requestAnimationFrame(frame);
}
