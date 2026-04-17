import { LuaBattleHost } from "./lua/LuaBattleHost";
import { CanvasRenderer } from "./render/CanvasRenderer";
import { BattleStore } from "./state/battleStore";
import type { BattleSetup } from "./types/battle";
import { createControls, renderControls } from "./ui/domControls";

export async function bootstrapApp(container: HTMLElement) {
  const shell = document.createElement("div");
  shell.className = "shell";

  const stage = document.createElement("div");
  stage.className = "stage";

  const diagnostics = document.createElement("pre");
  diagnostics.className = "diagnostics";
  diagnostics.textContent = "正在初始化浏览器战斗运行时...";
  stage.append(diagnostics);

  const sidePanel = document.createElement("div");
  sidePanel.className = "hud";

  shell.append(stage, sidePanel);
  container.append(shell);

  const host = await LuaBattleHost.create();
  const store = new BattleStore();
  const renderer = new CanvasRenderer();
  // #region debug-point A:runtime-debug
  const enableTraeDebug = new URLSearchParams(window.location.search).has("traeDebug");
  const debugReport = (
    hypothesisId: "A" | "B" | "C" | "D" | "E",
    msg: string,
    data: Record<string, unknown>,
  ) =>
    enableTraeDebug
      ? fetch("http://127.0.0.1:7777/event", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            sessionId: "mobile-battle-speed",
            runId: "pre-fix",
            hypothesisId,
            location: "web/app/app.ts",
            msg: `[DEBUG] ${msg}`,
            data,
            ts: Date.now(),
          }),
        }).catch(() => {})
      : Promise.resolve();
  // #endregion
  const setup: BattleSetup = {
    level: 50,
    heroCount: 6,
    enemyCount: 6,
    initialEnergy: 80,
    speed: 1,
  };
  let speed = setup.speed;
  let autoUltimate = false;

  const toRuntimeConfig = (nextSetup: BattleSetup) => ({
    level: nextSetup.level,
    heroCount: nextSetup.heroCount,
    enemyCount: nextSetup.enemyCount,
    initialEnergy: nextSetup.initialEnergy,
  });

  diagnostics.remove();
  stage.append(renderer.canvas);

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

  sidePanel.replaceWith(controls.root);

  const initialSnapshot = await host.initBattle(toRuntimeConfig(setup));
  store.setSnapshot(initialSnapshot);
  // #region debug-point D:init-snapshot
  void debugReport("D", "initial battle snapshot", {
    speed,
    round: initialSnapshot.round,
    phase: initialSnapshot.phase,
    pendingCommands: initialSnapshot.pendingCommands,
    hasResult: Boolean(initialSnapshot.result),
  });
  // #endregion

  let lastFrame = performance.now();
  let frameCount = 0;
  let inFlight = false;
  let battleStartWallClock = performance.now();
  let lastRound = initialSnapshot.round;

  const frame = async (now: number) => {
    const delta = Math.min(120, now - lastFrame);
    lastFrame = now;
    const logicDelta = delta * speed;
    frameCount += 1;

    // #region debug-point A:reentry
    if (inFlight) {
      void debugReport("A", "frame reentry detected", {
        now,
        delta,
        logicDelta,
        speed,
        frameCount,
      });
    }
    // #endregion

    inFlight = true;
    const { events, snapshot } = await host.tick(logicDelta);
    inFlight = false;
    store.appendEvents(events);
    store.setSnapshot(snapshot);

    if (autoUltimate && !snapshot.result && snapshot.pendingCommands === 0) {
      const readyUnit = snapshot.leftTeam.find((unit) => unit.isAlive && unit.ultimateReady);
      if (readyUnit) {
        await castUltimate(readyUnit.id);
      }
    }

    // #region debug-point B:frame-sample
    if (frameCount <= 5 || frameCount % 20 === 0) {
      void debugReport("B", "frame sample", {
        now,
        delta,
        logicDelta,
        speed,
        frameCount,
        eventCount: events.length,
        round: snapshot.round,
        phase: snapshot.phase,
        hasResult: Boolean(snapshot.result),
      });
    }
    // #endregion

    // #region debug-point C:round-and-end
    if (snapshot.round !== lastRound) {
      void debugReport("C", "round advanced", {
        round: snapshot.round,
        previousRound: lastRound,
        elapsedWallClockMs: Math.round(now - battleStartWallClock),
        activeHeroId: snapshot.activeHeroId,
        phase: snapshot.phase,
      });
      lastRound = snapshot.round;
    }

    if (snapshot.result) {
      void debugReport("E", "battle finished", {
        elapsedWallClockMs: Math.round(now - battleStartWallClock),
        round: snapshot.round,
        winner: snapshot.result.winner,
        reason: snapshot.result.reason,
        speed,
      });
    }
    // #endregion

    renderer.render(store.getState(), now);
    renderControls(controls, store.getState().snapshot, store.getState().log, castUltimate);
    store.clearTransient(now);

    requestAnimationFrame(frame);
  };

  renderer.render(store.getState(), performance.now());
  renderControls(controls, store.getState().snapshot, store.getState().log, castUltimate);
  requestAnimationFrame(frame);
}
