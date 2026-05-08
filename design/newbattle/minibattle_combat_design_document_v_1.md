﻿﻿# MiniBattle 战斗系统总纲 V1.1

## 0. 文档定位

- 本文档是 `MiniBattle` 战斗系统的**最高规则源**。
- 所有下级文档（单场战斗、Roguelike Run、职业系统、参数表等）必须向本稿对齐，不得反向改写总纲。
- 本文档只定义**硬规则与术语**，不重复下级稿件中的参数值与示例。

下级文档清单：

- `single_battle_design.md` / `single_battle_parameter_table.md`
- `roguelike_run_system_design.md` / `roguelike_node_parameter_table.md` / `roguelike_service_parameter_table.md`
- `class_system_design.md` / `class_promotion_design.md`
- `physical_class_core_skill_design.md` / `caster_class_core_skill_design.md`

---

## 1. 项目定位

`MiniBattle` 是一款：

- 小队制
- 自动战斗
- Roguelike
- 尸潮增援
- Hero-like 阵容构筑

的轻量化战斗游戏。

核心体验：

```text
构筑队伍
→ 机制联动
→ 战场进入失控
→ 连锁清场
```

---

## 2. 核心循环

### 2.1 Run 大循环

```text
进入章节地图
→ 选择节点
→ 结算节点
→ 战斗胜利 → 经验结算 → 固定恢复 → 职业卡三选一
→ 装备 / 金币 / 招募 / 营地共同修正队伍
→ 章节 Boss
→ 章节结算
→ Run 结束
```

### 2.2 单场战斗循环

```text
载入开场敌军编组
→ 按回合自动推进
→ 按刷新规则从后备池补位
→ 满足胜利或失败条件
→ 战斗结算
```

单场战斗内**不进行成长**。全部成长发生在战斗结束后。

---

## 3. 硬规则

### 3.1 战场

- 固定 `3 前排 + 3 后排`
- 单位分类只有 `Hero` 和 `Enemy`
- 没有召唤物、士兵、临时单位独立分类

### 3.2 回合

- 自动回合制
- 单场回合数目标 `6~12`
- 回合内严格顺序：`速度排序 → 单位行动 → 结算 → 连锁 → 下一单位`

### 3.3 敌军

- 开场敌军 ≤ `6`
- 多余敌方单位进入**后备池**
- 固定回合刷新，清场立刷
- 普通战 / 精英战胜利条件：`后备池耗尽 且 战场清空`
- Boss 战胜利条件：`击杀 Boss`
- 失败条件：`Hero 全灭`

### 3.4 成长

- 战斗内无成长
- 战斗胜利后先结算经验与自动升级，再执行固定恢复
- 战斗胜利后进入**职业卡三选一**
- 职业卡结果只允许两类：`新职业单位` / `同职业进阶`
- 职业卡不产出 `装备` / `祝福` / `金币`
- 职业阶段只允许 `low / mid / high`
- 高阶单位不再进入职业卡候选池

### 3.5 装备与金币

- 装备来源：商店、事件、战斗节点掉落
- 职业卡**不产出装备**，商店**不产出职业进阶**
- 金币不直接结算为职业进阶

---

## 4. 术语表

本节为全项目**唯一术语源**。下级稿件中出现冲突时以本节为准。

### 4.1 成长术语

| 术语 | 定义 |
| --- | --- |
| `进阶 (Promotion)` | 同一职业单位从 `low → mid → high` 的阶段推进 |
| `升级 (Level Up)` | 同一职业单位通过经验提升等级后的数值成长 |
| `转职 (Reclass)` | 职业单位的 `class_id` 切换 |
| `招募 (Recruit)` | 在 Run 内获得新职业单位的服务节点入口 |

### 4.2 战斗术语

| 术语 | 定义 |
| --- | --- |
| `开场编组 (opening_group)` | 战斗开始时上场的敌方单位组合 |
| `后备池 (reserve_units)` | 未上场敌方单位列表，按刷新规则补位 |
| `增援 (reinforce)` | 从后备池补位到战场的行为 |
| `刷新节拍 (refresh_turns)` | 每 N 回合触发一次增援 |
| `清场立刷 (refresh_on_clear)` | 本回合场上敌人全部死亡时立即触发一次增援 |
| `补位顺序 (spawn_order)` | 增援时优先填补的站位顺序，统一为 `后排 → 前排` |

### 4.3 单位术语

| 术语 | 定义 |
| --- | --- |
| `Hero` | 玩家侧战斗单位 |
| `Enemy` | 敌方侧战斗单位 |
| `上阵 (active)` | 当前参战的 Hero |
| `候补 (bench)` | 持有但未上阵的 Hero |
| `死亡 (dead)` | Run 内已死亡但仍被记录的 Hero |

