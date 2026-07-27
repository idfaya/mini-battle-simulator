import type { RunMapNodeState, RunSnapshot, RunTeamMember } from "../types/roguelike";

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
const MINIMAP_WIDTH = 260;
const MINIMAP_HEIGHT = 210;
const MINIMAP_PADDING = 18;

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
   * 地图已收束为小地图，canvas 始终保持战场比例。
   */
  getPreferredCanvasHeight(_width: number, _snapshot: RunSnapshot | null) {
    return null;
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

    const currentNode = getCurrentNode(snapshot, bucket);
    this.drawDungeonStage(ctx, width, height, snapshot, bucket, currentNode);
    this.drawMiniMap(ctx, width, bucket, snapshot.map.edges ?? []);
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

  private drawDungeonStage(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    snapshot: RunSnapshot,
    bucket: FloorBucket,
    currentNode: RunMapNodeState | null,
  ) {
    if (width < 520) {
      this.drawMobileDungeonStage(ctx, width, height, snapshot, bucket, currentNode);
      return;
    }

    const floorLabel = bucket.floor === 9 ? "隐藏层" : `第 ${bucket.floor} 层`;
    const nodeType = currentNode?.nodeType ?? "empty";
    const nodeColor = this.getNodeColor(nodeType);
    const title = currentNode?.titleVisible ? currentNode.title : this.getNodeTypeLabel(nodeType);
    const phaseCopy = getPhaseCopy(snapshot, currentNode);

    ctx.save();

    const wallGradient = ctx.createLinearGradient(0, 0, 0, height);
    wallGradient.addColorStop(0, "#17263a");
    wallGradient.addColorStop(0.58, "#0f1a2a");
    wallGradient.addColorStop(1, "#090f19");
    ctx.fillStyle = wallGradient;
    ctx.fillRect(0, 0, width, height);

    ctx.fillStyle = "rgba(255,255,255,0.04)";
    ctx.fillRect(28, 34, Math.max(240, width - 56), Math.max(220, height - 90));
    ctx.strokeStyle = "rgba(255,255,255,0.1)";
    ctx.lineWidth = 1;
    ctx.strokeRect(28.5, 34.5, Math.max(240, width - 57), Math.max(220, height - 91));

    const floorY = Math.floor(height * 0.68);
    const floorGradient = ctx.createLinearGradient(0, floorY, 0, height);
    floorGradient.addColorStop(0, "rgba(47, 59, 76, 0.62)");
    floorGradient.addColorStop(1, "rgba(11, 19, 32, 0.95)");
    ctx.fillStyle = floorGradient;
    ctx.beginPath();
    ctx.moveTo(28, floorY);
    ctx.lineTo(width - 28, floorY);
    ctx.lineTo(width - 10, height);
    ctx.lineTo(10, height);
    ctx.closePath();
    ctx.fill();

    this.drawStageDoor(ctx, width * 0.5, floorY - 80, Math.min(210, width * 0.22), 210, nodeColor);
    this.drawExitHints(ctx, width, floorY, snapshot, currentNode);
    this.drawPartySilhouettes(ctx, width, floorY);

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "700 26px sans-serif";
    ctx.textAlign = "left";
    ctx.textBaseline = "alphabetic";
    ctx.fillText(`Act ${snapshot.chapterId === 101 ? 1 : snapshot.chapterId} · ${floorLabel}`, 42, 58);

    ctx.fillStyle = "rgba(255,255,255,0.72)";
    ctx.font = "13px sans-serif";
    ctx.fillText(`金币 ${snapshot.gold} · 装备 ${snapshot.equipments.length} · 祝福 ${snapshot.blessings.length}`, 42, 82);

    ctx.fillStyle = nodeColor.stroke;
    ctx.font = "700 16px sans-serif";
    ctx.fillText(getPhaseLabel(snapshot.phase), 42, 122);

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "800 34px sans-serif";
    ctx.fillText(title || "未知房间", 42, 164);

    ctx.fillStyle = "rgba(217,226,236,0.9)";
    ctx.font = "15px sans-serif";
    wrapText(ctx, phaseCopy, 42, 194, Math.max(280, Math.min(520, width - MINIMAP_WIDTH - 96)), 22);

    ctx.restore();
  }

  private drawStageDoor(
    ctx: CanvasRenderingContext2D,
    cx: number,
    cy: number,
    doorWidth: number,
    doorHeight: number,
    color: { fill: string; stroke: string },
  ) {
    const half = doorWidth / 2;
    ctx.save();
    ctx.fillStyle = "rgba(3, 7, 12, 0.72)";
    ctx.fillRect(cx - half, cy - doorHeight / 2, doorWidth, doorHeight);
    ctx.strokeStyle = color.stroke;
    ctx.lineWidth = 3;
    ctx.strokeRect(cx - half + 0.5, cy - doorHeight / 2 + 0.5, doorWidth - 1, doorHeight - 1);
    ctx.fillStyle = "rgba(255,255,255,0.05)";
    ctx.fillRect(cx - half + 10, cy - doorHeight / 2 + 10, doorWidth - 20, doorHeight - 20);
    ctx.fillStyle = color.fill;
    ctx.globalAlpha = 0.22;
    ctx.fillRect(cx - half + 18, cy - doorHeight / 2 + 18, doorWidth - 36, doorHeight - 36);
    ctx.restore();
  }

  private drawExitHints(
    ctx: CanvasRenderingContext2D,
    width: number,
    floorY: number,
    snapshot: RunSnapshot,
    currentNode: RunMapNodeState | null,
  ) {
    const selectable = snapshot.map?.nodes.filter((node) => node.selectable) ?? [];
    if (!currentNode || selectable.length === 0) {
      return;
    }
    const labels = selectable
      .map((node) => {
        const dir = getDirectionLabel(currentNode, node);
        return dir ? `${dir}门` : "可移动";
      })
      .slice(0, 4);
    ctx.save();
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.font = "700 13px sans-serif";
    ctx.fillStyle = "rgba(128,237,153,0.9)";
    const startX = width / 2 - (labels.length - 1) * 54;
    labels.forEach((label, index) => {
      const x = startX + index * 108;
      ctx.fillStyle = "rgba(36,95,75,0.55)";
      ctx.strokeStyle = "rgba(128,237,153,0.42)";
      ctx.lineWidth = 1;
      roundRect(ctx, x - 42, floorY + 34, 84, 28, 14);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = "#d8ffe0";
      ctx.fillText(label, x, floorY + 48);
    });
    ctx.restore();
  }

  private drawPartySilhouettes(ctx: CanvasRenderingContext2D, width: number, floorY: number) {
    ctx.save();
    const startX = width * 0.22;
    for (let index = 0; index < 4; index += 1) {
      const x = startX + index * 38;
      const y = floorY + 44 + (index % 2) * 8;
      ctx.fillStyle = index % 2 === 0 ? "rgba(248,249,250,0.72)" : "rgba(217,226,236,0.62)";
      ctx.beginPath();
      ctx.arc(x, y - 22, 8, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillRect(x - 6, y - 14, 12, 30);
      ctx.fillStyle = "rgba(0,0,0,0.22)";
      ctx.fillRect(x - 10, y + 16, 20, 5);
    }
    ctx.restore();
  }

  private drawMobileDungeonStage(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    snapshot: RunSnapshot,
    bucket: FloorBucket,
    currentNode: RunMapNodeState | null,
  ) {
    const floorLabel = bucket.floor === 9 ? "隐藏层" : `第 ${bucket.floor} 层`;
    const nodeType = currentNode?.nodeType ?? "empty";
    const nodeColor = this.getNodeColor(nodeType);
    const title = currentNode?.titleVisible ? currentNode.title : this.getNodeTypeLabel(nodeType);
    const phaseCopy = getPhaseCopy(snapshot, currentNode);
    const topH = Math.max(210, Math.floor(height * 0.42));
    const partyTop = topH + 10;
    const partyBottom = Math.max(partyTop + 160, height - 12);

    ctx.save();
    const wallGradient = ctx.createLinearGradient(0, 0, 0, height);
    wallGradient.addColorStop(0, "#111724");
    wallGradient.addColorStop(0.55, "#0d1119");
    wallGradient.addColorStop(1, "#07090d");
    ctx.fillStyle = wallGradient;
    ctx.fillRect(0, 0, width, height);

    // 上半部：竖版房间 / 地图区域。
    ctx.fillStyle = "rgba(255,255,255,0.035)";
    roundRect(ctx, 8, 8, width - 16, topH - 8, 16);
    ctx.fill();
    ctx.strokeStyle = "rgba(255,255,255,0.12)";
    ctx.lineWidth = 1;
    ctx.stroke();

    const floorY = Math.floor(topH * 0.72);
    const roomGradient = ctx.createLinearGradient(0, 8, 0, topH);
    roomGradient.addColorStop(0, "#1a2332");
    roomGradient.addColorStop(1, "#0d1119");
    ctx.fillStyle = roomGradient;
    roundRect(ctx, 9, 9, width - 18, topH - 10, 15);
    ctx.fill();

    ctx.strokeStyle = "rgba(232,213,176,0.14)";
    ctx.beginPath();
    ctx.moveTo(width * 0.12, floorY - 54);
    ctx.lineTo(width * 0.88, floorY - 54);
    ctx.moveTo(width * 0.22, floorY - 6);
    ctx.lineTo(width * 0.78, floorY - 6);
    ctx.stroke();

    this.drawStageDoor(ctx, width * 0.5, Math.max(58, topH * 0.26), Math.min(92, width * 0.24), 86, nodeColor);

    if (snapshot.phase === "event" && snapshot.eventState) {
      ctx.fillStyle = "rgba(214,168,80,0.12)";
      ctx.strokeStyle = "rgba(241,209,135,0.58)";
      roundRect(ctx, width * 0.5 - 58, floorY - 86, 116, 66, 12);
      ctx.fill();
      ctx.stroke();
      ctx.fillStyle = "#f1d187";
      ctx.font = "700 13px sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(snapshot.eventState.title || "事件", width * 0.5, floorY - 58, 104);
    }

    ctx.fillStyle = "#f8f9fa";
    ctx.textAlign = "left";
    ctx.textBaseline = "alphabetic";
    ctx.font = "700 15px sans-serif";
    ctx.fillText(`Act ${snapshot.chapterId === 101 ? 1 : snapshot.chapterId} · ${floorLabel}`, 18, 32);
    ctx.fillStyle = nodeColor.stroke;
    ctx.font = "700 12px sans-serif";
    ctx.fillText(getPhaseLabel(snapshot.phase), 18, 54);
    ctx.fillStyle = "#f8f9fa";
    ctx.font = "800 21px sans-serif";
    ctx.fillText(title || "未知房间", 18, 82, width - 126);
    ctx.fillStyle = "rgba(217,226,236,0.82)";
    ctx.font = "12px sans-serif";
    wrapText(ctx, phaseCopy, 18, 104, Math.max(180, width - 130), 17);

    // 下半部：与战斗阵容一致的 3 列前后排单位卡。
    this.drawMobilePartyFormation(ctx, width, Math.min(partyBottom, height - 8), partyTop, snapshot.team);
    ctx.restore();
  }

  private drawMobilePartyFormation(
    ctx: CanvasRenderingContext2D,
    width: number,
    bottom: number,
    top: number,
    team: RunTeamMember[],
  ) {
    const left = 8;
    const w = width - 16;
    const h = Math.max(150, bottom - top);
    ctx.save();
    ctx.fillStyle = "rgba(9,17,30,0.66)";
    roundRect(ctx, left, top, w, h, 16);
    ctx.fill();
    ctx.strokeStyle = "rgba(255,255,255,0.12)";
    ctx.lineWidth = 1;
    ctx.stroke();

    ctx.fillStyle = "rgba(217,226,236,0.78)";
    ctx.font = "700 12px sans-serif";
    ctx.textAlign = "left";
    ctx.fillText("队伍阵列", left + 12, top + 22);
    ctx.fillStyle = "rgba(217,226,236,0.48)";
    ctx.font = "11px sans-serif";
    ctx.fillText("3 列前后排 / 战斗单位卡", left + 78, top + 22, width - 100);

    const gap = 7;
    const cardW = Math.floor((w - 24 - gap * 2) / 3);
    const cardH = Math.max(54, Math.floor((h - 44 - gap) / 2));
    const startX = left + 12;
    const startY = top + 34;
    const slots: Array<RunTeamMember | null> = [
      team[0] ?? null,
      team[1] ?? null,
      team[2] ?? null,
      team[3] ?? null,
      team[4] ?? null,
      team[5] ?? null,
    ];
    slots.forEach((member, index) => {
      const col = index % 3;
      const row = Math.floor(index / 3);
      const x = startX + col * (cardW + gap);
      const y = startY + row * (cardH + gap);
      this.drawMobileUnitCard(ctx, x, y, cardW, cardH, member);
    });
    ctx.restore();
  }

  private drawMobileUnitCard(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    width: number,
    height: number,
    member: RunTeamMember | null,
  ) {
    ctx.save();
    if (!member) {
      ctx.strokeStyle = "rgba(255,255,255,0.12)";
      ctx.setLineDash([4, 4]);
      roundRect(ctx, x, y, width, height, 12);
      ctx.stroke();
      ctx.setLineDash([]);
      ctx.restore();
      return;
    }

    const dead = member.isDead || member.hp <= 0;
    const fillGradient = ctx.createLinearGradient(0, y, 0, y + height);
    fillGradient.addColorStop(0, "rgba(25,40,36,0.96)");
    fillGradient.addColorStop(1, "rgba(12,15,22,0.96)");
    ctx.fillStyle = fillGradient;
    roundRect(ctx, x, y, width, height, 12);
    ctx.fill();
    ctx.strokeStyle = dead ? "rgba(255,255,255,0.18)" : "rgba(128,237,153,0.46)";
    ctx.lineWidth = 1.5;
    ctx.stroke();

    const badgeSize = 18;
    ctx.fillStyle = this.getClassBadgeFill(member.classId);
    ctx.strokeStyle = "rgba(159,179,200,0.72)";
    roundRect(ctx, x + 7, y + 7, badgeSize, badgeSize, badgeSize / 2);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#f8f9fa";
    ctx.font = "700 11px sans-serif";
    ctx.textAlign = "left";
    ctx.textBaseline = "alphabetic";
    ctx.fillText(member.name, x + 31, y + 21, Math.max(20, width - 66));

    const levelText = `Lv${Math.max(1, Math.floor(Number(member.level) || 1))}`;
    ctx.fillStyle = "rgba(128,237,153,0.14)";
    ctx.strokeStyle = "rgba(128,237,153,0.44)";
    roundRect(ctx, x + width - 34, y + 7, 27, 16, 8);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = "#f8f9fa";
    ctx.font = "700 8px sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(levelText, x + width - 20.5, y + 15);

    const hpRate = member.maxHp > 0 ? Math.max(0, Math.min(1, member.hp / member.maxHp)) : 0;
    const hpY = y + Math.max(31, height - 25);
    this.drawBar(ctx, x + 8, hpY, width - 16, 8, hpRate, this.getHpBarColor(hpRate), "#263238");
    ctx.fillStyle = "#f8f9fa";
    ctx.font = "700 7px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(`${Math.max(0, Math.floor(member.hp))}/${Math.floor(member.maxHp)}`, x + width / 2, hpY + 4);

    for (let index = 0; index < 3; index += 1) {
      const bx = x + 8 + index * 15;
      const by = hpY + 12;
      ctx.fillStyle = index === 0 ? "rgba(128,237,153,0.16)" : "rgba(255,255,255,0.05)";
      ctx.strokeStyle = index === 0 ? "rgba(128,237,153,0.58)" : "rgba(255,255,255,0.16)";
      roundRect(ctx, bx, by, 12, 12, 3);
      ctx.fill();
      ctx.stroke();
    }

    if (dead) {
      ctx.fillStyle = "rgba(0,0,0,0.46)";
      roundRect(ctx, x, y, width, height, 12);
      ctx.fill();
      ctx.fillStyle = "#f8f9fa";
      ctx.font = "700 10px sans-serif";
      ctx.textAlign = "center";
      ctx.fillText("DEFEATED", x + width / 2, y + height / 2 + 3, width - 8);
    }
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
    roundRect(ctx, x, y, width, height, height / 2);
    ctx.fill();
    ctx.fillStyle = fill;
    roundRect(ctx, x, y, Math.max(0, width * Math.max(0, Math.min(1, rate))), height, height / 2);
    ctx.fill();
  }

  private getHpBarColor(rate: number) {
    if (rate <= 0.25) return "#ef476f";
    if (rate <= 0.5) return "#ffd166";
    return "#80ed99";
  }

  private getClassBadgeFill(classId: number) {
    if (classId >= 1 && classId <= 5) return "#243b53";
    if (classId >= 6 && classId <= 9) return "#3d3650";
    return "#2e4634";
  }

  private drawMiniMap(
    ctx: CanvasRenderingContext2D,
    width: number,
    bucket: FloorBucket,
    edges: Array<{ fromNodeId: number; toNodeId: number }>,
  ) {
    const mobile = width < 520;
    const mapW = mobile ? 96 : Math.min(MINIMAP_WIDTH, Math.max(190, width * 0.32));
    const mapH = mobile ? 96 : MINIMAP_HEIGHT;
    const x = Math.max(mobile ? 10 : 24, width - mapW - (mobile ? 10 : MINIMAP_PADDING));
    const y = mobile ? 10 : MINIMAP_PADDING;
    const layout = computeMiniMapLayout(x, y, mapW, mapH, bucket);
    const positions = new Map<number, { x: number; y: number; revealed: boolean }>();
    const visibleNodeIds = new Set<number>();

    ctx.save();
    ctx.fillStyle = "rgba(5,10,18,0.72)";
    roundRect(ctx, x, y, mapW, mapH, 14);
    ctx.fill();
    ctx.strokeStyle = "rgba(255,255,255,0.14)";
    ctx.lineWidth = 1;
    ctx.stroke();

    ctx.fillStyle = "rgba(255,255,255,0.86)";
    ctx.font = mobile ? "700 9px sans-serif" : "700 13px sans-serif";
    ctx.textAlign = "left";
    ctx.fillText(mobile ? "MAP" : "小地图", x + (mobile ? 8 : 14), y + (mobile ? 16 : 24));

    for (const placement of layout.placements) {
      positions.set(placement.node.id, {
        x: placement.x,
        y: placement.y,
        revealed: placement.node.revealed,
      });
      if (placement.node.revealed) {
        visibleNodeIds.add(placement.node.id);
      }
    }

    for (const edge of edges) {
      const from = positions.get(edge.fromNodeId);
      const to = positions.get(edge.toNodeId);
      if (!from || !to || (!from.revealed && !to.revealed)) {
        continue;
      }
      visibleNodeIds.add(edge.fromNodeId);
      visibleNodeIds.add(edge.toNodeId);
      ctx.strokeStyle = from.revealed && to.revealed ? "rgba(255,255,255,0.42)" : "rgba(255,255,255,0.18)";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(from.x, from.y);
      ctx.lineTo(to.x, to.y);
      ctx.stroke();
      this.lastDebugState.drawnEdges += 1;
    }

    for (const placement of layout.placements) {
      if (!visibleNodeIds.has(placement.node.id)) {
        continue;
      }
      if (placement.node.revealed) {
        this.drawMiniRoom(ctx, placement.x, placement.y, placement.node, layout.cellSize);
        this.lastDebugState.drawnRooms += 1;
      } else {
        this.drawMiniFogRoom(ctx, placement.x, placement.y, layout.cellSize, placement.node.selectable);
        this.lastDebugState.drawnFogRooms += 1;
      }
    }
    ctx.restore();
  }

  private drawMiniRoom(ctx: CanvasRenderingContext2D, cx: number, cy: number, node: RunMapNodeState, cellSize: number) {
    const color = node.isHiddenFloor ? { fill: "#5a189a", stroke: "#e0aaff" } : this.getNodeColor(node.nodeType);
    const half = cellSize / 2;
    ctx.save();
    ctx.fillStyle = node.current ? "#ffd166" : color.fill;
    ctx.fillRect(cx - half, cy - half, cellSize, cellSize);
    ctx.strokeStyle = node.selectable ? "#80ed99" : color.stroke;
    ctx.lineWidth = node.current ? 3 : node.selectable ? 2.5 : 1;
    ctx.strokeRect(cx - half + 0.5, cy - half + 0.5, cellSize - 1, cellSize - 1);
    ctx.fillStyle = "#07111e";
    ctx.font = `700 ${Math.max(10, Math.floor(cellSize * 0.48))}px sans-serif`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(this.getNodeShortLabel(node.nodeType), cx, cy);
    if (node.visited && !node.current) {
      ctx.fillStyle = "rgba(0,0,0,0.22)";
      ctx.fillRect(cx - half, cy - half, cellSize, cellSize);
    }
    ctx.restore();
  }

  private drawMiniFogRoom(ctx: CanvasRenderingContext2D, cx: number, cy: number, cellSize: number, selectable: boolean) {
    const half = cellSize / 2;
    ctx.save();
    ctx.fillStyle = "rgba(20,28,40,0.66)";
    ctx.fillRect(cx - half, cy - half, cellSize, cellSize);
    ctx.setLineDash([3, 3]);
    ctx.strokeStyle = selectable ? "#80ed99" : "rgba(255,255,255,0.22)";
    ctx.lineWidth = selectable ? 2 : 1;
    ctx.strokeRect(cx - half + 0.5, cy - half + 0.5, cellSize - 1, cellSize - 1);
    ctx.setLineDash([]);
    ctx.fillStyle = "rgba(255,255,255,0.62)";
    ctx.font = `700 ${Math.max(10, Math.floor(cellSize * 0.5))}px sans-serif`;
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

function getCurrentNode(snapshot: RunSnapshot, bucket: FloorBucket): RunMapNodeState | null {
  if (snapshot.currentNodeId != null) {
    return bucket.nodes.find((node) => node.id === snapshot.currentNodeId) ?? null;
  }
  return bucket.nodes.find((node) => node.current) ?? null;
}

function getPhaseLabel(phase: RunSnapshot["phase"]) {
  switch (phase) {
    case "map":
      return "探索";
    case "stair":
      return "楼梯";
    case "event":
      return "事件";
    case "shop":
      return "商店";
    case "camp":
      return "营地";
    case "reward":
      return "结算";
    case "chapter_result":
      return "章节结果";
    case "failed":
      return "失败";
    default:
      return "地牢";
  }
}

function getPhaseCopy(snapshot: RunSnapshot, currentNode: RunMapNodeState | null) {
  if (snapshot.phase === "map") {
    const exits = snapshot.map?.nodes.filter((node) => node.selectable).length ?? 0;
    return exits > 0
      ? `队伍停在${currentNode?.titleVisible ? currentNode.title : "当前房间"}。选择一扇门继续推进，迷宫定位保留在右上角。`
      : "本层暂时没有可用出口。";
  }
  if (snapshot.phase === "stair") {
    return snapshot.stairState?.isHiddenEntrance
      ? "隐藏入口已打开，队伍可以从这里进入额外楼层。"
      : "楼梯连接上下层，使用后会切换当前探索楼层。";
  }
  if (snapshot.phase === "event") {
    return snapshot.eventState?.title
      ? `${snapshot.eventState.title} 正在当前房间内展开，事件按钮显示在事件物件旁。`
      : "事件正在当前房间内展开，事件按钮显示在事件物件旁。";
  }
  if (snapshot.phase === "shop") {
    return snapshot.shopState?.name
      ? `${snapshot.shopState.name} 就在这个房间，购买时队伍状态保持可见。`
      : "商店交易在当前房间完成，购买时队伍状态保持可见。";
  }
  if (snapshot.phase === "camp") {
    return snapshot.campState?.name
      ? `${snapshot.campState.name} 提供本层休整，处理后回到探索。`
      : "营地提供本层休整，处理后回到探索。";
  }
  if (snapshot.phase === "reward") {
    return "战利品和升级选择在当前房间结算，确认后继续探索。";
  }
  if (snapshot.phase === "chapter_result") {
    return "章节已经结束，队伍本次地牢推进结果已确定。";
  }
  if (snapshot.phase === "failed") {
    return "队伍已经无法继续推进，本次 Run 失败。";
  }
  return snapshot.lastActionMessage || "队伍正在地牢中推进。";
}

function getDirectionLabel(currentNode: RunMapNodeState, target: RunMapNodeState) {
  if (currentNode.gridX == null || currentNode.gridY == null || target.gridX == null || target.gridY == null) {
    return "";
  }
  const dx = target.gridX - currentNode.gridX;
  const dy = target.gridY - currentNode.gridY;
  if (dx === 0 && dy < 0) return "上";
  if (dx === 0 && dy > 0) return "下";
  if (dy === 0 && dx < 0) return "左";
  if (dy === 0 && dx > 0) return "右";
  return "";
}

function wrapText(
  ctx: CanvasRenderingContext2D,
  text: string,
  x: number,
  y: number,
  maxWidth: number,
  lineHeight: number,
) {
  const chars = Array.from(text);
  let line = "";
  let lineY = y;
  for (const char of chars) {
    const nextLine = line + char;
    if (ctx.measureText(nextLine).width > maxWidth && line !== "") {
      ctx.fillText(line, x, lineY);
      line = char;
      lineY += lineHeight;
    } else {
      line = nextLine;
    }
  }
  if (line !== "") {
    ctx.fillText(line, x, lineY);
  }
}

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  const radius = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + w - radius, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + radius);
  ctx.lineTo(x + w, y + h - radius);
  ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h);
  ctx.lineTo(x + radius, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}

function computeMiniMapLayout(
  x: number,
  y: number,
  width: number,
  height: number,
  bucket: FloorBucket,
): { cellSize: number; placements: { node: RunMapNodeState; x: number; y: number }[] } {
  const gridW = Math.max(1, bucket.gridW);
  const gridH = Math.max(1, bucket.gridH);
  const compact = width < 120 || height < 120;
  const pad = compact ? 8 : 18;
  const titleReserve = compact ? 22 : 42;
  const innerX = x + pad;
  const innerY = y + titleReserve;
  const innerW = Math.max(40, width - pad * 2);
  const innerH = Math.max(40, height - titleReserve - (compact ? 8 : 16));
  const gap = compact ? 4 : 8;
  const cellSize = Math.max(
    compact ? 8 : 14,
    Math.min(compact ? 18 : 30, Math.floor(Math.min((innerW - gap * (gridW - 1)) / gridW, (innerH - gap * (gridH - 1)) / gridH))),
  );
  const mapW = gridW * cellSize + (gridW - 1) * gap;
  const mapH = gridH * cellSize + (gridH - 1) * gap;
  const originX = innerX + (innerW - mapW) / 2 + cellSize / 2;
  const originY = innerY + (innerH - mapH) / 2 + cellSize / 2;
  const placements: { node: RunMapNodeState; x: number; y: number }[] = [];
  for (const node of bucket.nodes) {
    const gx = Math.max(1, node.gridX ?? 1);
    const gy = Math.max(1, node.gridY ?? 1);
    placements.push({
      node,
      x: originX + (gx - 1) * (cellSize + gap),
      y: originY + (gy - 1) * (cellSize + gap),
    });
  }
  return { cellSize, placements };
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
