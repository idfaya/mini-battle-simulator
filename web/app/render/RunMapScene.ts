import type { RunMapNodeState, RunSnapshot } from "../types/roguelike";

type FloorBucket = {
  floor: number;
  nodes: RunMapNodeState[];
  gridW: number;
  gridH: number;
};

const HEADER_HEIGHT = 110;
const ROOM_SIZE = 64;
const ROOM_GAP = 22;
const SIDE_PADDING = 32;
const BOTTOM_PADDING = 48;

type RunMapDebugState = {
  totalNodes: number;
  revealedNodes: number;
  hiddenNodes: number;
  drawnRooms: number;
  drawnFogRooms: number;
  drawnEdges: number;
};

export class RunMapScene {
  private lastDebugState: RunMapDebugState = {
    totalNodes: 0,
    revealedNodes: 0,
    hiddenNodes: 0,
    drawnRooms: 0,
    drawnFogRooms: 0,
    drawnEdges: 0,
  };
  private fogPattern: CanvasPattern | null = null;

  /**
   * Used by CanvasRenderer to decide whether we should grow the canvas.
   * 单层平面图通常一屏可以放下，但窄屏 / 大网格仍可能溢出。
   */
  getPreferredCanvasHeight(width: number, snapshot: RunSnapshot | null) {
    if (!snapshot?.map) {
      return null;
    }
    const bucket = pickActiveFloor(snapshot);
    if (!bucket) {
      return null;
    }
    const layout = computeFloorLayout(width, bucket);
    return layout.totalHeight;
  }

  draw(ctx: CanvasRenderingContext2D, width: number, height: number, snapshot: RunSnapshot | null) {
    ctx.clearRect(0, 0, width, height);
    this.drawBackground(ctx, width, height);
    this.lastDebugState = {
      totalNodes: 0,
      revealedNodes: 0,
      hiddenNodes: 0,
      drawnRooms: 0,
      drawnFogRooms: 0,
      drawnEdges: 0,
    };

    if (!snapshot?.map) {
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "24px sans-serif";
      ctx.fillText("地图加载中...", width / 2 - 70, height / 2);
      return;
    }

    const bucket = pickActiveFloor(snapshot);
    if (!bucket) {
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "16px sans-serif";
      ctx.fillText("地图无房间", 42, 140);
      return;
    }

    const revealedNodes = countRevealed(bucket);
    this.lastDebugState = {
      totalNodes: bucket.nodes.length,
      revealedNodes,
      hiddenNodes: Math.max(0, bucket.nodes.length - revealedNodes),
      drawnRooms: 0,
      drawnFogRooms: 0,
      drawnEdges: 0,
    };

    const layout = computeFloorLayout(width, bucket);

    // Position lookup
    const nodePositions = new Map<number, { x: number; y: number; revealed: boolean }>();
    const visibleNodeIds = new Set<number>();
    const visibleEdges: Array<{ fromX: number; fromY: number; toX: number; toY: number; bothRevealed: boolean }> = [];
    for (const placement of layout.placements) {
      nodePositions.set(placement.node.id, {
        x: placement.x,
        y: placement.y,
        revealed: placement.node.revealed,
      });
      if (placement.node.revealed) {
        visibleNodeIds.add(placement.node.id);
      }
    }

    // Floor plate
    ctx.fillStyle = "rgba(255,255,255,0.04)";
    ctx.fillRect(layout.plateX, layout.plateY, layout.plateW, layout.plateH);
    ctx.strokeStyle = "rgba(255,255,255,0.08)";
    ctx.lineWidth = 1;
    ctx.strokeRect(
      layout.plateX + 0.5,
      layout.plateY + 0.5,
      layout.plateW - 1,
      layout.plateH - 1,
    );

    // Doors（迷雾两端的门完全隐藏；至少一端可见才显示，强度按可见度差异化）
    for (const edge of snapshot.map.edges ?? []) {
      const from = nodePositions.get(edge.fromNodeId);
      const to = nodePositions.get(edge.toNodeId);
      if (!from || !to) {
        continue;
      }
      if (!from.revealed && !to.revealed) {
        continue;
      }
      visibleNodeIds.add(edge.fromNodeId);
      visibleNodeIds.add(edge.toNodeId);
      const bothRevealed = from.revealed && to.revealed;
      visibleEdges.push({
        fromX: from.x,
        fromY: from.y,
        toX: to.x,
        toY: to.y,
        bothRevealed,
      });
    }

    this.drawUnexploredFog(ctx, layout);

    for (const edge of visibleEdges) {
      ctx.strokeStyle = edge.bothRevealed ? "rgba(255,255,255,0.36)" : "rgba(255,255,255,0.16)";
      ctx.lineWidth = 4;
      ctx.lineCap = "round";
      ctx.beginPath();
      ctx.moveTo(edge.fromX, edge.fromY);
      ctx.lineTo(edge.toX, edge.toY);
      ctx.stroke();
      this.lastDebugState.drawnEdges += 1;
    }

    // Rooms
    for (const placement of layout.placements) {
      if (!visibleNodeIds.has(placement.node.id)) {
        continue;
      }
      if (placement.node.revealed) {
        this.drawRoom(ctx, placement.x, placement.y, placement.node, layout.cellSize);
        this.lastDebugState.drawnRooms += 1;
      } else {
        this.drawFogRoom(ctx, placement.x, placement.y, layout.cellSize, placement.node.selectable);
        this.lastDebugState.drawnFogRooms += 1;
      }
    }

    // Header
    ctx.fillStyle = "#f8f9fa";
    ctx.font = "bold 28px sans-serif";
    ctx.textAlign = "left";
    ctx.textBaseline = "alphabetic";
    ctx.fillText(`Act 1 · Chapter ${snapshot.chapterId}`, 42, 50);

    ctx.font = "14px sans-serif";
    ctx.fillText(
      `金币 ${snapshot.gold} · 装备 ${snapshot.equipments.length} · 祝福 ${snapshot.blessings.length}`,
      42,
      74,
    );

    ctx.fillStyle = "rgba(255,255,255,0.85)";
    ctx.font = "bold 14px sans-serif";
    const floorLabel = bucket.floor === 9 ? "隐藏层" : `第 ${bucket.floor} 层`;
    ctx.fillText(`${floorLabel} · ${countRevealed(bucket)} / ${bucket.nodes.length} 房间已探索`, 42, 96);
  }

