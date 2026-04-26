import type { AnimationEvent, UnitState } from "../types/battle";

export type FloatingText = {
  text: string;
  color: string;
  createdAt: number;
  emphasis: boolean;
  lifetimeMs: number;
};

export function createFloatingText(event: AnimationEvent, unit: UnitState | undefined, now: number): FloatingText | null {
  if (!unit) {
    return null;
  }

  if (event.type === "damage") {
    return {
      text: event.critical ? `暴击 ${event.value}` : `-${event.value}`,
      color: event.critical ? "#ff4d6d" : "#ffd166",
      createdAt: now,
      emphasis: event.critical,
      lifetimeMs: event.critical ? 1400 : 1000,
    };
  }

  if (event.type === "heal") {
    return {
      text: `+${event.value}`,
      color: "#80ed99",
      createdAt: now,
      emphasis: false,
      lifetimeMs: 1000,
    };
  }

  if (event.type === "miss") {
    return {
      text: event.text,
      color: "#f8f9fa",
      createdAt: now,
      emphasis: true,
      lifetimeMs: 1200,
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
  const scale = text.emphasis ? 1 + (1 - progress) * 0.18 : 1;
  ctx.save();
  ctx.globalAlpha = 1 - progress;
  ctx.fillStyle = text.color;
  ctx.font = text.emphasis ? `bold ${Math.round(28 * scale)}px sans-serif` : "20px sans-serif";
  ctx.textAlign = "center";
  if (text.emphasis) {
    ctx.strokeStyle = "rgba(20, 8, 12, 0.75)";
    ctx.lineWidth = 4;
    ctx.strokeText(text.text, originX, originY - progress * 42);
  }
  ctx.fillText(text.text, originX, originY - progress * 42);
  ctx.restore();
  return true;
}
