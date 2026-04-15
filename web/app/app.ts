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
  const setup: BattleSetup = {
    level: 50,
    heroCount: 3,
    enemyCount: 4,
    initialEnergy: 80,
    speed: 1,
  };
  let speed = setup.speed;

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
    setup,
  );

  sidePanel.replaceWith(controls.root);

  const initialSnapshot = await host.initBattle(toRuntimeConfig(setup));
  store.setSnapshot(initialSnapshot);

  let lastFrame = performance.now();

  const frame = async (now: number) => {
    const delta = Math.min(120, now - lastFrame);
    lastFrame = now;

    const { events, snapshot } = await host.tick(delta * speed);
    store.appendEvents(events);
    store.setSnapshot(snapshot);

    renderer.render(store.getState(), now);
    renderControls(controls, store.getState().snapshot, store.getState().log, castUltimate);
    store.clearTransient(now);

    requestAnimationFrame(frame);
  };

  renderer.render(store.getState(), performance.now());
  renderControls(controls, store.getState().snapshot, store.getState().log, castUltimate);
  requestAnimationFrame(frame);
}
