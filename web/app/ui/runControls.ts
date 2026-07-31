import type { EquipmentState, FeatOption, RewardOption, RunSnapshot, RunTeamMember } from "../types/roguelike";

type RunHandlers = {
  onChooseNode: (nodeId: number) => void;
  onEnterNode: () => void;
  onChooseEventOption: (optionId: number) => void;
  onContinueEvent: () => void;
  onChooseReward: (index: number) => void;
  onShopBuy: (goodsId: number) => void;
  onShopRefresh: () => void;
  onShopLeave: () => void;
  onPromoteBenchHero: (benchRosterId: number) => void;
  onSwapBenchWithTeam: (benchRosterId: number, teamRosterId: number) => void;
  onCampChoose: (actionId: number) => void;
  onStairUse: () => void;
  onStairLeave: () => void;
  onRestart: () => void;
};

type RunScreen = "map" | "team" | "info" | "log";

type RunControls = {
  root: HTMLDivElement;
  status: HTMLDivElement;
  screenTabs: HTMLDivElement;
  mapPanel: HTMLDivElement;
  mapOverlay: HTMLDivElement;
  teamPanel: HTMLDivElement;
  infoPanel: HTMLDivElement;
  logList: HTMLUListElement;
  handlers: RunHandlers;
  selectedBenchRosterId: number | null;
  currentScreen: RunScreen;
  setScreen: (screen: RunScreen) => void;
  /** 阶段变化时，把用户强制跳到最适合操作的页 */
  autoRouteByPhase: (phase: RunSnapshot["phase"] | null) => void;
};

export function createRunControls(handlers: RunHandlers): RunControls {
  const root = document.createElement("div");
  root.className = "hud";
  root.dataset.screen = "map";

  const screenTabs = document.createElement("div");
  screenTabs.className = "hud-screen-tabs";

  const status = document.createElement("div");
  status.className = "hud-status";

  const mapPanel = document.createElement("div");
  mapPanel.className = "ult-panel run-map-panel";

  const mapOverlay = document.createElement("div");
  mapOverlay.className = "run-map-overlay";

  const teamPanel = document.createElement("div");
  teamPanel.className = "setup-panel run-team-panel";

  const infoPanel = document.createElement("div");
  infoPanel.className = "setup-panel run-info-panel";

  const logList = document.createElement("ul");
  logList.className = "battle-log";

  const controls: RunControls = {
    root,
    status,
    screenTabs,
    mapPanel,
    mapOverlay,
    teamPanel,
    infoPanel,
    logList,
    handlers,
    selectedBenchRosterId: null,
    currentScreen: "map",
    setScreen: () => {},
    autoRouteByPhase: () => {},
  };

  const setScreen = (screen: RunScreen) => {
    controls.currentScreen = screen;
    root.dataset.screen = screen;
    const shell = root.closest(".shell");
    shell?.setAttribute("data-screen", `run-${screen}`);
    // Reset stage scroll position when leaving the map screen so the battle
    // canvas isn't shifted by leftover scrollTop on the stage container.
    if (screen !== "map" && shell) {
      const stage = shell.querySelector<HTMLElement>(".stage");
      if (stage) stage.scrollTop = 0;
    }
    for (const button of screenTabs.querySelectorAll<HTMLButtonElement>("button[data-screen]")) {
      button.classList.toggle("active", button.dataset.screen === screen);
    }
  };
  controls.setScreen = setScreen;

  const addScreenButton = (screen: RunScreen, label: string) => {
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.screen = screen;
    button.textContent = label;
    button.onclick = () => setScreen(screen);
    screenTabs.append(button);
  };

  addScreenButton("map", "地图");
  addScreenButton("team", "队伍");
  addScreenButton("info", "信息");
  addScreenButton("log", "日志");

  // 自动路由：根据 phase 把玩家推到最该看的 tab（但尊重用户主动切换）
  let lastAutoPhase: string | null = null;
  controls.autoRouteByPhase = (phase) => {
    if (!phase || phase === lastAutoPhase) {
      return;
    }
    lastAutoPhase = phase;
    // phase 切换意味着新的操作场景。事件 / 商店 / 奖励操作直接显示在战场舞台上，继续留在地图页。
    if (phase === "camp") {
      setScreen("info");
    } else if (phase === "map" || phase === "stair" || phase === "event" || phase === "shop" || phase === "reward") {
      setScreen("map");
    } else if (phase === "chapter_result" || phase === "failed") {
      setScreen("info");
    }
  };

  root.append(status, mapPanel, mapOverlay, teamPanel, infoPanel, logList, screenTabs);
  setScreen("map");

  return controls;
}

function makeButton(label: string, disabled: boolean, onClick: () => void | Promise<void>) {
  const button = document.createElement("button");
  button.className = "ult-button";
  button.type = "button";
  button.disabled = disabled;
  button.textContent = label;
  button.onclick = () => {
    const result = onClick();
    if (result && typeof (result as Promise<void>).then === "function") {
      void result;
    }
  };
  return button;
}

function createStageModal(title: string, subtitle?: string) {
  const modal = document.createElement("section");
  modal.className = "run-stage-modal";

  const header = document.createElement("div");
  header.className = "run-stage-modal__header";

  const titleEl = document.createElement("div");
  titleEl.className = "run-stage-modal__title";
  titleEl.textContent = title;
  header.append(titleEl);

  if (subtitle) {
    const subtitleEl = document.createElement("div");
    subtitleEl.className = "run-stage-modal__subtitle";
    subtitleEl.textContent = subtitle;
    header.append(subtitleEl);
  }

  const body = document.createElement("div");
  body.className = "run-stage-modal__body";
  modal.append(header, body);
  return { modal, body };
}

function getStageModalRenderState(snapshot: RunSnapshot): { type: string; key: string } | null {
  if (snapshot.phase === "event" && snapshot.eventState) {
    const event = snapshot.eventState;
    const resultKey = event.result
      ? `result:${event.result.title}:${event.result.optionLabel ?? ""}:${event.result.summary}:${event.result.actionLabel}`
      : `options:${event.options.map((option) => option.id).join(",")}`;
    const check = event.lastSkillCheck;
    const checkKey = check ? `${check.total ?? ""}:${check.tier ?? ""}` : "";
    return { type: "event", key: `event:${event.id}:${event.code}:${resultKey}:${checkKey}` };
  }

  if (snapshot.phase === "shop" && snapshot.shopState) {
    const shop = snapshot.shopState;
    const goodsKey = shop.goods
      .map((goods) => `${goods.goodsId}:${goods.price}:${goods.sold ? 1 : 0}`)
      .join(",");
    return { type: "shop", key: `shop:${shop.shopId}:${shop.refreshCount}:${snapshot.gold}:${goodsKey}` };
  }

  if (snapshot.phase === "reward" && snapshot.rewardState) {
    const reward = snapshot.rewardState;
    const optionKey = reward.options
      .map((option) => "featId" in option ? option.featId : `${option.rewardType}:${option.refId ?? ""}:${option.value ?? ""}`)
      .join(",");
    return { type: "reward", key: `reward:${reward.kind}:${optionKey}` };
  }

  return null;
}

