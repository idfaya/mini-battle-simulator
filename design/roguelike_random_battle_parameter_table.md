# MiniBattle Roguelike 随机关卡与怪物参数表

## 1. 文档范围

- 本文档定义 Roguelike 随机生成中的 `关卡层` 与 `怪物层` 参数结构。
- 本文档对应 `roguelike_random_generation_design.md` 中的：
  - 关卡随机规则
  - 怪物随机规则
- 本文档用于替代固定图时代 `node -> battle_id -> 固定 enemyIds` 的单一路径接法。

---

## 2. 战斗模板池表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 战斗模板池编号 |
| `name` | string | 文本 | 池名称 |
| `act` | string | 章节编号 | 所属章节 |
| `floor_min` | integer | 正整数 | 最低层 |
| `floor_max` | integer | 正整数 | 最高层 |
| `kind` | enum | `normal` / `elite` / `boss` / `event_battle` | 战斗类型 |
| `difficulty_band` | enum | `easy` / `medium` / `hard` / `deadly` | 推荐难度带 |
| `entry_count` | integer | `1+` | 模板候选数 |
| `allow_repeat_in_run` | boolean | `true` / `false` | 本局是否允许重复 |

---

## 3. 战斗模板池条目表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `pool_id` | string | 有效池编号 | 所属模板池 |
| `battle_template_id` | string | 模板编号 | 战斗模板入口 |
| `weight` | integer | `0+` | 抽取权重 |
| `min_run_progress` | number | `0~1` | 本局最小进度要求 |
| `max_run_progress` | number | `0~1` | 本局最大进度要求 |

---

## 4. 战斗模板主表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 战斗模板编号 |
| `name` | string | 文本 | 模板名称 |
| `kind` | enum | `normal` / `elite` / `boss` / `event_battle` | 战斗类型 |
| `exp_reward` | integer | `0+` | 胜利经验 |
| `wave_count_min` | integer | `1+` | 最少波次数 |
| `wave_count_max` | integer | `1+` | 最多波次数 |
| `refresh_turns` | integer | `0~3` | 波次刷新间隔；`0` 表示仅清场后进入下一波 |
| `refresh_on_clear` | boolean | `true` / `false` | 清场是否立刷 |
| `spawn_order` | enum | `back_first_then_front` / `front_first_then_back` | 补位顺序 |
| `win_rule` | enum | `reserve_empty_and_board_clear` | 胜利条件，Boss 战也必须清场 |
| `lose_rule` | enum | `all_hero_dead` | 失败条件 |
| `boss_required` | boolean | `true` / `false` | 是否必须有 Boss 本体 |
| `boss_phase_group_id` | string | 编号或空 | Boss 阶段组 |
| `wave_group_pool_id` | string | 编号 | 波次组池入口 |
| `encounter_pool_id` | string | 遭遇池编号 | 怪物层预算/强度入口 |
| `theme_tag` | string | 文本 | 主题标签 |

---

## 5. 遭遇池主表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 遭遇池编号 |
| `name` | string | 文本 | 遭遇池名称 |
| `act` | string | 章节编号 | 所属章节 |
| `kind` | enum | `normal` / `elite` / `boss` / `event_battle` | 战斗类型 |
| `budget_difficulty` | enum | `easy` / `medium` / `hard` / `deadly` | 核心难度 |
| `pressure_factor` | number | 正数 | 压强系数 |
| `initial_energy_min` | integer | `0+` | 初始能量下限 |
| `initial_energy_max` | integer | `0+` | 初始能量上限 |
| `gold_min` | integer | `0+` | 金币下限 |
| `gold_max` | integer | `0+` | 金币上限 |
| `player_scale_id` | string | 配置编号 | 玩家侧轻量修正 |
| `enemy_scale_id` | string | 配置编号 | 敌人侧轻量修正 |
| `formation_pool_id` | string | 配置编号 | 编成模板池入口 |

---

## 5.1 波次组池表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 波次组池编号 |
| `name` | string | 文本 | 池名称 |
| `entry_count` | integer | `1+` | 候选数量 |
| `allow_repeat_wave_group` | boolean | `true` / `false` | 单场是否允许重复波次组 |

---

## 5.2 波次组池条目表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `wave_group_pool_id` | string | 有效池编号 | 所属波次组池 |
| `wave_group_template_id` | string | 模板编号 | 波次组模板入口 |
| `weight` | integer | `0+` | 抽取权重 |
| `min_wave_index` | integer | `1+` | 最早可出现波次序号 |
| `max_wave_index` | integer | `1+` | 最晚可出现波次序号 |

---

