# 程序开发文档

本目录存放**程序向**文档：模块实现、配置与导出管线、工程约束、回归说明。

- 活跃文档**只描述当前实现与设计**，不写旧版对照、迁移说明或已删除系统的长期留痕。
- 与策划稿冲突时：先以源码与 `docs/implementation_guidelines.md` 为准，再回写 `design/` 活跃稿件。
- 策划设计见 [`design/README.md`](../design/README.md)；`design/legacy/` 禁止阅读维护。
- Agent 行为准则见 [`AGENTS.md`](../AGENTS.md)；仓库工程约束见 [`repo_constraints.md`](./repo_constraints.md)。

## 必读

| 文档 | 内容 |
| --- | --- |
| [repo_constraints.md](./repo_constraints.md) | 5e、目录、Web 镜像、平衡规则、文档与元数据（改代码必读） |
| [implementation_guidelines.md](./implementation_guidelines.md) | Feat/skill、BuildState、Run 模块与 EXP/地牢 SSOT、Web 表现、测试口径（写代码必读） |
| [skill_system_implementation.md](./skill_system_implementation.md) | Timeline 技能、三层配置、释放流程 |
| [buff_system_implementation.md](./buff_system_implementation.md) | Buff 生命周期与注册表 |
| [buff_shared_table.md](./buff_shared_table.md) | Buff 逐 ID 实现对照表（与 `buffs.json` 同步） |

## 策划规则来源（改代码时对照）

| 主题 | 策划文档 |
| --- | --- |
| 战场 / 术语 | `design/combat_system_design.md` |
| Buff / 状态规则 | `design/buff_system_design.md` |
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
| Run EXP / 怪物 CR 与展示 Level | `config/roguelike/exp_5e.lua`（含 `MONSTER_DISPLAY_LEVEL_BY_CR`）、`battle_exp_reward.lua`；楼层 CR 梯度见 `run_enemy_pick_pool.lua` + `bin/test_roguelike_act1_floor_cr.lua` |
| 权威配置 | `config/data/*.json` → `config/tables/*.lua`（含 `events.json`、`trinkets.json` → `tables/events.lua`、`tables/trinkets.lua`） |
| Run trinket 池 | `config/roguelike/run_trinket_config.lua` |
| 单技能逻辑 | `config/skill/skill_*.lua` |
| Web 镜像 | `web/public/lua/project/`（`npm run export:lua` 生成） |
| Lua 回归 | `bin/test_*.lua` |
| Web E2E | `web/tests/*.spec.ts`；共享 helper 见 `web/tests/helpers/` |
| Web E2E（按职业） | 见下表 §Web E2E 按职业；**改哪个职业只测哪个** |
| 反应技 hold 死亡释放 E2E | `web/tests/reaction-hold-death.spec.ts` |
| Playwright 浏览器路径解析 | `web/scripts/run-playwright.mjs`、`resolve-playwright-browsers.mjs` |

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
lua bin/test_roguelike_act1_floor_cr.lua   # Act1 F1–F5 遭遇池 CR 梯度
lua bin/test_enemy_cr_alignment.lua
lua bin/test_roguelike_ch101_reach.lua   # 101 章 Boss 触达（autoWin，只验路由，不验数值）

# 平衡验收（改怪物/池/budget 后必跑真战；详见 repo_constraints.md、implementation_guidelines.md §8.4）
lua bin/test_roguelike_balance.lua --runs=4
lua bin/test_roguelike_real_combat_balance.lua
lua bin/test_real_combat_winrate.lua
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
lua bin/test_fighter_build_runtime.lua
lua bin/test_three_class_build_pipeline.lua   # 聚合入口；亦可单独跑下列分文件
lua bin/test_monk_build_pipeline.lua
lua bin/test_paladin_build_pipeline.lua
lua bin/test_barbarian_build_pipeline.lua
lua bin/test_ranger_build_pipeline.lua
lua bin/test_rogue_build_pipeline.lua
lua bin/test_cleric_build_pipeline.lua
lua bin/test_class_build_shared.lua
lua bin/test_class_tree_runtime_fixes.lua
lua bin/test_cleric_holy_spark_targeting.lua
lua bin/test_physical_class_budget.lua
lua bin/test_enemy_skill_alignment.lua
lua bin/test_roguelike_enemy_generation.lua
lua bin/test_roguelike_act23_battle_pools.lua
lua bin/test_roguelike_event_revive.lua
lua bin/test_skill_targeting.lua
lua bin/test_skill_tier_scaling.lua
lua bin/test_timeline_passive.lua
lua bin/test_buff_ticks.lua
lua bin/test_positioning.lua
lua bin/test_feat_mod_helper.lua
lua bin/test_browser_battle_runtime.lua

cd web && npm run install:playwright   # 首次
cd web && npm run test:playwright      # 全量（跨职业 / 核心改动再用）
cd web && npm run test:playwright:scripts
cd web && npm run test:playwright -- tests/ranger-web-smoke.spec.ts   # 示例：只测游侠
```

### Web E2E 按职业

Lua 改动后先 `npm run export:lua`，再跑**对应用例**（不要默认全量）。

| 职业 | Playwright | 常见 Lua 回归（可选） |
| --- | --- | --- |
| 战士 | `tests/fighter-web-smoke.spec.ts` | `bin/test_fighter_build_*.lua` |
| 武僧 | `tests/monk-web-smoke.spec.ts` | `bin/test_class_tree_runtime_fixes.lua`（武僧段） |
| 盗贼 | `tests/rogue-web-smoke.spec.ts` | 同上（盗贼段） |
| 游侠 | `tests/ranger-web-smoke.spec.ts` | `bin/test_ranger_build_pipeline.lua`、`bin/test_class_tree_runtime_fixes.lua` |
| 圣武士 | `tests/paladin-web-smoke.spec.ts` | `bin/test_paladin_build_pipeline.lua` |
| 牧师 | `tests/cleric-web-smoke.spec.ts` | — |
| 野蛮人 | `tests/barbarian-web-smoke.spec.ts` | `bin/test_barbarian_build_pipeline.lua` |
| 术士 / 法师 / 邪术师 | `tests/caster-web-smoke.spec.ts` | — |
| Roguelike 流程 | `tests/roguelike-act1.spec.ts`、`tests/roguelike-dungeon.spec.ts` | `bin/test_roguelike_*.lua` |
| 反应技 / 战斗核心 | `tests/reaction-hold-death.spec.ts`、`tests/smoke.spec.ts` | `bin/test_timeline_passive.lua` 等 |

跨模块（`modules/battle_skill.lua`、`hero_build`、`config/tables/feats.lua` 全职业）或用户明确要求时，再扩面或 `npm run test:playwright` 全量。
