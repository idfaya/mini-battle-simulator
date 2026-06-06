# 策划设计文档

本目录仅存放**策划向**设计稿：玩法规则、数值口径、关卡结构、职业与技能设计、参数表。

- 活跃稿件**只描述当前设计**（现在时）；不写旧版对照或长期「已删除/已迁移」清单。
- **程序实现**见 [`docs/README.md`](../docs/README.md)。
- **`legacy/`**：过时策划归档，**禁止阅读、禁止维护、禁止在活跃文档中引用对照**。
- Agent 行为准则见 [`AGENTS.md`](../AGENTS.md)；工程约束（含不做旧设计兼容）见 [`docs/repo_constraints.md`](../docs/repo_constraints.md)。

## 文档关系

```text
combat_system_design.md     ← 术语 + 战场硬规则
├── buff_system_design.md                ← Buff / 状态策划总纲
├── single_battle_design.md
│   └── single_battle_parameter_table.md
├── class_system_design.md                ← 职业 / 5e 画像
│   └── auto_battle_targeting.md          ← 自动战斗目标倾向
├── character_progression_design.md        ← Run 养成
├── dungeon_design.md                      ← 地牢 / 房间
├── roguelike_random_battle_parameter_table.md
├── roguelike_monster_system_design.md
├── equipment_system_design.md
└── roguelike_feat_skill_fill_sheet.md     ← Feat 树节点级 SSOT
```

## 按任务查找

| 任务 | 文档 |
| --- | --- |
| 改玩法 / 术语 / 战场 | `combat_system_design.md` → `single_battle_design.md` |
| 改 Buff / 状态规则 | `buff_system_design.md`（§2.4 状态符、§11 设计债）→ `roguelike_feat_skill_fill_sheet.md` §8 |
| 改职业 / 5e 属性口径 | `class_system_design.md` |
| 改职业核心技 / Feat 树节点 | `roguelike_feat_skill_fill_sheet.md` |
| 改自动战斗 AI 目标倾向 | `auto_battle_targeting.md` |
| 改养成 / Feat 档位 | `character_progression_design.md` |
| 改地牢 / 房间 / 掉落 / trinket / 隐藏层 | `dungeon_design.md`（§3.3、§4.4–§4.7） |
| 改遭遇预算 / 怪物生态 | `roguelike_random_battle_parameter_table.md` + `roguelike_monster_system_design.md` |
| 改装备策划案 | `equipment_system_design.md` |
| **改代码 / 模块 / 测试** | → [`docs/README.md`](../docs/README.md) |

## 产品口径摘要

- **战斗**：3+3、自动回合、波次清场立刷、单场无成长。
- **养成**：`partyExp`（5e PHB 阈值）+ Feat 三选一；无职业卡、无招募扩编。第一章怪物难度随楼层抬升（更高 CR 遭遇池 + budget），展示 `Level` 跟 `enemies.json`/`exp_5e` 映射；队伍章末约 Lv9–10。
- **地牢**：3×5 房间迷宫；事件 5e 检定；精英装备 + 概率 bless；章末 Boss 必掉 trinket；事件大成功可开隐藏层（3~5 房 + 双倍 trinket）。
- **难度**：`budget.difficulty` + `budget.pressureFactor`；章节内随楼层换更高 CR 的 `run_enemy_pick_pool`（见 `design/dungeon_design.md` §3.2）。