function applyStageModalRenderState(modal: HTMLElement, renderState: { type: string; key: string }) {
  modal.dataset.stageModal = renderState.type;
  modal.dataset.stageModalKey = renderState.key;
}

function appendStageNotice(host: HTMLElement, text = "请在战场弹窗中处理当前选择。") {
  const notice = document.createElement("div");
  notice.className = "run-stage-notice";
  notice.textContent = text;
  host.append(notice);
}

function formatSigned(value: number | undefined | null): string {
  if (value === undefined || value === null || Number.isNaN(value)) return "-";
  const v = Math.trunc(value);
  return v >= 0 ? `+${v}` : `${v}`;
}

function formatAbility(score: number | undefined, mod: number | undefined): string {
  if (score === undefined || score === null) return "-";
  return `${score} (${formatSigned(mod)})`;
}

function createRosterInfo(member: RunTeamMember) {
  const wrapper = document.createElement("div");
  wrapper.className = "run-roster-info";

  const primary = document.createElement("div");
  primary.className = "run-roster-meta";
  const levelText = `Lv${member.level}${member.nextLevelExp && member.nextLevelExp > 0 ? ` ${member.exp ?? 0}/${(member.exp ?? 0) + member.nextLevelExp}` : ""}`;
  primary.textContent = `${member.name} · ${levelText}${member.isDead ? " · 阵亡" : ` · HP ${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`}`;
  wrapper.append(primary);

  const summary = member.buildSummary ?? [];
  if (summary.length > 0) {
    const summaryHost = document.createElement("div");
    summaryHost.className = "run-build-summary";
    summaryHost.textContent = `构筑: ${summary.join(" / ")}`;
    wrapper.append(summaryHost);
  }

  // 详细战斗属性卡片
  const hasCombatStats =
    member.ac !== undefined ||
    member.hit !== undefined ||
    member.spellDC !== undefined ||
    member.saveCon !== undefined;
  if (hasCombatStats) {
    const stats = document.createElement("div");
    stats.className = "run-roster-stats";
    const statItems: Array<{ label: string; value: string }> = [
      { label: "AC", value: member.ac !== undefined ? String(member.ac) : "-" },
      { label: "命中", value: formatSigned(member.hit) },
      { label: "法术", value: formatSigned(member.spellAttack) },
      { label: "法术DC", value: member.spellDC !== undefined ? String(member.spellDC) : "-" },
      { label: "体质", value: formatSigned(member.saveCon) },
      { label: "敏捷", value: formatSigned(member.saveDex) },
      { label: "感知", value: formatSigned(member.saveWis) },
      { label: "武器骰", value: member.weaponDice ?? "-" },
    ];
    for (const item of statItems) {
      const cell = document.createElement("div");
      cell.className = "run-roster-stat-cell";
      cell.innerHTML = `<span>${item.label}</span><strong>${item.value}</strong>`;
      stats.append(cell);
    }
    wrapper.append(stats);
  }

  const hasAbilities = member.str !== undefined;
  if (hasAbilities) {
    const abilities = document.createElement("div");
    abilities.className = "run-roster-abilities";
    const abilityItems: Array<{ label: string; score?: number; mod?: number }> = [
      { label: "力量", score: member.str, mod: member.strMod },
      { label: "敏捷", score: member.dex, mod: member.dexMod },
      { label: "体质", score: member.con, mod: member.conMod },
      { label: "智力", score: member.int, mod: member.intMod },
      { label: "感知", score: member.wis, mod: member.wisMod },
      { label: "魅力", score: member.cha, mod: member.chaMod },
    ];
    for (const item of abilityItems) {
      const cell = document.createElement("div");
      cell.className = "run-roster-ability-cell";
      cell.innerHTML = `<span>${item.label}</span><strong>${formatAbility(item.score, item.mod)}</strong>`;
      abilities.append(cell);
    }
    wrapper.append(abilities);
  }

  return wrapper;
}

function formatBattleSummaryDelta(change: { delta: number; format: "flat" | "bp_pct" }) {
  const sign = change.delta > 0 ? "+" : "";
  if (change.format === "bp_pct") {
    const pct = change.delta / 100;
    const text = Number.isInteger(pct) ? String(pct) : pct.toFixed(2).replace(/\.?0+$/, "");
    return `${sign}${text}%`;
  }
  return `${sign}${change.delta}`;
}

function formatEventTierLabel(tier: string | undefined): string {
  if (tier === "critSuccess") return "大成功";
  if (tier === "success") return "成功";
  if (tier === "failure") return "失败";
  if (tier === "critFailure") return "大失败";
  return tier || "?";
}

function renderBattleSummary(host: HTMLDivElement, snapshot: RunSnapshot) {
  const summary = snapshot.lastBattleSummary;
  if (!summary || summary.won !== true) {
    return;
  }
  const levelUpUnitCount = new Set((summary.levelUps ?? []).map((item) => item.rosterId)).size;

  const section = document.createElement("section");
  section.className = "run-info-section run-battle-summary-section";

  const title = document.createElement("div");
  title.className = "panel-title";
  title.textContent = "升级奖励";
  section.append(title);

  const stats = document.createElement("div");
  stats.className = "setup-grid run-compact-grid";
  stats.innerHTML = `
    <div class="setup-field run-compact-field"><span>获得经验</span><strong>${summary.expReward ?? 0}</strong></div>
    <div class="setup-field run-compact-field"><span>获得金币</span><strong>${summary.earnedGold ?? 0}</strong></div>
    <div class="setup-field run-compact-field"><span>升级人数</span><strong>${levelUpUnitCount}</strong></div>
    <div class="setup-field run-compact-field"><span>掉落装备</span><strong>${summary.equipmentDropCount ?? 0}</strong></div>
  `;
  section.append(stats);

  if ((summary.levelUps?.length ?? 0) <= 0) {
    const empty = document.createElement("div");
    empty.className = "run-roster-meta";
    empty.textContent = "本场没有单位升级";
    section.append(empty);
    host.append(section);
    return;
  }

  const levelTitle = document.createElement("div");
  levelTitle.className = "panel-title";
  levelTitle.textContent = "升级效果";
  section.append(levelTitle);

  const levelList = document.createElement("div");
  levelList.className = "run-team-summary";
  for (const levelUp of summary.levelUps ?? []) {
    const card = document.createElement("div");
    card.className = "run-team-card";

    const header = document.createElement("div");
    header.className = "run-roster-meta";
    header.textContent = `${levelUp.heroName} · Lv${levelUp.levelBefore} -> Lv${levelUp.levelAfter}`;
    card.append(header);

    const skillCards = levelUp.gainedSkillCards ?? [];
    const skillRow = document.createElement("div");
    skillRow.className = "run-build-summary";
    skillRow.textContent =
      skillCards.length > 0
        ? `新技能卡: ${skillCards.map((skill) => `${skill.runtimeKind === "passive" ? "被动" : "主动"}·${skill.name}`).join(" / ")}`
        : "新技能卡: 无新增";
    card.append(skillRow);

    const statText =
      levelUp.statChanges.length > 0
        ? `属性: ${levelUp.statChanges.map((change) => `${change.label} ${formatBattleSummaryDelta(change)}`).join(" / ")}`
        : "属性: 无变化";
    const statRow = document.createElement("div");
    statRow.className = "run-build-summary";
    statRow.textContent = statText;
    card.append(statRow);

    const featRow = document.createElement("div");
    featRow.className = "run-build-summary";
    featRow.textContent =
      levelUp.gainedFeats.length > 0
        ? `专长: ${levelUp.gainedFeats.map((feat) => feat.name).join(" / ")}`
        : "专长: 无新增";
    card.append(featRow);

    if (levelUp.gainedFeats.length > 0) {
      const descRow = document.createElement("div");
      descRow.className = "run-roster-meta";
      descRow.textContent = levelUp.gainedFeats
        .map((feat) => `${feat.name}${feat.description ? ` - ${feat.description}` : ""}`)
        .join(" / ");
      card.append(descRow);
    }

    levelList.append(card);
  }
  section.append(levelList);
  host.append(section);
}

function createEquipmentCard(equipment: EquipmentState): HTMLDivElement {
  const card = document.createElement("div");
  card.className = `run-equipment-card run-equipment-card--${equipment.rarity ?? "common"}`;

  const header = document.createElement("div");
  header.className = "run-equipment-card__header";

  const name = document.createElement("div");
  name.className = "run-equipment-card__name";
  name.textContent = equipment.name;
  header.append(name);

  if (equipment.slotLabel) {
    const slot = document.createElement("div");
    slot.className = "run-equipment-card__slot";
    slot.textContent = equipment.slotLabel;
    header.append(slot);
  }
  card.append(header);

  if (equipment.effectDescription && equipment.effectDescription !== "") {
    const effect = document.createElement("div");
    effect.className = "run-equipment-card__effect";
    effect.textContent = equipment.effectDescription;
    card.append(effect);
  }

  if (equipment.classScope && equipment.classScope !== "") {
    const scope = document.createElement("div");
    scope.className = "run-equipment-card__scope";
    scope.textContent = `适用: ${equipment.classScope}`;
    card.append(scope);
  }

  return card;
}

function getBestSkillCheckMod(snapshot: RunSnapshot, ability: string) {
  const key = (ability || "investigation").toLowerCase();
  const table: Record<string, keyof RunTeamMember> = {
    athletics: "str",
    acrobatics: "dex",
    stealth: "dex",
    investigation: "int",
    arcana: "int",
    religion: "wis",
    perception: "wis",
    deception: "cha",
    persuasion: "cha",
  };
  const stat = table[key] ?? "int";
  let best = -99;
  for (const hero of snapshot.team) {
    if (hero.isDead) continue;
    const score = Number(hero[stat] ?? 10);
    const mod = Math.floor((score - 10) / 2);
    if (mod > best) best = mod;
  }
  return best;
}

function renderEventStageModal(controls: RunControls, snapshot: RunSnapshot) {
  if (!snapshot.eventState) {
    return;
  }
  const { modal, body } = createStageModal(`事件 · ${snapshot.eventState.title}`, "在当前房间内处理");
  modal.classList.add("run-stage-modal--event");
  const renderState = getStageModalRenderState(snapshot);
  if (renderState) applyStageModalRenderState(modal, renderState);

  const lastCheck = snapshot.eventState.lastSkillCheck;
  if (lastCheck) {
    const outcome = document.createElement("div");
    outcome.className = "run-stage-modal__meta";
    outcome.textContent = `检定结果：${lastCheck.heroName ? `${lastCheck.heroName} · ` : ""}${lastCheck.ability ?? "?"} d20(${lastCheck.roll ?? "?"})+${lastCheck.modifier ?? "?"}=${lastCheck.total ?? "?"} vs DC${lastCheck.dc ?? "?"} → ${formatEventTierLabel(lastCheck.tier)}`;
    body.append(outcome);
  }

  if (snapshot.eventState.result) {
    const resultTitle = document.createElement("div");
    resultTitle.className = "run-stage-modal__result-title";
    resultTitle.textContent = snapshot.eventState.result.title || "事件结果";
    body.append(resultTitle);

    if (snapshot.eventState.result.optionLabel) {
      const option = document.createElement("div");
      option.className = "run-stage-modal__meta";
      option.textContent = `已选项：${snapshot.eventState.result.optionLabel}`;
      body.append(option);
    }

    const summary = document.createElement("div");
    summary.className = "run-stage-modal__summary";
    summary.textContent = snapshot.eventState.result.summary || "事件已结算";
    body.append(summary);

    for (const line of snapshot.eventState.result.details ?? []) {
      const detail = document.createElement("div");
      detail.className = "run-stage-modal__meta";
      detail.textContent = line;
      body.append(detail);
    }

    const actions = document.createElement("div");
    actions.className = "run-stage-modal__actions";
    const continueButton = makeButton(
      snapshot.eventState.result.actionLabel || "继续前进",
      false,
      controls.handlers.onContinueEvent,
    );
    continueButton.classList.add("run-stage-modal__button");
    actions.append(continueButton);
    body.append(actions);
  } else {
    const optionGrid = document.createElement("div");
    optionGrid.className = "run-stage-choice-grid run-stage-choice-grid--event";
    for (const option of snapshot.eventState.options) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = option.zeroRisk ? "run-event-choice" : "run-event-choice run-event-choice--risk";
      button.addEventListener("click", () => controls.handlers.onChooseEventOption(option.id));

      const header = document.createElement("div");
      header.className = "run-event-choice__header";
      const label = document.createElement("div");
      label.className = "run-event-choice__label";
      label.textContent = option.label;
      const risk = document.createElement("div");
      risk.className = "run-event-choice__tag";
      risk.textContent = option.zeroRisk ? "零风险" : "事件选择";
      header.append(label, risk);
      button.append(header);

      if (option.skillCheck) {
        const mod = getBestSkillCheckMod(snapshot, option.skillCheck.ability);
        const desc = document.createElement("div");
        desc.className = "run-event-choice__desc";
        desc.textContent = `检定 ${option.skillCheck.ability} DC${option.skillCheck.dc} · 队伍最佳修正约 +${mod >= 0 ? mod : mod}`;
        button.append(desc);
      }

      optionGrid.append(button);
    }
    body.append(optionGrid);
  }

  controls.mapOverlay.append(modal);
  controls.mapOverlay.classList.add("run-map-overlay--modal");
  controls.mapOverlay.classList.add("is-active");
}

