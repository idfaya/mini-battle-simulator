import { createFloatingText, drawFloatingText, type FloatingText } from "./animations";
import type { BattleStoreState } from "../state/battleStore";
import type { AnimationEvent, UnitState } from "../types/battle";

type UnitLayout = { x: number; y: number; width: number; height: number; unit: UnitState };
const TOP_BAR_TEXT_Y = 52;
const TIMELINE_PANEL_Y = 72;
const TIMELINE_PANEL_HEIGHT = 104;
const BATTLEFIELD_TOP_SAFE_Y = TIMELINE_PANEL_Y + TIMELINE_PANEL_HEIGHT + 24;
const LANE_GAP_Y = 140;

type ClassBadge = {
  fill: string;
  stroke: string;
};

type TimelineOverlay = {
  heroId: string;
  heroName: string;
  skillName: string;
  // totalFrames here means "keyframe count" (#frame defs), not 30fps timeline frames.
  totalFrames: number;
  frameIndex: number;
  frame: number;
  op: string;
  effect: string;
  targetIds: string[];
  startedAt: number;
  completedAt: number | null;
  totalDamage: number;
  succeeded: boolean | null;
};

export class BattleScene {
  private floatingTexts: Array<FloatingText & { unitId: string }> = [];
  private activeTimeline: TimelineOverlay | null = null;

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
    this.drawTimelineOverlay(ctx, width, now, state);
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
    const laneYs = [
      BATTLEFIELD_TOP_SAFE_Y,
      BATTLEFIELD_TOP_SAFE_Y + LANE_GAP_Y,
      BATTLEFIELD_TOP_SAFE_Y + LANE_GAP_Y * 2,
    ];
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
    const isCastingHero = this.activeTimeline?.heroId === unit.id;
    const isTimelineTarget = this.activeTimeline?.targetIds.includes(unit.id) ?? false;
    const classBadge = this.getClassBadge(unit.classId);

    ctx.save();
    ctx.fillStyle = unit.team === "left" ? "#173f5f" : "#5f0f40";
    ctx.strokeStyle = isActive
      ? "#ffd166"
      : isCastingHero
        ? "#ffd166"
        : isTimelineTarget
          ? "#4cc9f0"
          : unit.ultimateReady
            ? "#80ed99"
            : "rgba(255,255,255,0.2)";
    ctx.lineWidth = isActive || isCastingHero ? 4 : isTimelineTarget ? 3 : 2;
    ctx.fillRect(x, y, width, height);
    ctx.strokeRect(x, y, width, height);

    if (isCastingHero || isTimelineTarget) {
      ctx.fillStyle = isCastingHero ? "rgba(255, 209, 102, 0.12)" : "rgba(76, 201, 240, 0.12)";
      ctx.fillRect(x + 2, y + 2, width - 4, height - 4);
    }

    this.drawClassIconBadge(ctx, x + 12, y + 10, 22, classBadge, unit.classIcon);

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "bold 18px sans-serif";
    ctx.fillText(unit.name, x + 44, y + 26);

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

  private drawPill(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
    text: string,
    fill: string,
    stroke: string,
    color: string,
    font = "bold 12px sans-serif",
  ) {
    ctx.save();
    ctx.fillStyle = fill;
    ctx.strokeStyle = stroke;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.roundRect(x, y, width, height, 10);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = color;
    ctx.font = font;
    ctx.fillText(text, x + 8, y + 14);
    ctx.restore();
  }

  private getClassBadge(classId: number): ClassBadge {
    if (classId >= 1 && classId <= 5) {
      return { fill: "#243b53", stroke: "#9fb3c8" };
    }
    if (classId >= 6 && classId <= 9) {
      return { fill: "#33265c", stroke: "#c77dff" };
    }
    return { fill: "#263238", stroke: "rgba(255,255,255,0.35)" };
  }

