import { createFloatingText, drawFloatingText, type FloatingText } from "./animations";
import type { BattleStoreState } from "../state/battleStore";
import type { ActionOrderState, AnimationEvent, UnitState } from "../types/battle";

type FormationSide = "player" | "enemy";
type FormationRow = "front" | "back";

type UnitLayout = {
  x: number;
  y: number;
  width: number;
  height: number;
  unit: UnitState;
  formationSide: FormationSide;
  row: FormationRow;
  column: number;
  baseX: number;
  baseY: number;
};

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

type MeleeClash = {
  attackerId: string;
  anchorTargetId: string;
  targetIds: string[];
  startedAt: number;
  durationMs: number;
  hitMoments: number[];
  precise: boolean;
};

type ProjectileStyle = {
  kind: "orb" | "shard" | "lightning";
  core: string;
  glow: string;
  trail: string;
  radius: number;
  arcHeight: number;
};

type ProjectileAnimation = {
  id: string;
  attackerId: string;
  targetId: string;
  startedAt: number;
  durationMs: number;
  style: ProjectileStyle;
};

type ImpactBurst = {
  unitId: string;
  startedAt: number;
  durationMs: number;
  delayMs: number;
  color: string;
  ringColor: string;
  size: number;
};

type FormationMetrics = {
  cardWidth: number;
  cardHeight: number;
  gapX: number;
  rowGap: number;
  centerGap: number;
  startX: number;
  enemyBackY: number;
  enemyFrontY: number;
  playerFrontY: number;
  playerBackY: number;
};

const TOP_BAR_TEXT_Y = 36;
const ACTION_ORDER_BAR_Y = 50;
const ACTION_ORDER_BAR_HEIGHT = 56;
const BATTLEFIELD_TOP_SAFE_Y = ACTION_ORDER_BAR_Y + ACTION_ORDER_BAR_HEIGHT + 22;
const BATTLEFIELD_BOTTOM_SAFE_Y = 0;
const COMPACT_BATTLEFIELD_BOTTOM_SAFE_Y = 0;
const TEAM_ROW_GAP = 26;
const TEAM_CENTER_GAP = 44;

export class BattleScene {
  private floatingTexts: Array<FloatingText & { unitId: string }> = [];
  private activeTimeline: TimelineOverlay | null = null;
  private meleeClashes: MeleeClash[] = [];
  private projectiles: ProjectileAnimation[] = [];
  private impactBursts: ImpactBurst[] = [];
  private lastProjectileAtByCaster = new Map<string, number>();
  private pendingExtraAttackUntilByHero = new Map<string, number>();
  private pendingPreciseTargetsByHero = new Map<string, { until: number; targetId: string }>();
  private actionOrderRound: number | null = null;
  private actionOrderRosterKey = "";
  private actionOrderIds: string[] = [];

  draw(ctx: CanvasRenderingContext2D, width: number, height: number, state: BattleStoreState, now: number) {
    ctx.clearRect(0, 0, width, height);
    this.drawBackground(ctx, width, height);

    if (!state.snapshot) {
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "24px sans-serif";
      ctx.fillText("加载战斗中...", width / 2 - 64, height / 2);
      return;
    }

    const metrics = this.computeFormationMetrics(width, height);
    const enemyLayouts = this.layoutTeam(state.snapshot.rightTeam, metrics, "enemy");
    const playerLayouts = this.layoutTeam(state.snapshot.leftTeam, metrics, "player");
    const baseLayouts = [...enemyLayouts, ...playerLayouts];

    this.consumeAnimations(state.animations, baseLayouts, now);
    this.pruneTransientAnimations(now);

    const allLayouts = baseLayouts.map((layout) => this.resolveAnimatedLayout(layout, baseLayouts, now));
    this.drawBoardFrame(ctx, width, height, allLayouts);

    for (const layout of allLayouts) {
      this.drawUnitCard(ctx, layout, state.snapshot.activeHeroId === layout.unit.id);
    }

    this.drawProjectileAnimations(ctx, allLayouts, now);
    this.drawImpactBursts(ctx, allLayouts, now);
    this.drawTopBar(ctx, width, state);
    this.drawActionOrderBar(ctx, width, state);
    this.drawFloatingTexts(ctx, allLayouts, now);
  }

  private drawBackground(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const gradient = ctx.createLinearGradient(0, 0, 0, height);
    gradient.addColorStop(0, "#12263a");
    gradient.addColorStop(0.55, "#0c1829");
    gradient.addColorStop(1, "#09111e");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);

    const topGlow = ctx.createRadialGradient(width / 2, BATTLEFIELD_TOP_SAFE_Y + 72, 12, width / 2, BATTLEFIELD_TOP_SAFE_Y + 72, 360);
    topGlow.addColorStop(0, "rgba(255, 118, 117, 0.16)");
    topGlow.addColorStop(1, "rgba(255, 118, 117, 0)");
    ctx.fillStyle = topGlow;
    ctx.fillRect(0, 0, width, height);

