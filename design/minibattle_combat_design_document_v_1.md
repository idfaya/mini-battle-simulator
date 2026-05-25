# MiniBattle 战斗系统总纲 V1.1

## 0. 文档定位

- 本文档是 `MiniBattle` 战斗系统的**最高规则源**（战场、术语、敌军波次、难度口径）。
- Run 地图与养成见 [`dungeon_design.md`](./dungeon_design.md)、[`character_progression_design.md`](./character_progression_design.md)。**勿读** `design/legacy/`。
- 本文档只定义**硬规则与术语**，不重复下级稿件中的参数值与示例。

下级文档清单：

- `single_battle_design.md` / `single_battle_parameter_table.md`
- `dungeon_design.md` / `character_progression_design.md`
- `class_system_design.md`
- `physical_class_core_skill_design.md` / `caster_class_core_skill_design.md`
- `roguelike_random_battle_parameter_table.md` / `roguelike_monster_system_design.md`

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
进入地牢楼层（房间迷宫）
→ 选择相邻房间 / 楼梯
→ 结算房间（战斗 / 事件 / 商店 / 营地等）
→ 战斗胜利 → 金币与掉落 → partyExp → 若升级则 Feat 三选一 → 固定恢复
→ 章节 Boss 层通关 → 下一章或 Run 结束
```

细则见 [`dungeon_design.md`](./dungeon_design.md) 与 [`character_progression_design.md`](./character_progression_design.md)。

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
- Boss 战胜利条件：`后备池耗尽 且 战场清空`
- 失败条件：`Hero 全灭`

### 3.4 成长

- 战斗内无成长
- 战斗经验进入 `partyExp`；跨阈值触发**队伍升级**，从存活英雄「下一级可选 Feat」汇总池中随机三选一
- 普通战：经验 + 金币，一般无装备 / bless
- 精英战：经验 + 装备（必掉）+ 概率 bless
- Boss：章节级经验 / 金币 / 装备 / bless（见 `dungeon_design.md`）
- 子职业由 **Lv3 Feat** 锁定；**Lv5 Feat** 为子职 capstone；无职业卡、无挂起进阶、Run 内不扩编人数

### 3.5 装备与金币

- 装备 / bless：Run 级全局池，战斗前注入 Build；Run 结束清空
- 来源：精英战、宝箱房、商店、事件、Boss（见 `dungeon_design.md` / `equipment_system_design_v0_1.md`）
- 金币：房间与战斗结算；用于商店（含复活卷轴）

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
| `波次组 (wave_group)` | 某一波敌方单位编组，包含前后排/精英/Boss 等槽位 |
| `波次列表 (wave_group_ids)` | 战斗内按顺序刷出的敌军波次编号列表 |
| `增援 (reinforce)` | 当前波次清空后，下一波进入战场的行为 |
| `刷新节拍 (refresh_turns)` | 波次刷新间隔；当前推荐值为 `0`，即不做按回合刷新 |
| `清场立刷 (refresh_on_clear)` | 本回合场上敌人全部死亡时立即刷出下一波 |
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
| `battle_normal` | 普通战节点 |
| `battle_elite` | 精英战节点 |
| `boss` | Boss 战节点 |
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
- `normal_battle / elite_battle / boss_battle` → 统一为 `battle_normal / battle_elite / boss`
- `开场敌军 + 后备池增援`（用于描述实际多波结构时）→ 统一按 `波 / 第 2 波 / 第 3 波` 表达
- `encounterId / battleId`（作为节点到战斗的对外字段）→ 统一为 `battle_id`

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
  - 地牢房间 / 楼梯选择
  - 房间内交互（商店购买、事件选项、营地结算、升级 Feat 三选一）
- 玩家**不操作**角色技能、战场走位、增援刷新时机

> 战术技能系统（全局级主动技能）在 MVP 阶段暂不做。后续若纳入，必须单独立稿，并在总纲加入条目。

---

## 10. MVP 范围

- 3 章 × 5 层随机地牢（房间迷宫 + 楼梯），见 `dungeon_design.md`
- 房间类型：普通战 / 精英 / 装备 / 事件 / 营地 / 商店 / 楼梯 / Boss
- 10 职业（物理 6 + 法系 4），能力由 Feat → skill 驱动，见 `class_system_design.md` 与职业核心技稿
- 起手 4 人固定；`partyExp` + 升级 Feat 三选一；精英装备 + 概率 bless
- 实现进度见 `docs/dungeon_system_overall_plan.md`

---

## 11. 文档关系

见 [`README.md`](./README.md)。

---

## 12. 一页结论

```text
固定 3 前排 + 3 后排
自动回合制
按波次刷新敌军（清场立刷）
战斗后：partyExp → Feat 三选一 → 固定恢复
地牢房间迷宫，精英装备 + 概率 bless
起手 4 人，Run 内无招募扩编
Boss 层通关 → 章节推进
```
