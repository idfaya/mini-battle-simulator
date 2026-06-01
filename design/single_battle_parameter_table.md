# MiniBattle 单场战斗参数表

## 1. 文档范围

- 本文档定义单场战斗的当前参数口径，覆盖 `battle_id`、波次、增援与结算输出。
- 难度与奖励采用当前 Roguelike 方案：敌军组成走 `wave_group_ids`，压力走 `budget`，经验走 `partyExp`，不再维护旧式 `route / exp_reward` 静态字段。
- 随机遭遇、budget 与怪物生成细节见 [`roguelike_random_battle_parameter_table.md`](./roguelike_random_battle_parameter_table.md)。

---

## 2. 战斗入口表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `battle_id` | integer | 唯一值 | 战斗编号；Run 节点对外统一使用该字段 |
| `name` | string | 文本 | 战斗名称 |
| `chapter_id` | integer | 章节编号 | 所属章节 |
| `kind` | enum | `normal` / `elite` / `boss` / `event_battle` | 战斗类型 |
| `wave_group_ids` | integer[] | 编组编号列表 | 敌军波次列表，按顺序刷出 |
| `refresh_turns` | integer | `0~2` | 波次刷新间隔；`0` 表示仅清场后刷下一波 |
| `refresh_on_clear` | boolean | `true` / `false` | 清场立刷 |
| `spawn_order` | enum | `back_first_then_front` | 补位顺序 |
| `win_rule` | enum | `reserve_empty_and_board_clear` | 胜利条件，Boss 战也必须清场 |
| `lose_rule` | enum | `all_hero_dead` | 失败条件 |
| `initial_energy` | integer | `0+` | 敌军开场能量 |
| `gold_min` | integer | `0+` | 金币下限 |
| `gold_max` | integer | `0+` | 金币上限 |
| `budget_difficulty` | enum | `easy` / `medium` / `hard` / `deadly` | budget 难度档 |
| `pressure_factor` | number | 正数 | 预算压强系数 |
| `boss_phase_group_id` | integer | 编号或空 | Boss 阶段组入口；普通战为空 |

---

## 3. 波次组表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `wave_group_id` | integer | 编组编号 |
| `name` | string | 编组名称 |
| `front` | integer[] | 前排单位列表 |
| `back` | integer[] | 后排单位列表 |
| `elite` | integer[] | 精英单位列表 |
| `boss` | integer | Boss 单位编号或空 |
| `guards` | integer[] | Boss 护卫列表 |

---

## 4. 固定默认值

| 字段 | 固定值 |
| --- | --- |
| `hero_front_slots` | `3` |
| `hero_back_slots` | `3` |
| `enemy_front_slots` | `3` |
| `enemy_back_slots` | `3` |
| `max_hero_units` | `6` |
| `max_enemy_units` | `6` |
| `turn_mode` | `auto_round` |
| `min_turn_count` | `6` |
| `max_turn_count` | `12` |
| `spawn_fill_target` | `battlefield_cap` |
| `keep_front_back_structure` | `true` |
| `default_refresh_turns` | `0` |
| `default_refresh_on_clear` | `true` |

---

## 5. 推荐模板

### 5.1 normal

| 字段 | 推荐值 |
| --- | --- |
| `kind` | `normal` |
| `wave_group_ids` | `2~3` 个编组 |
| `refresh_turns` | `0` |
| `refresh_on_clear` | `true` |
| `spawn_order` | `back_first_then_front` |
| `win_rule` | `reserve_empty_and_board_clear` |
| `lose_rule` | `all_hero_dead` |
| `budget_difficulty` | `easy` |
| `pressure_factor` | `0.10~0.14` |
| `boss_phase_group_id` | 空 |

### 5.2 elite