function renderShopStageModal(controls: RunControls, snapshot: RunSnapshot) {
  if (!snapshot.shopState) {
    return;
  }

  const { modal, body } = createStageModal(`商店 · ${snapshot.shopState.name}`, `金币 ${snapshot.gold}`);
  modal.classList.add("run-stage-modal--shop");
  const renderState = getStageModalRenderState(snapshot);
  if (renderState) applyStageModalRenderState(modal, renderState);

  const goodsGrid = document.createElement("div");
  goodsGrid.className = "run-shop-goods";

  for (const goods of snapshot.shopState.goods) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = goods.sold ? "run-shop-good is-sold" : "run-shop-good";
    button.disabled = goods.sold || snapshot.gold < goods.price;
    button.addEventListener("click", () => controls.handlers.onShopBuy(goods.goodsId));

    const header = document.createElement("div");
    header.className = "run-shop-good__header";

    const name = document.createElement("div");
    name.className = "run-shop-good__name";
    name.textContent = goods.name;

    const price = document.createElement("div");
    price.className = "run-shop-good__price";
    price.textContent = goods.sold ? "已售" : `${goods.price}G`;

    header.append(name, price);
    button.append(header);

    if (goods.description) {
      const description = document.createElement("div");
      description.className = "run-shop-good__desc";
      description.textContent = goods.description;
      button.append(description);
    }

    const tags = document.createElement("div");
    tags.className = "run-shop-good__tags";
    const type = document.createElement("span");
    type.textContent = goods.goodsType;
    const rarity = document.createElement("span");
    rarity.textContent = goods.rarity;
    tags.append(type, rarity);
    button.append(tags);

    goodsGrid.append(button);
  }

  body.append(goodsGrid);

  const actions = document.createElement("div");
  actions.className = "run-stage-modal__actions run-shop-actions";

  if (snapshot.shopState.maxRefresh > 0) {
    const refresh = makeButton(
      `刷新 ${snapshot.shopState.refreshCost}G`,
      snapshot.shopState.refreshCount >= snapshot.shopState.maxRefresh || snapshot.gold < snapshot.shopState.refreshCost,
      controls.handlers.onShopRefresh,
    );
    refresh.classList.add("run-stage-modal__button");
    actions.append(refresh);
  }

  const leave = makeButton("离开商店", false, controls.handlers.onShopLeave);
  leave.classList.add("run-stage-modal__button");
  actions.append(leave);
  body.append(actions);

  controls.mapOverlay.append(modal);
  controls.mapOverlay.classList.add("run-map-overlay--modal");
  controls.mapOverlay.classList.add("is-active");
}

