# Mini Battle Web 可视化方案

> 记录时间: 2026-04-09  
> 方案类型: 服务器驱动 + 轻前端架构  
> 预估工期: 1-2 天

---

## 1. 架构概述

### 1.1 核心思路
采用**服务器驱动**架构：
- Lua 战斗逻辑完全复用，不做改动
- 新增 WebRenderer 订阅 BattleVisualEvents
- 通过 WebSocket 实时推送事件到浏览器
- 前端 Canvas 负责纯展示，无业务逻辑

```
┌─────────────────────────────────────────────────────────────┐
│  Lua 战斗服务器 (mini-battle-simulator)                      │
│  ├─ BattleMain (战斗逻辑)                                    │
│  ├─ BattleVisualEvents (事件系统) ← 已存在                   │
│  └─ WebRenderer (新增) ──► WebSocket 推送                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ WebSocket
┌─────────────────────────────────────────────────────────────┐
│  浏览器 (HTML5 Canvas)                                       │
│  ├─ 战斗场景渲染 (Canvas 2D)                                 │
│  ├─ 动画系统 (伤害飘字、技能特效)                            │
│  └─ UI 控制 (速度、暂停、回看)                               │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 为什么选这个方案

| 优势 | 说明 |
|-----|------|
| **复用现有代码** | Lua 战斗逻辑完全不用改，只需加 WebRenderer |
| **事件系统现成** | BattleVisualEvents 已有 20+ 种事件，直接转发 |
| **前后端解耦** | 前端只负责展示，逻辑在服务端，易调试 |
| **支持多人观看** | WebSocket 广播，多人可同时观战 |
| **天然录像回放** | 事件日志序列化即可回放 |

---

## 2. UI 设计

### 2.1 界面布局

```
┌────────────────────────────────────────────────────────────────┐
│  ⚔️ Mini Battle                          [速度 x1]  [⏸ 暂停]   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│    ╔══════════╗  ╔══════════╗         ╔══════════╗            │
│    ║ ♀️ 亚瑟  ║  ║ ⚔️ 关羽  ║         ║ 👹 魔王  ║            │
│    ║ HP ████░ ║  ║ HP █████ ║         ║ HP ███░░ ║            │
│    ║ EN [◆◆◇] ║  ║ EN [◆◆◆] ║         ║ EN [◆◆◆] ║            │
│    ╚══════════╝  ╚══════════╝         ╚══════════╝            │
│                                                                │
│    ╔══════════╗                       ╔══════════╗            │
│    ║ 🔮 法师  ║                       ║ 💀 骷髅  ║            │
│    ║ HP ███░░ ║                       ║ HP ██░░░ ║            │
│    ║ EN [◆◇◇] ║                       ║ EN [◆◆◇] ║            │
│    ╚══════════╝                       ╚══════════╝            │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  🎲 第 12 回合  → 亚瑟 使用 火球术 → 魔王 造成 150 伤害        │
│                                                                │
│  ───────────────────────────────────────────────────────────  │
│  > 关羽 使用 重击 对 骷髅 造成 120 伤害                        │
│  > 魔王 反击 对 亚瑟 造成 45 伤害                              │
│  > 骷髅 被击败了！                                             │
├────────────────────────────────────────────────────────────────┤
│  [开始战斗]  [重置]  [保存录像]  [分享]                        │
└────────────────────────────────────────────────────────────────┘
```

### 2.2 视觉元素

| 元素 | 实现方式 |
|-----|---------|
| 英雄头像 | Emoji 图标 (♀️⚔️🔮👹💀) |
| HP 条 | Canvas 渐变矩形 (绿→黄→红) |
| 能量条 | 点数型显示 [◆◆◇] |
| Buff 图标 | 小圆角方块 + 层数数字 |
| 伤害数字 | Canvas 浮动动画，暴击红色放大 |
| 技能特效 | 弹道、爆炸、光束等 Canvas 粒子效果 |

---

## 3. 技术实现

### 3.1 后端模块 (Lua)

| 文件 | 职责 |
|-----|------|
| `web/web_server.lua` | HTTP 服务器，提供静态文件服务 |
| `web/web_socket.lua` | WebSocket 服务器，管理客户端连接 |
| `web/web_renderer.lua` | 订阅 BattleVisualEvents，转 JSON 推送 |
| `web/web_event_bridge.lua` | 事件序列化/反序列化 |

### 3.2 前端模块 (JavaScript)

| 文件 | 职责 |
|-----|------|
| `web/static/index.html` | 主页面 |
| `web/static/css/style.css` | 样式 |
| `web/static/js/main.js` | 入口，初始化 |
| `web/static/js/renderer.js` | Canvas 渲染器主循环 |
| `web/static/js/battle_scene.js` | 战斗场景管理（英雄位置、HP条） |
| `web/static/js/hero_card.js` | 英雄卡片渲染 |
| `web/static/js/animations.js` | 动画系统（飘字、抖动、特效） |
| `web/static/js/skill_effect.js` | 技能特效（弹道、爆炸） |
| `web/static/js/ws_client.js` | WebSocket 客户端 |
| `web/static/js/battle_log.js` | 战斗日志面板 |

### 3.3 关键技术栈

| 模块 | 技术方案 | 说明 |
|-----|---------|------|
| 实时通信 | WebSocket (lua-websocket) | 原生 Lua 实现 |
| 前端渲染 | HTML5 Canvas 2D | 无框架依赖 |
| 动画系统 | requestAnimationFrame | 60fps 流畅动画 |
| 数据格式 | JSON | 与 BattleVisualEvents 对应 |
| 资源 | Emoji + CSS 渐变 | 零外部依赖 |

---

## 4. 通信协议

### 4.1 服务端 → 客户端 事件

| 事件类型 | Lua 事件 | 数据字段 |
|---------|---------|---------|
| 战斗开始 | `BATTLE_STARTED` | teamLeft, teamRight |
| 回合开始 | `TURN_STARTED` | round, heroId, heroName |
| 伤害 | `DAMAGE_DEALT` | attackerId, targetId, damage, isCrit |
| 治疗 | `HEAL_RECEIVED` | healerId, targetId, healAmount |
| 技能释放 | `SKILL_CAST_STARTED` | heroId, skillId, skillName, targets |
| Buff 添加 | `BUFF_ADDED` | targetId, buffId, buffName, stackCount |
| Buff 移除 | `BUFF_REMOVED` | targetId, buffId |
| 英雄阵亡 | `HERO_DIED` | heroId, heroName |
| 战斗结束 | `BATTLE_ENDED` | winner, reason |

### 4.2 消息格式

```json
{
    "type": "DamageDealt",
    "timestamp": 1234567890,
    "data": {
        "attackerId": "hero_001",
        "attackerName": "亚瑟",
        "targetId": "enemy_001",
        "targetName": "魔王",
        "damage": 150,
        "isCrit": true
    }
}
```

### 4.3 客户端 → 服务端 指令

```json
{ "cmd": "start_battle" }
{ "cmd": "pause" }
{ "cmd": "resume" }
{ "cmd": "speed_up" }
{ "cmd": "speed_down" }
```

---

## 5. 实现步骤

### Phase 1: 服务端 WebSocket (Day 1)

1. 创建 `web/` 目录结构
2. 实现 `web_server.lua` - HTTP 静态文件服务
3. 实现 `web_socket.lua` - WebSocket 服务器
4. 实现 `web_renderer.lua` - 订阅 BattleVisualEvents 并推送
5. 验证：浏览器能连接到 WebSocket 并收到测试消息

### Phase 2: 前端 Canvas 渲染 (Day 2)

1. 创建 `web/static/` 目录结构
2. 实现 `index.html` 基础页面
3. 实现 `renderer.js` - Canvas 初始化 + 渲染循环
4. 实现 `hero_card.js` - 英雄卡片绘制（头像、HP条、能量）
5. 实现 `battle_scene.js` - 战场布局（左右队伍位置）
6. 实现 `animations.js` - 伤害飘字动画
7. 对接 WebSocket，实时更新战场状态

### Phase 3: 完整功能 (Day 2-3)

1. 实现所有 BattleVisualEvents 对应的前端动画
2. 添加战斗日志面板
3. 添加速度控制、暂停功能
4. 添加录像回放支持（保存事件日志）

---

## 6. 与备选方案对比

| 特性 | 纯浏览器方案 | 本方案 (服务器驱动) |
|-----|-------------|-------------------|
| **改动量** | 大（需移植 Lua→JS） | 小（复用 Lua） |
| **开发时间** | 5-7 天 | 1-2 天 |
| **多人观看** | ❌ 困难 | ✅ 支持 |
| **录像回放** | ❌ 需额外实现 | ✅ 天然支持 |
| **可离线** | ✅ 可以 | ❌ 需要服务器 |
| **性能** | 本地，无延迟 | 依赖网络 |

---

## 7. 启动方式

### 7.1 启动战斗服务器

```bash
cd mini-battle-simulator
lua55 main.lua --web
# 或
lua55 web/web_server.lua
```

### 7.2 访问 Web 界面

浏览器打开：`http://localhost:8080`

### 7.3 开发模式（自动刷新）

```bash
cd mini-battle-simulator/web/static
python -m http.server 8080
```

---

## 8. 参考文档

- [BattleVisualEvents 定义](./ui/battle_visual_events.lua)
- [ConsoleRenderer 实现](./ui/console_renderer.lua)
- [BattleMain 战斗主控](./modules/battle_main.lua)

---

## 9. 待办

- [ ] Phase 1: 服务端 WebSocket 实现
- [ ] Phase 2: 前端 Canvas 渲染实现
- [ ] Phase 3: 完整功能 + 录像回放
- [ ] 文档：WebSocket API 文档
- [ ] 文档：前端组件使用说明
