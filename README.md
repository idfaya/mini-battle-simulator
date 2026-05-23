# Mini Battle Simulator

D&D 5e 风格的小队自动战斗 + Roguelike 原型。核心逻辑为 **Lua**（Unity/ToLua 与 CLI 共用），**Web** 通过 Fengari 在浏览器中运行同一套 Lua，用于可视化与 E2E 验证。

## 文档入口

| 入口 | 说明 |
| --- | --- |
| [design/README.md](design/README.md) | **策划设计**（玩法、数值、关卡、职业） |
| [docs/README.md](docs/README.md) | **程序开发**（实现、工程约束、落地计划） |
| [AGENTS.md](AGENTS.md) | 编码 Agent 规范（目录、export、5e、预算） |

## 快速开始

### Web（推荐）

```bash
cd web
npm install
npm run dev:full    # export:lua + Vite 开发服
```

浏览器打开开发服地址。URL 参数示例：

- 默认：Roguelike 第一章
- `?mode=battle`：单场战斗调试
- `?mode=single-battle`：单战模式

### Lua CLI 测试

需本机 Lua 5.x（脚本入口在 `bin/`）：

```bash
lua bin/test_single_battle.lua
lua bin/test_roguelike_act1.lua
lua bin/test_party_exp_levelup.lua
lua bin/test_roguelike_progression_pacing.lua
lua bin/test_roguelike_room_one_shot.lua
```

### Lua 改动后的必做步骤

```bash
cd web && npm run export:lua
```

会将 `core/`、`modules/`、`config/`、`skills/`、`roguelike/` 等同步到 `web/public/lua/project/`。**不要手改生成目录。**

## 仓库结构

```text
core/           类型、枚举、事件
modules/        战斗引擎（battle_main、buff、skill、5e）
skills/         技能效果、被动、时间轴
roguelike/      Run、地图、地牢生成、Feat 选择
config/
  data/         权威 JSON（skills、classes、heroes…）
  tables/       JSON 加载与运行时表
  skill/        单技能 Lua 逻辑
  roguelike/    章节、战斗池、遭遇
bin/            Lua 回归脚本
web/            TypeScript + Vite + Playwright
design/         策划设计文档（`legacy/` 禁止读/维护）
docs/           程序开发文档
```

## 测试

```bash
# Web E2E
cd web && npm run test:playwright

# 示例 Lua 回归
lua bin/test_fighter_build_pipeline.lua
lua bin/test_roguelike_dungeon_generation.lua
```

## 部署

`main` 分支 push 后通过 GitHub Actions 构建 `web/` 并发布 GitHub Pages（见 `.github/workflows/deploy-pages.yml`）。

## 非目标说明

- 根目录旧版 `README` 中的 `main.lua`、`res_ally_info.json`、`damage = atk - def` 等描述已废弃。
- 完整规则与养成口径以 [design/README.md](design/README.md) 为准。
