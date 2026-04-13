import { createFloatingText, drawFloatingText, type FloatingText } from "./animations";
import type { BattleStoreState } from "../state/battleStore";
import type { AnimationEvent, UnitState } from "../types/battle";

type UnitLayout = { x: number; y: number; width: number; height: number; unit: UnitState };

export class BattleScene {
  private floatingTexts: Array<FloatingText & { unitId: string }> = [];

  draw(ctx: CanvasRenderingContext2D, width: number, height: number, state: BattleStoreState, now: number) {
    ctx.clearRect(0, 0, width, height);
    this.drawBackground(ctx, width, height);

    if (!state.snapshot) {
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "24px sans-serif";
      ctx.fillText("加载战斗中...", width / 2 - 64, height / 2);
      return;
    }

    const leftLayouts = this.layoutTeam(state.snapshot.leftTeam, 80, 120, "left");
    const rightLayouts = this.layoutTeam(state.snapshot.rightTeam, width - 320, 120, "right");
    const allLayouts = [...leftLayouts, ...rightLayouts];

    this.consumeAnimations(state.animations, allLayouts, now);

    for (const layout of allLayouts) {
      this.drawUnitCard(ctx, layout, state.snapshot.activeHeroId === layout.unit.id);
    }

    this.drawTopBar(ctx, width, state);
    this.drawBottomHint(ctx, width, height, state);
    this.drawFloatingTexts(ctx, allLayouts, now);
  }

  private drawBackground(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const gradient = ctx.createLinearGradient(0, 0, 0, height);
    gradient.addColorStop(0, "#12263a");
    gradient.addColorStop(1, "#0b1320");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
  }

  private layoutTeam(team: UnitState[], startX: number, startY: number, side: "left" | "right"): UnitLayout[] {
    return team.map((unit, index) => ({
      x: startX + (side === "left" ? 0 : 40),
      y: startY + index * 140,
      width: 240,
      height: 110,
      unit,
    }));
  }

  private drawUnitCard(ctx: CanvasRenderingContext2D, layout: UnitLayout, isActive: boolean) {
    const { x, y, width, height, unit } = layout;

    ctx.save();
    ctx.fillStyle = unit.team === "left" ? "#173f5f" : "#5f0f40";
    ctx.strokeStyle = isActive ? "#ffd166" : unit.ultimateReady ? "#80ed99" : "rgba(255,255,255,0.2)";
    ctx.lineWidth = isActive ? 4 : 2;
    ctx.fillRect(x, y, width, height);
    ctx.strokeRect(x, y, width, height);

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "bold 18px sans-serif";
    ctx.fillText(unit.name, x + 16, y + 26);

    if (unit.ultimateReady) {
      ctx.fillStyle = "#80ed99";
      ctx.font = "bold 12px sans-serif";
      ctx.fillText("ULT READY", x + width - 86, y + 22);
    }

    this.drawBar(ctx, x + 16, y + 44, width - 32, 12, unit.maxHp > 0 ? unit.hp / unit.maxHp : 0, "#ef476f", "#4a4a4a");
    this.drawBar(ctx, x + 16, y + 66, width - 32, 10, unit.maxEnergy > 0 ? unit.energy / unit.maxEnergy : 0, "#4cc9f0", "#2a2a2a");

    ctx.fillStyle = "#d9e2ec";
    ctx.font = "12px sans-serif";
    ctx.fillText(`HP ${Math.max(0, Math.floor(unit.hp))}/${Math.floor(unit.maxHp)}`, x + 16, y + 98);
    ctx.fillText(`EN ${Math.floor(unit.energy)}/${Math.floor(unit.maxEnergy)}`, x + width - 92, y + 98);

    if (!unit.isAlive) {
      ctx.fillStyle = "rgba(0,0,0,0.48)";
      ctx.fillRect(x, y, width, height);
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "bold 20px sans-serif";
      ctx.fillText("DEFEATED", x + 68, y + 62);
    }

    ctx.restore();
  }

  private drawBar(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
    rate: number,
    fill: string,
    background: string,
  ) {
    ctx.fillStyle = background;
    ctx.fillRect(x, y, width, height);
    ctx.fillStyle = fill;
    ctx.fillRect(x, y, width * Math.max(0, Math.min(1, rate)), height);
  }

  private drawTopBar(ctx: CanvasRenderingContext2D, width: number, state: BattleStoreState) {
    if (!state.snapshot) {
      return;
    }

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "bold 24px sans-serif";
    ctx.fillText(`Round ${state.snapshot.round}`, 48, 52);
    ctx.font = "14px sans-serif";
    ctx.fillText(state.banner ?? "AFK 战斗进行中", width / 2 - 70, 50);
  }

  private drawBottomHint(ctx: CanvasRenderingContext2D, width: number, height: number, state: BattleStoreState) {
    const snapshot = state.snapshot;
    if (!snapshot) {
      return;
    }

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "14px sans-serif";
    const ready = snapshot.leftTeam.filter((unit) => unit.ultimateReady);
    const hint = ready.length > 0
      ? `可点击右侧大招栏立刻释放: ${ready.map((unit) => unit.name).join(" / ")}`
      : "战斗自动进行中，等待大招蓄满";
    ctx.fillText(hint, 48, height - 28);
    ctx.fillText(`Pending Commands: ${snapshot.pendingCommands}`, width - 190, height - 28);
  }

  private consumeAnimations(events: AnimationEvent[], layouts: UnitLayout[], now: number) {
    for (const event of events) {
      if (event.type !== "damage" && event.type !== "heal") {
        continue;
      }
      const layout = layouts.find((item) => item.unit.id === event.heroId);
      const text = createFloatingText(event, layout?.unit, now);
      if (!text || !layout) {
        continue;
      }
      this.floatingTexts.push({
        ...text,
        unitId: layout.unit.id,
      });
    }
  }

  private drawFloatingTexts(ctx: CanvasRenderingContext2D, layouts: UnitLayout[], now: number) {
    this.floatingTexts = this.floatingTexts.filter((item) => {
      const layout = layouts.find((candidate) => candidate.unit.id === item.unitId);
      if (!layout) {
        return false;
      }
      return drawFloatingText(ctx, item, layout.x + layout.width / 2, layout.y + 28, now);
    });
  }
}
