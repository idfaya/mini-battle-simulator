# MiniBattle 单场战斗参数表

## 1. 战斗主表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 战斗编号 |
| `name` | string | 文本 | 战斗名称 |
| `act` | string | 章节编号 | 所属章节 |
| `type` | enum | `normal` / `elite` / `boss` | 战斗类型 |
| `route` | enum | `safe` / `high_pressure` / `boss_path` | 路线档位 |
| `wave_group_ids` | string[] | 编组编号列表 | 敌军波次列表，按顺序依次刷出 |
| `exp_reward` | integer | `0+` | 胜利后发放给存活上阵单位的经验 |
| `refresh_turns` | integer | `0~2` | 波次刷新间隔；`0` 表示仅清场后刷下一波 |
| `refresh_on_clear` | boolean | `true` / `false` | 清场立刷 |
| `spawn_order` | enum | `back_first_then_front` | 补位顺序 |
| `win_rule` | enum | `reserve_empty_and_board_clear` | 胜利条件，Boss 战也必须清场 |
| `lose_rule` | enum | `all_hero_dead` | 失败条件 |
| `boss_id` | string | Boss 编号或空 | Boss 主体 |
| `boss_phase_count` | integer | `0~3` | Boss 阶段数 |
| `boss_refresh_turns` | integer | `0` / `1` / `2` | Boss 增援间隔 |
| `boss_phase_trigger` | string | 阈值文本或空 | Boss 阶段触发 |

---

## 2. 敌军编组表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 编组编号 |
| `name` | string | 编组名称 |
| `front` | string[] | 前排单位列表 |
| `back` | string[] | 后排单位列表 |
| `elite` | string[] | 精英单位列表 |
| `boss` | string | Boss 单位编号或空 |
| `guards` | string[] | Boss 护卫列表 |

---

## 3. 固定默认值

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
| `target_priority_rule` | `front_then_nearest_then_focus` |
| `spawn_fill_target` | `battlefield_cap` |
| `keep_front_back_structure` | `true` |

---

## 4. 模板

### 4.1 normal

| 字段 | 推荐值 |
| --- | --- |
| `type` | `normal` |
| `route` | `safe` 或 `high_pressure` |
| `wave_group_ids` | `2~3` 个编组 |
| `exp_reward` | `20` |
| `refresh_turns` | `0` |
| `refresh_on_clear` | `true` |
| `spawn_order` | `back_first_then_front` |
| `win_rule` | `reserve_empty_and_board_clear` |
| `lose_rule` | `all_hero_dead` |
| `boss_id` | 空 |
| `boss_phase_count` | `0` |
| `boss_refresh_turns` | `0` |
| `boss_phase_trigger` | 空 |

### 4.2 elite

| 字段 | 推荐值 |
| --- | --- |
| `type` | `elite` |
| `route` | `high_pressure` |
| `wave_group_ids` | `2~3` 个编组 |
| `exp_reward` | `36` |
| `refresh_turns` | `0` |
| `refresh_on_clear` | `true` |
| `spawn_order` | `back_first_then_front` |
| `win_rule` | `reserve_empty_and_board_clear` |
| `lose_rule` | `all_hero_dead` |
| `boss_id` | 空 |
| `boss_phase_count` | `0` |
| `boss_refresh_turns` | `0` |
| `boss_phase_trigger` | 空 |

### 4.3 boss

| 字段 | 推荐值 |
| --- | --- |
| `type` | `boss` |
| `route` | `boss_path` |
| `wave_group_ids` | `2~4` 个编组，最后一波通常含 Boss |
| `exp_reward` | `60` |
| `refresh_turns` | `0` |
| `refresh_on_clear` | `true` |
| `spawn_order` | `back_first_then_front` |
| `win_rule` | `reserve_empty_and_board_clear` |
| `lose_rule` | `all_hero_dead` |
| `boss_id` | 必填 |
| `boss_phase_count` | `1~3` |
| `boss_refresh_turns` | `1` 或 `2` |
| `boss_phase_trigger` | `hp70|40` |

---

## 5. 最小配置集

普通战 / 精英战：

- `id`
- `name`
- `act`
- `type`
- `route`
- `wave_group_ids`
- `exp_reward`
- `refresh_turns`
- `refresh_on_clear`
- `spawn_order`
- `win_rule`
- `lose_rule`

Boss 战额外字段：

- `boss_id`
- `boss_phase_count`
- `boss_refresh_turns`
- `boss_phase_trigger`

---

## 6. 对外接口

### 6.1 Run 节点接入

Run 节点统一通过以下关系接入战斗主表：

```text
roguelike_run_system_design.md
→ node.battle_id
→ single_battle_parameter_table.id
```

### 6.2 战斗结算输出

单场战斗统一向 Run 层输出以下结果：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `battle_result` | enum | `win` / `lose` |
| `dead_units` | string[] | 本场死亡单位 |
| `survive_units` | string[] | 本场存活单位 |
| `hp_snapshot` | table | 本场结束生命快照 |
| `exp_gain` | table | 各 `unit_id` 的经验结算结果 |
| `level_up_result` | table | 各 `unit_id` 的升级结果 |

---

## 7. 示例

### 7.1 战斗主表

```text
id = act1_normal_01
name = 墓园外围
act = act1
type = normal
route = safe
wave_group_ids = enemy_group_act1_wave_01,enemy_group_act1_wave_02
exp_reward = 20
refresh_turns = 0
refresh_on_clear = true
spawn_order = back_first_then_front
win_rule = reserve_empty_and_board_clear
lose_rule = all_hero_dead
boss_id =
boss_phase_count = 0
boss_refresh_turns = 0
boss_phase_trigger =
```

### 7.2 Boss 战斗主表

```text
id = act1_boss_01
name = 墓园领主
act = act1
type = boss
route = boss_path
wave_group_ids = enemy_group_act1_boss_wave_01,enemy_group_act1_boss_wave_02,enemy_group_act1_boss_wave_03
exp_reward = 60
refresh_turns = 0
refresh_on_clear = true
spawn_order = back_first_then_front
win_rule = reserve_empty_and_board_clear
lose_rule = all_hero_dead
boss_id = graveyard_lord
boss_phase_count = 3
boss_refresh_turns = 2
boss_phase_trigger = hp70|40
```

### 7.3 敌军编组表

```text
id = enemy_group_act1_wave_01
name = 墓园外围第一波
front = zombie_grunt,zombie_grunt
back = bone_thrower
elite =
boss =
guards =
```