function renderRewardStageModal(controls: RunControls, snapshot: RunSnapshot) {
  if (!snapshot.rewardState) {
    return;
  }
  const title =
    snapshot.rewardState.kind === "feat_levelup"
      ? "队伍升级"
      : snapshot.rewardState.kind === "node_recruit"
        ? "选择职业卡"
        : snapshot.rewardState.kind === "chest"
          ? "战斗结算"
          : "选择奖励";
  const { modal, body } = createStageModal(title, "在战场结算当前选择");
  const renderState = getStageModalRenderState(snapshot);
  if (renderState) applyStageModalRenderState(modal, renderState);

  if (snapshot.rewardState.kind === "feat_levelup") {
    const featState = snapshot.rewardState;
    const pendingHint = featState.pendingLevels > 1 ? `剩余 ${featState.pendingLevels} 次升级` : "三选一";
    const subtitle = document.createElement("div");
    subtitle.className = "run-stage-modal__meta";
    subtitle.textContent = `请为队伍中一名英雄选择 1 张专长 · ${pendingHint}`;
    body.append(subtitle);

    const grid = document.createElement("div");
    grid.className = "reward-card-grid run-stage-choice-grid";
    const featOptions = featState.options as FeatOption[];
    featOptions.forEach((option, index) => {
      const tier = option.tier ?? "small";
      const tierLabel = tier === "high" ? "高阶" : tier === "medium" ? "中阶" : "小";
      const isSubclassCore = option.isSubclassCore === true;
      const heroName = option.heroName ?? "未知";
      const featName = option.featName ?? `Feat ${option.featId}`;
      const featDesc = option.featDescription ?? "";

      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = `reward-card${isSubclassCore ? " feat-card--subclass-core" : ""}`;
      btn.addEventListener("click", () => controls.handlers.onChooseReward(index + 1));

      const header = document.createElement("div");
      header.className = "reward-card__header";
      const hero = document.createElement("div");
      hero.className = "reward-card__hero";
      hero.textContent = `为 ${heroName} 选择 Lv${option.level} 天赋`;
      const lv = document.createElement("div");
      lv.className = "reward-card__level";
      lv.textContent = `${tierLabel}${isSubclassCore ? " · 子职核心" : ""}`;
      header.append(hero, lv);

      const feat = document.createElement("div");
      feat.className = "reward-card__feat";
      feat.textContent = `#${option.featId} ${featName}`;

      const desc = document.createElement("div");
      desc.className = "reward-card__desc";
      desc.textContent = featDesc;

      btn.append(header, feat, desc);
      grid.append(btn);
    });
    body.append(grid);
  } else if (snapshot.rewardState.kind === "chest") {
    const option = (snapshot.rewardState.options as RewardOption[])[0];
    if (option) {
      const rarityLabel =
        option.rarity === "boss" ? "传说" : option.rarity === "rare" ? "稀有" : "普通";
      const typeLabel =
        option.rewardType === "equipment"
          ? "装备"
          : option.rewardType === "blessing"
            ? "祝福"
            : option.rewardType === "gold"
              ? "金币"
              : "奖励";
      const reveal = document.createElement("div");
      reveal.className = `chest-reveal chest-reveal--${option.rewardType}`;

      const icon = document.createElement("div");
      icon.className = "chest-reveal__icon";
      icon.textContent = snapshot.rewardState.source === "elite_victory" ? "战" : "箱";

      const copy = document.createElement("div");
      copy.className = "chest-reveal__copy";
      const headline = document.createElement("div");
      headline.className = "chest-reveal__headline";
      headline.textContent = `获得 ${rarityLabel}${typeLabel}`;
      const desc = document.createElement("div");
      desc.className = "chest-reveal__desc";
      desc.textContent = option.description || option.label;
      copy.append(headline, desc);
      reveal.append(icon, copy);
      body.append(reveal);

      if (option.rewardType === "equipment") {
        const equipment =
          option.equipmentPreview ??
          ({
            equipmentId: option.refId ?? 0,
            name: option.label,
            rarity: option.rarity ?? "common",
            code: option.description,
            effectDescription: option.description,
          } satisfies EquipmentState);
        body.append(createEquipmentCard(equipment));
      }

      const actions = document.createElement("div");
      actions.className = "run-stage-modal__actions";
      const take = makeButton("收下奖励", false, () => controls.handlers.onChooseReward(1));
      take.classList.add("run-stage-modal__button");
      actions.append(take);
      body.append(actions);
    }
  } else {
    const grid = document.createElement("div");
    grid.className = "run-stage-choice-grid";
    const options = snapshot.rewardState.options as RewardOption[];
    options.forEach((option, index) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "reward-card";
      btn.addEventListener("click", () => controls.handlers.onChooseReward(index + 1));
      const name = document.createElement("div");
      name.className = "reward-card__feat";
      name.textContent = option.label;
      const desc = document.createElement("div");
      desc.className = "reward-card__desc";
      desc.textContent = option.description ?? "";
      btn.append(name, desc);
      grid.append(btn);
    });
    body.append(grid);
  }

  controls.mapOverlay.append(modal);
  controls.mapOverlay.classList.add("run-map-overlay--modal");
  controls.mapOverlay.classList.add("is-active");
}

