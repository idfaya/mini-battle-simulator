import type { RunSnapshot } from "../types/roguelike";

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
    root.closest(".shell")?.setAttribute("data-screen", `run-${screen}`);
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
    } else if (phase === "map") {
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
      item.textContent = `${member.name} ${member.isDead ? "· 阵亡" : `· HP ${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`}`;
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

    const info = document.createElement("div");
    info.className = "run-roster-meta";
    info.textContent = `${member.name} · HP ${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`;

    const action = makeButton(
      selectedBench?.rosterId === member.rosterId ? "取消选择" : "选择候补",
      false,
      () => {
        controls.selectedBenchRosterId =
          controls.selectedBenchRosterId === member.rosterId ? null : member.rosterId ?? null;
        renderRunControls(controls, snapshot, []);
      },
    );

    wrapper.append(info, action);
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

      const info = document.createElement("div");
      info.className = "run-roster-meta";
      info.textContent = `${member.name}${member.isDead ? " · 阵亡" : ` · HP ${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`}`;

      const action = makeButton("替换上阵", false, () => {
        controls.handlers.onSwapBenchWithTeam(selectedBench.rosterId!, member.rosterId!);
      });

      wrapper.append(info, action);
      teamHost.append(wrapper);
    }
    section.append(teamHost);
  }

  host.append(section);
}

function renderInfoPanel(host: HTMLDivElement, controls: RunControls, snapshot: RunSnapshot) {
  host.replaceChildren();

  // 资源概览
  const chapter = document.createElement("div");
  chapter.className = "panel-title";
  chapter.textContent = `第一章 · 节点 ${snapshot.currentNodeId ?? "-"}`;
  host.append(chapter);

  const stats = document.createElement("div");
  stats.className = "setup-grid";
  stats.innerHTML = `
    <div class="setup-field"><span>队伍等级</span><strong>Lv.${snapshot.partyLevel}</strong></div>
    <div class="setup-field"><span>升级进度</span><strong>${snapshot.nextLevelExp > 0 ? `${snapshot.levelProgressExp}/${snapshot.nextLevelExp}` : "已满级"}</strong></div>
    <div class="setup-field"><span>金币</span><strong>${snapshot.gold}</strong></div>
    <div class="setup-field"><span>食物</span><strong>${snapshot.food}</strong></div>
    <div class="setup-field"><span>遗物</span><strong>${snapshot.relics.length}</strong></div>
    <div class="setup-field"><span>祝福</span><strong>${snapshot.blessings.length}</strong></div>
  `;
  host.append(stats);

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
    title.textContent = "选择奖励";
    host.append(title);
    snapshot.rewardState.options.forEach((option, index) => {
      host.append(
        makeButton(`${option.label}${option.description ? ` · ${option.description}` : ""}`, false, () =>
          controls.handlers.onChooseReward(index + 1),
        ),
      );
    });
  } else if (snapshot.phase === "shop" && snapshot.shopState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = `商店 · ${snapshot.shopState.name}`;
    host.append(title);
    for (const goods of snapshot.shopState.goods) {
      host.append(
        makeButton(
          `${goods.goodsType} · ${goods.refId ?? goods.code ?? goods.goodsId} · ${goods.price}`,
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
    hint.textContent = "（地图推进中，请切到「地图」页选择下一个节点）";
    host.append(hint);
  }
}

function renderMapPanel(host: HTMLDivElement, controls: RunControls, snapshot: RunSnapshot) {
  host.replaceChildren();

  if (snapshot.phase === "map" && snapshot.map) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = "选择下一个节点";
    host.append(title);

    const selectable = snapshot.map.nodes.filter((item) => item.selectable);
    for (const node of selectable) {
      host.append(
        makeButton(`${node.title} · ${node.nodeType}`, false, async () => {
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