### 4.4 节点术语

| 术语 | 定义 |
| --- | --- |
| `normal_battle` | 普通战节点 |
| `elite_battle` | 精英战节点 |
| `boss_battle` | Boss 战节点 |
| `recruit` | 招募节点 |
| `shop` | 商店节点 |
| `event` | 事件节点 |
| `camp` | 营地节点 |
| `route` | 节点所属路线，取值 `safe / high_pressure / boss_path` |

### 4.5 技能术语

| 术语 | 定义 |
| --- | --- |
| `basic_attack_slot` | 基础出手技能槽，所有阶段启用 |
| `core_slot` | 低阶核心能力槽，`low` 起启用 |
| `mid_slot` | 中阶新增能力槽，`mid` 起启用 |
| `high_slot` | 高阶终局能力槽，`high` 启用 |
| `反击` | 受到攻击事件后的回手动作 |
| `连击` | 命中后概率触发的额外攻击 |
| `伏击 / 标记 / 点燃 / 印记` | 条件附加伤害或状态，由各职业核心技定义 |

### 4.6 路线术语

| 术语 | 定义 |
| --- | --- |
| `safe` | 稳健路线，普通战与服务节点占比高 |
| `high_pressure` | 高压路线，精英战与高收益节点占比高 |
| `boss_path` | 通往章节 Boss 的专用路线 |

---

## 5. 禁用术语

以下旧术语在项目内**全面禁用**，下级稿件出现即视为待修：

- `圣物` → 统一为 `装备`
- `升级` 在涉及重复获得同职业时 → 必须改为 `进阶`
- `火法 / 火法+ / 炎术师 / 灾厄法师` 这类具象职业演化示例 → 一律不写入总纲与 Class 稿
- `3 波敌人` / `第 1 波 / 第 2 波` → 统一改为 `开场敌军 + 后备池增援`
- `battle_normal / battle_elite / boss` → 统一为 `normal_battle / elite_battle / boss_battle`
- `encounterId`（作为节点到战斗的对外字段）→ 统一为 `battle_id`

---

## 6. 敌人

敌人只分为：

- `普通怪`：数量多、血量低
- `精英怪`：带机制、能打断连锁
- `Boss`：改变战场规则，拥有专属增援

敌人不是玩家构筑对象，统一作为**Build 的燃料**存在。

---

## 7. 数值口径

- 输出必须明显高于治疗
- 单位死亡节奏控制在 `3~6` 次有效攻击内
- 难度提升**只**通过以下四项调节：
  - 后备单位数量
  - 刷新频率
  - 高威胁目标比例
  - 敌军组合
- 5e 核心公式保留：`HP / AC / hit bonus / spell DC / damage` 统一采用现有 5e helper

---

## 8. AI 原则

- 自动战斗只做极简目标评分
- 不做寻路、卡位、复杂技能判断
- 自动战斗的目标倾向由**职业核心技**按职业加点，不改公共框架

---

## 9. 玩家操作边界

- 玩家只操作：
  - 地图路线选择
  - 节点内服务选择（招募 / 商店 / 事件 / 营地）
  - 职业卡三选一
- 玩家**不操作**角色技能、战场走位、增援刷新时机

> 战术技能系统（全局级主动技能）在 MVP 阶段暂不做。后续若纳入，必须单独立稿，并在总纲加入条目。

---

## 10. MVP 范围

- 1 张章节地图（Act 1）
- 2 条主路线：`safe` / `high_pressure`
- 7 类节点：`normal_battle / elite_battle / boss_battle / recruit / shop / event / camp`
- 物理 6 职业 + 法系 4 职业（详见 `class_promotion_design.md`）
- 每个职业低 / 中 / 高三阶技能包
- 战斗后经验升级 + 固定恢复 + 职业卡三选一
- 装备由商店、事件、战斗掉落产出

---

## 11. 文档关系

```text
minibattle_combat_design_document_v_1.md  ← 规则源
├── single_battle_design.md               ← 战场结构、回合、增援、胜负
│   └── single_battle_parameter_table.md
├── roguelike_run_system_design.md        ← Run 主循环、章节、路线
│   ├── roguelike_node_parameter_table.md
│   └── roguelike_service_parameter_table.md
└── class_system_design.md                ← 职业规则
    ├── class_promotion_design.md
    ├── physical_class_core_skill_design.md
    └── caster_class_core_skill_design.md
```

---

## 12. 一页结论

```text
固定 3 前排 + 3 后排
自动回合制
开场敌军 + 后备池增援
战斗后固定恢复
战斗后职业卡三选一（新职业单位 / 同职业进阶）
职业阶段 low → mid → high
装备由商店、事件、战斗掉落产出
路线分 safe / high_pressure / boss_path
Boss 通关即章节结算
```