## 5.3 波次组模板表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 波次组模板编号 |
| `name` | string | 文本 | 模板名称 |
| `kind` | enum | `normal` / `elite` / `boss` / `event_battle` | 波次战斗类型 |
| `formation_profile_id` | string | 模板编号 | 单波编成模板 |
| `encounter_pool_override_id` | string | 编号或空 | 若不为空则覆盖战斗默认遭遇池 |
| `must_include_boss` | boolean | `true` / `false` | 本波是否必须包含 Boss |
| `must_be_last_wave` | boolean | `true` / `false` | 是否必须作为最后一波 |
| `theme_tag` | string | 文本 | 波次主题标签 |

---

## 6. 玩家轻量修正表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 修正编号 |
| `hp` | number | 正数 | 生命倍率 |
| `atk` | number | 正数 | 攻击倍率 |
| `def` | number | 正数 | 防御倍率 |
| `energy_bonus` | integer | 可正可负 | 初始额外能量 |

说明：

- 玩家侧修正仅用于微调容错。
- 不用于主导难度，不得替代预算系统。

---

## 7. 敌人轻量修正表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 修正编号 |
| `hp` | number | 正数 | 生命倍率 |
| `atk` | number | 正数 | 攻击倍率 |
| `def` | number | 正数 | 防御倍率 |
| `hit_delta` | integer | 小整数 | 命中修正 |
| `spell_dc_delta` | integer | 小整数 | 法术 DC 修正 |
| `save_delta` | integer | 小整数 | 豁免修正 |

说明：

- 敌人轻量修正仅保留语义化微调。
- 不允许用大倍率堆砌难度。

---

## 8. 编成模板池表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 编成模板池编号 |
| `name` | string | 文本 | 池名称 |
| `entry_count` | integer | `1+` | 候选数量 |

---

## 9. 编成模板池条目表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `formation_pool_id` | string | 有效池编号 | 所属编成池 |
| `formation_profile_id` | string | 模板编号 | 编成模板入口 |
| `weight` | integer | `0+` | 抽取权重 |

---

## 10. 怪物编成模板表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 编成模板编号 |
| `name` | string | 文本 | 编成模板名称 |
| `front_slots` | integer | `0~3` | 前排数量 |
| `back_slots` | integer | `0~3` | 后排数量 |
| `wave_unit_cap` | integer | `1~6` | 单波单位上限 |
| `required_tags` | string[] | 标签列表 | 必须出现的怪物标签 |
| `forbidden_tags` | string[] | 标签列表 | 禁止出现的怪物标签 |
| `max_same_enemy` | integer | `1+` | 单怪最大重复数 |
| `front_pool_id` | string | 编号或空 | 前排候选池 |
| `back_pool_id` | string | 编号或空 | 后排候选池 |
| `guard_pool_id` | string | 编号或空 | 护卫候选池 |
| `reinforce_pool_id` | string | 编号或空 | 增援候选池 |
| `boss_pool_id` | string | 编号或空 | Boss 候选池 |

---

## 11. 怪物候选池表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 怪物候选池编号 |
| `name` | string | 文本 | 候选池名称 |
| `allow_boss` | boolean | `true` / `false` | 是否允许 Boss |
| `allow_elite_only` | boolean | `true` / `false` | 是否允许精英专属怪 |
| `entry_count` | integer | `1+` | 候选数量 |

---

## 12. 怪物候选条目表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `pool_id` | string | 有效池编号 | 所属候选池 |
| `enemy_id` | string | 怪物编号 | 候选怪物 |
| `weight` | integer | `0+` | 抽取权重 |
| `tags` | string[] | 标签列表 | 语义标签 |
| `min_floor` | integer | `1+` | 最低允许层 |
| `max_floor` | integer | `1+` | 最高允许层 |
| `max_repeat_in_battle` | integer | `1+` | 单场最大重复数 |

推荐标签：

- `frontliner`
- `backliner`
- `caster`
- `summoner`
- `undead`
- `beast`
- `guard`
- `boss`
- `elite_only`

---

## 13. Boss 模板补充表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | Boss 规则编号 |
| `boss_required` | boolean | `true` | Boss 本体必出 |
| `guard_count_min` | integer | `0+` | 护卫最少数量 |
| `guard_count_max` | integer | `0+` | 护卫最多数量 |
| `boss_wave_min` | integer | `1+` | Boss 最早出现波次 |
| `boss_wave_max` | integer | `1+` | Boss 最晚出现波次 |
| `boss_must_last` | boolean | `true` / `false` | Boss 是否必须最后出场 |
| `win_rule_override` | enum | 空 | 预留字段，当前不启用特殊胜利条件 |

---

## 14. 战斗实例输出结构

随机关卡在进入战斗前，应组装出统一战斗实例：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `battle_template_id` | string | 所选战斗模板 |
| `encounter_pool_id` | string | 所选遭遇池 |
| `wave_group_ids` | string[] | 所选波次组实例列表 |
| `kind` | enum | 战斗类型 |
| `exp_reward` | integer | 经验奖励 |
| `refresh_turns` | integer | 刷新轮次 |
| `refresh_on_clear` | boolean | 清场刷新 |
| `spawn_order` | enum | 刷怪顺序 |
| `win_rule` | enum | 胜利规则 |
| `lose_rule` | enum | 失败规则 |
| `wave_groups` | table[] | 实际波次组列表 |
| `initial_energy` | integer | 本场初始能量 |
| `gold_min` | integer | 本场金币下限 |
| `gold_max` | integer | 本场金币上限 |

