# 策划设计文档

本目录仅存放**策划向**设计稿：玩法规则、数值口径、关卡结构、职业与技能设计、参数表。

- **程序实现**（模块说明、配置管线、落地计划、工程约束）见 [`docs/README.md`](../docs/README.md)。
- **`legacy/`**：过时策划稿归档，**禁止阅读、禁止维护**。见 [`legacy/README.md`](./legacy/README.md)。
- Agent 仓库规范见 [`AGENTS.md`](../AGENTS.md)。

## 文档关系

```text
minibattle_combat_design_document_v_1.md     ← 术语 + 战场硬规则
├── single_battle_design.md
│   └── single_battle_parameter_table.md
├── class_system_design.md
│   ├── physical_class_core_skill_design.md
│   └── caster_class_core_skill_design.md
├── character_progression_design.md        ← Run 养成
├── dungeon_design.md                      ← 地牢 / 房间
├── roguelike_random_battle_parameter_table.md
├── roguelike_monster_system_design.md
├── equipment_system_design_v0_1.md
└── roguelike_feat_skill_fill_sheet.md
```

## 按任务查找

| 任务 | 文档 |
| --- | --- |
| 改玩法 / 术语 / 战场 | `minibattle_combat_design_document_v_1.md` → `single_battle_design.md` |
| 改职业 / 5e 属性口径 | `class_system_design.md` |
| 改职业核心技机制 | `physical_class_core_skill_design.md` / `caster_class_core_skill_design.md` |
| 改养成 / Feat 档位 | `character_progression_design.md` |
| 改地牢 / 房间 / 掉落规则 | `dungeon_design.md` |
| 改遭遇预算 / 怪物生态 | `roguelike_random_battle_parameter_table.md` + `roguelike_monster_system_design.md` |
| 改装备策划案 | `equipment_system_design_v0_1.md` |
| **改代码 / 模块 / 测试** | → [`docs/README.md`](../docs/README.md) |

## 产品口径摘要

- **战斗**：3+3、自动回合、波次清场立刷、单场无成长。
- **养成**：`partyExp` + Feat 三选一；无职业卡、无招募扩编。
- **地牢**：3×5 房间迷宫；精英装备 + 概率 bless。
- **难度**：仅 `budget.difficulty` + `budget.pressureFactor`。
