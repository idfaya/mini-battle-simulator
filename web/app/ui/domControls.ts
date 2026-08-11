import type { BattleSetup, BattleSnapshot, UnitState } from "../types/battle";
import type { RunCardBattleState, RunCardState } from "../types/roguelike";

const LEVEL_MIN = 1;
const LEVEL_MAX = 20;

type Controls = {
  root: HTMLDivElement;
  logList: HTMLUListElement;
  status: HTMLDivElement;
  buttonsHost: HTMLDivElement;
  resultActionsHost: HTMLDivElement;
  screenTabs: HTMLDivElement;
  autoUltToggle: HTMLInputElement;
  levelInput: HTMLInputElement;
  heroCountInput: HTMLInputElement;
  enemyCountInput: HTMLInputElement;
  speedSelect: HTMLSelectElement;
};

type HudScreen = "battle" | "settings" | "log";

function getFormationSlot(unit: UnitState, fallbackIndex: number) {
  const position = Number.isFinite(unit.position) ? Math.floor(unit.position) : 0;
  const slot = position >= 1 && position <= 6 ? position - 1 : fallbackIndex;
  return {
    row: Math.floor(slot / 3) + 1,
    column: (slot % 3) + 1,
  };
}

function cardTypeLabel(card: RunCardState): string {
  switch (card.type) {
    case "attack":
      return "ATTACK";
    case "skill":
      return "SKILL";
    case "power":
      return "POWER";
    case "status":
      return "STATUS";
    case "curse":
      return "CURSE";
    default:
      return String(card.type ?? "CARD").toUpperCase();
  }
}

function cardHintText(card: RunCardState): string {
  const parts: string[] = [];
  if (card.upgraded === true || (card.upgradeLevel ?? 0) > 0) {
    parts.push(`升级 +${Math.max(1, card.upgradeLevel ?? 1)}`);
  }
  if ((card.guardValue ?? 0) > 0) {
    parts.push(`guard +${card.guardValue}`);
  }
  if ((card.drawCards ?? 0) > 0) {
    parts.push(`抽 ${card.drawCards}`);
  }
  if ((card.energyGain ?? 0) > 0) {
    parts.push(`能量 +${card.energyGain}`);
  }
  if ((card.momentumGain ?? 0) > 0) {
    parts.push(`蓄势 +${card.momentumGain}`);
  }
  if ((card.momentumSpend ?? 0) > 0) {
    const spendBits = [`耗势 ${card.momentumSpend}`];
    if ((card.momentumCostReduction ?? 0) > 0) {
      spendBits.push(`费用 -${card.momentumCostReduction}`);
    }
    if ((card.momentumEnergyGain ?? 0) > 0) {
      spendBits.push(`能量 +${card.momentumEnergyGain}`);
    }
    if ((card.momentumDrawCards ?? 0) > 0) {
      spendBits.push(`抽 ${card.momentumDrawCards}`);
    }
    if ((card.momentumGuardValue ?? 0) > 0) {
      spendBits.push(`guard +${card.momentumGuardValue}`);
    }
    parts.push(spendBits.join("/"));
  }
  if ((card.targetCount ?? 0) > 1) {
    parts.push(`${card.targetCount} 目标`);
  }
  if (card.exhaust) {
    parts.push("消耗");
  }
  if (card.retain) {
    parts.push("保留");
  }
  if (card.ethereal) {
    parts.push("虚灵");
  }
  return parts.length > 0 ? parts.join(" · ") : "点击打出";
}

function effectiveCardCost(cardBattle: RunCardBattleState, card: RunCardState, baseCost: number): number {
  const momentum = Math.max(0, Math.floor(cardBattle.momentum ?? 0));
  const spend = Math.max(0, Math.floor(card.momentumSpend ?? 0));
  if (spend > 0 && momentum >= spend) {
    return Math.max(0, baseCost - Math.max(0, Math.floor(card.momentumCostReduction ?? 0)));
  }
  return baseCost;
}

