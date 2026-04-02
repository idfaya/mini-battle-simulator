# Mini Battle Simulator 纯浏览器端独立运行方案

## 1. 架构概述

完全脱离 Lua 后端，所有战斗逻辑和渲染都在浏览器中运行。

### 1.1 技术栈
- **纯前端**: HTML5 + JavaScript (ES6+)
- **战斗逻辑**: JavaScript 移植 Lua 战斗核心代码
- **渲染**: HTML5 Canvas 2D
- **数据**: JSON 配置文件 (从 Lua 配置转换)
- **存储**: LocalStorage 保存用户设置

### 1.2 文件结构
```
web_standalone/
├── index.html                    # 主页面
├── css/
│   └── style.css                 # 样式
├── js/
│   ├── main.js                   # 入口
│   ├── config/
│   │   ├── hero_data.js          # 英雄数据 (从 Lua 转换)
│   │   ├── enemy_data.js         # 敌人数据
│   │   ├── skill_data.js         # 技能数据
│   │   └── buff_data.js          # Buff数据
│   ├── core/
│   │   ├── battle_types.js       # 类型定义
│   │   ├── battle_enum.js        # 枚举值
│   │   ├── battle_math.js        # 随机数/数学
│   │   ├── battle_formula.js     # 战斗公式
│   │   └── battle_event.js       # 事件系统
│   ├── modules/
│   │   ├── battle_main.js        # 战斗主控
│   │   ├── battle_formation.js   # 阵型
│   │   ├── battle_attribute.js   # 属性系统
│   │   ├── battle_action_order.js# 行动顺序
│   │   ├── battle_skill.js       # 技能系统
│   │   ├── battle_buff.js        # Buff系统
│   │   ├── battle_damage.js      # 伤害计算
│   │   └── battle_energy.js      # 能量系统
│   └── ui/
│       ├── renderer.js           # Canvas渲染器
│       ├── battle_scene.js       # 战斗场景
│       ├── hero_card.js          # 英雄卡片
│       ├── skill_effect.js       # 技能特效
│       ├── animation.js          # 动画系统
│       └── battle_log.js         # 战斗日志
└── assets/
    └── (可选) 图片/音效资源
```

## 2. 数据转换方案

### 2.1 Lua 配置 → JavaScript 模块

使用 Node.js 脚本自动转换：

```javascript
// tools/convert_lua_to_js.js
// 读取 Lua 配置，输出 JS 模块
```

转换示例：

**Lua (config/hero_data.lua)**:
```lua
local HeroData = {
    [13101] = {
        id = 13101,
        name = "亚瑟",
        job = 2, -- 战士
        baseHp = 1000,
        baseAtk = 100,
    }
}
```

**JavaScript (js/config/hero_data.js)**:
```javascript
export const HeroData = {
    13101: {
        id: 13101,
        name: "亚瑟",
        job: 2,
        baseHp: 1000,
        baseAtk: 100,
    }
};
```

### 2.2 需要转换的数据文件
- `config/hero_data.lua` → `js/config/hero_data.js`
- `config/enemy_data.lua` → `js/config/enemy_data.js`
- `config/skill_data.lua` → `js/config/skill_data.js`
- `config/buff_config.lua` → `js/config/buff_data.js`
- `config/buff/*.lua` → 合并到 `js/config/buff_details.js`
- `config/skill/*.lua` → 合并到 `js/config/skill_details.js`

## 3. 核心模块移植

### 3.1 战斗主循环 (js/modules/battle_main.js)
```javascript
export class BattleMain {
    constructor() {
        this.isRunning = false;
        this.currentRound = 0;
        this.battleResult = null;
    }

    start(beginState) {
        // 初始化所有子系统
        this.initSubsystems(beginState);
        this.isRunning = true;
        this.runLoop();
    }

    async runLoop() {
        // 主循环：行动顺序 → 执行行动 → 检查结束
        while (this.isRunning) {
            const hero = this.actionOrder.getNextHero();
            if (hero) {
                await this.executeHeroAction(hero);
                this.checkBattleEnd();
            }
            await this.delay(500); // 动画延迟
        }
    }
}
```

### 3.2 事件系统 (js/core/battle_event.js)
```javascript
export class BattleEvent {
    constructor() {
        this.listeners = new Map();
    }

    addListener(eventType, callback, context) {
        if (!this.listeners.has(eventType)) {
            this.listeners.set(eventType, []);
        }
        this.listeners.get(eventType).push({ callback, context });
    }

    publish(eventType, data) {
        const listeners = this.listeners.get(eventType);
        if (listeners) {
            listeners.forEach(({ callback, context }) => {
                callback.call(context, data);
            });
        }
    }
}

// 全局事件实例
export const battleEvent = new BattleEvent();
```

### 3.3 属性系统 (js/modules/battle_attribute.js)
```javascript
export class BattleAttribute {
    static ATTR_ID = {
        HP: 1,
        ATK: 2,
        DEF: 3,
        SPEED: 18,
        CRIT_RATE: 21,
        CRIT_DMG: 22,
    };

    static initHero(hero, attributeMap) {
        hero.attributes = new Map();
        for (const [id, value] of Object.entries(attributeMap)) {
            hero.attributes.set(parseInt(id), value);
        }
    }

    static getAttr(hero, attrId) {
        return hero.attributes.get(attrId) || 0;
    }
}
```

## 4. UI 设计