| 字段 | 推荐值 |
| --- | --- |
| `kind` | `elite` |
| `wave_group_ids` | `2~3` 个编组 |
| `refresh_turns` | `0` |
| `refresh_on_clear` | `true` |
| `spawn_order` | `back_first_then_front` |
| `win_rule` | `reserve_empty_and_board_clear` |
| `lose_rule` | `all_hero_dead` |
| `budget_difficulty` | `easy` 或 `medium` |
| `pressure_factor` | `0.14~0.20` |
| `boss_phase_group_id` | 空 |

### 5.3 boss

| 字段 | 推荐值 |
| --- | --- |
| `kind` | `boss` |
| `wave_group_ids` | `2~4` 个编组，最后一波通常含 Boss |
| `refresh_turns` | `0` 或 `1` |
| `refresh_on_clear` | `true` |
| `spawn_order` | `back_first_then_front` |
| `win_rule` | `reserve_empty_and_board_clear` |
| `lose_rule` | `all_hero_dead` |
| `budget_difficulty` | `easy` 或 `medium` |
| `pressure_factor` | `0.16~0.30` |
| `boss_phase_group_id` | 必填 |

### 5.4 event_battle

| 字段 | 推荐值 |
| --- | --- |
| `kind` | `event_battle` |
| `wave_group_ids` | `1~2` 个编组 |
| `refresh_turns` | `0` |
| `refresh_on_clear` | `true` |
| `spawn_order` | `back_first_then_front` |
| `win_rule` | `reserve_empty_and_board_clear` |
| `lose_rule` | `all_hero_dead` |
| `budget_difficulty` | `easy` |
| `pressure_factor` | `0.20~0.34` |
| `boss_phase_group_id` | 空 |

---

## 6. 最小配置集

普通战 / 精英战 / 事件战：

- `battle_id`
- `name`
- `chapter_id`
- `kind`
- `wave_group_ids`
- `refresh_turns`
- `refresh_on_clear`
- `spawn_order`
- `win_rule`
- `lose_rule`
- `initial_energy`
- `gold_min`
- `gold_max`
- `budget_difficulty`
- `pressure_factor`

Boss 战额外字段：

- `boss_phase_group_id`

---

## 7. 对外接口

### 7.1 Run 节点接入

Run 节点统一通过以下关系接入战斗参数：

```text
dungeon_design.md / config/roguelike/run_battle_*.lua
→ battle_id
→ run_battle_profile.lua
→ wave_group_ids / budget / boss_phase_group_id
```

### 7.2 战斗结算输出

单场战斗统一向 Run 层输出以下结果：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `battle_result` | enum | `win` / `lose` |
| `dead_units` | integer[] | 本场死亡单位 |
| `survive_units` | integer[] | 本场存活单位 |
| `hp_snapshot` | table | 本场结束生命快照 |
| `gold_gain` | integer | 本场金币结算 |
| `party_exp_gain` | integer | 发放到 `state.partyExp` 的经验 |

---

## 8. 示例

### 8.1 普通战入口

```text
battle_id = 101001
name = 墓园外围
chapter_id = 101
kind = normal
wave_group_ids = 10100101,10100102
refresh_turns = 0
refresh_on_clear = true
spawn_order = back_first_then_front
win_rule = reserve_empty_and_board_clear
lose_rule = all_hero_dead
initial_energy = 90
gold_min = 20
gold_max = 30
budget_difficulty = easy
pressure_factor = 0.10
boss_phase_group_id =
```

### 8.2 Boss 战入口

```text
battle_id = 101201
name = 墓园领主
chapter_id = 101
kind = boss
wave_group_ids = 10120101,10120102
refresh_turns = 0
refresh_on_clear = true
spawn_order = back_first_then_front
win_rule = reserve_empty_and_board_clear
lose_rule = all_hero_dead
initial_energy = 20
gold_min = 96
gold_max = 118
budget_difficulty = easy
pressure_factor = 0.16
boss_phase_group_id = 101201
```

### 8.3 波次组

```text
wave_group_id = 10100101
name = 墓园外围第一波
front = 300101,300101
back = 300201
elite =
boss =
guards =
```
