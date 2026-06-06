# Mini Battle Simulator

D&D 5e 风格的小队自动战斗 + Roguelike 原型。核心逻辑为 **Lua**（Unity/ToLua 与 CLI 共用），**Web** 通过 Fengari 在浏览器中运行同一套 Lua，用于可视化与 E2E 验证。

## 特性概览

- **战斗核心**：基于 Lua 的回合制战斗引擎，遵循 D&D 5e 风格规则。
- **技能系统**：包含主动技能、被动技能、职业构筑和时间轴效果。
- **Roguelike 系统**：包含 Run 生命周期、地牢生成、事件、遭遇战、Feat 成长。
- **Web 前端**：基于 Vite + TypeScript + Fengari，用浏览器直接运行同一套 Lua 逻辑。
- **测试链路**：Lua 回归脚本位于 `bin/`，Web 端到端测试使用 Playwright。

## 架构概览

```text
config/                    权威配置与运行时表
  data/                    JSON SSOT（skills、classes、heroes、enemies...）
  tables/                  Lua 表加载器
  skill/                   单技能 Lua 逻辑
  roguelike/               章节、战斗池、遭遇配置
core/ + modules/           战斗核心、属性、Buff、5e 规则、技能运行时
skills/                    主动技能、被动、时间轴、效果注册
roguelike/                 Run 生命周期、地图、事件、遭遇、成长
bin/                       Lua 回归脚本
web/                       Vite + TypeScript + Fengari + Playwright
design/                    策划设计文档
docs/                      程序实现文档
```

数据流：`config/` -> `modules/skills/roguelike/` -> `ui/` / `web/`

## 核心约定

- **5e 规则**：HP / AC / 命中加值 / 法术 DC 遵循 D&D 5e 风格，不额外发明公式。
- **目录职责**：技能逻辑在 `skills/`，Roguelike 运行时在 `roguelike/`，战斗引擎核心在 `modules/`。
- **Require 风格**：统一使用点路径，如 `require("skills.battle_skill_status")`。
- **镜像生成**：`web/public/lua/project/` 为生成产物，只能通过 `npm run export:lua` 刷新。
- **文档口径**：当前规则写在 `design/` 与 `docs/` 的活跃文档，`design/legacy/` 仅作归档。

## 文档入口

| 入口 | 说明 |
| --- | --- |
| [design/README.md](design/README.md) | **策划设计**（玩法、数值、关卡、职业） |
| [docs/README.md](docs/README.md) | **程序开发**（实现、工程约束、回归命令） |
| [AGENTS.md](AGENTS.md) | 编码 Agent 行为准则 |
| [docs/repo_constraints.md](docs/repo_constraints.md) | 仓库工程约束（5e、镜像、平衡、文档） |

改代码前优先看 `design/` 和 `docs/` 的活跃文档；`design/legacy/` 为过时归档，不参与当前实现。

## 快速开始

### Web 开发（推荐）

```bash
cd web
npm install
npm run dev:full    # export:lua + Vite 开发服
```

浏览器打开开发服地址。URL 参数示例：

- 默认：Roguelike 第一章
- `?mode=battle`：单场战斗调试
- `?mode=single-battle`：单战模式

### Lua CLI

需本机 Lua 5.x（脚本入口在 `bin/`）：

```bash
lua bin/test_single_battle.lua
lua bin/test_roguelike_act1.lua
lua bin/test_party_exp_levelup.lua
lua bin/test_roguelike_progression_pacing.lua
lua bin/test_roguelike_room_one_shot.lua
```

## 开发工作流

### Lua 改动后刷新 Web 镜像

```bash
cd web && npm run export:lua
```

会将 `core/`、`modules/`、`config/`、`skills/`、`roguelike/` 等同步到 `web/public/lua/project/`。**不要手改生成目录。**

### 完整 Web 回归

```bash
cd web && npm run export:lua && npm run test:playwright
```

首次环境可执行：

```bash
cd web && npm run install:playwright
```

`npm run test:playwright` 经 `web/scripts/run-playwright.mjs` 启动，会自动选用本机 `ms-playwright` 缓存（macOS：`~/Library/Caches/ms-playwright`），无需手动设置 `PLAYWRIGHT_BROWSERS_PATH`。本地调试可复用已有 dev 服：`PW_REUSE_SERVER=1 npm run test:playwright`。

反应技 hold 死亡释放专项回归：

```bash
cd web && npm run test:playwright -- tests/reaction-hold-death.spec.ts
```

若 `5173` 被旧进程占用导致 `.lua` 返回 HTML，先结束旧进程再跑测试。

## 关键路径

- Roguelike 配置：`config/roguelike/`
- 技能权威数据：`config/data/skills.json`
- 被动权威数据：`config/data/passives.json`
- 职业权威数据：`config/data/classes.json`
- 英雄权威数据：`config/data/heroes.json`
- 敌人权威数据：`config/data/enemies.json`
- Buff 权威数据：`config/data/buffs.json`
- 事件权威数据：`config/data/events.json`
- 饰品权威数据：`config/data/trinkets.json`
- Lua 表加载器：`config/tables/*.lua`
- 战斗核心模块：`modules/`
- 技能逻辑模块：`skills/`
- Web Lua 生成镜像：`web/public/lua/project/`

## 测试

```bash
# Web E2E（含浏览器路径自动解析）
cd web && npm run test:playwright

# Playwright 启动脚本单测
cd web && npm run test:playwright:scripts

# 反应技 reactor 死亡后立即解除 hold
cd web && npm run test:playwright -- tests/reaction-hold-death.spec.ts

# 示例 Lua 回归
lua bin/test_fighter_build_pipeline.lua
lua bin/test_roguelike_dungeon_generation.lua
```

## 部署

`main` 分支 push 后通过 GitHub Actions 构建 `web/` 并发布 GitHub Pages（见 `.github/workflows/deploy-pages.yml`）。

## 非目标说明

- 根目录旧版 `README` 中的 `main.lua`、`res_ally_info.json`、`damage = atk - def` 等描述已废弃。
- 完整规则与养成口径以 [design/README.md](design/README.md) 为准。