function renderTeamPanel(host: HTMLDivElement, controls: RunControls, snapshot: RunSnapshot) {
  host.replaceChildren();

  const title = document.createElement("div");
  title.className = "panel-title";
  title.textContent = "当前队伍";
  host.append(title);

  const team = document.createElement("div");
  team.className = "run-team-summary";
  team.replaceChildren(
    ...snapshot.team.map((member) => {
      const item = document.createElement("div");
      item.className = "run-team-card";
      item.append(createRosterInfo(member));
      return item;
    }),
  );
  host.append(team);

  // 装备卡区块（与队伍信息同屏，便于快速核对当前 build 加成）
  if ((snapshot.equipments?.length ?? 0) > 0) {
    const equipmentSection = document.createElement("div");
    equipmentSection.className = "run-equipment-section";

    const equipmentTitle = document.createElement("div");
    equipmentTitle.className = "panel-title";
    equipmentTitle.textContent = `装备 (${snapshot.equipments.length})`;
    equipmentSection.append(equipmentTitle);

    const grid = document.createElement("div");
    grid.className = "run-equipment-grid";
    for (const equipment of snapshot.equipments) {
      grid.append(createEquipmentCard(equipment));
    }
    equipmentSection.append(grid);
    host.append(equipmentSection);
  }

  // 候补编成（仅非战斗/非结算阶段显示）
  if (snapshot.phase === "battle" || snapshot.phase === "failed" || snapshot.phase === "chapter_result") {
    controls.selectedBenchRosterId = null;
    return;
  }
  if ((snapshot.bench?.length ?? 0) === 0) {
    controls.selectedBenchRosterId = null;
    const hint = document.createElement("div");
    hint.className = "run-roster-meta";
    hint.textContent = "（暂无候补英雄）";
    host.append(hint);
    return;
  }

  const section = document.createElement("div");
  section.className = "run-roster-panel";

  const benchTitle = document.createElement("div");
  benchTitle.className = "panel-title";
  benchTitle.textContent = "候补编成";
  section.append(benchTitle);

  const benchHost = document.createElement("div");
  benchHost.className = "run-roster-grid";
  const selectedBench = snapshot.bench.find((member) => member.rosterId === controls.selectedBenchRosterId) ?? null;
  if (!selectedBench) {
    controls.selectedBenchRosterId = null;
  }

  for (const member of snapshot.bench) {
    const wrapper = document.createElement("div");
    wrapper.className = `run-roster-card${selectedBench?.rosterId === member.rosterId ? " active" : ""}`;

    const action = makeButton(
      selectedBench?.rosterId === member.rosterId ? "取消选择" : "选择候补",
      false,
      () => {
        controls.selectedBenchRosterId =
          controls.selectedBenchRosterId === member.rosterId ? null : member.rosterId ?? null;
        renderRunControls(controls, snapshot, []);
      },
    );

    wrapper.append(createRosterInfo(member), action);
    benchHost.append(wrapper);
  }
  section.append(benchHost);

  if (selectedBench?.rosterId != null) {
    const actionTitle = document.createElement("div");
    actionTitle.className = "panel-title";
    actionTitle.textContent = `上阵目标 · ${selectedBench.name}`;
    section.append(actionTitle);

    if (snapshot.team.length < snapshot.maxHeroCount) {
      section.append(
        makeButton("直接上阵", false, () => {
          controls.handlers.onPromoteBenchHero(selectedBench.rosterId!);
        }),
      );
    }

    const teamHost = document.createElement("div");
    teamHost.className = "run-roster-grid";
    for (const member of snapshot.team) {
      const wrapper = document.createElement("div");
      wrapper.className = "run-roster-card";

      const action = makeButton("替换上阵", false, () => {
        controls.handlers.onSwapBenchWithTeam(selectedBench.rosterId!, member.rosterId!);
      });

      wrapper.append(createRosterInfo(member), action);
      teamHost.append(wrapper);
    }
    section.append(teamHost);
  }

  host.append(section);
}