    const centerY = Math.round((BATTLEFIELD_TOP_SAFE_Y + (height - this.getBattlefieldBottomSafeY(width))) / 2);
    const centerGlow = ctx.createLinearGradient(0, centerY - 60, 0, centerY + 60);
    centerGlow.addColorStop(0, "rgba(255,255,255,0)");
    centerGlow.addColorStop(0.5, "rgba(255, 209, 102, 0.16)");
    centerGlow.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = centerGlow;
    ctx.fillRect(24, centerY - 60, width - 48, 120);
  }

  private drawBoardFrame(ctx: CanvasRenderingContext2D, width: number, height: number, layouts: UnitLayout[]) {
    const boardTop = BATTLEFIELD_TOP_SAFE_Y - 12;
    const boardBottom = height - this.getBattlefieldBottomSafeY(width) + 12;
    const centerY = Math.round((boardTop + boardBottom) / 2);
    const playerFront = layouts.filter((layout) => layout.formationSide === "player" && layout.row === "front");
    const enemyFront = layouts.filter((layout) => layout.formationSide === "enemy" && layout.row === "front");

    ctx.save();
    ctx.strokeStyle = "rgba(255,255,255,0.08)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    const boardMarginX = width < 520 ? 8 : 24;
    ctx.roundRect(boardMarginX, boardTop, width - boardMarginX * 2, boardBottom - boardTop, 24);
    ctx.stroke();

    ctx.strokeStyle = "rgba(255, 209, 102, 0.22)";
    ctx.setLineDash([10, 10]);
    ctx.beginPath();
    ctx.moveTo(48, centerY);
    ctx.lineTo(width - 48, centerY);
    ctx.stroke();
    ctx.setLineDash([]);

    for (let column = 0; column < 3; column += 1) {
      const sample = playerFront.find((layout) => layout.column === column) ?? enemyFront.find((layout) => layout.column === column);
      if (!sample) {
        continue;
      }
      const laneX = sample.baseX + sample.width / 2;
      ctx.strokeStyle = "rgba(255,255,255,0.05)";
      ctx.beginPath();
      ctx.moveTo(laneX, boardTop + 18);
      ctx.lineTo(laneX, boardBottom - 18);
      ctx.stroke();
    }
    ctx.restore();
  }

  private computeFormationMetrics(width: number, height: number): FormationMetrics {
    const marginX = width < 520 ? 18 : 48;
    const desiredCardWidth = 208;
    const desiredGapX = width < 520 ? 14 : 28;
    const minCardWidth = width < 520 ? 96 : 158;
    const minGapX = width < 520 ? 8 : 16;

    const compactViewport = width < 520;
    const desiredCardHeight = 110;
    const minCardHeight = compactViewport ? 64 : 92;
    const desiredRowGap = TEAM_ROW_GAP;
    const minRowGap = compactViewport ? 6 : 12;
    const desiredCenterGap = TEAM_CENTER_GAP;
    const minCenterGap = compactViewport ? 22 : 24;

    const availableX = Math.max(0, width - marginX * 2);
    const desiredTotalX = desiredCardWidth * 3 + desiredGapX * 2;
    const scaleX = desiredTotalX > 0 ? Math.min(1, availableX / desiredTotalX) : 1;
    const cardWidth = Math.max(minCardWidth, Math.floor(desiredCardWidth * scaleX));
    const gapX = Math.max(minGapX, Math.floor(desiredGapX * scaleX));
    const totalWidth = cardWidth * 3 + gapX * 2;
    const startX = Math.round((width - totalWidth) / 2);

    const battlefieldTop = BATTLEFIELD_TOP_SAFE_Y + 8;
    const battlefieldBottom = height - this.getBattlefieldBottomSafeY(width) - 4;
    const availableY = Math.max(0, battlefieldBottom - battlefieldTop);
    const desiredTotalY = 2 * (2 * desiredCardHeight + desiredRowGap) + desiredCenterGap;
    const scaleY = desiredTotalY > 0 ? Math.min(1, availableY / desiredTotalY) : 1;
    let cardHeight = Math.max(minCardHeight, Math.floor(desiredCardHeight * scaleY));
    let rowGap = Math.max(minRowGap, Math.floor(desiredRowGap * scaleY));
    let centerGap = Math.max(minCenterGap, Math.floor(desiredCenterGap * scaleY));

    const minTotalY = 4 * minCardHeight + 2 * minRowGap + minCenterGap;
    if (compactViewport && availableY > 0 && availableY < minTotalY) {
      const tightScale = availableY / minTotalY;
      cardHeight = Math.max(54, Math.floor(minCardHeight * tightScale));
      rowGap = Math.max(4, Math.floor(minRowGap * tightScale));
      centerGap = Math.max(16, Math.floor(minCenterGap * tightScale));
    }

    const totalFormationHeight = () => 4 * cardHeight + 2 * rowGap + centerGap;
    if (availableY > 0 && totalFormationHeight() > availableY) {
      const hardMinCardHeight = compactViewport ? 54 : 80;
      const hardMinRowGap = compactViewport ? 4 : 8;
      const hardMinCenterGap = compactViewport ? 16 : 20;
      const targetRowGap = Math.max(hardMinRowGap, Math.min(rowGap, Math.floor(availableY * 0.025)));
      const targetCenterGap = Math.max(hardMinCenterGap, Math.min(centerGap, Math.floor(availableY * 0.075)));

      rowGap = targetRowGap;
      centerGap = targetCenterGap;
      cardHeight = Math.max(hardMinCardHeight, Math.floor((availableY - 2 * rowGap - centerGap) / 4));

      if (totalFormationHeight() > availableY) {
        rowGap = hardMinRowGap;
        centerGap = hardMinCenterGap;
        cardHeight = Math.max(40, Math.floor((availableY - 2 * rowGap - centerGap) / 4));
      }
    }

    // Stack from top to bottom:
    // enemy back -> enemy front -> center gap -> player front -> player back
    const enemyBackY = battlefieldTop;
    const enemyFrontY = enemyBackY + cardHeight + rowGap;
    const playerFrontY = enemyFrontY + cardHeight + centerGap;
    const playerBackY = playerFrontY + cardHeight + rowGap;

    return {
      cardWidth,
      cardHeight,
      gapX,
      rowGap,
      centerGap,
      startX,
      enemyBackY,
      enemyFrontY,
      playerFrontY,
      playerBackY,
    };
  }

  private getBattlefieldBottomSafeY(width: number) {
    return width < 520 ? COMPACT_BATTLEFIELD_BOTTOM_SAFE_Y : BATTLEFIELD_BOTTOM_SAFE_Y;
  }

  private layoutTeam(team: UnitState[], metrics: FormationMetrics, formationSide: FormationSide): UnitLayout[] {
    return team.map((unit, index) => {
      const position = Number.isFinite(unit.position) ? Math.floor(unit.position) : 0;
      const hasMappedPosition = position >= 1 && position <= 6;
      const row: FormationRow = hasMappedPosition ? (position <= 3 ? "front" : "back") : index < 3 ? "front" : "back";
      const column = hasMappedPosition ? (position - 1) % 3 : index % 3;
      const baseX = metrics.startX + column * (metrics.cardWidth + metrics.gapX);
      const baseY = formationSide === "enemy"
        ? row === "front"
          ? metrics.enemyFrontY
          : metrics.enemyBackY
        : row === "front"
          ? metrics.playerFrontY
          : metrics.playerBackY;

      return {
        x: baseX,
        y: baseY,
        width: metrics.cardWidth,
        height: metrics.cardHeight,
        unit,
        formationSide,
        row,
        column,
        baseX,
        baseY,
      };
    });
  }

  private resolveAnimatedLayout(layout: UnitLayout, baseLayouts: UnitLayout[], now: number): UnitLayout {
    let dx = 0;
    let dy = 0;

    for (const clash of this.meleeClashes) {
      const attacker = baseLayouts.find((candidate) => candidate.unit.id === clash.attackerId);
      const targets = clash.targetIds
        .map((targetId) => baseLayouts.find((candidate) => candidate.unit.id === targetId))
        .filter((candidate): candidate is UnitLayout => Boolean(candidate));
      if (!attacker || targets.length === 0) {
        continue;
      }
      const elapsed = now - clash.startedAt;
      if (elapsed < 0 || elapsed > clash.durationMs) {
        continue;
      }
      const progress = elapsed / clash.durationMs;
      const anchorTarget = targets.find((candidate) => candidate.unit.id === clash.anchorTargetId) ?? targets[0];
      const focus = this.getMeleeFocusPoint(attacker, targets, clash);
      const vectorX = focus.x - (attacker.baseX + attacker.width / 2);
      const vectorY = focus.y - (attacker.baseY + attacker.height / 2);
      const distance = Math.max(1, Math.hypot(vectorX, vectorY));
      const unitX = vectorX / distance;
      const unitY = vectorY / distance;
      const tangentX = -unitY;
      const tangentY = unitX;
      const attackStart = this.getCardEdgePoint(attacker, anchorTarget);
      const attackEnd = this.getCardEdgePoint(anchorTarget, attacker);
      const heavyImpactInset = 5;
      const contactDistance = Math.max(
        18,
        Math.hypot(attackEnd.x - attackStart.x, attackEnd.y - attackStart.y) + heavyImpactInset,
      );

      if (layout.unit.id === attacker.unit.id) {
        const maxPush = contactDistance;
        const travel = this.getMeleeTravelDistance(progress, maxPush, clash.hitMoments.length);

        dx += unitX * travel;
        dy += unitY * travel;
      } else if (targets.some((target) => target.unit.id === layout.unit.id)) {
        for (const hitMoment of clash.hitMoments) {
          const hitProgress = this.getHitEnvelope(progress, hitMoment, 0.18);
          if (hitProgress <= 0) {
            continue;
          }
          const envelope = Math.sin(hitProgress * Math.PI);
          const shakeAmplitude = Math.min(11, distance * 0.026) * envelope;
          const shakeWaveA = Math.sin(hitProgress * Math.PI * 8);
          const shakeWaveB = Math.sin(hitProgress * Math.PI * 14);
          dx += tangentX * shakeWaveA * shakeAmplitude;
          dy += tangentY * shakeWaveA * shakeAmplitude;
          dx += unitX * shakeWaveB * shakeAmplitude * 0.28;
          dy += unitY * shakeWaveB * shakeAmplitude * 0.28;
        }
      }
    }

    return {
      ...layout,
      x: layout.baseX + dx,
      y: layout.baseY + dy,
    };
  }

  private drawUnitCard(ctx: CanvasRenderingContext2D, layout: UnitLayout, isActive: boolean) {
    const { x, y, width, height, unit } = layout;
    const isCastingHero = this.activeTimeline?.heroId === unit.id;
    const isTimelineTarget = this.activeTimeline?.targetIds.includes(unit.id) ?? false;
    const classBadge = this.getClassBadge(unit.classId);
    const fillGradient = ctx.createLinearGradient(x, y, x, y + height);

    if (unit.team === "left") {
      fillGradient.addColorStop(0, "#1f567d");
      fillGradient.addColorStop(1, "#15344a");
    } else {
      fillGradient.addColorStop(0, "#7b1737");
      fillGradient.addColorStop(1, "#4b1024");
    }

    ctx.save();
    ctx.shadowColor = "rgba(0, 0, 0, 0.28)";
    ctx.shadowBlur = 18;
    ctx.shadowOffsetY = 8;
    ctx.fillStyle = fillGradient;
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
    ctx.beginPath();
    ctx.roundRect(x, y, width, height, 18);
    ctx.fill();
    ctx.shadowBlur = 0;
    ctx.shadowOffsetY = 0;
    ctx.stroke();

    if (isCastingHero || isTimelineTarget) {
      ctx.fillStyle = isCastingHero ? "rgba(255, 209, 102, 0.12)" : "rgba(76, 201, 240, 0.12)";
      ctx.beginPath();
      ctx.roundRect(x + 2, y + 2, width - 4, height - 4, 16);
      ctx.fill();
    }

    const compact = width < 120 || height < 76;
    const tight = height < 58;
    const micro = height < 48;
    const badgeSize = compact ? 16 : 22;
    const nameX = compact ? x + 30 : x + 44;
    if (compact) {
      this.drawClassIconBadge(ctx, x + 8, y + 8, badgeSize, classBadge, unit.classIcon);
    } else {
      this.drawClassIconBadge(ctx, x + 12, y + 10, badgeSize, classBadge, unit.classIcon);
    }

    ctx.fillStyle = "#f8f9fa";
    ctx.font = compact ? "bold 11px sans-serif" : "bold 18px sans-serif";
    ctx.fillText(unit.name, nameX, y + (compact ? 21 : 26), width - (compact ? 38 : 52));

    const hpY = micro ? y + height - 22 : tight ? y + height - 26 : compact ? y + height - 30 : y + 52;
    const hpRate = unit.maxHp > 0 ? unit.hp / unit.maxHp : 0;
    const hpBarHeight = micro ? 5 : tight ? 6 : compact ? 8 : 10;
    this.drawBar(ctx, x + 12, hpY, width - 24, hpBarHeight, hpRate, this.getHpBarColor(hpRate), "#263238");
    ctx.fillStyle = "#f8f9fa";
    ctx.font = compact ? "bold 7px sans-serif" : "bold 10px sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(`${Math.max(0, Math.floor(unit.hp))}/${Math.floor(unit.maxHp)}`, x + width / 2, hpY + hpBarHeight / 2);
    ctx.textAlign = "left";
    ctx.textBaseline = "alphabetic";

    this.drawBuffIcons(
      ctx,
      compact ? x + 10 : x + 16,
      micro ? hpY + 8 : tight ? hpY + 10 : compact ? hpY + 12 : y + 72,
      compact ? width - 20 : width - 32,
      unit,
      micro ? 10 : tight ? 14 : 18,
      micro ? 4 : 6,
    );

    if (!unit.isAlive) {
      ctx.fillStyle = "rgba(0,0,0,0.48)";
      ctx.beginPath();
      ctx.roundRect(x, y, width, height, 18);
      ctx.fill();
      ctx.fillStyle = "#f8f9fa";
      ctx.font = compact ? "bold 10px sans-serif" : "bold 20px sans-serif";
      ctx.textAlign = "center";
      ctx.fillText("DEFEATED", x + width / 2, y + height / 2 + 4, width - 8);
      ctx.textAlign = "left";
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

  private getHpBarColor(rate: number) {
    const hpRate = Math.max(0, Math.min(1, rate));
    if (hpRate > 0.72) {
      return "#43d17a";
    }
    if (hpRate > 0.45) {
      return "#ffd166";
    }
    if (hpRate > 0.22) {
      return "#ff9f1c";
    }
    return "#ef476f";
  }

  private drawBuffIcons(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    unit: UnitState,
    iconSize = 18,
    gap = 6,
  ) {
    const buffs = (unit.buffs ?? []).slice(0, 4);
    ctx.save();
    ctx.font = "10px sans-serif";

    if (buffs.length === 0) {
      ctx.restore();
      return;
    }

    for (let index = 0; index < buffs.length; index += 1) {
      const buff = buffs[index];
      const iconX = x + index * (iconSize + gap);
      if (iconX + iconSize > x + width) {
        break;
      }
      const style = this.getBuffIconStyle(buff.buffId, buff.name);

      ctx.fillStyle = style.fill;
      ctx.strokeStyle = style.stroke;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.roundRect(iconX, y, iconSize, iconSize, 5);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = "#f8f9fa";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.font = iconSize < 14 ? "bold 7px sans-serif" : iconSize < 18 ? "bold 8px sans-serif" : "bold 10px sans-serif";
      ctx.fillText(style.label, iconX + iconSize / 2, y + iconSize / 2 + 0.5);

      const stackText = buff.stackCount > 1 ? String(buff.stackCount) : buff.duration > 0 && buff.duration < 99 ? String(buff.duration) : "";
      if (stackText) {
        ctx.fillStyle = "rgba(11, 19, 32, 0.95)";
        ctx.beginPath();
        const stackRadius = Math.max(4, Math.floor(iconSize / 3));
        ctx.arc(iconX + iconSize - 2, y + iconSize - 2, stackRadius, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#f8f9fa";
        ctx.font = iconSize < 14 ? "bold 6px sans-serif" : "bold 8px sans-serif";
        ctx.fillText(stackText, iconX + iconSize - 2, y + iconSize - 2.5);
      }
    }

    if ((unit.buffs?.length ?? 0) > buffs.length) {
      ctx.textAlign = "left";
      ctx.textBaseline = "alphabetic";
      ctx.fillStyle = "#d9e2ec";
      ctx.font = iconSize < 14 ? "8px sans-serif" : "10px sans-serif";
      ctx.fillText(`+${(unit.buffs?.length ?? 0) - buffs.length}`, x + buffs.length * (iconSize + gap), y + iconSize - 5);
    }

    ctx.restore();
  }

  private getBuffIconStyle(buffId: number, name: string) {
    const id = Math.floor((Number(buffId) || 0) / 10000);
    if (id === 82) {
      return { label: "嘲", fill: "#3b5b7a", stroke: "#91c9ff" };
    }
    if (id === 84) {
      return { label: "战", fill: "#5c4a1f", stroke: "#ffd166" };
    }
    if (id === 85) {
      return { label: "毒", fill: "#24573a", stroke: "#80ed99" };
    }
    if (id === 86) {
      return { label: "亲", fill: "#29445f", stroke: "#4cc9f0" };
    }
    if (id === 87) {
      return { label: "火", fill: "#6f2a1f", stroke: "#ff8a65" };
    }
    if (id === 88) {
      return { label: name.includes("冻") ? "冻" : "慢", fill: "#263b5f", stroke: "#90caf9" };
    }
    return { label: String(name || "?").slice(0, 1), fill: "#263238", stroke: "rgba(255,255,255,0.45)" };
  }

  private drawTopBar(ctx: CanvasRenderingContext2D, width: number, state: BattleStoreState) {
    if (!state.snapshot) {
      return;
    }

    const compact = width < 520;
    ctx.fillStyle = "#f8f9fa";
    ctx.font = compact ? "bold 20px sans-serif" : "bold 24px sans-serif";
    ctx.fillText(`Round ${state.snapshot.round}`, compact ? 28 : 48, compact ? 30 : TOP_BAR_TEXT_Y);

    const resultText = state.snapshot.result
      ? `Result ${state.snapshot.result.winner} · ${state.snapshot.result.reason}`
      : "Result running";
    ctx.textAlign = compact ? "right" : "center";
    ctx.font = compact ? "bold 12px sans-serif" : "bold 14px sans-serif";
    ctx.fillText(resultText, compact ? width - 24 : width / 2, compact ? 24 : TOP_BAR_TEXT_Y - 6, compact ? width - 150 : undefined);

    if (state.banner) {
      ctx.font = compact ? "11px sans-serif" : "12px sans-serif";
      ctx.fillStyle = "#d9e2ec";
      ctx.fillText(state.banner, compact ? width - 24 : width / 2, compact ? 40 : TOP_BAR_TEXT_Y + 12, compact ? width - 150 : undefined);
    }
    ctx.textAlign = "left";

    if (state.runContext) {
      ctx.font = "12px sans-serif";
      ctx.fillStyle = "#d9e2ec";
      ctx.fillText(
        `${state.runContext.chapterLabel} · ${state.runContext.nodeTitle} · 金币 ${state.runContext.gold} · 装备 ${state.runContext.equipmentCount} · 祝福 ${state.runContext.blessingCount}`,
        48,
        TOP_BAR_TEXT_Y + 14,
      );
    }
  }

  private drawActionOrderBar(ctx: CanvasRenderingContext2D, width: number, state: BattleStoreState) {
    const snapshot = state.snapshot;
    if (!snapshot) {
      return;
    }

    const allUnits = [...snapshot.leftTeam, ...snapshot.rightTeam];
    const order = this.resolveActionOrder(snapshot, allUnits);
    const panelWidth = Math.min(760, Math.max(380, width - 96));
    const x = Math.round((width - panelWidth) / 2);
    const y = ACTION_ORDER_BAR_Y;
    const trackX = x + 34;
    const trackY = y + ACTION_ORDER_BAR_HEIGHT / 2;
    const trackWidth = panelWidth - 68;
    const iconSize = width < 560 ? 24 : 28;

    ctx.save();
    ctx.fillStyle = "rgba(11, 19, 32, 0.9)";
    ctx.strokeStyle = "rgba(255,255,255,0.14)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(x, y, panelWidth, ACTION_ORDER_BAR_HEIGHT, 10);
    ctx.fill();
    ctx.stroke();

    ctx.strokeStyle = "rgba(255,255,255,0.16)";
    ctx.lineWidth = 6;
    ctx.lineCap = "round";
    ctx.beginPath();
    ctx.moveTo(trackX, trackY);
    ctx.lineTo(trackX + trackWidth, trackY);
    ctx.stroke();

    const step = order.length > 1 ? trackWidth / (order.length - 1) : 0;
    for (let index = 0; index < order.length; index += 1) {
      const item = order[index];
      const isActive = snapshot.activeHeroId === item.id;
      const badge = this.getClassBadge(item.classId);
      const iconCenterX = trackX + Math.round(step * index);
      const laneY = trackY;
      const iconX = Math.max(trackX - iconSize / 2, Math.min(trackX + trackWidth - iconSize / 2, iconCenterX - iconSize / 2));
      const iconY = laneY - iconSize / 2;
      const teamStroke = item.team === "left" ? "#4cc9f0" : "#ef476f";

      ctx.globalAlpha = item.isAlive ? 1 : 0.32;
      if (isActive) {
        ctx.shadowColor = "rgba(255, 209, 102, 0.65)";
        ctx.shadowBlur = 12;
        ctx.strokeStyle = "#ffd166";
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(iconCenterX, laneY, iconSize / 2 + 8, 0, Math.PI * 2);
        ctx.stroke();
        ctx.shadowBlur = 0;
      }

      this.drawClassIconBadge(ctx, iconX, iconY, iconSize, badge, item.classIcon);

      ctx.strokeStyle = isActive ? "#ffd166" : teamStroke;
      ctx.lineWidth = isActive ? 3 : 2;
      ctx.beginPath();
      ctx.roundRect(iconX - 1, iconY - 1, iconSize + 2, iconSize + 2, 7);
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    ctx.restore();
  }

  private resolveActionOrder(snapshot: NonNullable<BattleStoreState["snapshot"]>, units: UnitState[]): ActionOrderState[] {
    const rosterKey = units
      .map((unit) => `${unit.id}:${unit.team}:${unit.classId}:${unit.initiative}`)
      .join("|");

    if (this.actionOrderRound !== snapshot.round || this.actionOrderRosterKey !== rosterKey || this.actionOrderIds.length === 0) {
      this.actionOrderRound = snapshot.round;
      this.actionOrderRosterKey = rosterKey;
      this.actionOrderIds = units
        .filter((unit) => unit.isAlive)
        .sort((a, b) => {
          if (b.initiative !== a.initiative) {
            return b.initiative - a.initiative;
          }
          return a.id.localeCompare(b.id);
        })
        .map((unit) => unit.id);
    }

    const unitById = new Map(units.map((unit) => [unit.id, unit]));
    return this.actionOrderIds
      .map((id) => unitById.get(id))
      .filter((unit): unit is UnitState => Boolean(unit))
      .map((unit) => ({
        id: unit.id,
        name: unit.name,
        team: unit.team,
        classId: unit.classId,
        classIcon: unit.classIcon,
        progress: unit.actionBar ?? 0,
        max: unit.actionBarMax ?? 1000,
        initiative: unit.initiative ?? 0,
        isAlive: unit.isAlive,
      }));
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
        this.maybeQueueAttackAnimation(event, layouts, now);
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

      if (event.type === "passive_triggered") {
        if (event.skillName === "额外攻击") {
          this.pendingExtraAttackUntilByHero.set(event.heroId, now + 900);
        }
        continue;
      }

      if (event.type === "combat_cue") {
        if (event.cue === "precise_attack") {
          this.pendingPreciseTargetsByHero.set(event.heroId, {
            until: now + 900,
            targetId: event.targetId,
          });
        }
        continue;
      }

      if (event.type === "damage" || event.type === "heal" || event.type === "miss") {
        const layout = layouts.find((item) => item.unit.id === event.heroId);
        const text = createFloatingText(event, layout?.unit, now);
        if (!text || !layout) {
          continue;
        }
        this.floatingTexts.push({
          ...text,
          unitId: layout.unit.id,
        });
        if (event.type === "miss") {
          continue;
        }
        this.impactBursts.push({
          unitId: layout.unit.id,
          startedAt: now,
          durationMs: event.type === "damage" ? 320 : 360,
          delayMs: 0,
          color: event.type === "damage" ? "rgba(255, 120, 117, 0.22)" : "rgba(128, 237, 153, 0.2)",
          ringColor: event.type === "damage" ? "rgba(255, 209, 102, 0.72)" : "rgba(128, 237, 153, 0.72)",
          size: event.type === "damage" ? 58 : 48,
        });
        if (event.type === "damage") {
          this.maybeAugmentMeleeClashFromDamage(event, now);
        }
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

  private maybeQueueAttackAnimation(event: Extract<AnimationEvent, { type: "timeline_frame" }>, layouts: UnitLayout[], now: number) {
    const attacker = layouts.find((layout) => layout.unit.id === event.heroId);
    if (!attacker || event.targetIds.length === 0) {
      return;
    }

    const hostileTargets = event.targetIds
      .map((targetId) => layouts.find((layout) => layout.unit.id === targetId))
      .filter((layout): layout is UnitLayout => Boolean(layout && layout.unit.team !== attacker.unit.team));

    const isMelee = this.isMeleeUnit(attacker.unit);
    const isProjectileFrame = event.op === "projectile" || this.looksLikeProjectileEffect(event.effect);
    const isDamageFrame = this.isDamageLikeOp(event.op);
    const isMeleeExecuteFrame = isMelee && event.op === "effect" && this.looksLikeMeleeHitEffect(event.effect);
    const isRangedExecuteFrame = !isMelee && event.op === "effect" && this.looksLikeMeleeHitEffect(event.effect);

    if (isProjectileFrame) {
      for (const target of hostileTargets) {
        this.projectiles.push({
          id: `${event.heroId}:${target.unit.id}:${event.frameIndex}:${event.frame}`,
          attackerId: attacker.unit.id,
          targetId: target.unit.id,
          startedAt: now,
          durationMs: 340,
          style: this.resolveProjectileStyle(event.effect, attacker.unit.classId),
        });
      }
      this.lastProjectileAtByCaster.set(attacker.unit.id, now);
      return;
    }

    const friendlyTargets = event.targetIds
      .map((targetId) => layouts.find((layout) => layout.unit.id === targetId))
      .filter((layout): layout is UnitLayout => Boolean(layout && layout.unit.team === attacker.unit.team));

    // Support skills often target allies (heal/aura/revive) and would otherwise show only numbers/bursts.
    // Render a lightweight projectile to allies for better readability without touching combat logic.
    if (hostileTargets.length === 0 && friendlyTargets.length > 0) {
      if (event.op !== "cast") {
        for (const target of friendlyTargets) {
          this.projectiles.push({
            id: `${event.heroId}:${target.unit.id}:${event.frameIndex}:${event.frame}:support`,
            attackerId: attacker.unit.id,
            targetId: target.unit.id,
            startedAt: now,
            durationMs: 300,
            style: this.resolveProjectileStyle(event.effect, attacker.unit.classId),
          });
        }
        this.lastProjectileAtByCaster.set(attacker.unit.id, now);
      }
      return;
    }

    if (hostileTargets.length === 0) {
      return;
    }

    if ((isMelee && isDamageFrame) || isMeleeExecuteFrame) {
      const primaryTarget = hostileTargets[0];
      const pendingExtraAttackUntil = this.pendingExtraAttackUntilByHero.get(attacker.unit.id) ?? -Infinity;
      const preciseCue = this.pendingPreciseTargetsByHero.get(attacker.unit.id);
      const preciseTargetId = preciseCue && preciseCue.until >= now ? preciseCue.targetId : "";
      const recentClash = this.findRecentMeleeClash(attacker.unit.id, primaryTarget.unit.id, now);

      if (pendingExtraAttackUntil >= now && recentClash) {
        recentClash.hitMoments = [0.34, 0.56];
        recentClash.durationMs = Math.max(recentClash.durationMs, 460);
        recentClash.precise = recentClash.precise || preciseTargetId === primaryTarget.unit.id;
        if (recentClash.precise) {
          this.queueImpactBurst(primaryTarget.unit.id, now, {
            delayMs: 210,
            durationMs: 260,
            color: "rgba(255, 209, 102, 0.28)",
            ringColor: "rgba(255, 244, 179, 0.9)",
            size: 66,
          });
        }
        this.pendingExtraAttackUntilByHero.delete(attacker.unit.id);
      } else {
        const clash: MeleeClash = {
          attackerId: attacker.unit.id,
          anchorTargetId: primaryTarget.unit.id,
          targetIds: [primaryTarget.unit.id],
          startedAt: now,
          durationMs: 360,
          hitMoments: [0.5],
          precise: preciseTargetId === primaryTarget.unit.id,
        };
        this.meleeClashes.push(clash);
        if (clash.precise) {
          this.queueImpactBurst(primaryTarget.unit.id, now, {
            delayMs: 150,
            durationMs: 240,
            color: "rgba(255, 209, 102, 0.24)",
            ringColor: "rgba(255, 244, 179, 0.88)",
            size: 62,
          });
        }
      }
      if (preciseTargetId === primaryTarget.unit.id) {
        this.pendingPreciseTargetsByHero.delete(attacker.unit.id);
      }
      return;
    }

    if (!isMelee && (isDamageFrame || isRangedExecuteFrame)) {
      const lastProjectileAt = this.lastProjectileAtByCaster.get(attacker.unit.id) ?? -Infinity;
      if (now - lastProjectileAt < 180) {
        return;
      }
      for (const target of hostileTargets) {
        this.projectiles.push({
          id: `${event.heroId}:${target.unit.id}:${event.frameIndex}:${event.frame}:fallback`,
          attackerId: attacker.unit.id,
          targetId: target.unit.id,
          startedAt: now,
          durationMs: 280,
          style: this.resolveProjectileStyle(event.effect, attacker.unit.classId),
        });
      }
      this.lastProjectileAtByCaster.set(attacker.unit.id, now);
    }
  }

  private pruneTransientAnimations(now: number) {
    this.meleeClashes = this.meleeClashes.filter((item) => now - item.startedAt <= item.durationMs);
    this.projectiles = this.projectiles.filter((item) => now - item.startedAt <= item.durationMs);
    this.impactBursts = this.impactBursts.filter((item) => now - (item.startedAt + item.delayMs) <= item.durationMs);
    for (const [heroId, until] of this.pendingExtraAttackUntilByHero.entries()) {
      if (until < now) {
        this.pendingExtraAttackUntilByHero.delete(heroId);
      }
    }
    for (const [heroId, precise] of this.pendingPreciseTargetsByHero.entries()) {
      if (precise.until < now) {
        this.pendingPreciseTargetsByHero.delete(heroId);
      }
    }
  }

  private findRecentMeleeClash(attackerId: string, targetId: string, now: number) {
    for (let index = this.meleeClashes.length - 1; index >= 0; index -= 1) {
      const clash = this.meleeClashes[index];
      if (clash.attackerId !== attackerId || clash.anchorTargetId !== targetId) {
        continue;
      }
      if (now - clash.startedAt <= 520) {
        return clash;
      }
      break;
    }
    return null;
  }

  private maybeAugmentMeleeClashFromDamage(event: Extract<AnimationEvent, { type: "damage" }>, now: number) {
    if (event.attackerId === "" || event.skillName !== "") {
      return;
    }
    for (let index = this.meleeClashes.length - 1; index >= 0; index -= 1) {
      const clash = this.meleeClashes[index];
      if (clash.attackerId !== event.attackerId || now - clash.startedAt > 520) {
        continue;
      }
      if (clash.targetIds.includes(event.heroId)) {
        return;
      }
      clash.targetIds = [...clash.targetIds, event.heroId];
      clash.durationMs = Math.max(clash.durationMs, 400);
      clash.hitMoments = [0.5];
      this.queueImpactBurst(event.heroId, now, {
        delayMs: 0,
        durationMs: 280,
        color: "rgba(255, 140, 102, 0.26)",
        ringColor: "rgba(255, 209, 102, 0.78)",
        size: 60,
      });
      return;
    }
  }

  private queueImpactBurst(
    unitId: string,
    startedAt: number,
    options: {
      delayMs?: number;
      durationMs: number;
      color: string;
      ringColor: string;
      size: number;
    },
  ) {
    this.impactBursts.push({
      unitId,
      startedAt,
      durationMs: options.durationMs,
      delayMs: options.delayMs ?? 0,
      color: options.color,
      ringColor: options.ringColor,
      size: options.size,
    });
  }

  private getMeleeFocusPoint(attacker: UnitLayout, targets: UnitLayout[], clash: MeleeClash) {
    if (targets.length === 1) {
      const target = targets[0];
      return {
        x: target.baseX + target.width / 2,
        y: target.baseY + target.height / 2,
      };
    }
    const averageX = targets.reduce((sum, target) => sum + target.baseX + target.width / 2, 0) / targets.length;
    const averageY = targets.reduce((sum, target) => sum + target.baseY + target.height / 2, 0) / targets.length;
    const anchor = targets.find((target) => target.unit.id === clash.anchorTargetId) ?? targets[0];
    return {
      x: averageX,
      y: (averageY + anchor.baseY + anchor.height / 2) / 2,
    };
  }

  private getMeleeTravelDistance(progress: number, maxPush: number, hitCount: number) {
    const keyframes =
      hitCount >= 2
        ? [
            { progress: 0, distance: 0 },
            { progress: 0.28, distance: maxPush },
            { progress: 0.40, distance: maxPush * 0.8 },
            { progress: 0.56, distance: maxPush },
            { progress: 0.7, distance: maxPush * 0.92 },
            { progress: 1, distance: 0 },
          ]
        : [
            { progress: 0, distance: 0 },
            { progress: 0.46, distance: maxPush },
            { progress: 0.62, distance: maxPush },
            { progress: 1, distance: 0 },
          ];

    for (let index = 1; index < keyframes.length; index += 1) {
      const previous = keyframes[index - 1];
      const current = keyframes[index];
      if (progress <= current.progress) {
        const span = Math.max(0.0001, current.progress - previous.progress);
        const t = Math.max(0, Math.min(1, (progress - previous.progress) / span));
        const eased = Math.sin(t * Math.PI * 0.5);
        return previous.distance + (current.distance - previous.distance) * eased;
      }
    }

    return 0;
  }

  private getHitEnvelope(progress: number, hitMoment: number, halfWidth: number) {
    const start = hitMoment - halfWidth;
    const end = hitMoment + halfWidth;
    if (progress <= start || progress >= end) {
      return 0;
    }
    return (progress - start) / Math.max(0.0001, end - start);
  }

  private isMeleeUnit(unit: UnitState) {
    // Web-only heuristic: Ranger (class 5) looks/feels ranged in this prototype,
    // while healer (class 6) still uses a melee weapon basic attack.
    return (unit.classId >= 1 && unit.classId <= 4) || unit.classId === 6;
  }

  private isDamageLikeOp(op: string) {
    // Some Lua skills emit an explicit "attack" timeline op before damage is resolved.
    // Treat it as an attack frame so basics / counters / extra attacks also get motion.
    return op === "damage" || op === "chain_damage" || op === "attack";
  }

  private looksLikeProjectileEffect(effect: string) {
    const normalized = String(effect ?? "").toLowerCase();
    return /projectile|fire|ball|ice|arrow|bolt|orb|arc|lightning|missile|shard/.test(normalized);
  }

  private looksLikeMeleeHitEffect(effect: string) {
    const normalized = String(effect ?? "").toLowerCase();
    // Many melee skills use op="effect" + "*_execute" handlers (e.g. random_hits_damage, poison_burst).
    // This heuristic enables a clash animation without changing combat logic.
    return /_execute\b|execute\b/.test(normalized);
  }

  private resolveProjectileStyle(effect: string, classId: number): ProjectileStyle {
    const normalized = String(effect ?? "").toLowerCase();

    if (normalized.includes("lightning") || classId === 9) {
      return {
        kind: "lightning",
        core: "#fff3b0",
        glow: "rgba(255, 242, 179, 0.82)",
        trail: "rgba(173, 216, 255, 0.8)",
        radius: 7,
        arcHeight: 18,
      };
    }

    if (normalized.includes("fire") || classId === 7) {
      return {
        kind: "orb",
        core: "#ff9f1c",
        glow: "rgba(255, 69, 0, 0.78)",
        trail: "rgba(255, 140, 0, 0.58)",
        radius: 9,
        arcHeight: 26,
      };
    }

    if (normalized.includes("ice") || classId === 8) {
      return {
        kind: "shard",
        core: "#caf0f8",
        glow: "rgba(76, 201, 240, 0.82)",
        trail: "rgba(173, 232, 244, 0.64)",
        radius: 8,
        arcHeight: 34,
      };
    }

    if (normalized.includes("poison") || classId === 5) {
      return {
        kind: "orb",
        core: "#b7efc5",
        glow: "rgba(46, 204, 113, 0.78)",
        trail: "rgba(46, 204, 113, 0.52)",
        radius: 8,
        arcHeight: 22,
      };
    }

    if (normalized.includes("holy") || classId === 6 || classId === 4) {
      return {
        kind: "orb",
        core: "#fff3b0",
        glow: "rgba(255, 243, 176, 0.82)",
        trail: "rgba(255, 209, 102, 0.56)",
        radius: 9,
        arcHeight: 26,
      };
    }

    if (normalized.includes("poison") || normalized.includes("venom") || classId === 5) {
      return {
        kind: "orb",
        core: "#b7efc5",
        glow: "rgba(82, 183, 136, 0.78)",
        trail: "rgba(128, 237, 153, 0.48)",
        radius: 8,
        arcHeight: 24,
      };
    }

    return {
      kind: "orb",
      core: "#ff9f1c",
      glow: "rgba(255, 127, 80, 0.82)",
      trail: "rgba(255, 209, 102, 0.52)",
      radius: 10,
      arcHeight: 28,
    };
  }

  private drawProjectileAnimations(ctx: CanvasRenderingContext2D, layouts: UnitLayout[], now: number) {
    for (const projectile of this.projectiles) {
      const attacker = layouts.find((layout) => layout.unit.id === projectile.attackerId);
      const target = layouts.find((layout) => layout.unit.id === projectile.targetId);
      if (!attacker || !target) {
        continue;
      }

      const elapsed = now - projectile.startedAt;
      if (elapsed < 0 || elapsed > projectile.durationMs) {
        continue;
      }

      const progress = Math.max(0, Math.min(1, elapsed / projectile.durationMs));
      const start = this.getCardEdgePoint(attacker, target);
      const end = this.getCardEdgePoint(target, attacker);
      const control = this.getProjectileControlPoint(start, end, projectile.style.arcHeight);
      const point = this.getQuadraticPoint(start, control, end, progress);

      ctx.save();

      if (projectile.style.kind === "lightning") {
        this.drawLightningArc(ctx, start, control, end, progress, projectile.style);
      } else {
        const trailPoint = this.getQuadraticPoint(start, control, end, Math.max(0, progress - 0.12));
        ctx.strokeStyle = projectile.style.trail;
        ctx.lineWidth = projectile.style.radius;
        ctx.lineCap = "round";
        ctx.globalAlpha = 0.42;
        ctx.beginPath();
        ctx.moveTo(trailPoint.x, trailPoint.y);
        ctx.lineTo(point.x, point.y);
        ctx.stroke();

        ctx.shadowColor = projectile.style.glow;
        ctx.shadowBlur = 24;
        ctx.fillStyle = projectile.style.core;

        if (projectile.style.kind === "shard") {
          ctx.translate(point.x, point.y);
          const angle = Math.atan2(end.y - start.y, end.x - start.x);
          ctx.rotate(angle);
          ctx.beginPath();
          ctx.moveTo(10, 0);
          ctx.lineTo(0, 6);
          ctx.lineTo(-10, 0);
          ctx.lineTo(0, -6);
          ctx.closePath();
          ctx.fill();
        } else {
          ctx.beginPath();
          ctx.arc(point.x, point.y, projectile.style.radius, 0, Math.PI * 2);
          ctx.fill();
        }
      }

      ctx.restore();
    }
  }

  private drawLightningArc(
    ctx: CanvasRenderingContext2D,
    start: { x: number; y: number },
    control: { x: number; y: number },
    end: { x: number; y: number },
    progress: number,
    style: ProjectileStyle,
  ) {
    const steps = 10;
    const points: Array<{ x: number; y: number }> = [];
    const completedSteps = Math.max(2, Math.round(steps * progress));

    for (let step = 0; step <= completedSteps; step += 1) {
      const t = step / steps;
      const point = this.getQuadraticPoint(start, control, end, Math.min(t, progress));
      const wobble = step > 0 && step < completedSteps ? (step % 2 === 0 ? -10 : 10) : 0;
      points.push({ x: point.x + wobble, y: point.y });
    }

    ctx.strokeStyle = style.glow;
    ctx.lineWidth = 4;
    ctx.lineCap = "round";
    ctx.shadowColor = style.glow;
    ctx.shadowBlur = 16;
    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);
    for (let index = 1; index < points.length; index += 1) {
      ctx.lineTo(points[index].x, points[index].y);
    }
    ctx.stroke();

    const last = points[points.length - 1];
    ctx.fillStyle = style.core;
    ctx.beginPath();
    ctx.arc(last.x, last.y, style.radius, 0, Math.PI * 2);
    ctx.fill();
  }

  private drawImpactBursts(ctx: CanvasRenderingContext2D, layouts: UnitLayout[], now: number) {
    for (const burst of this.impactBursts) {
      const layout = layouts.find((candidate) => candidate.unit.id === burst.unitId);
      if (!layout) {
        continue;
      }

      const elapsed = now - (burst.startedAt + burst.delayMs);
      if (elapsed < 0 || elapsed > burst.durationMs) {
        continue;
      }

      const progress = elapsed / burst.durationMs;
      const centerX = layout.x + layout.width / 2;
      const centerY = layout.y + layout.height / 2;
      const radius = burst.size * (0.55 + progress * 0.65);

      ctx.save();
      ctx.globalAlpha = 1 - progress;
      ctx.fillStyle = burst.color;
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius * 0.72, 0, Math.PI * 2);
      ctx.fill();
      ctx.strokeStyle = burst.ringColor;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }
  }

  private getCardEdgePoint(source: UnitLayout, target: UnitLayout) {
    const sourceCenterX = source.x + source.width / 2;
    const sourceCenterY = source.y + source.height / 2;
    const targetCenterY = target.y + target.height / 2;
    const sourceIsAbove = sourceCenterY <= targetCenterY;

    return {
      x: sourceCenterX,
      y: sourceIsAbove ? source.y + source.height - 10 : source.y + 10,
    };
  }

  private getProjectileControlPoint(
    start: { x: number; y: number },
    end: { x: number; y: number },
    arcHeight: number,
  ) {
    const midX = (start.x + end.x) / 2;
    const midY = (start.y + end.y) / 2;
    const horizontalBend = Math.max(-64, Math.min(64, (end.x - start.x) * 0.18));
    const verticalLift = Math.max(26, Math.abs(end.y - start.y) * 0.22) + arcHeight;
    return {
      x: midX + horizontalBend,
      y: midY - verticalLift,
    };
  }

  private getQuadraticPoint(
    start: { x: number; y: number },
    control: { x: number; y: number },
    end: { x: number; y: number },
    t: number,
  ) {
    const invT = 1 - t;
    return {
      x: invT * invT * start.x + 2 * invT * t * control.x + t * t * end.x,
      y: invT * invT * start.y + 2 * invT * t * control.y + t * t * end.y,
    };
  }
}
