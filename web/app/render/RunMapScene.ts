import type { RunSnapshot } from "../types/roguelike";

export class RunMapScene {
  /**
   * Used by CanvasRenderer to decide whether we should grow the canvas and rely on native scrolling.
   * Only meaningful for portrait/mobile layouts where vertical map may exceed the viewport.
   */
  getPreferredCanvasHeight(width: number, snapshot: RunSnapshot | null) {
    if (!snapshot?.map) {
      return null;
    }
    // Portrait/mobile: floors stacked vertically.
    const isPortrait = width <= 720;
    if (!isPortrait) {
      return null;
    }
    const top = 110;
    const bottom = 64;
    const floorGap = 112;
    return top + (snapshot.map.floorCount - 1) * floorGap + bottom;
  }

  draw(ctx: CanvasRenderingContext2D, width: number, height: number, snapshot: RunSnapshot | null) {
    ctx.clearRect(0, 0, width, height);
    this.drawBackground(ctx, width, height);

    if (!snapshot?.map) {
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "24px sans-serif";
      ctx.fillText("地图加载中...", width / 2 - 70, height / 2);
      return;
    }

    const map = snapshot.map;
    const nodesByFloor = new Map<number, typeof map.nodes>();
    for (const node of map.nodes) {
      const bucket = nodesByFloor.get(node.floor) ?? [];
      bucket.push(node);
      nodesByFloor.set(node.floor, bucket);
    }

    const nodePositions = new Map<number, { x: number; y: number }>();
    const isPortrait = width <= 720;
    const top = 110;
    const left = 120;
    const right = 120;
    const floorGap = 112;

    if (isPortrait) {
      // Vertical map: floors stacked from top -> bottom, lanes spread on X.
      for (let floor = 1; floor <= map.floorCount; floor += 1) {
        const floorNodes = [...(nodesByFloor.get(floor) ?? [])].sort((a, b) => a.lane - b.lane);
        const usableWidth = Math.max(1, width - left - right);
        const maxGap = 160;
        const laneGap =
          floorNodes.length <= 1 ? 0 : Math.min(maxGap, Math.floor(usableWidth / Math.max(1, floorNodes.length - 1)));
        const startX = width / 2 - ((floorNodes.length - 1) * laneGap) / 2;
        for (let index = 0; index < floorNodes.length; index += 1) {
          const node = floorNodes[index];
          nodePositions.set(node.id, {
            x: startX + index * laneGap,
            y: top + (floor - 1) * floorGap,
          });
        }
      }
    } else {
      // Desktop map: keep the original left->right layout.
      for (let floor = 1; floor <= map.floorCount; floor += 1) {
        const floorNodes = [...(nodesByFloor.get(floor) ?? [])].sort((a, b) => a.lane - b.lane);
        const laneGap = floorNodes.length <= 1 ? 0 : 160;
        const startY = height / 2 - ((floorNodes.length - 1) * laneGap) / 2;
        for (let index = 0; index < floorNodes.length; index += 1) {
          const node = floorNodes[index];
          nodePositions.set(node.id, {
            x: left + (floor - 1) * floorGap,
            y: startY + index * laneGap,
          });
        }
      }
    }

    for (const edge of map.edges ?? []) {
      const from = nodePositions.get(edge.fromNodeId);
      if (!from) {
        continue;
      }
      const to = nodePositions.get(edge.toNodeId);
      if (!to) {
        continue;
      }
      ctx.strokeStyle = "rgba(255,255,255,0.1)";
      ctx.lineWidth = 2;
      ctx.beginPath();
      if (isPortrait) {
        ctx.moveTo(from.x, from.y + 18);
        ctx.lineTo(to.x, to.y - 18);
      } else {
        ctx.moveTo(from.x + 18, from.y);
        ctx.lineTo(to.x - 18, to.y);
      }
      ctx.stroke();
    }

    for (const node of map.nodes) {
      const pos = nodePositions.get(node.id);
      if (!pos) {
        continue;
      }
      this.drawNode(ctx, pos.x, pos.y, node);
    }

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "bold 28px sans-serif";
    ctx.fillText(`Act 1 · Chapter ${snapshot.chapterId}`, 42, 50);
    ctx.font = "14px sans-serif";
    ctx.fillText(`金币 ${snapshot.gold} · 装备 ${snapshot.equipments.length} · 祝福 ${snapshot.blessings.length}`, 42, 74);

    ctx.fillStyle = "rgba(255,255,255,0.7)";
    ctx.font = "13px sans-serif";
    // Put the hint near the header so it stays visible even when the canvas becomes scrollable.
    ctx.fillText("地图为竖向推进（手机可上下滑动查看）。", 42, 96);
  }

  private drawBackground(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const gradient = ctx.createLinearGradient(0, 0, width, height);
    gradient.addColorStop(0, "#12263a");
    gradient.addColorStop(1, "#0b1320");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
  }

  private drawNode(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    node: RunSnapshot["map"]["nodes"][number],
  ) {
    const color = this.getNodeColor(node.nodeType);
    ctx.save();
    ctx.beginPath();
    ctx.arc(x, y, 24, 0, Math.PI * 2);
    ctx.fillStyle = node.current ? "#ffd166" : color.fill;
    ctx.fill();
    ctx.lineWidth = node.selectable ? 4 : node.visited ? 2 : 1;
    ctx.strokeStyle = node.selectable ? "#80ed99" : color.stroke;
    ctx.stroke();

    ctx.fillStyle = "#0b1320";
    ctx.font = "bold 12px sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(this.getNodeShortLabel(node.nodeType), x, y);

    const title = node.titleVisible ? node.title : this.getNodeTypeLabel(node.nodeType);
    ctx.fillStyle = node.selectable || node.current ? "#f8f9fa" : "rgba(255,255,255,0.6)";
    ctx.font = "12px sans-serif";
    ctx.fillText(title, x, y + 42);
    ctx.restore();
  }

  private getNodeShortLabel(nodeType: string) {
    switch (nodeType) {
      case "battle_normal":
        return "战";
      case "battle_elite":
        return "精";
      case "event":
        return "事";
      case "shop":
        return "商";
      case "camp":
        return "营";
      case "recruit":
        return "募";
      case "boss":
        return "B";
      default:
        return "?";
    }
  }

  private getNodeColor(nodeType: string) {
    switch (nodeType) {
      case "battle_normal":
        return { fill: "#4cc9f0", stroke: "#a9def9" };
      case "battle_elite":
        return { fill: "#ef476f", stroke: "#ffb3c1" };
      case "event":
        return { fill: "#ffd166", stroke: "#ffe29a" };
      case "shop":
        return { fill: "#06d6a0", stroke: "#93f5d8" };
      case "camp":
        return { fill: "#118ab2", stroke: "#8ecae6" };
      case "recruit":
        return { fill: "#ff9f1c", stroke: "#ffd6a5" };
      case "boss":
        return { fill: "#8338ec", stroke: "#d0b3ff" };
      default:
        return { fill: "#65748b", stroke: "#d9e2ec" };
    }
  }

  private getNodeTypeLabel(nodeType: string) {
    switch (nodeType) {
      case "battle_normal":
        return "普通战";
      case "battle_elite":
        return "精英战";
      case "event":
        return "事件";
      case "shop":
        return "商店";
      case "camp":
        return "营地";
      case "recruit":
        return "招募";
      case "boss":
        return "Boss";
      default:
        return "未知";
    }
  }
}