function renderInfoPanel(host: HTMLDivElement, controls: RunControls, snapshot: RunSnapshot) {
  host.replaceChildren();

  renderBattleSummary(host, snapshot);

  const generalSection = document.createElement("section");
  generalSection.className = "run-info-section run-general-info-section";

  const chapter = document.createElement("div");
  chapter.className = "panel-title";
  chapter.textContent = `普通信息 · 第一章 / 节点 ${snapshot.currentNodeId ?? "-"}`;
  generalSection.append(chapter);

  const stats = document.createElement("div");
  stats.className = "setup-grid run-compact-grid";
  stats.innerHTML = `
    <div class="setup-field run-compact-field"><span>队伍等级</span><strong>Lv.${snapshot.partyLevel}</strong></div>
    <div class="setup-field run-compact-field"><span>升级进度</span><strong>${snapshot.nextLevelExp > 0 ? `${snapshot.levelProgressExp}/${snapshot.nextLevelExp}` : "已满级"}</strong></div>
    <div class="setup-field run-compact-field"><span>金币</span><strong>${snapshot.gold}</strong></div>
    <div class="setup-field run-compact-field"><span>食物</span><strong>${snapshot.food}</strong></div>
    <div class="setup-field run-compact-field"><span>装备</span><strong>${snapshot.equipments.length}</strong></div>
    <div class="setup-field run-compact-field"><span>祝福</span><strong>${snapshot.blessings.length}</strong></div>
    <div class="setup-field run-compact-field"><span>Trinket</span><strong>${snapshot.trinkets?.length ?? 0}</strong></div>
  `;
  generalSection.append(stats);

  if ((snapshot.trinkets?.length ?? 0) > 0) {
    const trinketSection = document.createElement("div");
    trinketSection.className = "run-blessing-list";
    snapshot.trinkets?.forEach((trinket) => {
      const card = document.createElement("div");
      card.className = "run-blessing-card run-blessing-card--boss";
      card.textContent = `${trinket.name} · ${trinket.description ?? trinket.code}`;
      trinketSection.append(card);
    });
    generalSection.append(trinketSection);
  }

  if (snapshot.blessings.length > 0) {
    const blessingSection = document.createElement("div");
    blessingSection.className = "run-blessing-list";
    snapshot.blessings.forEach((blessing) => {
      const card = document.createElement("div");
      card.className = `run-blessing-card run-blessing-card--${blessing.rarity ?? "common"}`;

      const header = document.createElement("div");
      header.className = "run-blessing-card__header";

      const name = document.createElement("div");
      name.className = "run-blessing-card__name";
      name.textContent = blessing.name;

      const rarity = document.createElement("div");
      rarity.className = "run-blessing-card__rarity";
      rarity.textContent =
        blessing.rarity === "boss" ? "Boss" : blessing.rarity === "rare" ? "Rare" : "Common";

      const desc = document.createElement("div");
      desc.className = "run-blessing-card__desc";
      desc.textContent = blessing.description ?? blessing.code ?? "";

      header.append(name, rarity);
      card.append(header, desc);
      blessingSection.append(card);
    });
    generalSection.append(blessingSection);
  }

  host.append(generalSection);

  // 阶段性交互
  if (snapshot.phase === "event" && snapshot.eventState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = `事件 · ${snapshot.eventState.title}`;
    host.append(title);

    const lastCheck = snapshot.eventState.lastSkillCheck;
    if (lastCheck) {
      const outcome = document.createElement("div");
      outcome.className = "run-roster-meta";
      outcome.textContent = `检定结果：${lastCheck.heroName ? `${lastCheck.heroName} · ` : ""}${lastCheck.ability ?? "?"} d20(${lastCheck.roll ?? "?"})+${lastCheck.modifier ?? "?"}=${lastCheck.total ?? "?"} vs DC${lastCheck.dc ?? "?"} → ${formatEventTierLabel(lastCheck.tier)}`;
      host.append(outcome);
    }
    appendStageNotice(host);
    return;

    if (snapshot.eventState.result) {
      const resultSection = document.createElement("section");
      resultSection.className = "run-info-section";

      const resultTitle = document.createElement("div");
      resultTitle.className = "panel-title";
      resultTitle.textContent = snapshot.eventState.result.title || "事件结果";
      resultSection.append(resultTitle);

      if (snapshot.eventState.result.optionLabel) {
        const option = document.createElement("div");
        option.className = "run-roster-meta";
        option.textContent = `已选项：${snapshot.eventState.result.optionLabel}`;
        resultSection.append(option);
      }

      const summary = document.createElement("div");
      summary.className = "setup-field";
      summary.innerHTML = `
        <span>结果</span>
        <strong>${snapshot.eventState.result.summary || "事件已结算"}</strong>
      `;
      resultSection.append(summary);

      for (const line of snapshot.eventState.result.details ?? []) {
        const detail = document.createElement("div");
        detail.className = "run-roster-meta";
        detail.textContent = line;
        resultSection.append(detail);
      }

      resultSection.append(
        makeButton(
          snapshot.eventState.result.actionLabel || "继续前进",
          false,
          controls.handlers.onContinueEvent,
        ),
      );
      host.append(resultSection);
      return;
    }

    const modFor = (ability: string) => {
      const key = (ability || "investigation").toLowerCase();
      const table: Record<string, keyof RunTeamMember> = {
        athletics: "str",
        acrobatics: "dex",
        stealth: "dex",
        investigation: "int",
        arcana: "int",
        religion: "wis",
        perception: "wis",
        deception: "cha",
        persuasion: "cha",
      };
      const stat = table[key] ?? "int";
      let best = -99;
      for (const hero of snapshot.team) {
        if (hero.isDead) continue;
        const score = Number(hero[stat] ?? 10);
        const mod = Math.floor((score - 10) / 2);
        if (mod > best) best = mod;
      }
      return best;
    };

    for (const option of snapshot.eventState.options) {
      if (option.skillCheck) {
        const mod = modFor(option.skillCheck.ability);
        const hint = document.createElement("div");
        hint.className = "run-roster-meta";
        hint.textContent = `检定 ${option.skillCheck.ability} DC${option.skillCheck.dc} · 队伍最佳修正约 +${mod >= 0 ? mod : mod}`;
        host.append(hint);
      }
      const label = option.zeroRisk ? `${option.label}（零风险）` : option.label;
      host.append(
        makeButton(label, false, () => controls.handlers.onChooseEventOption(option.id)),
      );
    }
  } else if (snapshot.phase === "reward" && snapshot.rewardState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent =
      snapshot.rewardState.kind === "feat_levelup"
        ? "队伍升级"
        : snapshot.rewardState.kind === "node_recruit"
          ? "选择职业卡"
          : snapshot.rewardState.kind === "chest"
            ? "宝箱开启"
          : "选择奖励";
    host.append(title);
    appendStageNotice(host);
    return;
    if (snapshot.rewardState.kind === "feat_levelup") {
      const featState = snapshot.rewardState;
      const subtitle = document.createElement("div");
      subtitle.className = "run-roster-meta";
      const pendingHint =
        featState.pendingLevels > 1 ? `（剩余 ${featState.pendingLevels} 次升级）` : "";
      subtitle.textContent = `请为队伍中一名英雄选择 1 张专长${pendingHint}`;
      host.append(subtitle);

      const grid = document.createElement("div");
      grid.className = "reward-card-grid";
      const featOptions = featState.options as FeatOption[];
      featOptions.forEach((option, index) => {
        const tier = option.tier ?? "small";
        const tierLabel = tier === "high" ? "高阶" : tier === "medium" ? "中阶" : "小";
        const isSubclassCore = option.isSubclassCore === true;
        const heroName = option.heroName ?? "未知";
        const featName = option.featName ?? `Feat ${option.featId}`;
        const featDesc = option.featDescription ?? "";

        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = `reward-card${isSubclassCore ? " feat-card--subclass-core" : ""}`;
        btn.addEventListener("click", () => controls.handlers.onChooseReward(index + 1));

        const header = document.createElement("div");
        header.className = "reward-card__header";
        const hero = document.createElement("div");
        hero.className = "reward-card__hero";
        hero.textContent = `为 ${heroName} 选择 Lv${option.level} 天赋`;
        const lv = document.createElement("div");
        lv.className = "reward-card__level";
        lv.textContent = `${tierLabel}${isSubclassCore ? " · 子职核心" : ""}`;
        header.append(hero, lv);

        const feat = document.createElement("div");
        feat.className = "reward-card__feat";
        feat.textContent = `#${option.featId} ${featName}`;

        const desc = document.createElement("div");
        desc.className = "reward-card__desc";
        desc.textContent = featDesc;

        const tagRow = document.createElement("div");
        tagRow.className = "reward-card__tags";
        const tierBadge = document.createElement("span");
        tierBadge.className = `reward-tag reward-tag--tier-${tier}`;
        tierBadge.textContent = tierLabel;
        tagRow.append(tierBadge);
        if (isSubclassCore) {
          const coreBadge = document.createElement("span");
          coreBadge.className = "reward-tag reward-tag--subclass-core";
          coreBadge.textContent = "子职核心";
          tagRow.append(coreBadge);
        }

        btn.append(header, feat, desc, tagRow);
        grid.append(btn);
      });
      host.append(grid);
    } else if (snapshot.rewardState.kind === "chest") {
      const option = (snapshot.rewardState.options as RewardOption[])[0];
      const rewardSource = snapshot.rewardState.source ?? "chest";
      if (option) {
        const rarityLabel =
          option.rarity === "boss" ? "传说" : option.rarity === "rare" ? "稀有" : "普通";
        const typeLabel =
          option.rewardType === "equipment"
            ? "装备"
            : option.rewardType === "blessing"
              ? "祝福"
              : option.rewardType === "gold"
                ? "金币"
                : "奖励";

        const reveal = document.createElement("div");
        reveal.className = `chest-reveal chest-reveal--${option.rewardType}`;

        const icon = document.createElement("div");
        icon.className = "chest-reveal__icon";
        icon.textContent = rewardSource === "elite_victory" ? "战" : "箱";

        const copy = document.createElement("div");
        copy.className = "chest-reveal__copy";

        const headline = document.createElement("div");
        headline.className = "chest-reveal__headline";
        headline.textContent =
          rewardSource === "elite_victory"
            ? "精英战利品已就绪，确认收下装备。"
            : option.rewardType === "gold"
              ? "锁扣弹开，箱底滚出一把金币。"
              : option.rewardType === "blessing"
                ? "光芒从箱缝溢出，一道祝福浮现。"
                : "宝箱开启，一件战利品显露出来。";

        const desc = document.createElement("div");
        desc.className = "chest-reveal__desc";
        desc.textContent =
          rewardSource === "elite_victory"
            ? `本次掉落：${rarityLabel}${typeLabel}`
            : `本次开箱结果：${rarityLabel}${typeLabel}`;

        copy.append(headline, desc);
        reveal.append(icon, copy);
        host.append(reveal);

        if (option.rewardType === "equipment") {
          const equipment =
            option.equipmentPreview ??
            ({
              equipmentId: option.refId ?? 0,
              name: option.label,
              rarity: option.rarity ?? "common",
              code: option.description,
              effectDescription: option.description,
            } satisfies EquipmentState);
          host.append(createEquipmentCard(equipment));
        }

        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = `reward-card reward-card--chest reward-card--type-${option.rewardType} reward-card--rarity-${option.rarity ?? "common"}`;
        btn.addEventListener("click", () => controls.handlers.onChooseReward(1));

        const header = document.createElement("div");
        header.className = "reward-card__header";
        const name = document.createElement("div");
        name.className = "reward-card__feat";
        name.textContent = option.label;
        const rarity = document.createElement("div");
        rarity.className = "reward-card__level";
        rarity.textContent = `${rarityLabel}${typeLabel}`;
        header.append(name, rarity);

        const detail = document.createElement("div");
        detail.className = "reward-card__desc";
        detail.textContent =
          option.description || (option.rewardType === "gold" ? "收下金币后返回地图继续推进。" : "收下奖励后返回地图继续推进。");

        const tagRow = document.createElement("div");
        tagRow.className = "reward-card__tags";
        const typeBadge = document.createElement("span");
        typeBadge.className = "reward-tag";
        typeBadge.textContent = typeLabel;
        const rarityBadge = document.createElement("span");
        rarityBadge.className = `reward-tag reward-tag--tier-${option.rarity ?? "common"}`;
        rarityBadge.textContent = rarityLabel;
        tagRow.append(typeBadge, rarityBadge);

        const action = document.createElement("div");
        action.className = "chest-reveal__action";
        action.textContent = "点击收下奖励";

        btn.append(header, detail, tagRow, action);
        host.append(btn);
      }
    } else {
      const options = snapshot.rewardState.options as RewardOption[];
      options.forEach((option, index) => {
        host.append(
          makeButton(`${option.label}${option.description ? ` · ${option.description}` : ""}`, false, () =>
            controls.handlers.onChooseReward(index + 1),
          ),
        );
      });
    }
  } else if (snapshot.phase === "shop" && snapshot.shopState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = `商店 · ${snapshot.shopState.name}`;
    host.append(title);
    appendStageNotice(host, "请在战场商店弹窗中购买或离开。");
  } else if (snapshot.phase === "camp" && snapshot.campState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = `营地 · ${snapshot.campState.name}`;
    host.append(title);
    for (const action of snapshot.campState.actions) {
      host.append(
        makeButton(action.label, !action.available, () => controls.handlers.onCampChoose(action.id)),
      );
    }
  } else if (snapshot.phase === "chapter_result" || snapshot.phase === "failed") {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = snapshot.chapterResult?.success ? "章节通关" : "Run 失败";
    host.append(title);
    const details = document.createElement("div");
    details.className = "setup-field";
    details.innerHTML = `
      <span>结果</span>
      <strong>${snapshot.chapterResult?.reason ?? "-"}</strong>
      <span>金币 ${snapshot.chapterResult?.gold ?? snapshot.gold}</span>
    `;
    host.append(details, makeButton("重新开始第一章", false, controls.handlers.onRestart));
  } else if (snapshot.phase === "map") {
    const hint = document.createElement("div");
    hint.className = "run-roster-meta";
    const msg = snapshot.lastActionMessage || "";
    hint.textContent = snapshot.hiddenFloorInjected && !snapshot.hiddenFloorCleared
      ? "已发现隐藏层入口：在地图上前往「隐藏层入口」房间并下楼。"
      : msg.includes("营地安息")
      ? msg
      : snapshot.lastBattleSummary?.won
        ? "（结算已展示，在战场下方选择下一扇门继续推进）"
        : "（探索推进中，在战场下方选择一扇门）";
    host.append(hint);
  }
}

