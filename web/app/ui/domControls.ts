import type { BattleSetup, BattleSnapshot } from "../types/battle";

const LEVEL_MIN = 1;
const LEVEL_MAX = 20;

type Controls = {
  root: HTMLDivElement;
  logList: HTMLUListElement;
  status: HTMLDivElement;
  buttonsHost: HTMLDivElement;
  screenTabs: HTMLDivElement;
  autoUltToggle: HTMLInputElement;
  levelInput: HTMLInputElement;
  heroCountInput: HTMLInputElement;
  enemyCountInput: HTMLInputElement;
  speedSelect: HTMLSelectElement;
};

type HudScreen = "battle" | "settings" | "log";

export function createControls(
  onUltCast: (heroId: string) => void,
  onRestart: (setup: BattleSetup) => void,
  onSpeedChange: (speed: number) => void,
  onAutoUltChange: (enabled: boolean) => void,
  initialSetup: BattleSetup,
  initialAutoUlt: boolean,
  options?: {
    showSetupPanel?: boolean;
  },
): Controls {
  const root = document.createElement("div");
  root.className = "hud";
  root.dataset.screen = "battle";

  const screenTabs = document.createElement("div");
  screenTabs.className = "hud-screen-tabs";

  const setScreen = (screen: HudScreen) => {
    root.dataset.screen = screen;
    root.closest(".shell")?.setAttribute("data-screen", screen);
    for (const button of screenTabs.querySelectorAll<HTMLButtonElement>("button[data-screen]")) {
      button.classList.toggle("active", button.dataset.screen === screen);
    }
  };

  const addScreenButton = (screen: HudScreen, label: string) => {
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.screen = screen;
    button.textContent = label;
    button.onclick = () => setScreen(screen);
    screenTabs.append(button);
  };

  addScreenButton("battle", "战斗");
  addScreenButton("settings", "设置");
  addScreenButton("log", "日志");

  const status = document.createElement("div");
  status.className = "hud-status";

  const buttonsHost = document.createElement("div");
  buttonsHost.className = "ult-panel";

  const logList = document.createElement("ul");
  logList.className = "battle-log";

  const actions = document.createElement("div");
  actions.className = "global-actions";

  const setupPanel = document.createElement("div");
  setupPanel.className = "setup-panel";

  const setupTitle = document.createElement("div");
  setupTitle.className = "panel-title";
  setupTitle.textContent = "战斗设置";

  const setupGrid = document.createElement("div");
  setupGrid.className = "setup-grid";

  const createNumberField = (
    labelText: string,
    id: string,
    value: number,
    min: number,
    max: number,
  ) => {
    const wrapper = document.createElement("label");
    wrapper.className = "setup-field";
    wrapper.htmlFor = id;

    const text = document.createElement("span");
    text.textContent = labelText;

    const input = document.createElement("input");
    input.id = id;
    input.type = "number";
    input.min = String(min);
    input.max = String(max);
    input.step = "1";
    input.value = String(value);
    input.onblur = () => {
      const numericValue = Number(input.value);
      const fallback = Number.isFinite(numericValue) ? numericValue : value;
      input.value = String(Math.max(min, Math.min(max, Math.round(fallback))));
    };

    wrapper.append(text, input);
    return { wrapper, input };
  };

  const createSelectField = (
    labelText: string,
    id: string,
    value: number,
    options: Array<{ value: number; label: string }>,
  ) => {
    const wrapper = document.createElement("label");
    wrapper.className = "setup-field";
    wrapper.htmlFor = id;

    const text = document.createElement("span");
    text.textContent = labelText;

    const select = document.createElement("select");
    select.id = id;
    for (const option of options) {
      const element = document.createElement("option");
      element.value = String(option.value);
      element.textContent = option.label;
      if (option.value === value) {
        element.selected = true;
      }
      select.append(element);
    }

    wrapper.append(text, select);
    return { wrapper, select };
  };

  const levelField = createNumberField("等级", "battle-level", initialSetup.level, LEVEL_MIN, LEVEL_MAX);
  const heroCountField = createNumberField("英雄数量", "battle-hero-count", initialSetup.heroCount, 1, 6);
  const enemyCountField = createNumberField("敌人数量", "battle-enemy-count", initialSetup.enemyCount, 1, 6);
  const speedField = createSelectField("速度", "battle-speed", initialSetup.speed, [
    { value: 1, label: "x1" },
    { value: 2, label: "x2" },
    { value: 3, label: "x3" },
    { value: 4, label: "x4" },
  ]);

  const readSetup = (): BattleSetup => ({
    level: Math.max(LEVEL_MIN, Math.min(LEVEL_MAX, Number(levelField.input.value) || initialSetup.level)),
    heroCount: Math.max(1, Math.min(6, Number(heroCountField.input.value) || initialSetup.heroCount)),
    enemyCount: Math.max(1, Math.min(6, Number(enemyCountField.input.value) || initialSetup.enemyCount)),
    initialEnergy: initialSetup.initialEnergy,
    speed: Math.max(1, Math.min(4, Number(speedField.select.value) || initialSetup.speed)),
    heroIds: initialSetup.heroIds,
    enemyIds: initialSetup.enemyIds,
    seed: initialSetup.seed,
    seedArray: initialSetup.seedArray,
  });

  speedField.select.onchange = () => {
    onSpeedChange(readSetup().speed);
  };

  setupGrid.append(
    levelField.wrapper,
    heroCountField.wrapper,
    enemyCountField.wrapper,
    speedField.wrapper,
  );
  setupPanel.append(setupTitle, setupGrid);

  const restartButton = document.createElement("button");
  restartButton.textContent = "应用设置并重开";
  restartButton.onclick = () => onRestart(readSetup());

  const autoUltLabel = document.createElement("label");
  autoUltLabel.className = "setup-field";

  const autoUltToggle = document.createElement("input");
  autoUltToggle.type = "checkbox";
  autoUltToggle.checked = initialAutoUlt;
  autoUltToggle.onchange = () => onAutoUltChange(autoUltToggle.checked);

  const autoUltText = document.createElement("span");
  autoUltText.textContent = "自动放大招";

  autoUltLabel.append(autoUltToggle, autoUltText);

  actions.append(restartButton, autoUltLabel);
  if (options?.showSetupPanel === false) {
    // Roguelike 模式无需重新配队伍，仍保留"速度/自动大招"便于战斗中调节
    setupPanel.style.display = "none";
    restartButton.style.display = "none";
    const speedCopy = speedField.wrapper.cloneNode(true) as HTMLLabelElement;
    const speedCopySelect = speedCopy.querySelector("select");
    if (speedCopySelect instanceof HTMLSelectElement) {
      speedCopySelect.id = "battle-speed-compact";
      speedCopySelect.value = speedField.select.value;
      speedCopySelect.onchange = () => {
        speedField.select.value = speedCopySelect.value;
        onSpeedChange(readSetup().speed);
      };
      speedField.select.addEventListener("change", () => {
        speedCopySelect.value = speedField.select.value;
      });
    }
    speedCopy.htmlFor = "battle-speed-compact";
    actions.append(speedCopy);
  }

  root.append(screenTabs, status, setupPanel, buttonsHost, actions, logList);
  setScreen("battle");

  return {
    root,
    logList,
    status,
    buttonsHost,
    screenTabs,
    autoUltToggle,
    levelInput: levelField.input,
    heroCountInput: heroCountField.input,
    enemyCountInput: enemyCountField.input,
    speedSelect: speedField.select,
  };
}

