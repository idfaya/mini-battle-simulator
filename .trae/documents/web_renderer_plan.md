# Mini Battle Simulator Web 渲染器设计方案

## 1. 架构概述

从零开始设计一个 2D 网页回合制对战游戏渲染系统，不依赖现有的 ConsoleRenderer。

### 1.1 技术栈选择
- **后端**: Lua + LuaSocket (HTTP服务器) + LuaWebSocket (实时通信)
- **前端**: HTML5 Canvas + JavaScript (原生，无框架依赖)
- **通信**: WebSocket 用于实时战斗数据推送
- **渲染**: Canvas 2D API 实现精灵、动画、粒子效果

### 1.2 模块结构
```
web/
├── web_server.lua          # HTTP服务器，提供静态文件服务
├── web_socket.lua          # WebSocket服务器，实时通信
├── web_renderer.lua        # Web渲染器核心，订阅战斗事件
├── web_battle_state.lua    # 战斗状态管理（服务端）
└── web_event_bridge.lua    # 事件桥接，将战斗事件转为WebSocket消息

web/static/
├── index.html              # 主页面
├── css/
│   └── style.css           # 样式文件
└── js/
    ├── main.js             # 前端入口
    ├── renderer.js         # Canvas渲染器
    ├── battle_scene.js     # 战斗场景管理
    ├── hero_card.js        # 英雄卡片渲染
    ├── skill_effect.js     # 技能特效
    ├── animation.js        # 动画系统
    └── websocket_client.js # WebSocket客户端

web/assets/
├── sprites/                # 精灵图（占位，可用emoji或简单图形）
└── effects/                # 特效资源
```

## 2. 后端设计 (Lua)

### 2.1 Web服务器 (web_server.lua)
```lua
---@class WebServer
local WebServer = {}

-- 功能:
-- 1. 启动HTTP服务器监听指定端口
-- 2. 提供静态文件服务 (html/css/js)
-- 3. 提供API端点获取战斗状态
-- 4. 与WebSocket服务器协作

function WebServer.Start(port)
function WebServer.Stop()
function WebServer.ServeStaticFile(path, response)
```

### 2.2 WebSocket服务器 (web_socket.lua)
```lua
---@class WebSocketServer
local WebSocketServer = {}

-- 功能:
-- 1. 处理WebSocket握手
-- 2. 管理客户端连接
-- 3. 广播战斗事件到所有客户端
-- 4. 接收客户端指令（如开始战斗、暂停等）

function WebSocketServer.Start(port)
function WebSocketServer.Broadcast(eventType, data)
function WebSocketServer.SendTo(client, message)
```

### 2.3 Web渲染器 (web_renderer.lua)
```lua
---@class WebRenderer
local WebRenderer = {}

-- 功能:
-- 1. 订阅 BattleVisualEvents 事件
-- 2. 将事件转换为WebSocket消息
-- 3. 维护战斗状态快照
-- 4. 提供战斗数据查询接口

function WebRenderer.Init()
function WebRenderer.OnFinal()
function WebRenderer.RegisterEventListeners()
```

### 2.4 事件桥接 (web_event_bridge.lua)
```lua
---@class WebEventBridge
local WebEventBridge = {}

-- 功能:
-- 1. 定义事件到消息的映射
-- 2. 序列化事件数据为JSON
-- 3. 处理消息压缩/优化

function WebEventBridge.ConvertEvent(eventType, eventData)
```

## 3. 前端设计 (JavaScript + Canvas)

### 3.1 渲染架构
```
Canvas (800x600)
├── Background Layer      # 背景层
├── Effect Layer          # 特效层（技能动画）
├── Hero Layer            # 英雄层
│   ├── HeroCard (Left Team)
│   └── HeroCard (Right Team)
├── UI Layer              # UI层
│   ├── HP Bars
│   ├── Energy Bars
│   ├── Buff Icons
│   └── Skill Icons
└── Overlay Layer         # 覆盖层
    ├── Damage Numbers
    ├── Turn Indicator
    └── Battle Log
```

### 3.2 核心类设计

#### BattleRenderer (renderer.js)
```javascript
class BattleRenderer {
    constructor(canvas)
    init()
    render()  // 主渲染循环
    clear()
    
    // 渲染对象
    renderHeroCard(hero, x, y)
    renderHpBar(current, max, x, y, width)
    renderEnergyBar(current, max, x, y, width)
    renderBuffIcons(buffList, x, y)
    renderDamageNumber(value, x, y, type)
}
```

#### BattleScene (battle_scene.js)
```javascript
class BattleScene {
    constructor(renderer)
    
    // 场景管理
    setupLayout()           // 设置英雄位置布局
    updateHeroState(heroId, state)
    playSkillAnimation(skillId, fromHero, toHeros)
    showDamageNumber(value, targetHero, type)
    
    // 布局配置
    getHeroPosition(team, index)  // 返回 {x, y}
}
```

#### HeroCard (hero_card.js)
```javascript
class HeroCard {
    constructor(heroData)
    
    // 状态
    update(data)            // 更新HP/能量/Buff等
    setHighlight(type)      // 高亮效果 (attack/defend/heal)
    
    // 渲染
    render(ctx, x, y)
    renderHpBar(ctx)
    renderEnergyBar(ctx)
    renderBuffs(ctx)
}
```

#### SkillEffect (skill_effect.js)
```javascript
class SkillEffect {
    constructor(effectId)
    
    // 动画
    play(fromX, fromY, toX, toY)
    update(deltaTime)
    render(ctx)
    
    // 特效类型
    static TYPE_PROJECTILE  // 弹道
    static TYPE_AOE         // 范围
    static TYPE_BEAM        // 光束
    static TYPE_BUFF        // Buff特效
}
```