function renderMapPanel(host: HTMLDivElement, controls: RunControls, snapshot: RunSnapshot) {
  host.replaceChildren();
  const nextModalState = getStageModalRenderState(snapshot);
  const existingModal = controls.mapOverlay.querySelector<HTMLElement>(".run-stage-modal[data-stage-modal-key]");
  if (nextModalState && existingModal?.dataset.stageModalKey === nextModalState.key) {
    controls.mapOverlay.classList.add("is-active");
    controls.mapOverlay.classList.add("run-map-overlay--modal");
    return;
  }

  const previousModalType = existingModal?.dataset.stageModal ?? "";
  const previousBodyScrollTop =
    existingModal?.querySelector<HTMLElement>(".run-stage-modal__body")?.scrollTop ?? 0;

  controls.mapOverlay.replaceChildren();
  controls.mapOverlay.classList.remove("is-active");
  controls.mapOverlay.classList.remove("run-map-overlay--modal");

  if ((snapshot.phase === "map" || snapshot.phase === "stair") && snapshot.map) {
    const currentNode = snapshot.currentNodeId
      ? snapshot.map.nodes.find((item) => item.id === snapshot.currentNodeId) ?? null
      : null;
    const selectable = snapshot.map.nodes.filter((item) => item.selectable);
    const directionPad = document.createElement("div");
    directionPad.className = "run-direction-pad";

    const directionOf = (target: typeof selectable[number]) => {
      if (!currentNode || currentNode.gridX == null || currentNode.gridY == null
        || target.gridX == null || target.gridY == null) {
        return "";
      }
      const dx = target.gridX - currentNode.gridX;
      const dy = target.gridY - currentNode.gridY;
      if (dx === 0 && dy < 0) return "上";
      if (dx === 0 && dy > 0) return "下";
      if (dy === 0 && dx < 0) return "左";
      if (dy === 0 && dx > 0) return "右";
      return "";
    };

    const slotItems = new Map<string, Array<typeof selectable[number]>>();
    const ensureSlotItems = (slot: string) => {
      let list = slotItems.get(slot);
      if (!list) {
        list = [];
        slotItems.set(slot, list);
      }
      return list;
    };
    const appendPadCell = (slot: string, child?: HTMLElement) => {
      const cell = document.createElement("div");
      cell.className = `run-direction-cell run-direction-cell--${slot}`;
      cell.dataset.slot = slot;
      if (child) {
        cell.append(child);
      } else {
        cell.classList.add("run-direction-cell--empty");
      }
      directionPad.append(cell);
    };

    for (const node of selectable) {
      const dir = directionOf(node);
      const slotKey =
        dir === "上" ? "up" :
        dir === "下" ? "down" :
        dir === "左" ? "left" :
        dir === "右" ? "right" :
        "free";
      ensureSlotItems(slotKey).push(node);
    }

    const buttonLabelBySlot: Record<string, string> = {
      up: "进入",
      down: "返回",
      left: "左门",
      right: "右门",
    };

    const buildNodeButtons = (slot: string) => {
      const items = slotItems.get(slot) ?? [];
      return items.map((node) => {
        const label = buttonLabelBySlot[slot] ?? "移动";
        const button = makeButton(label, false, async () => {
          await controls.handlers.onChooseNode(node.id);
          await controls.handlers.onEnterNode();
        });
        button.classList.add("run-direction-button");
        return button;
      });
    };

    appendPadCell("up", buildNodeButtons("up")[0]);
    appendPadCell("left", buildNodeButtons("left")[0]);

    let centerButton: HTMLElement | undefined;
    if (snapshot.phase === "stair" && snapshot.stairState) {
      const dir = snapshot.stairState.direction;
      const dirLabel = snapshot.stairState.isHiddenEntrance
        ? "下楼"
        : dir === "up"
          ? "上楼"
          : "下楼";
      const stairButton = makeButton(dirLabel, false, () => controls.handlers.onStairUse());
      stairButton.classList.add("run-direction-button", "run-direction-button--stair");
      centerButton = stairButton;
    }
    appendPadCell("center", centerButton);

    appendPadCell("right", buildNodeButtons("right")[0]);
    appendPadCell("down", buildNodeButtons("down")[0]);
    controls.mapOverlay.append(directionPad);
    controls.mapOverlay.classList.add("is-active");
  } else if (snapshot.phase === "event" && snapshot.eventState) {
    renderEventStageModal(controls, snapshot);
  } else if (snapshot.phase === "shop" && snapshot.shopState) {
    renderShopStageModal(controls, snapshot);
  } else if (snapshot.phase === "reward" && snapshot.rewardState) {
    renderRewardStageModal(controls, snapshot);
  }

  if (nextModalState && previousModalType === nextModalState.type && previousBodyScrollTop > 0) {
    const nextBody = controls.mapOverlay.querySelector<HTMLElement>(".run-stage-modal__body");
    if (nextBody) {
      nextBody.scrollTop = previousBodyScrollTop;
    }
  }
}

