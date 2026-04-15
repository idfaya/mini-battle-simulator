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

    const leftLayouts = this.layoutTeam(state.snapshot.leftTeam, width, "left");
    const rightLayouts = this.layoutTeam(state.snapshot.rightTeam, width, "right");
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

  private layoutTeam(team: UnitState[], width: number, side: "left" | "right"): UnitLayout[] {
    const desiredCardWidth = 240;
    const cardHeight = 110;
    const laneYs = [120, 260, 400];
    const margin = 20;
    const desiredDepthGap = 40; // gap between back row card and front row card
    const desiredCenterGap = 40; // gap between left-front and right-front columns

    // Layout is 4 columns: leftBack, leftFront, rightFront, rightBack.
    // When screen is narrow, scale card width and gaps down to avoid overlap.
    const minCardWidth = 160;
    const minDepthGap = 16;
    const minCenterGap = 20;

    const available = Math.max(0, width - margin * 2);
    const desiredTotal =
      4 * desiredCardWidth + 2 * desiredDepthGap + desiredCenterGap + 0; // margins are excluded already
    const scale = desiredTotal > 0 ? Math.min(1, available / desiredTotal) : 1;

    const cardWidth = Math.max(minCardWidth, Math.floor(desiredCardWidth * scale));
    const depthGap = Math.max(minDepthGap, Math.floor(desiredDepthGap * scale));
    const centerGap = Math.max(minCenterGap, Math.floor(desiredCenterGap * scale));

    // Compute the 4 columns deterministically, symmetric from both sides.
    const leftBackX = margin;
    const leftFrontX = leftBackX + cardWidth + depthGap;
    const rightFrontX = Math.max(leftFrontX + cardWidth + centerGap, width - margin - (2 * cardWidth + depthGap));
    const rightBackX = rightFrontX + cardWidth + depthGap;

    // If screen is extremely narrow, rightBackX might exceed canvas; push the right side left as a group.
    const overflow = Math.max(0, rightBackX + cardWidth + margin - width);
    const adjustedRightFrontX = rightFrontX - overflow;
    const adjustedRightBackX = rightBackX - overflow;

    const fallbackLayout = (index: number) => ({
      x: side === "left" ? leftBackX : adjustedRightBackX,
      y: laneYs[Math.min(index, laneYs.length - 1)],
    });

    return team.map((unit, index) => {
      const position = Number.isFinite(unit.position) ? Math.floor(unit.position) : 0;
      const laneIndex = position >= 1 && position <= 6 ? (position - 1) % 3 : Math.min(index, laneYs.length - 1);
      const isFrontRow = position >= 1 && position <= 3;
      const isBackRow = position >= 4 && position <= 6;
      let x = fallbackLayout(index).x;
      if (isFrontRow) {
        x = side === "left" ? leftFrontX : adjustedRightFrontX;
      } else if (isBackRow) {
        x = side === "left" ? leftBackX : adjustedRightBackX;
      }

      return {
        x,
        y: laneYs[laneIndex],
        width: cardWidth,
        height: cardHeight,
        unit,
      };
    });
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