#### AnimationSystem (animation.js)
```javascript
class AnimationSystem {
    constructor()
    
    // 动画管理
    addAnimation(anim)
    update(deltaTime)
    
    // 预设动画
    createDamageFloat(value, x, y)
    createShakeEffect(target)
    createFlashEffect(color)
    createParticleExplosion(x, y, color)
}
```

### 3.3 WebSocket客户端 (websocket_client.js)
```javascript
class BattleWebSocketClient {
    constructor(url)
    connect()
    disconnect()
    
    // 消息处理
    onMessage(event)        // 解析服务器消息
    handleBattleStart(data)
    handleTurnStart(data)
    handleDamage(data)
    handleHeal(data)
    handleSkillCast(data)
    handleBuffChange(data)
    handleBattleEnd(data)
}
```

## 4. 通信协议

### 4.1 消息格式 (JSON)
```json
{
    "type": "event_name",
    "timestamp": 1234567890,
    "data": { ... }
}
```

### 4.2 事件类型映射
| 战斗事件 | WebSocket消息类型 | 数据字段 |
|---------|------------------|---------|
| BATTLE_STARTED | battle_start | teamLeft, teamRight |
| TURN_STARTED | turn_start | round, heroId, heroName |
| DAMAGE_DEALT | damage | attackerId, targetId, damage, isCrit |
| HEAL_RECEIVED | heal | healerId, targetId, healAmount |
| SKILL_CAST_STARTED | skill_cast | heroId, skillId, skillName, targets |
| BUFF_ADDED | buff_add | targetId, buffId, buffName, buffType |
| BUFF_REMOVED | buff_remove | targetId, buffId |
| HERO_DIED | hero_die | heroId, heroName |
| BATTLE_ENDED | battle_end | winner, reason |

### 4.3 客户端到服务器指令
```json
{
    "cmd": "start_battle" | "pause" | "resume" | "speed_up" | "speed_down"
}
```

## 5. UI设计

### 5.1 布局 (800x600 Canvas)
```
+--------------------------------------------------+
|  回合: 15                              [速度 x1]  |
+--------------------------------------------------+
|                                                  |
|  [Hero1]    [Hero2]         [Enemy1]   [Enemy2]  |
|  HP: ████   HP: ████        HP: ████   HP: ████  |
|  EN: ◆◆◇    EN: ◆◆◆         EN: ◆◆◆   EN: ◆◇◇   |
|                                                  |
|  [Hero3]    [Hero4]         [Enemy3]   [Enemy4]  |
|  HP: ████   HP: ████        HP: ████   HP: ████  |
|                                                  |
+--------------------------------------------------+
|  战斗日志                                        |
|  > 英雄A 使用 火球术 对 敌人B 造成 150 伤害     |
|  > 敌人B 闪避了 英雄C 的攻击                    |
+--------------------------------------------------+
```

### 5.2 视觉元素
- **英雄卡片**: 圆角矩形，带边框，显示头像/名称/HP/能量
- **HP条**: 渐变色 (绿->黄->红)
- **能量条**: 蓝色渐变，点数类型用菱形图标
- **Buff图标**: 小圆角方块，带层数数字
- **伤害数字**: 浮动动画，暴击红色放大
- **技能特效**: 弹道、爆炸、光束等Canvas动画

## 6. 实现步骤

### Phase 1: 基础框架
1. 创建 web/ 目录结构
2. 实现 Web服务器 (web_server.lua)
3. 实现基础静态文件服务
4. 创建前端 index.html 和基础 Canvas

### Phase 2: WebSocket通信
1. 实现 WebSocket服务器 (web_socket.lua)
2. 实现 WebSocket客户端 (websocket_client.js)
3. 建立基础连接和心跳
4. 实现消息序列化/反序列化

### Phase 3: 渲染器核心
1. 实现 BattleRenderer 基础渲染循环
2. 实现 HeroCard 渲染
3. 实现 HP/Energy 条渲染
4. 实现 Buff 图标渲染

### Phase 4: 事件集成
1. 实现 WebRenderer 事件订阅
2. 实现事件到消息的转换
3. 前端处理各种战斗事件
4. 实现战斗状态同步

### Phase 5: 动画特效
1. 实现 AnimationSystem
2. 实现伤害数字浮动
3. 实现技能特效 (弹道、爆炸)
4. 实现屏幕震动等效果

### Phase 6: 完善与优化
1. 添加战斗日志面板
2. 添加速度控制
3. 优化性能和内存
4. 添加错误处理和重连

## 7. 关键技术点

### 7.1 LuaSocket HTTP服务器
- 使用 `socket.bind()` 和 `socket.select()`
- 处理HTTP请求解析
- 支持WebSocket Upgrade

### 7.2 Canvas渲染优化
- 使用 `requestAnimationFrame` 循环
- 分层渲染减少重绘
- 对象池复用粒子对象

### 7.3 状态同步
- 服务端维护权威状态
- 客户端预测 + 服务端校正
- 关键事件（伤害/治疗）服务端驱动

### 7.4 资源管理
- 使用emoji作为临时英雄头像
- Canvas绘制简单几何图形作为特效
- 无需外部图片资源即可运行

## 8. 启动流程

```lua
-- main.lua 添加
local WebRenderer = require("web.web_renderer")

-- 初始化时
WebRenderer.Init({
    httpPort = 8080,
    wsPort = 8081,
    autoOpenBrowser = true
})

-- 战斗开始时自动广播事件到Web客户端
```

浏览器访问: `http://localhost:8080`
