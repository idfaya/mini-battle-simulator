import type { FeatOption, RewardOption, RunSnapshot } from "../types/roguelike";

type RunHandlers = {
  onChooseNode: (nodeId: number) => void;
  onEnterNode: () => void;
  onChooseEventOption: (optionId: number) => void;
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
    // phase 切换意味着新的操作场景，统一把玩家引导到 info（营地/商店/事件/奖励）或 map
    if (phase === "event" || phase === "reward" || phase === "shop" || phase === "camp") {
      setScreen("info");
    } else if (phase === "map" || phase === "stair") {
      setScreen("map");
    } else if (phase === "chapter_result" || phase === "failed") {
      setScreen("info");
    }
  };

  root.append(screenTabs, status, mapPanel, teamPanel, infoPanel, logList);
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

function createRosterInfo(member: RunSnapshot["team"][number]) {
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
  `;
  generalSection.append(stats);

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
    for (const option of snapshot.eventState.options) {
      host.append(
        makeButton(option.label, false, () => controls.handlers.onChooseEventOption(option.id)),
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
          : "选择奖励";
    host.append(title);
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
    for (const goods of snapshot.shopState.goods) {
      host.append(
        makeButton(
          `${goods.name}${goods.description ? ` · ${goods.description}` : ""} · ${goods.price}`,
          goods.sold,
          () => controls.handlers.onShopBuy(goods.goodsId),
        ),
      );
    }
    host.append(makeButton(`刷新商店 - ${snapshot.shopState.refreshCost}`, false, controls.handlers.onShopRefresh));
    host.append(makeButton("离开商店", false, controls.handlers.onShopLeave));
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
    hint.textContent = snapshot.lastBattleSummary?.won
      ? "（结算已展示，切到「地图」页选择下一个节点）"
      : "（地图推进中，请切到「地图」页选择下一个节点）";
    host.append(hint);
  }
}

function renderMapPanel(host: HTMLDivElement, controls: RunControls, snapshot: RunSnapshot) {
  host.replaceChildren();

  if ((snapshot.phase === "map" || snapshot.phase === "stair") && snapshot.map) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = snapshot.phase === "stair" ? "楼梯房：选择行动" : "选择下一个节点";
    host.append(title);

    // 楼梯房：把上/下楼按钮直接作为「方位」选项与房间选择按钮并列。
    if (snapshot.phase === "stair" && snapshot.stairState) {
      const dir = snapshot.stairState.direction;
      const dirLabel = dir === "up" ? "上楼" : "下楼";
      host.append(
        makeButton(`${dirLabel} · 进入下一层`, false, () => controls.handlers.onStairUse()),
      );
    }

    const currentNode = snapshot.currentNodeId
      ? snapshot.map.nodes.find((item) => item.id === snapshot.currentNodeId) ?? null
      : null;
    const selectable = snapshot.map.nodes.filter((item) => item.selectable);

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

    // 同方向去重：跨层楼梯等极端情况下若多个邻居在同一方位，加序号区分。
    const usedDirs = new Map<string, number>();
    for (const node of selectable) {
      const dir = directionOf(node);
      let dirLabel = dir;
      if (dir) {
        const count = (usedDirs.get(dir) ?? 0) + 1;
        usedDirs.set(dir, count);
        dirLabel = count > 1 ? `${dir}${count}` : dir;
      }
      // 未踏足的房间不暴露类型/标题；已访问过的（迂回回头路）才显示原标题。
      const knownTitle = node.revealed && node.titleVisible && node.title ? node.title : "未知房间";
      const label = dirLabel ? `${dirLabel} · ${knownTitle}` : knownTitle;
      host.append(
        makeButton(label, false, async () => {
          // 选择即进入，避免手机端多一步操作
          await controls.handlers.onChooseNode(node.id);
          await controls.handlers.onEnterNode();
        }),
      );
    }
  } else {
    // 非 map 阶段：显示当前所在场景提示，提示切回「信息」页
    const title = document.createElement("div");
    title.className = "panel-title";
    const phaseLabel =
      snapshot.phase === "event"
        ? "事件进行中"
        : snapshot.phase === "reward"
          ? "选择奖励中"
          : snapshot.phase === "shop"
            ? "商店中"
            : snapshot.phase === "camp"
              ? "营地中"
              : snapshot.phase === "battle"
                ? "战斗中"
                : snapshot.phase === "chapter_result"
                  ? "章节结算"
                  : snapshot.phase === "failed"
                    ? "Run 已失败"
                    : snapshot.phase;
    title.textContent = `当前场景：${phaseLabel}`;
    host.append(title);
    const hint = document.createElement("div");
    hint.className = "run-roster-meta";
    hint.textContent = "请切到「信息」页处理当前场景";
    host.append(hint);
  }
}

export function renderRunControls(controls: RunControls, snapshot: RunSnapshot | null, logs: string[]) {
  if (!snapshot) {
    controls.status.textContent = "run: loading | Run 加载中";
    controls.mapPanel.replaceChildren();
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