  getDebugState() {
    return { ...this.lastDebugState };
  }

  private drawBackground(ctx: CanvasRenderingContext2D, width: number, height: number) {
    const gradient = ctx.createLinearGradient(0, 0, width, height);
    gradient.addColorStop(0, "#12263a");
    gradient.addColorStop(1, "#0b1320");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
  }

  private drawUnexploredFog(
    ctx: CanvasRenderingContext2D,
    layout: FloorRenderLayout,
  ) {
    ctx.save();
    ctx.beginPath();
    ctx.rect(layout.plateX, layout.plateY, layout.plateW, layout.plateH);
    ctx.clip();

    // 底色：弥漫整层的暗色蒙版
    ctx.fillStyle = "rgba(6, 12, 22, 0.55)";
    ctx.fillRect(layout.plateX, layout.plateY, layout.plateW, layout.plateH);

    // 斜线 hatch pattern：覆盖整张地图
    const pattern = this.getFogPattern(ctx);
    if (pattern) {
      ctx.fillStyle = pattern;
      ctx.fillRect(layout.plateX, layout.plateY, layout.plateW, layout.plateH);
    }

    ctx.restore();
  }

  private getFogPattern(ctx: CanvasRenderingContext2D): CanvasPattern | null {
    if (this.fogPattern) {
      return this.fogPattern;
    }
    const tileSize = 12;
    const tile = document.createElement("canvas");
    tile.width = tileSize;
    tile.height = tileSize;
    const tctx = tile.getContext("2d");
    if (!tctx) {
      return null;
    }
    tctx.clearRect(0, 0, tileSize, tileSize);
    tctx.strokeStyle = "rgba(220, 230, 245, 0.18)";
    tctx.lineWidth = 1.5;
    tctx.lineCap = "square";
    // 主斜线
    tctx.beginPath();
    tctx.moveTo(-2, tileSize + 2);
    tctx.lineTo(tileSize + 2, -2);
    tctx.stroke();
    // 平铺接缝补线
    tctx.beginPath();
    tctx.moveTo(-2, 2);
    tctx.lineTo(2, -2);
    tctx.stroke();
    tctx.beginPath();
    tctx.moveTo(tileSize - 2, tileSize + 2);
    tctx.lineTo(tileSize + 2, tileSize - 2);
    tctx.stroke();

    this.fogPattern = ctx.createPattern(tile, "repeat");
    return this.fogPattern;
  }


