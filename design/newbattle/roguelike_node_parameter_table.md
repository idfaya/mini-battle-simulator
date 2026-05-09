# MiniBattle Roguelike 节点参数表

## 1. 节点主表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 节点编号 |
| `act` | string | 章节编号 | 所属章节 |
| `type` | enum | `normal_battle` / `elite_battle` / `boss_battle` / `recruit` / `shop` / `event` / `camp` | 节点类型 |
| `route` | enum | `safe` / `high_pressure` / `boss_path` | 路线档位 |
| `layer` | integer | 正整数 | 所在层级 |
| `battle_id` | string | 战斗编号或空 | 固定图模式战斗节点入口 |
| `battle_pool_id` | string | 战斗池编号或空 | 随机图模式战斗节点入口 |
| `shop_id` | string | 商店编号或空 | 商店节点入口 |
| `event_id` | string | 事件编号或空 | 事件节点入口 |
| `camp_id` | string | 营地编号或空 | 营地节点入口 |
| `recruit_id` | string | 招募编号或空 | 招募节点入口 |
| `reward_gold` | integer | `0+` | 节点固定金币收益 |
| `reward_equip_count` | integer | `0+` | 节点装备掉落次数 |
| `next_nodes` | string[] | 节点编号列表 | 下一跳节点 |

---

## 2. 节点类型模板

### 2.1 normal_battle

| 字段 | 推荐值 |
| --- | --- |
| `type` | `normal_battle` |
| `battle_id` | 固定图模式必填 |
| `battle_pool_id` | 随机图模式必填 |
| `reward_gold` | `1~2` |
| `reward_equip_count` | `0~1` |

### 2.2 elite_battle

| 字段 | 推荐值 |
| --- | --- |
| `type` | `elite_battle` |
| `battle_id` | 固定图模式必填 |
| `battle_pool_id` | 随机图模式必填 |
| `reward_gold` | `2~4` |
| `reward_equip_count` | `1` |

### 2.3 boss_battle

| 字段 | 推荐值 |
| --- | --- |
| `type` | `boss_battle` |
| `battle_id` | 固定图模式必填 |
| `battle_pool_id` | 随机图模式必填 |
| `route` | `boss_path` |
| `reward_gold` | `0` 或章节结算处理 |
| `reward_equip_count` | `0` 或章节结算处理 |

### 2.4 recruit

| 字段 | 推荐值 |
| --- | --- |
| `type` | `recruit` |
| `recruit_id` | 必填 |
| `reward_gold` | `0` |
| `reward_equip_count` | `0` |

### 2.5 shop

| 字段 | 推荐值 |
| --- | --- |
| `type` | `shop` |
| `shop_id` | 必填 |
| `reward_gold` | `0` |
| `reward_equip_count` | `0` |

### 2.6 event

| 字段 | 推荐值 |
| --- | --- |
| `type` | `event` |
| `event_id` | 必填 |
| `reward_gold` | `0` |
| `reward_equip_count` | `0` |

### 2.7 camp

| 字段 | 推荐值 |
| --- | --- |
| `type` | `camp` |
| `camp_id` | 必填 |
| `reward_gold` | `0` |
| `reward_equip_count` | `0` |

---

## 3. 对外接口

### 3.1 节点到战斗

固定图模式：

```text
roguelike_node_parameter_table.id
→ battle_id
→ single_battle_parameter_table.id
```

随机图模式：

```text
roguelike_node_parameter_table.id
→ battle_pool_id
→ battle_template.id
→ wave_group_pool.id
→ wave_group_ids
```

### 3.2 战斗到职业卡

```text
normal_battle / elite_battle
→ 战斗胜利
→ 固定恢复
→ 职业卡三选一
```

节点结算阶段统一向 Run 层传递：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `battle_result` | enum | `win` / `lose` |
| `reward_gold` | integer | 节点金币收益 |
| `reward_equip_count` | integer | 节点装备掉落次数 |
| `enter_card_reward` | boolean | 是否进入职业卡三选一 |

### 3.3 节点到其他系统

```text
shop
→ shop_id

event
→ event_id

camp
→ camp_id

recruit
→ recruit_id
```

---

## 4. Act 1 最小层级结构

Act 1 建议采用以下层级：

```text
L1 起点
L2 分路
L3 中段节点
L4 中段节点
L5 收束节点
L6 Boss
```

---

## 5. Act 1 示例

### 5.1 节点主表

```text
id = act1_start_01
act = act1
type = normal_battle
route = safe
layer = 1
battle_id = act1_normal_01
battle_pool_id =
shop_id =
event_id =
camp_id =
recruit_id =
reward_gold = 1
reward_equip_count = 0
next_nodes = act1_safe_02,act1_high_02
```

```text
id = act1_safe_02
act = act1
type = recruit
route = safe
layer = 2
battle_id =
battle_pool_id =
shop_id =
event_id =
camp_id =
recruit_id = recruit_basic_01
reward_gold = 0
reward_equip_count = 0
next_nodes = act1_safe_03
```

```text
id = act1_high_02
act = act1
type = elite_battle
route = high_pressure
layer = 2
battle_id = act1_elite_01
battle_pool_id =
shop_id =
event_id =
camp_id =
recruit_id =
reward_gold = 3
reward_equip_count = 1
next_nodes = act1_high_03
```

```text
id = act1_safe_03
act = act1
type = shop
route = safe
layer = 3
battle_id =
battle_pool_id =
shop_id = shop_act1_01
event_id =
camp_id =
recruit_id =
reward_gold = 0
reward_equip_count = 0
next_nodes = act1_merge_04
```

```text
id = act1_high_03
act = act1
type = event
route = high_pressure
layer = 3
battle_id =
battle_pool_id =
shop_id =
event_id = event_act1_01
camp_id =
recruit_id =
reward_gold = 0
reward_equip_count = 0
next_nodes = act1_merge_04
```

```text
id = act1_merge_04
act = act1
type = normal_battle
route = safe
layer = 4
battle_id = act1_normal_02
battle_pool_id =
shop_id =
event_id =
camp_id =
recruit_id =
reward_gold = 2
reward_equip_count = 0
next_nodes = act1_camp_05,act1_elite_05
```

```text
id = act1_camp_05
act = act1
type = camp
route = safe
layer = 5
battle_id =
battle_pool_id =
shop_id =
event_id =
camp_id = camp_basic_01
recruit_id =
reward_gold = 0
reward_equip_count = 0
next_nodes = act1_boss_06
```

```text
id = act1_elite_05
act = act1
type = elite_battle
route = high_pressure
layer = 5
battle_id = act1_elite_02
battle_pool_id =
shop_id =
event_id =
camp_id =
recruit_id =
reward_gold = 4
reward_equip_count = 1
next_nodes = act1_boss_06
```

```text
id = act1_boss_06
act = act1
type = boss_battle
route = boss_path
layer = 6
battle_id = act1_boss_01
battle_pool_id =
shop_id =
event_id =
camp_id =
recruit_id =
reward_gold = 0
reward_equip_count = 0
next_nodes =
```

---

## 6. 一页结论

节点表只负责三件事：

```text
节点类型
节点入口
节点连线
```

战斗入口统一接：

```text
固定图：battle_id → single_battle_parameter_table.id
随机图：battle_pool_id → battle_template.id → wave_group_ids
```
