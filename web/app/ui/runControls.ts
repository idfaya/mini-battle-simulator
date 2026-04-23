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

type RunControls = {
  root: HTMLDivElement;
  status: HTMLDivElement;
  summary: HTMLDivElement;
  panel: HTMLDivElement;
  logList: HTMLUListElement;
  handlers: RunHandlers;
  selectedBenchRosterId: number | null;
};

export function createRunControls(handlers: RunHandlers): RunControls {
  const root = document.createElement("div");
  root.className = "hud";

  const status = document.createElement("div");
  status.className = "hud-status";

  const summary = document.createElement("div");
  summary.className = "setup-panel";

  const panel = document.createElement("div");
  panel.className = "ult-panel";

  const logList = document.createElement("ul");
  logList.className = "battle-log";

  root.append(status, summary, panel, logList);

  return { root, status, summary, panel, logList, handlers, selectedBenchRosterId: null };
}

function makeButton(label: string, disabled: boolean, onClick: () => void) {
  const button = document.createElement("button");
  button.className = "ult-button";
  button.type = "button";
  button.disabled = disabled;
  button.textContent = label;
  button.onclick = onClick;
  return button;
}

function renderSummary(host: HTMLDivElement, snapshot: RunSnapshot) {
  const chapter = document.createElement("div");
  chapter.className = "panel-title";
  chapter.textContent = `第一章 · 节点 ${snapshot.currentNodeId ?? "-"}`;

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

  const team = document.createElement("div");
  team.className = "run-team-summary";
  team.replaceChildren(
    ...snapshot.team.map((member) => {
      const item = document.createElement("div");
      item.className = "run-team-card";
      item.textContent = `${member.name} ${member.isDead ? "· 阵亡" : `· ${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`}`;
      return item;
    }),
  );

  host.replaceChildren(chapter, stats, team);
}

function renderRosterSection(controls: RunControls, snapshot: RunSnapshot, logs: string[]) {
  if (snapshot.phase === "battle" || snapshot.phase === "failed" || snapshot.phase === "chapter_result") {
    return;
  }
  if ((snapshot.bench?.length ?? 0) === 0) {
    controls.selectedBenchRosterId = null;
    return;
  }

  const section = document.createElement("div");
  section.className = "run-roster-panel";

  const title = document.createElement("div");
  title.className = "panel-title";
  title.textContent = "候补编成";
  section.append(title);

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
    info.textContent = `${member.name} · ${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`;

    const action = makeButton(
      selectedBench?.rosterId === member.rosterId ? "取消选择" : "选择候补",
      false,
      () => {
        controls.selectedBenchRosterId =
          controls.selectedBenchRosterId === member.rosterId ? null : member.rosterId ?? null;
        renderRunControls(controls, snapshot, logs);
      },
    );

    wrapper.append(info, action)
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
      info.textContent = `${member.name}${member.isDead ? " · 阵亡" : ` · ${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`}`;

      const action = makeButton("替换上阵", false, () => {
        controls.handlers.onSwapBenchWithTeam(selectedBench.rosterId!, member.rosterId!);
      });

      wrapper.append(info, action);
      teamHost.append(wrapper);
    }
    section.append(teamHost);
  }

  controls.panel.append(section);
}