  private drawRoom(ctx: CanvasRenderingContext2D, cx: number, cy: number, node: RunMapNodeState, cellSize: number) {
    const color = node.isHiddenFloor
      ? { fill: "#5a189a", stroke: "#e0aaff" }
      : this.getNodeColor(node.nodeType);
    const half = cellSize / 2;
    ctx.save();

    ctx.beginPath();
    ctx.rect(cx - half, cy - half, cellSize, cellSize);
    ctx.fillStyle = node.current ? "#ffd166" : color.fill;
    ctx.fill();

    ctx.lineWidth = node.selectable ? 4 : node.visited ? 2 : 1.5;
    ctx.strokeStyle = node.selectable ? "#80ed99" : color.stroke;
    ctx.stroke();

    ctx.fillStyle = "#0b1320";
    ctx.font = "bold 16px sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(this.getNodeShortLabel(node.nodeType), cx, cy - 2);

    const title = node.titleVisible ? node.title : this.getNodeTypeLabel(node.nodeType);
    ctx.fillStyle = node.selectable || node.current ? "#f8f9fa" : "rgba(255,255,255,0.7)";
    ctx.font = "11px sans-serif";
    ctx.textBaseline = "alphabetic";
    ctx.fillText(title, cx, cy + half + 14);

    if (node.visited && !node.current) {
      ctx.fillStyle = "rgba(0,0,0,0.25)";
      ctx.fillRect(cx - half, cy - half, cellSize, cellSize);
    }

    ctx.restore();
  }

  private drawFogRoom(ctx: CanvasRenderingContext2D, cx: number, cy: number, cellSize: number, selectable: boolean) {
    const half = cellSize / 2;
    ctx.save();

    ctx.beginPath();
    ctx.rect(cx - half, cy - half, cellSize, cellSize);
    ctx.fillStyle = "rgba(20, 28, 40, 0.55)";
    ctx.fill();

    ctx.setLineDash([4, 4]);
    ctx.strokeStyle = selectable ? "#80ed99" : "rgba(255,255,255,0.18)";
    ctx.lineWidth = selectable ? 3 : 1.5;
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.fillStyle = selectable ? "rgba(255,255,255,0.85)" : "rgba(255,255,255,0.45)";
    ctx.font = "bold 18px sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText("?", cx, cy);

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
      case "equip":
        return "箱";
      case "stair_up":
        return "↑";
      case "stair_down":
        return "↓";
      case "entrance":
        return "入";
      case "empty":
        return "·";
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
      case "equip":
        return { fill: "#bdb2ff", stroke: "#e0d7ff" };
      case "stair_up":
      case "stair_down":
        return { fill: "#adb5bd", stroke: "#e9ecef" };
      case "entrance":
        return { fill: "#52b788", stroke: "#b7e4c7" };
      case "empty":
        return { fill: "#3a4756", stroke: "#7a8694" };
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
      case "equip":
        return "宝箱房";
      case "stair_up":
        return "上楼梯";
      case "stair_down":
        return "下楼梯";
      case "entrance":
        return "入口";
      case "empty":
        return "空房间";
      default:
        return "未知";
    }
  }
}