  private drawClassIconBadge(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    size: number,
    badge: ClassBadge,
    icon: string,
  ) {
    ctx.save();
    ctx.fillStyle = badge.fill;
    ctx.strokeStyle = badge.stroke;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(x, y, size, size, 6);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#f8f9fa";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.font = "16px 'Segoe UI Emoji', 'Apple Color Emoji', sans-serif";
    ctx.fillText(icon && icon.length > 0 ? icon : "?", x + size / 2, y + size / 2 + 1);

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
    ctx.fillText(`Round ${state.snapshot.round}`, 48, TOP_BAR_TEXT_Y);
    ctx.font = "14px sans-serif";
    ctx.fillText(state.banner ?? "AFK 战斗进行中", width / 2 - 70, TOP_BAR_TEXT_Y - 2);

    if (state.runContext) {
      ctx.font = "12px sans-serif";
      ctx.fillStyle = "#d9e2ec";
      ctx.fillText(
        `${state.runContext.chapterLabel} · ${state.runContext.nodeTitle} · 金币 ${state.runContext.gold} · 遗物 ${state.runContext.relicCount} · 祝福 ${state.runContext.blessingCount}`,
        48,
        TOP_BAR_TEXT_Y + 18,
      );
    }
  }

  private drawTimelineOverlay(ctx: CanvasRenderingContext2D, width: number, now: number, state: BattleStoreState) {
    const snapshot = state.snapshot;
    const activeUnit = snapshot
      ? [...snapshot.leftTeam, ...snapshot.rightTeam].find((unit) => unit.id === snapshot.activeHeroId) ?? null
      : null;

    if (!this.activeTimeline && !activeUnit) {
      return;
    }

    if (this.activeTimeline.completedAt && now - this.activeTimeline.completedAt > 280) {
      this.activeTimeline = null;
    }

    const overlay = this.activeTimeline;
    const panelWidth = Math.min(520, Math.max(380, width - 120));
    const panelHeight = TIMELINE_PANEL_HEIGHT;
    const x = Math.round((width - panelWidth) / 2);
    const y = TIMELINE_PANEL_Y;
    const infoWidth = 180;
    const timelineX = x + infoWidth + 12;
    const timelineWidth = panelWidth - infoWidth - 28;
    const keyframeCount = Math.max(overlay?.totalFrames ?? 1, 1);
    const currentKeyframeIndex = Math.max(0, overlay?.frameIndex ?? 0);
    const progress = overlay ? Math.max(0.08, Math.min(1, currentKeyframeIndex / keyframeCount)) : 0;
    const timelineMs = Math.max(0, Math.round(((overlay?.frame ?? 0) || 0) * (1000 / 30)));

    ctx.save();
    ctx.fillStyle = "rgba(11, 19, 32, 0.92)";
    ctx.strokeStyle = overlay?.completedAt ? "#80ed99" : "#ffd166";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(x, y, panelWidth, panelHeight, 12);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "rgba(255,255,255,0.08)";
    ctx.fillRect(x + infoWidth, y + 10, 1, panelHeight - 20);

    if (activeUnit) {
      const badge = this.getClassBadge(activeUnit.classId);
      const hpRate = activeUnit.maxHp > 0 ? activeUnit.hp / activeUnit.maxHp : 0;
      const enRate = activeUnit.maxEnergy > 0 ? activeUnit.energy / activeUnit.maxEnergy : 0;

      this.drawClassIconBadge(ctx, x + 12, y + 12, 24, badge, activeUnit.classIcon);
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "bold 15px sans-serif";
      ctx.fillText(activeUnit.name, x + 44, y + 20);

      ctx.font = "11px sans-serif";
      ctx.fillStyle = "#d9e2ec";
      const actionText = overlay
        ? overlay.skillName
        : activeUnit.ultimateReady
          ? `ULT READY · ${activeUnit.ultimateSkillName}`
          : activeUnit.ultimateSkillName;
      ctx.fillText(actionText, x + 44, y + 36);

      this.drawBar(ctx, x + 12, y + 48, infoWidth - 24, 8, hpRate, "#ef476f", "#3a3a3a");
      this.drawBar(ctx, x + 12, y + 62, infoWidth - 24, 6, enRate, "#4cc9f0", "#2a2a2a");

      ctx.fillStyle = "#f8f9fa";
      ctx.font = "10px sans-serif";
      ctx.fillText(`${Math.max(0, Math.floor(activeUnit.hp))}/${Math.floor(activeUnit.maxHp)}`, x + 12, y + 46);
      ctx.fillText(`EN ${Math.floor(activeUnit.energy)}/${Math.floor(activeUnit.maxEnergy)}`, x + infoWidth - 62, y + 72);

      this.drawBuffSummary(ctx, x + 12, y + 80, infoWidth - 24, activeUnit);
    }

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "bold 18px sans-serif";
    ctx.fillText(overlay ? `${overlay.heroName} · ${overlay.skillName}` : "等待技能时间轴", timelineX, y + 24);

    ctx.font = "13px sans-serif";
    const phaseText = overlay
      ? overlay.completedAt
        ? `完成 · ${overlay.succeeded ? "成功" : "失败"} · 总伤害 ${overlay.totalDamage}`
        : `播放中 · 关键帧 ${overlay.frameIndex}/${keyframeCount} · 时间轴帧 ${overlay.frame} (~${timelineMs}ms)`
      : "尚未进入技能时间轴，等待本轮动作开始";
    ctx.fillText(phaseText, timelineX, y + 46);

    ctx.fillStyle = "#263238";
    ctx.fillRect(timelineX, y + 76, timelineWidth, 8);
    ctx.fillStyle = overlay?.completedAt ? "#80ed99" : "#ffd166";
    ctx.fillRect(timelineX, y + 76, Math.round(timelineWidth * progress), 8);
    ctx.restore();
  }