### 4.1 主界面布局
```
+----------------------------------------------------------+
|  Mini Battle Simulator                    [设置] [帮助]  |
+----------------------------------------------------------+
|                                                          |
|  左侧队伍                        右侧队伍               |
|  +--------+  +--------+          +--------+  +--------+  |
|  | 英雄1  |  | 英雄2  |          | 敌人1  |  | 敌人2  |  |
|  | HP:=== |  | HP:=== |          | HP:=== |  | HP:=== |  |
|  | EN:◆◆◆ |  | EN:◆◆◇ |          | EN:◆◆◆ |  | EN:◆◇◇ |  |
|  +--------+  +--------+          +--------+  +--------+  |
|                                                          |
|  +--------+  +--------+          +--------+  +--------+  |
|  | 英雄3  |  | 英雄4  |          | 敌人3  |  | 敌人4  |  |
|  | HP:=== |  | HP:=== |          | HP:=== |  | HP:=== |  |
|  +--------+  +--------+          +--------+  +--------+  |
|                                                          |
+----------------------------------------------------------+
|  回合: 12    当前行动: 亚瑟                    [▶ 自动]  |
+----------------------------------------------------------+
|  战斗日志                                                |
|  ------------------------------------------------------  |
|  > 亚瑟 使用 重击 对 哥布林 造成 150 伤害               |
|  > 哥布林 发动反击 对 亚瑟 造成 50 伤害                 |
|  > 法师 使用 火球术 造成 200 范围伤害                   |
+----------------------------------------------------------+
|  [开始战斗]  [重置]  [速度: x1 ▼]  [队伍配置]           |
+----------------------------------------------------------+
```

### 4.2 交互功能
- **开始战斗**: 初始化并开始战斗模拟
- **重置**: 清空当前战斗，回到初始状态
- **速度控制**: 0.5x / 1x / 2x / 4x
- **队伍配置**: 弹出面板选择英雄/敌人
- **自动/手动**: 切换自动播放或单步执行
- **点击英雄**: 查看详细属性和技能

## 5. 实现步骤

### Phase 1: 基础框架 (Day 1)
1. 创建目录结构
2. 实现基础 HTML + CSS
3. 设置 Canvas 画布
4. 实现基础渲染循环

### Phase 2: 数据层 (Day 2)
1. 编写 Lua → JS 转换脚本
2. 转换所有配置数据
3. 验证数据完整性

### Phase 3: 战斗核心 (Day 3-4)
1. 移植 battle_types / battle_enum
2. 实现 battle_math (随机数)
3. 实现 battle_event (事件)
4. 实现 battle_attribute (属性)
5. 实现 battle_formation (阵型)
6. 实现 battle_action_order (行动顺序)

### Phase 4: 战斗系统 (Day 5-6)
1. 实现 battle_skill (技能)
2. 实现 battle_buff (Buff)
3. 实现 battle_damage (伤害)
4. 实现 battle_energy (能量)
5. 实现 battle_main (主控)

### Phase 5: UI渲染 (Day 7-8)
1. 实现 HeroCard 渲染
2. 实现 HP/Energy 条动画
3. 实现 Buff 图标显示
4. 实现伤害数字浮动
5. 实现技能特效

### Phase 6: 完善功能 (Day 9-10)
1. 队伍配置界面
2. 战斗日志面板
3. 速度控制
4. 暂停/继续
5. 本地存储设置

## 6. 关键技术点

### 6.1 Lua 表 → JavaScript 对象
```javascript
// Lua: {a = 1, b = 2}
// JS:  {a: 1, b: 2}

// Lua: array = {1, 2, 3}
// JS:  array = [1, 2, 3]

// Lua: array[1] based
// JS:  array[0] based (需要转换索引)
```

### 6.2 异步战斗循环
```javascript
// 使用 async/await 实现可暂停的战斗循环
class BattleMain {
    async runLoop() {
        while (this.isRunning) {
            if (this.isPaused) {
                await this.waitForResume();
            }
            
            const hero = this.getNextHero();
            await this.executeAction(hero);
            
            // 根据速度设置延迟
            await this.delay(1000 / this.speed);
        }
    }
    
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
```

### 6.3 Canvas 渲染优化
```javascript
// 分层渲染
class BattleRenderer {
    constructor(canvas) {
        this.layers = {
            background: canvas.getContext('2d'),
            heroes: this.createLayer(),
            effects: this.createLayer(),
            ui: this.createLayer(),
        };
    }
    
    render() {
        // 只重绘变化的部分
        if (this.dirtyFlags.heroes) {
            this.renderHeroes();
        }
        if (this.dirtyFlags.effects) {
            this.renderEffects();
        }
    }
}
```

## 7. 启动方式

### 7.1 直接打开
双击 `index.html` 在浏览器中打开

### 7.2 本地服务器 (推荐)
```bash
cd web_standalone
python -m http.server 8080
# 或
npx serve .
```
访问 `http://localhost:8080`

### 7.3 打包部署
```bash
# 使用 Vite 打包
npm install -g vite
vite build

# 部署到 GitHub Pages / Vercel / Netlify
```

## 8. 优势对比

| 特性 | Lua+WebSocket方案 | 纯浏览器方案 |
|-----|------------------|-------------|
| 运行依赖 | 需要Lua环境 | 仅需浏览器 |
| 部署难度 | 需要服务器 | 静态文件即可 |
| 在线分享 | 需要托管服务 | 可直接分享HTML |
| 性能 | 受网络延迟影响 | 本地运行，无延迟 |
| 代码复用 | 直接复用Lua代码 | 需要移植到JS |
| 开发时间 | 短（复用现有代码） | 较长（需要移植） |
| 可离线使用 | 否 | 是 |

## 9. 推荐选择

**选择纯浏览器方案，如果：**
- 希望用户无需安装任何环境
- 需要在线分享/演示
- 希望部署到静态网站托管
- 需要离线使用

**选择 Lua+WebSocket方案，如果：**
- 需要与现有游戏服务器集成
- 需要服务端验证/防作弊
- 需要多人在线对战
- 希望快速实现，复用现有代码
