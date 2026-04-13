import type { BattleSnapshot } from "../types/battle";

type Controls = {
  root: HTMLDivElement;
  logList: HTMLUListElement;
  status: HTMLDivElement;
  buttonsHost: HTMLDivElement;
};

export function createControls(
  onUltCast: (heroId: string) => void,
  onRestart: () => void,
  onSpeedChange: (speed: number) => void,
): Controls {
  const root = document.createElement("div");
  root.className = "hud";

  const status = document.createElement("div");
  status.className = "hud-status";

  const buttonsHost = document.createElement("div");
  buttonsHost.className = "ult-panel";

  const logList = document.createElement("ul");
  logList.className = "battle-log";

  const actions = document.createElement("div");
  actions.className = "global-actions";

  const restartButton = document.createElement("button");
  restartButton.textContent = "重新开战";
  restartButton.onclick = onRestart;

  const speedButton = document.createElement("button");
  let speed = 1;
  speedButton.textContent = "倍速 x1";
  speedButton.onclick = () => {
    speed = speed >= 3 ? 1 : speed + 1;
    speedButton.textContent = `倍速 x${speed}`;
    onSpeedChange(speed);
  };

  actions.append(restartButton, speedButton);
  root.append(status, buttonsHost, actions, logList);

  return { root, logList, status, buttonsHost };
}

export function renderControls(
  controls: Controls,
  snapshot: BattleSnapshot | null,
  logEntries: string[],
  onUltCast: (heroId: string) => void,
) {
  controls.status.textContent = snapshot?.result
    ? `胜负: ${snapshot.result.winner} · ${snapshot.result.reason}`
    : `战斗状态: ${snapshot ? snapshot.phase : "loading"}`;

  controls.buttonsHost.replaceChildren();
  for (const unit of snapshot?.leftTeam ?? []) {
    const button = document.createElement("button");
    button.className = "ult-button";
    button.disabled = !unit.ultimateReady || !unit.isAlive;
    button.textContent = `${unit.name} · ${unit.ultimateSkillName}`;
    if (unit.ultimateReady) {
      button.classList.add("ready");
    }
    button.onclick = () => onUltCast(unit.id);
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
