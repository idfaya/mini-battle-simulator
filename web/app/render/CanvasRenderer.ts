import { BattleScene } from "./BattleScene";
import type { BattleStoreState } from "../state/battleStore";

export class CanvasRenderer {
  readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly scene = new BattleScene();

  constructor() {
    this.canvas = document.createElement("canvas");
    this.canvas.width = 960;
    this.canvas.height = 640;
    const context = this.canvas.getContext("2d");
    if (!context) {
      throw new Error("Canvas 2D context is not available");
    }
    this.ctx = context;
  }

  render(state: BattleStoreState, now: number) {
    this.scene.draw(this.ctx, this.canvas.width, this.canvas.height, state, now);
  }
}
