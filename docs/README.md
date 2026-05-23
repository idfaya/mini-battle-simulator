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
| [dungeon_system_overall_plan.md](./dungeon_system_overall_plan.md) | 地牢 / Run 落地进度；§2.4 / §3.1.5 为 5e EXP 与第一章怪物节奏 |

## 策划规则来源（改代码时对照）

| 主题 | 策划文档 |
| --- | --- |
| 战场 / 术语 | `design/minibattle_combat_design_document_v_1.md` |
| Class / 5e | `design/class_system_design.md` |
| Run 养成 / partyExp | `design/character_progression_design.md` §2 |
| 地牢 / 房间 / cleared 通路 | `design/dungeon_design.md` §4.2 |
| 事件 5e 检定 / 营地 / 商店 | `design/dungeon_design.md` §4.4–§4.6 |
| 章节 trinket / 隐藏层 | `design/dungeon_design.md` §3.3、§4.7 |
| 遭遇预算 | `design/roguelike_random_battle_parameter_table.md` |

## 仓库路径（代码）

| 区域 | 路径 |
| --- | --- |
| 战斗引擎 | `modules/`、`core/` |
| 技能 / 被动 | `skills/` |
| Roguelike | `roguelike/` |
| Run EXP / 楼层等级 | `config/roguelike/exp_5e.lua`、`battle_exp_reward.lua`、`encounter_level_curve.lua` |
| 权威配置 | `config/data/*.json` → `config/tables/*.lua`（含 `events.json`、`trinkets.json` → `tables/events.lua`、`tables/trinkets.lua`） |
| Run trinket 池 | `config/roguelike/run_trinket_config.lua` |
| 单技能逻辑 | `config/skill/skill_*.lua` |
| Web 镜像 | `web/public/lua/project/`（`npm run export:lua` 生成） |
| Lua 回归 | `bin/test_*.lua` |
| Web E2E | `web/tests/*.spec.ts` |

## 常用命令

```bash
cd web && npm run export:lua    # Lua 改动后必做
cd web && npm run dev:full

# Roguelike / 地牢 / 养成
lua bin/test_roguelike_dungeon_generation.lua
lua bin/test_roguelike_progression_pacing.lua
lua bin/test_roguelike_progression_gate.lua
lua bin/test_party_exp_levelup.lua
lua bin/test_roguelike_room_one_shot.lua
lua bin/test_events_json_loader.lua
lua bin/test_roguelike_act1.lua
lua bin/test_roguelike_chapter_success.lua
lua bin/test_roguelike_event_skill_check.lua
lua bin/test_roguelike_camp_full_rest.lua
lua bin/test_roguelike_shop_revive_scroll.lua
lua bin/test_roguelike_boss_trinket.lua
lua bin/test_roguelike_trinket_effects.lua
lua bin/test_roguelike_hidden_floor.lua

# 战斗 / 职业 build
lua bin/test_single_battle.lua
lua bin/test_fighter_build_pipeline.lua

cd web && npm run test:playwright
```
