# 程序开发文档

本目录存放**程序向**文档：模块实现、配置与导出管线、工程约束、落地计划、回归说明。内容以**当前源码**为准，与策划稿冲突时先对齐代码再回写 `design/`。

- **策划设计**（玩法、数值口径、关卡与职业）见 [`design/README.md`](../design/README.md)。
- **`design/legacy/`**：过时策划归档，禁止阅读维护。
- Agent 仓库规范见 [`AGENTS.md`](../AGENTS.md)。

## 必读

| 文档 | 内容 |
| --- | --- |
| [implementation_guidelines.md](./implementation_guidelines.md) | Feat/skill、BuildState、Web 表现、测试口径（写代码必读） |
| [SKILL_SYSTEM_IMPLEMENTATION.md](./SKILL_SYSTEM_IMPLEMENTATION.md) | Timeline 技能、三层配置、释放流程 |
| [BUFF_SYSTEM_IMPLEMENTATION.md](./BUFF_SYSTEM_IMPLEMENTATION.md) | Buff 生命周期与注册表 |
| [BUFF_SHARED_TABLE.md](./BUFF_SHARED_TABLE.md) | Buff 静态表字段 |
| [dungeon_system_overall_plan.md](./dungeon_system_overall_plan.md) | 地牢系统落地进度与验收 |

## 策划规则来源（改代码时对照）

| 主题 | 策划文档 |
| --- | --- |
| 战场 / 术语 | `design/minibattle_combat_design_document_v_1.md` |
| Class / 5e | `design/class_system_design.md` |
| Run 养成 | `design/character_progression_design.md` |
| 地牢 / 房间 | `design/dungeon_design.md` |
| 遭遇预算 | `design/roguelike_random_battle_parameter_table.md` |

## 仓库路径（代码）

| 区域 | 路径 |
| --- | --- |
| 战斗引擎 | `modules/`、`core/` |
| 技能 / 被动 | `skills/` |
| Roguelike | `roguelike/` |
| 权威配置 | `config/data/*.json` → `config/tables/*.lua` |
| 单技能逻辑 | `config/skill/skill_*.lua` |
| Web 镜像 | `web/public/lua/project/`（`npm run export:lua` 生成） |
| Lua 回归 | `bin/test_*.lua` |
| Web E2E | `web/tests/*.spec.ts` |

## 常用命令

```bash
cd web && npm run export:lua    # Lua 改动后必做
cd web && npm run dev:full
lua bin/test_roguelike_act1.lua
cd web && npm run test:playwright
```