export function renderBattleResultStageOverlay(controls: RunControls, onContinue: () => void | Promise<void>) {
  const existingModal = controls.mapOverlay.querySelector<HTMLElement>(
    ".run-stage-modal[data-stage-modal='battle-result']",
  );
  if (existingModal) {
    controls.mapOverlay.classList.add("run-map-overlay--modal");
    controls.mapOverlay.classList.add("is-active");
    return;
  }

  controls.mapOverlay.replaceChildren();
  const { modal, body } = createStageModal("战斗结算", "战斗已结束，继续处理奖励");
  modal.dataset.stageModal = "battle-result";
  const summary = document.createElement("div");
  summary.className = "run-stage-modal__summary";
  summary.textContent = "队伍保持在同一战场中，查看奖励后继续完成战利品 / 三选一选择。";
  body.append(summary);

  const actions = document.createElement("div");
  actions.className = "run-stage-modal__actions";
  const button = makeButton("查看奖励", false, onContinue);
  button.classList.add("run-stage-modal__button");
  actions.append(button);
  body.append(actions);

  controls.mapOverlay.append(modal);
  controls.mapOverlay.classList.add("run-map-overlay--modal");
  controls.mapOverlay.classList.add("is-active");
}

export function renderRunControls(controls: RunControls, snapshot: RunSnapshot | null, logs: string[]) {
  if (!snapshot) {
    controls.status.textContent = "run: loading | Run 加载中";
    controls.mapPanel.replaceChildren();
    controls.mapOverlay.replaceChildren();
    controls.mapOverlay.classList.remove("is-active");
    controls.teamPanel.replaceChildren();
    controls.infoPanel.replaceChildren();
    controls.logList.replaceChildren();
    return;
  }

  controls.autoRouteByPhase(snapshot.phase);

  // 顶部状态条简要显示
  if (snapshot.phase === "battle") {
    controls.status.textContent = `战斗中 · 节点 ${snapshot.currentNodeId ?? "-"}`;
  } else {
    const msg = snapshot.lastActionMessage ? ` | ${snapshot.lastActionMessage}` : "";
    controls.status.textContent = `阶段: ${snapshot.phase}${msg}`;
  }

  renderMapPanel(controls.mapPanel, controls, snapshot);
  renderTeamPanel(controls.teamPanel, controls, snapshot);
  renderInfoPanel(controls.infoPanel, controls, snapshot);

  controls.logList.replaceChildren(
    ...logs.map((entry) => {
      const item = document.createElement("li");
      item.textContent = entry;
      return item;
    }),
  );
}

export type { RunControls };