---

## 15. 对外接口

### 15.1 地图节点到战斗模板

```text
node_instance.content_pool_id
→ battle_pool.id
→ battle_template_id
```

### 15.2 战斗模板到怪物层

```text
battle_template.wave_group_pool_id
→ wave_group_template_id[]
→ battle_template.encounter_pool_id
→ encounter_pool.id
→ formation_profile_id
→ enemy_pick_pool.id / boss_pool.id / reinforce_pool.id
→ battle_instance
```

### 15.3 战斗结算输出

随机战斗统一向 Run 层输出以下结果：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `battle_result` | enum | `win` / `lose` |
| `dead_units` | string[] | 本场死亡单位 |
| `survive_units` | string[] | 本场存活单位 |
| `hp_snapshot` | table | 本场结束生命快照 |
| `reward_gold` | integer | 本场金币收益 |
| `exp_reward` | integer | 本场经验收益 |
| `enter_card_reward` | boolean | 是否进入职业卡三选一 |

---

## 16. Act 1 推荐模板

### 16.1 普通战模板池

```text
id = act1_mid_normal_pool_01
name = Act1 中段普通战池
act = act1
floor_min = 3
floor_max = 5
kind = normal
difficulty_band = medium
entry_count = 3
allow_repeat_in_run = false
```

### 16.2 普通战模板

```text
id = act1_normal_template_02
name = Act1 中段普通战模板
kind = normal
exp_reward = 24
wave_count_min = 2
wave_count_max = 3
refresh_turns = 0
refresh_on_clear = true
spawn_order = back_first_then_front
win_rule = reserve_empty_and_board_clear
lose_rule = all_hero_dead
boss_required = false
boss_phase_group_id =
wave_group_pool_id = act1_wave_group_pool_mid_01
encounter_pool_id = act1_normal_encounter_pool_02
theme_tag = ruins_snowfield
```

### 16.3 遭遇池

```text
id = act1_normal_encounter_pool_02
name = Act1 中段普通遭遇池
act = act1
kind = normal
budget_difficulty = medium
pressure_factor = 0.90
initial_energy_min = 80
initial_energy_max = 100
gold_min = 28
gold_max = 42
player_scale_id = act1_player_scale_mid_01
enemy_scale_id = act1_enemy_scale_mid_01
formation_pool_id = act1_formation_pool_mid_01
```

### 16.4 波次组模板

```text
id = act1_wave_group_mid_01
name = 中段基础增援波次
kind = normal
formation_profile_id = act1_formation_mid_01
encounter_pool_override_id =
must_include_boss = false
must_be_last_wave = false
theme_tag = ruins_snowfield
```

### 16.5 编成模板

```text
id = act1_formation_mid_01
name = 2前1后基础编成
front_slots = 2
back_slots = 1
wave_unit_cap = 3
required_tags = frontliner
forbidden_tags = boss
max_same_enemy = 2
front_pool_id = act1_front_pool_01
back_pool_id = act1_back_pool_01
guard_pool_id =
reinforce_pool_id = act1_reinforce_pool_01
boss_pool_id =
```

### 16.6 怪物候选条目

```text
pool_id = act1_front_pool_01
enemy_id = skeleton_guard
weight = 40
tags = frontliner,undead
min_floor = 1
max_floor = 6
max_repeat_in_battle = 2
```

```text
pool_id = act1_back_pool_01
enemy_id = bone_thrower
weight = 35
tags = backliner,undead
min_floor = 2
max_floor = 6
max_repeat_in_battle = 2
```

### 16.7 Boss 模板

```text
id = act1_boss_template_01
name = Frozen Gate Boss 模板
kind = boss
exp_reward = 60
wave_count_min = 2
wave_count_max = 3
refresh_turns = 0
refresh_on_clear = true
spawn_order = back_first_then_front
win_rule = reserve_empty_and_board_clear
lose_rule = all_hero_dead
boss_required = true
boss_phase_group_id = act1_boss_phase_group_01
wave_group_pool_id = act1_boss_wave_group_pool_01
encounter_pool_id = act1_boss_encounter_pool_01
theme_tag = frozen_gate
```

---

## 17. 合法性检查清单

- 普通战、精英战、Boss 战、事件战必须各走各自模板池。
- `budget_difficulty` 与 `pressure_factor` 必须完整存在。
- Boss 模板必须产出合法 Boss 本体。
- 编成模板必须满足槽位、标签与重复数约束。
- 随机结果不得出现空战斗、空波次列表、无 Boss 的 Boss 战。
