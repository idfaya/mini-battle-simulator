import { BattleScene } from "./BattleScene";
import type { BattleStoreState } from "../state/battleStore";
import { RunMapScene } from "./RunMapScene";
import type { RunSnapshot } from "../types/roguelike";

export class CanvasRenderer {
  readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly scene = new BattleScene();
  private readonly runMapScene = new RunMapScene();
  private displayWidth = 960;
  private displayHeight = 760;

  constructor() {
    this.canvas = document.createElement("canvas");
    this.canvas.width = 960;
    this.canvas.height = 760;
    const context = this.canvas.getContext("2d");
    if (!context) {
      throw new Error("Canvas 2D context is not available");
    }
    this.ctx = context;
  }

  resizeToDisplaySize() {
    const rect = this.canvas.getBoundingClientRect();
    const displayWidth = Math.max(1, Math.round(rect.width));
    const displayHeight = Math.max(1, Math.round(rect.height));
    const pixelRatio = Math.max(1, Math.min(3, Math.round(window.devicePixelRatio || 1)));
    const backingWidth = displayWidth * pixelRatio;
    const backingHeight = displayHeight * pixelRatio;

    if (this.canvas.width !== backingWidth || this.canvas.height !== backingHeight) {
      this.canvas.width = backingWidth;
      this.canvas.height = backingHeight;
    }
    this.displayWidth = displayWidth;
    this.displayHeight = displayHeight;
    this.ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
  }

  render(state: BattleStoreState, now: number) {
    this.resizeToDisplaySize();
    this.scene.draw(this.ctx, this.displayWidth, this.displayHeight, state, now);
  }

  renderBattle(state: BattleStoreState, now: number) {
    this.resizeToDisplaySize();
    this.scene.draw(this.ctx, this.displayWidth, this.displayHeight, state, now);
  }

  renderMap(snapshot: RunSnapshot | null) {
    const preferredHeight = this.runMapScene.getPreferredCanvasHeight(this.displayWidth, snapshot);
    if (preferredHeight != null) {
      // Let the canvas become taller than the viewport; the stage container will provide native scrolling.
      this.canvas.style.height = `${Math.max(1, Math.round(preferredHeight))}px`;
    } else {
      // Reset to normal behavior (CSS drives height).
      this.canvas.style.height = "";
    }
    this.resizeToDisplaySize();
    this.runMapScene.draw(this.ctx, this.displayWidth, this.displayHeight, snapshot);
  }
}