export function renderRunControls(controls: RunControls, snapshot: RunSnapshot | null, logs: string[]) {
  if (!snapshot) {
    controls.status.textContent = "run: loading | Run 加载中";
  } else if (snapshot.phase === "battle") {
    const bs = snapshot.battleSnapshot;
    const allUnits = [...(bs?.leftTeam ?? []), ...(bs?.rightTeam ?? [])];
    const active =
      bs?.activeHeroId != null ? allUnits.find((unit) => unit.id === bs.activeHeroId) : null;
    const focus =
      active ??
      (bs?.leftTeam ?? []).find((unit) => unit.isAlive) ??
      (bs?.rightTeam ?? []).find((unit) => unit.isAlive) ??
      null;
    const lines: string[] = [];
    lines.push(`battle: ${bs?.phase ?? "running"} | 战斗状态: ${bs?.phase ?? "running"}`);
    if (focus) {
      const stateBits: string[] = [];
      if (focus.isChanting) {
        stateBits.push(`吟唱:${focus.pendingSkillName ?? "未知技能"}`);
      }
      if (focus.isConcentrating) {
        stateBits.push(`专注:${focus.concentrationSkillName ?? focus.concentrationSkillId ?? "未知技能"}`);
      }
      lines.push(
        `${active ? "当前行动" : "当前角色"}: ${focus.name} | HP ${focus.hp}/${focus.maxHp} | 速度 ${focus.speed ?? 0} | AC ${focus.ac ?? 0} | 命中 ${focus.hit ?? 0} | 法术命中 ${focus.spellDC ?? 0} | 豁免 F/R/W ${focus.saveFort ?? 0}/${focus.saveRef ?? 0}/${focus.saveWill ?? 0}${stateBits.length > 0 ? ` | 状态 ${stateBits.join(" / ")}` : ""}`,
      );
    }
    controls.status.textContent = lines.join("\n");
  } else {
    controls.status.textContent = `run: ${snapshot.phase}${snapshot.lastActionMessage ? ` | ${snapshot.lastActionMessage}` : ""}`;
  }

  controls.panel.replaceChildren();
  if (!snapshot) {
    return;
  }

  renderSummary(controls.summary, snapshot);

  if (snapshot.phase === "map" && snapshot.map) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = "地图推进";
    controls.panel.append(title);

    for (const node of snapshot.map.nodes.filter((item) => item.selectable)) {
      controls.panel.append(
        makeButton(`${node.title} · ${node.nodeType}`, false, async () => {
          controls.handlers.onChooseNode(node.id);
        }),
      );
    }
    controls.panel.append(
      makeButton("进入当前选择节点", snapshot.debug.availableNextNodeIds.length === 0, controls.handlers.onEnterNode),
    );
  } else if (snapshot.phase === "event" && snapshot.eventState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = snapshot.eventState.title;
    controls.panel.append(title);
    for (const option of snapshot.eventState.options) {
      controls.panel.append(
        makeButton(option.label, false, () => controls.handlers.onChooseEventOption(option.id)),
      );
    }
  } else if (snapshot.phase === "reward" && snapshot.rewardState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = "选择奖励";
    controls.panel.append(title);
    snapshot.rewardState.options.forEach((option, index) => {
      controls.panel.append(
        makeButton(`${option.label}${option.description ? ` · ${option.description}` : ""}`, false, () =>
          controls.handlers.onChooseReward(index + 1),
        ),
      );
    });
  } else if (snapshot.phase === "shop" && snapshot.shopState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = snapshot.shopState.name;
    controls.panel.append(title);
    for (const goods of snapshot.shopState.goods) {
      controls.panel.append(
        makeButton(
          `${goods.goodsType} · ${goods.refId ?? goods.code ?? goods.goodsId} · ${goods.price}`,
          goods.sold,
          () => controls.handlers.onShopBuy(goods.goodsId),
        ),
      );
    }
    controls.panel.append(makeButton(`刷新商店 - ${snapshot.shopState.refreshCost}`, false, controls.handlers.onShopRefresh));
    controls.panel.append(makeButton("离开商店", false, controls.handlers.onShopLeave));
  } else if (snapshot.phase === "camp" && snapshot.campState) {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = snapshot.campState.name;
    controls.panel.append(title);
    for (const action of snapshot.campState.actions) {
      controls.panel.append(
        makeButton(action.label, !action.available, () => controls.handlers.onCampChoose(action.id)),
      );
    }
  } else if (snapshot.phase === "chapter_result" || snapshot.phase === "failed") {
    const title = document.createElement("div");
    title.className = "panel-title";
    title.textContent = snapshot.chapterResult?.success ? "章节通关" : "Run 失败";
    const details = document.createElement("div");
    details.className = "setup-field";
    details.innerHTML = `
      <span>结果</span>
      <strong>${snapshot.chapterResult?.reason ?? "-"}</strong>
      <span>金币 ${snapshot.chapterResult?.gold ?? snapshot.gold}</span>
    `;
    controls.panel.append(title, details, makeButton("重新开始第一章", false, controls.handlers.onRestart));
  }

  renderRosterSection(controls, snapshot, logs);

  controls.logList.replaceChildren(
    ...logs.map((entry) => {
      const item = document.createElement("li");
      item.textContent = entry;
      return item;
    }),
  );
}

export type { RunControls };