export function renderControls(
  controls: Controls,
  snapshot: BattleSnapshot | null,
  logEntries: string[],
  onUltCast: (heroId: string) => void,
  options?: {
    extraActions?: Array<{
      label: string;
      disabled?: boolean;
      onClick: () => void;
    }>;
  },
) {
  const allUnits = [...(snapshot?.leftTeam ?? []), ...(snapshot?.rightTeam ?? [])];
  const activeUnit =
    snapshot?.activeHeroId != null
      ? allUnits.find((unit) => unit.id === snapshot.activeHeroId)
      : null;
  const focusUnit =
    activeUnit ??
    (snapshot?.leftTeam ?? []).find((unit) => unit.isAlive) ??
    (snapshot?.rightTeam ?? []).find((unit) => unit.isAlive) ??
    null;
  const lines: string[] = [];
  if (snapshot?.result) {
    lines.push(`result: ${snapshot.result.reason} | 胜负: ${snapshot.result.winner} · ${snapshot.result.reason}`);
  } else {
    lines.push(`battle: ${snapshot ? snapshot.phase : "loading"} | 战斗状态: ${snapshot ? snapshot.phase : "loading"}`);
  }
  if (focusUnit) {
    const stateBits: string[] = [];
    if (focusUnit.isChanting) {
      stateBits.push(`吟唱:${focusUnit.pendingSkillName ?? "未知技能"}`);
    }
    if (focusUnit.isConcentrating) {
      stateBits.push(`专注:${focusUnit.concentrationSkillName ?? focusUnit.concentrationSkillId ?? "未知技能"}`);
    }
    lines.push(
      `${activeUnit ? "当前行动" : "当前角色"}: ${focusUnit.name} | HP ${focusUnit.hp}/${focusUnit.maxHp} | 先攻 ${focusUnit.initiative ?? 0} (${focusUnit.initiativeRoll ?? 0}${(focusUnit.initiativeMod ?? 0) >= 0 ? "+" : ""}${focusUnit.initiativeMod ?? 0}) | AC ${focusUnit.ac} | 命中 ${focusUnit.hit} | 法术命中 ${focusUnit.spellDC} | 豁免 F/R/W ${focusUnit.saveFort}/${focusUnit.saveRef}/${focusUnit.saveWill}${stateBits.length > 0 ? ` | 状态 ${stateBits.join(" / ")}` : ""}`,
    );
  }
  controls.status.textContent = lines.join("\n");

  controls.buttonsHost.replaceChildren();
  for (const unit of snapshot?.leftTeam ?? []) {
    const button = document.createElement("button");
    button.className = "ult-button";
    button.type = "button";
    button.disabled = !unit.ultimateReady || !unit.isAlive;
    const name = document.createElement("span");
    name.className = "ult-button-name";
    name.textContent = unit.name;
    const skill = document.createElement("span");
    skill.className = "ult-button-skill";
    skill.textContent = unit.ultimateSkillName;
    const charges = document.createElement("span");
    charges.className = "ult-button-charges";
    charges.textContent = `次数 ${unit.ultimateCharges}/${unit.ultimateChargesMax}`;
    button.replaceChildren(name, skill, charges);
    if (unit.ultimateReady) {
      button.classList.add("ready");
    }
    button.onpointerdown = (event) => {
      event.preventDefault();
      if (!button.disabled) {
        onUltCast(unit.id);
      }
    };
    controls.buttonsHost.append(button);
  }

  for (const action of options?.extraActions ?? []) {
    const button = document.createElement("button");
    button.className = "ult-button";
    button.type = "button";
    button.disabled = action.disabled === true;
    button.textContent = action.label;
    button.onpointerdown = (event) => {
      event.preventDefault();
      if (!button.disabled) {
        action.onClick();
      }
    };
    controls.buttonsHost.append(button);
  }

  controls.logList.replaceChildren(
    ...logEntries.map((entry) => {
      const item = document.createElement("li");
      item.textContent = entry;
      return item;
    }),
  );
}
