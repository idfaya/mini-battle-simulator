import { BattleScene } from "./BattleScene";
import type { BattleStoreState } from "../state/battleStore";
import { RunMapScene } from "./RunMapScene";
import type { RunSnapshot } from "../types/roguelike";

export class CanvasRenderer {
  readonly canvas: HTMLCanvasElement;
  private readonly ctx: CanvasRenderingContext2D;
  private readonly scene = new BattleScene();
  private readonly runMapScene = new RunMapScene(this.scene);
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
    // Reset any inline height left over from renderMap so the battle canvas
    // is sized by CSS (constrained to the stage container) instead of inheriting
    // the tall map height which would push the bottom rows out of view.
    if (this.canvas.style.height !== "") {
      this.canvas.style.height = "";
    }
    this.resizeToDisplaySize();
    this.scene.draw(this.ctx, this.displayWidth, this.displayHeight, state, now);
  }

  setSelectableTargetIds(targetIds: string[]) {
    this.scene.setSelectableTargetIds(targetIds);
    this.canvas.style.cursor = targetIds.length > 0 ? "crosshair" : "";
  }

  pickBattleUnit(clientX: number, clientY: number) {
    const rect = this.canvas.getBoundingClientRect();
    if (rect.width <= 0 || rect.height <= 0) {
      return null;
    }
    const x = ((clientX - rect.left) / rect.width) * this.displayWidth;
    const y = ((clientY - rect.top) / rect.height) * this.displayHeight;
    return this.scene.pickUnitAt(x, y);
  }

  renderMap(snapshot: RunSnapshot | null) {
    const preferredHeight = this.runMapScene.getPreferredCanvasHeight(this.displayWidth, snapshot);
    if (preferredHeight != null) {
      // Let the canvas become taller than the viewport; the stage container wis provide native scrolling.
      this.canvas.style.height = `${Math.max(1, Math.round(preferredHeight))}px`;
    } else {
      // Reset to normal behavior (CSS drives height).
      this.canvas.style.height = "";
    }
    this.resizeToDisplaySize();
    this.runMapScene.draw(this.ctx, this.displayWidth, this.displayHeight, snapshot);
  }

  getBattleDebugState() {
    return this.scene.getDebugState();
  }

  getRunMapDebugState() {
    return this.runMapScene.getDebugState();
  }
}
