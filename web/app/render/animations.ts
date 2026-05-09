import type { AnimationEvent, UnitState } from "../types/battle";

export type FloatingText = {
  text: string;
  kind: "damage" | "critical" | "heal" | "miss";
  color: string;
  outlineColor: string;
  createdAt: number;
  lifetimeMs: number;
  fontSize: number;
  startScale: number;
  endScale: number;
  riseY: number;
  driftX: number;
  rotationFrom: number;
  glowColor: string | null;
};

export function createFloatingText(event: AnimationEvent, unit: UnitState | undefined, now: number): FloatingText | null {
  if (!unit) {
    return null;
  }

  if (event.type === "damage") {
    return {
      text: event.value > 0 ? String(event.value) : "0",
      kind: event.critical ? "critical" : "damage",
      color: event.critical ? "#ffe08a" : "#ffb36b",
      outlineColor: event.critical ? "rgba(58, 20, 10, 0.92)" : "rgba(42, 18, 10, 0.9)",
      createdAt: now,
      lifetimeMs: event.critical ? 780 : 620,
      fontSize: event.critical ? 30 : 22,
      startScale: event.critical ? 1.22 : 1.08,
      endScale: 1,
      riseY: event.critical ? 30 : 22,
      driftX: event.critical ? 4 : 2,
      rotationFrom: 0,
      glowColor: event.critical ? "rgba(255, 184, 77, 0.45)" : null,
    };
  }

  if (event.type === "heal") {
    return {
      text: `+${event.value}`,
      kind: "heal",
      color: "#80ed99",
      outlineColor: "rgba(10, 42, 22, 0.82)",
      createdAt: now,
      lifetimeMs: 720,
      fontSize: 22,
      startScale: 1.06,
      endScale: 1,
      riseY: 20,
      driftX: 1,
      rotationFrom: 0,
      glowColor: "rgba(128, 237, 153, 0.25)",
    };
  }

  if (event.type === "miss") {
    const isDodge = String(event.text ?? "").toUpperCase().includes("DODGE");
    return {
      text: event.text,
      kind: "miss",
      color: isDodge ? "#a9def9" : "#f8f9fa",
      outlineColor: "rgba(8, 18, 30, 0.82)",
      createdAt: now,
      lifetimeMs: 440,
      fontSize: 20,
      startScale: 1,
      endScale: 0.96,
      riseY: 18,
      driftX: isDodge ? 10 : -10,
      rotationFrom: isDodge ? 0.12 : -0.12,
      glowColor: null,
    };
  }

  return null;
}

export function drawFloatingText(
  ctx: CanvasRenderingContext2D,
  text: FloatingText,
  originX: number,
  originY: number,
  now: number,
) {
  const elapsed = now - text.createdAt;
  if (elapsed > text.lifetimeMs) {
    return false;
  }

  const progress = elapsed / text.lifetimeMs;
  const easedOut = 1 - Math.pow(1 - progress, 3);
  const fadeStart = text.kind === "critical" ? 0.5 : text.kind === "miss" ? 0.3 : 0.42;
  const fadeProgress = Math.max(0, (progress - fadeStart) / Math.max(0.001, 1 - fadeStart));
  const alpha = 1 - fadeProgress;
  const scale = text.startScale + (text.endScale - text.startScale) * easedOut;
  const offsetX = text.driftX * Math.sin(progress * Math.PI);
  const offsetY = progress * text.riseY;
  const rotation = text.rotationFrom * (1 - easedOut);
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.translate(originX + offsetX, originY - offsetY);
  ctx.rotate(rotation);
  ctx.scale(scale, scale);
  if (text.glowColor) {
    ctx.shadowColor = text.glowColor;
    ctx.shadowBlur = 14;
  }
  ctx.fillStyle = text.color;
  ctx.font = `bold ${text.fontSize}px sans-serif`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.lineJoin = "round";
  ctx.miterLimit = 2;
  ctx.strokeStyle = text.outlineColor;
  ctx.lineWidth = text.kind === "critical" ? 6 : 4;
  ctx.strokeText(text.text, 0, 0);
  if (text.kind === "critical") {
    ctx.lineWidth = 2;
    ctx.strokeStyle = "rgba(255, 244, 179, 0.72)";
    ctx.strokeText(text.text, 0, 0);
  }
  ctx.fillText(text.text, 0, 0);
  ctx.restore();
  return true;
}