  private drawBuffSummary(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, unit: UnitState) {
    ctx.save();
    ctx.font = "10px sans-serif";
    ctx.fillStyle = "#9fb3c8";
    ctx.fillText("Buff", x, y + 10);

    const buffs = (unit.buffs ?? []).slice(0, 2);
    if (buffs.length === 0) {
      ctx.fillStyle = "rgba(255,255,255,0.55)";
      ctx.fillText("无", x + 30, y + 10);
      ctx.restore();
      return;
    }

    let chipX = x + 30;
    for (const buff of buffs) {
      const suffix = buff.stackCount > 1 ? `x${buff.stackCount}` : "";
      const label = `${String(buff.name ?? "").slice(0, 4)}${suffix}`;
      const chipWidth = Math.min(70, Math.max(36, 14 + label.length * 9));

      if (chipX + chipWidth > x + width) {
        break;
      }

      ctx.fillStyle = "rgba(255,255,255,0.08)";
      ctx.strokeStyle = "rgba(255,255,255,0.18)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.roundRect(chipX, y, chipWidth, 14, 7);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = "#f8f9fa";
      ctx.fillText(label, chipX + 6, y + 10);
      chipX += chipWidth + 6;
    }

    ctx.restore();
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
      if (event.type === "timeline_started") {
        this.activeTimeline = {
          heroId: event.heroId,
          heroName: event.heroName,
          skillName: event.skillName,
          totalFrames: event.totalFrames,
          frameIndex: 0,
          frame: 0,
          op: "cast",
          effect: "",
          targetIds: [],
          startedAt: now,
          completedAt: null,
          totalDamage: 0,
          succeeded: null,
        };
        continue;
      }

      if (event.type === "timeline_frame") {
        this.activeTimeline = {
          heroId: event.heroId,
          heroName: event.heroName,
          skillName: event.skillName,
          totalFrames: this.activeTimeline?.totalFrames ?? event.frameIndex,
          frameIndex: event.frameIndex,
          frame: event.frame,
          op: event.op,
          effect: event.effect,
          targetIds: event.targetIds,
          startedAt: this.activeTimeline?.startedAt ?? now,
          completedAt: null,
          totalDamage: this.activeTimeline?.totalDamage ?? 0,
          succeeded: null,
        };
        continue;
      }

      if (event.type === "timeline_completed") {
        this.activeTimeline = {
          heroId: event.heroId,
          heroName: event.heroName,
          skillName: event.skillName,
          totalFrames: Math.max(this.activeTimeline?.totalFrames ?? 0, event.totalFrames),
          frameIndex: this.activeTimeline?.frameIndex ?? event.totalFrames,
          frame: this.activeTimeline?.frame ?? 0,
          op: this.activeTimeline?.op ?? "complete",
          effect: this.activeTimeline?.effect ?? "",
          targetIds: this.activeTimeline?.targetIds ?? [],
          startedAt: this.activeTimeline?.startedAt ?? now,
          completedAt: now,
          totalDamage: event.totalDamage,
          succeeded: event.succeeded,
        };
        continue;
      }

      if (event.type === "damage" || event.type === "heal") {
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
