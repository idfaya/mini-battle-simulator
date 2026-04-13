import type { AnimationEvent, UnitState } from "../types/battle";

export type FloatingText = {
  text: string;
  color: string;
  createdAt: number;
  emphasis: boolean;
};

export function createFloatingText(event: AnimationEvent, unit: UnitState | undefined, now: number): FloatingText | null {
  if (!unit) {
    return null;
  }

  if (event.type === "damage") {
    return {
      text: `-${event.value}`,
      color: event.critical ? "#ff6b6b" : "#ffd166",
      createdAt: now,
      emphasis: event.critical,
    };
  }

  if (event.type === "heal") {
    return {
      text: `+${event.value}`,
      color: "#80ed99",
      createdAt: now,
      emphasis: false,
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
  if (elapsed > 900) {
    return false;
  }

  const progress = elapsed / 900;
  ctx.save();
  ctx.globalAlpha = 1 - progress;
  ctx.fillStyle = text.color;
  ctx.font = text.emphasis ? "bold 24px sans-serif" : "20px sans-serif";
  ctx.textAlign = "center";
  ctx.fillText(text.text, originX, originY - progress * 42);
  ctx.restore();
  return true;
}