function cardDisabledReason(cardBattle: RunCardBattleState, card: RunCardState, costValue: number): string {
  if (card.type === "status" || card.type === "curse") {
    return "污染";
  }
  if (card.disabled) {
    return "阵亡失效";
  }
  if (cardBattle.phase !== "player") {
    return "敌方行动";
  }
  if (cardBattle.teamEnergy < effectiveCardCost(cardBattle, card, costValue)) {
    return "能量不足";
  }
  return cardHintText(card);
}

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
  buttonsHost.style.display = "none";

  const resultActionsHost = document.createElement("div");
  resultActionsHost.className = "result-actions";
  resultActionsHost.style.display = "none";

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
  ]);

  const readSetup = (): BattleSetup => ({
    level: Math.max(LEVEL_MIN, Math.min(LEVEL_MAX, Number(levelField.input.value) || initialSetup.level)),
    heroCount: Math.max(1, Math.min(6, Number(heroCountField.input.value) || initialSetup.heroCount)),
    enemyCount: Math.max(1, Math.min(6, Number(enemyCountField.input.value) || initialSetup.enemyCount)),
    initialEnergy: initialSetup.initialEnergy,
    speed: Math.max(1, Math.min(3, Number(speedField.select.value) || initialSetup.speed)),
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
    actions.classList.add("compact-settings");
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

  root.append(screenTabs, status, setupPanel, buttonsHost, actions, resultActionsHost, logList);
  setScreen("battle");

  return {
    root,
    logList,
    status,
    buttonsHost,
    resultActionsHost,
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
    cardBattle?: RunCardBattleState | null;
    selectedCardUid?: string | null;
    onSelectCard?: (cardUid: string | null) => void;
    onPlayCard?: (cardUid: string, targetId?: string) => void | Promise<void>;
    onEndTurn?: () => void | Promise<void>;
    extraActions?: Array<{
      label: string;
      disabled?: boolean;
      onClick: () => void;
    }>;
  },
) {
  void onUltCast;
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
      `${activeUnit ? "当前行动" : "当前角色"}: ${focusUnit.name} | HP ${focusUnit.hp}/${focusUnit.maxHp} | 先攻 ${focusUnit.initiative ?? 0} (${focusUnit.initiativeRoll ?? 0}${(focusUnit.initiativeMod ?? 0) >= 0 ? "+" : ""}${focusUnit.initiativeMod ?? 0}) | AC ${focusUnit.ac} | 命中 ${focusUnit.hit} | 法术命中 ${focusUnit.spellDC} | 豁免 F/R/W ${focusUnit.saveCon}/${focusUnit.saveDex}/${focusUnit.saveWis}${stateBits.length > 0 ? ` | 状态 ${stateBits.join(" / ")}` : ""}`,
    );
  }
  if (options?.cardBattle) {
    const cardBattle = options.cardBattle;
    const intentText = (cardBattle.enemyIntents ?? []).length
      ? (cardBattle.enemyIntents ?? [])
          .map((intent) => {
            const preview = intent.preview?.summary ? ` [${intent.preview.summary}]` : "";
            return `${intent.enemyName ?? "敌人"}:${intent.skillName ?? intent.type}${intent.targetNames.length ? `→${intent.targetNames.join("/")}` : ""}${preview}`;
          })
          .join(" | ")
      : "无";
    lines.push(
      `牌局: ${cardBattle.phase} | 能量 ${cardBattle.teamEnergy}/${cardBattle.maxEnergy} | 蓄势 ${cardBattle.momentum ?? 0}/${cardBattle.momentumMax ?? 3} | 抽牌 ${cardBattle.drawPileCount} | 弃牌 ${cardBattle.discardPileCount} | 消耗 ${cardBattle.exhaustPileCount} | Intent ${intentText}`,
    );
  }
  controls.status.textContent = lines.join("\n");

  controls.buttonsHost.replaceChildren();
  if (snapshot && !snapshot.result && options?.cardBattle?.hand?.length) {
    const cardBattle = options.cardBattle;
    controls.buttonsHost.style.display = "";
    controls.buttonsHost.classList.add("battle-hand-panel");
    const selectedCard = cardBattle.hand.find((card) => card.uid === options.selectedCardUid) ?? null;

    const handHeader = document.createElement("div");
    handHeader.className = "battle-hand-head";

    const energy = document.createElement("div");
    energy.className = "battle-hand-energy";
    energy.textContent = String(cardBattle.teamEnergy);

    const turnText = document.createElement("div");
    turnText.className = "battle-hand-turn";
    const turnTitle = document.createElement("b");
    turnTitle.textContent = cardBattle.phase === "player" ? `第 ${cardBattle.turn} 回合 · 玩家行动` : `第 ${cardBattle.turn} 回合 · 敌方行动`;
    const turnMeta = document.createElement("span");
    turnMeta.textContent = `能量 ${cardBattle.teamEnergy}/${cardBattle.maxEnergy} · 蓄势 ${cardBattle.momentum ?? 0}/${cardBattle.momentumMax ?? 3} · 抽牌 ${cardBattle.drawPileCount} · 弃牌 ${cardBattle.discardPileCount} · Guard ${cardBattle.guard}`;
    turnText.append(turnTitle, turnMeta);

    const endTurnButton = document.createElement("button");
    endTurnButton.className = "ult-button battle-end-turn-button";
    endTurnButton.type = "button";
    endTurnButton.disabled = cardBattle.phase !== "player" || typeof options.onEndTurn !== "function";
    endTurnButton.textContent = cardBattle.phase === "player" ? "结束回合" : "敌方行动中";
    endTurnButton.onpointerdown = (event) => {
      event.preventDefault();
      if (!endTurnButton.disabled) {
        void options.onEndTurn?.();
      }
    };
    handHeader.append(energy, turnText, endTurnButton);

    const cardsGrid = document.createElement("div");
    cardsGrid.className = "battle-hand-cards";
    const handNodes = cardBattle.hand.map((card) => {
        const button = document.createElement("button");
        button.type = "button";
        const costValue = Number(card.cost ?? 0);
        const playableCost = effectiveCardCost(cardBattle, card, costValue);
        const isPollution = card.type === "status" || card.type === "curse";
        const canPlay =
          cardBattle.phase === "player" &&
          !isPollution &&
          card.disabled !== true &&
          cardBattle.teamEnergy >= playableCost &&
          typeof options.onPlayCard === "function";
        const isSelected = card.uid === selectedCard?.uid;
        const upgradedClass = card.upgraded === true || (card.upgradeLevel ?? 0) > 0 ? " upgraded" : "";
        button.className = `ult-button battle-card-button battle-card-button--${card.type}${canPlay ? " ready" : ""}${isSelected ? " selected" : ""}${upgradedClass}`;
        button.dataset.cardUid = card.uid;
        button.dataset.targetSide = String(card.targetSide ?? "none");
        button.disabled = !canPlay;
        button.onpointerdown = (event) => {
          event.preventDefault();
          if (!button.disabled) {
            if (card.targetSide === "self") {
              void options.onPlayCard?.(card.uid, card.ownerInstanceId ? String(card.ownerInstanceId) : undefined);
            } else if (card.targetSide === "none" || card.targetSide == null) {
              void options.onPlayCard?.(card.uid);
            } else {
              options.onSelectCard?.(card.uid);
            }
          }
        };

        const cost = document.createElement("span");
        cost.className = "battle-card-cost";
        cost.textContent = playableCost !== costValue ? `${costValue}>${playableCost}` : String(card.cost ?? 0);

        const type = document.createElement("span");
        type.className = "battle-card-type";
        type.textContent = cardTypeLabel(card);

        const name = document.createElement("span");
        name.className = "ult-button-name";
        name.textContent = card.name;

        const owner = document.createElement("span");
        owner.className = "ult-button-skill";
        owner.textContent = card.ownerName || "队伍";

        const desc = document.createElement("span");
        desc.className = "battle-card-desc";
        desc.textContent = card.description || "通过 Feat 投影生成的战斗卡。";

        const hint = document.createElement("span");
        hint.className = "battle-card-hint";
        hint.textContent = cardDisabledReason(cardBattle, card, costValue);

        button.append(cost, type, name, owner, desc, hint);
        return button;
      });
    cardsGrid.append(...handNodes);
    controls.buttonsHost.replaceChildren(handHeader, cardsGrid);
  } else if (snapshot && !snapshot.result) {
    controls.buttonsHost.style.display = "";
    controls.buttonsHost.classList.remove("battle-hand-panel");
    const missing = document.createElement("div");
    missing.className = "battle-card-missing";
    missing.textContent = "cardBattle 未初始化：战斗牌局状态缺失";
    controls.buttonsHost.replaceChildren(missing);
  } else {
    controls.buttonsHost.style.display = "none";
    controls.buttonsHost.classList.remove("battle-hand-panel");
  }

  // Battle result actions live in a dedicated host (not mixed with ult buttons).
  const extraActions = options?.extraActions ?? [];
  if (extraActions.length > 0) {
    controls.resultActionsHost.style.display = "";
    controls.resultActionsHost.replaceChildren(
      ...extraActions.map((action) => {
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
        return button;
      }),
    );
  } else {
    controls.resultActionsHost.replaceChildren();
    controls.resultActionsHost.style.display = "none";
  }

  controls.logList.replaceChildren(
    ...logEntries.map((entry) => {
      const item = document.createElement("li");
      item.textContent = entry;
      return item;
    }),
  );
}