function bucketByFloor(nodes: RunMapNodeState[]): Map<number, FloorBucket> {
  const map = new Map<number, FloorBucket>();
  for (const node of nodes) {
    const floor = node.floor ?? 1;
    let bucket = map.get(floor);
    if (!bucket) {
      bucket = { floor, nodes: [], gridW: node.floorGridW ?? 4, gridH: node.floorGridH ?? 4 };
      map.set(floor, bucket);
    }
    bucket.nodes.push(node);
    if (node.floorGridW && node.floorGridW > bucket.gridW) {
      bucket.gridW = node.floorGridW;
    }
    if (node.floorGridH && node.floorGridH > bucket.gridH) {
      bucket.gridH = node.floorGridH;
    }
  }
  for (const bucket of map.values()) {
    if (!bucket.nodes.some((node) => node.gridX != null)) {
      // 配置缺失 grid 时退化为单行布局，避免画面空白。
      bucket.nodes.sort((a, b) => (a.lane ?? 0) - (b.lane ?? 0));
      bucket.nodes.forEach((node, index) => {
        node.gridX = index + 1;
        node.gridY = 1;
      });
      bucket.gridW = bucket.nodes.length;
      bucket.gridH = 1;
    }
  }
  return map;
}

function pickActiveFloor(snapshot: RunSnapshot): FloorBucket | null {
  const map = snapshot.map;
  if (!map || map.nodes.length === 0) {
    return null;
  }
  const buckets = bucketByFloor(map.nodes);
  const explicit = snapshot.currentFloorDepth;
  if (explicit != null && buckets.has(explicit)) {
    return buckets.get(explicit) ?? null;
  }
  // Fallback：从当前节点反推楼层。
  if (snapshot.currentNodeId != null) {
    const current = map.nodes.find((node) => node.id === snapshot.currentNodeId);
    if (current && buckets.has(current.floor)) {
      return buckets.get(current.floor) ?? null;
    }
  }
  // 最后再退化到最低楼层。
  const sorted = [...buckets.values()].sort((a, b) => a.floor - b.floor);
  return sorted[0] ?? null;
}

function countRevealed(bucket: FloorBucket) {
  let n = 0;
  for (const node of bucket.nodes) {
    if (node.revealed) {
      n++;
    }
  }
  return n;
}

type FloorRenderLayout = {
  plateX: number;
  plateY: number;
  plateW: number;
  plateH: number;
  cellSize: number;
  totalHeight: number;
  placements: { node: RunMapNodeState; x: number; y: number }[];
};

function computeFloorLayout(width: number, bucket: FloorBucket): FloorRenderLayout {
  const gridW = Math.max(1, bucket.gridW);
  const gridH = Math.max(1, bucket.gridH);

  const usableWidth = Math.max(120, width - SIDE_PADDING * 2);
  let cellSize = ROOM_SIZE;
  if (gridW * (ROOM_SIZE + ROOM_GAP) - ROOM_GAP > usableWidth) {
    cellSize = Math.max(28, Math.floor((usableWidth - ROOM_GAP * (gridW - 1)) / gridW));
  }
  const stepX = cellSize + ROOM_GAP;
  const stepY = cellSize + ROOM_GAP;
  const floorWidth = gridW * stepX - ROOM_GAP;
  const floorHeight = gridH * stepY - ROOM_GAP;

  // 横向居中
  const plateX = Math.max(SIDE_PADDING - 8, Math.floor((width - floorWidth) / 2) - 8);
  const plateY = HEADER_HEIGHT;
  const plateW = floorWidth + 16;
  const plateH = floorHeight + 16 + 12;

  const originX = plateX + 8 + cellSize / 2;
  const originY = plateY + 8 + cellSize / 2;

  const placements: { node: RunMapNodeState; x: number; y: number }[] = [];
  for (const node of bucket.nodes) {
    const gx = Math.max(1, node.gridX ?? 1);
    const gy = Math.max(1, node.gridY ?? 1);
    placements.push({
      node,
      x: originX + (gx - 1) * stepX,
      y: originY + (gy - 1) * stepY,
    });
  }

  return {
    plateX,
    plateY,
    plateW,
    plateH,
    cellSize,
    totalHeight: plateY + plateH + BOTTOM_PADDING,
    placements,
  };
}
