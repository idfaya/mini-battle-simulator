# MiniBattle Roguelike 随机地图参数表

## 1. 文档范围

- 本文档定义 Roguelike 随机地图层的参数结构。
- 本文档对应 `roguelike_random_generation_design.md` 中的 `地图层` 设计。
- 本文档只处理：
  - 章节地图生成配置
  - 节点实例结构
  - 节点类型权重
  - 路线风格
  - 地图合法性约束

---

## 2. 地图生成配置主表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 地图生成配置编号 |
| `name` | string | 文本 | 配置名称 |
| `act` | string | 章节编号 | 所属章节 |
| `floor_count` | integer | 正整数 | 总层数 |
| `start_floor` | integer | `1` | 起始层 |
| `boss_floor` | integer | `2+` | Boss 所在层 |
| `start_node_count` | integer | `1` | 起点层节点数 |
| `boss_node_count` | integer | `1` | Boss 层节点数 |
| `default_map_vision` | enum | `node_type_only` / `unknown` | 默认地图视野规则 |
| `route_style_weights` | table | 权重表 | 稳健 / 高压风格权重 |
| `node_count_rule_id` | string | 规则编号 | 每层节点数规则 |
| `node_type_rule_id` | string | 规则编号 | 每层节点类型规则 |
| `connection_rule_id` | string | 规则编号 | 连线生成规则 |
| `constraint_rule_id` | string | 规则编号 | 地图约束规则 |
| `map_seed_version` | integer | 正整数 | 地图生成版本 |

---

## 3. 每层节点数规则表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 规则编号 |
| `floor` | integer | 正整数 | 层级 |
| `min_count` | integer | `1+` | 本层最少节点数 |
| `max_count` | integer | `1+` | 本层最多节点数 |
| `prefer_count` | integer | `1+` | 本层推荐节点数 |
| `allow_merge` | boolean | `true` / `false` | 是否允许本层作为汇合层 |
| `allow_split` | boolean | `true` / `false` | 是否允许本层作为分叉层 |

---

## 4. 节点类型规则表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 规则编号 |
| `floor` | integer | 正整数 | 层级 |
| `route_style` | enum | `safe` / `high_pressure` / `any` | 路线风格 |
| `allow_battle_normal` | boolean | `true` / `false` | 是否允许普通战 |
| `allow_battle_elite` | boolean | `true` / `false` | 是否允许精英战 |
| `allow_boss` | boolean | `true` / `false` | 是否允许 Boss |
| `allow_recruit` | boolean | `true` / `false` | 是否允许招募 |
| `allow_shop` | boolean | `true` / `false` | 是否允许商店 |
| `allow_event` | boolean | `true` / `false` | 是否允许事件 |
| `allow_camp` | boolean | `true` / `false` | 是否允许营地 |
| `weight_battle_normal` | integer | `0+` | 普通战权重 |
| `weight_battle_elite` | integer | `0+` | 精英战权重 |
| `weight_boss` | integer | `0+` | Boss 权重 |
| `weight_recruit` | integer | `0+` | 招募权重 |
| `weight_shop` | integer | `0+` | 商店权重 |
| `weight_event` | integer | `0+` | 事件权重 |
| `weight_camp` | integer | `0+` | 营地权重 |

---

## 5. 连线规则表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 规则编号 |
| `max_outgoing_per_node` | integer | `1~3` | 单节点最大后继数 |
| `max_incoming_per_node` | integer | `1~3` | 单节点最大前驱数 |
| `prefer_straight_lane` | boolean | `true` / `false` | 是否优先直连相邻 lane |
| `allow_cross_lane` | boolean | `true` / `false` | 是否允许跨列连线 |
| `force_full_reachability` | boolean | `true` / `false` | 是否强制所有节点可达 |
| `force_boss_reachability` | boolean | `true` / `false` | 是否强制 Boss 可达 |
| `avoid_dense_crossing` | boolean | `true` / `false` | 是否避免连线过密 |

---

## 6. 地图约束规则表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 规则编号 |
| `min_battle_normal` | integer | `0+` | 最少普通战节点数 |
| `max_battle_normal` | integer | `0+` | 最多普通战节点数 |
| `min_battle_elite` | integer | `0+` | 最少精英战节点数 |
| `max_battle_elite` | integer | `0+` | 最多精英战节点数 |
| `min_recruit` | integer | `0+` | 最少招募节点数 |
| `max_recruit` | integer | `0+` | 最多招募节点数 |
| `min_shop` | integer | `0+` | 最少商店节点数 |
| `max_shop` | integer | `0+` | 最多商店节点数 |
| `min_event` | integer | `0+` | 最少事件节点数 |
| `max_event` | integer | `0+` | 最多事件节点数 |
| `min_camp` | integer | `0+` | 最少营地节点数 |
| `max_camp` | integer | `0+` | 最多营地节点数 |
| `min_battle_ratio` | number | `0~1` | 战斗节点最低占比 |
| `max_consecutive_elite_floors` | integer | `0+` | 连续精英层上限 |
| `min_shop_gap` | integer | `0+` | 商店最小层间隔 |
| `min_camp_gap` | integer | `0+` | 营地最小层间隔 |
| `recruit_forbid_before_boss_floors` | integer | `0+` | Boss 前禁招募层数 |

---

## 7. 路线风格权重表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `style` | enum | `safe` / `high_pressure` | 路线风格 |
| `weight` | integer | `0+` | 风格权重 |
| `prefer_battle` | integer | `0+` | 战斗节点偏好 |
| `prefer_service` | integer | `0+` | 服务节点偏好 |
| `prefer_elite` | integer | `0+` | 精英节点偏好 |
| `prefer_recovery` | integer | `0+` | 恢复节点偏好 |

---

## 8. 节点实例结构

随机地图生成后，每个节点实例统一输出以下字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `node_instance_id` | string | 本局节点实例编号 |
| `act` | string | 所属章节 |
| `floor` | integer | 所在层级 |
| `lane` | integer | 所在列 |
| `type` | enum | `battle_normal` / `battle_elite` / `boss` / `recruit` / `shop` / `event` / `camp` |
| `route_style` | enum | `safe` / `high_pressure` |
| `content_pool_id` | string | 内容池入口编号 |
| `title_visibility` | enum | `hidden` / `node_type_only` / `full` |
| `revealed` | boolean | 是否已揭示 |
| `visited` | boolean | 是否已进入 |
| `next_nodes` | string[] | 下一跳节点实例编号 |

---

## 9. 对外接口

### 9.1 地图生成到 Run

```text
map_gen_profile.id
→ 生成地图实例
→ node_instance[]
→ Run 地图快照
```

### 9.2 节点实例到内容层

```text
node_instance.type = battle node
→ node_instance.content_pool_id
→ battle_pool.id
→ battle_template.id
→ wave_group_pool.id

node_instance.type = recruit / shop / event / camp
→ node_instance.content_pool_id
→ 对应服务池.id
```

### 9.3 节点选择输出

Run 层统一需要以下字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `current_node_instance_id` | string | 当前节点实例 |
| `available_next_nodes` | string[] | 当前可选后继节点 |
| `visited_node_ids` | string[] | 已访问节点 |
| `revealed_node_ids` | string[] | 已揭示节点 |

---

## 10. Act 1 推荐模板

### 10.1 地图生成配置

```text
id = act1_random_map_01
name = Act1 随机地图
act = act1
floor_count = 8
start_floor = 1
boss_floor = 8
start_node_count = 1
boss_node_count = 1
default_map_vision = node_type_only
route_style_weights = safe:50,high_pressure:50
node_count_rule_id = act1_node_count_rule_01
node_type_rule_id = act1_node_type_rule_01
connection_rule_id = act1_connection_rule_01
constraint_rule_id = act1_constraint_rule_01
map_seed_version = 1
```

### 10.2 每层节点数规则

```text
id = act1_node_count_rule_01
floor1 = 1
floor2 = 2
floor3 = 2~3
floor4 = 2~3
floor5 = 2~3
floor6 = 2
floor7 = 1
floor8 = 1
```

### 10.3 地图约束规则

```text
id = act1_constraint_rule_01
min_battle_normal = 4
max_battle_normal = 5
min_battle_elite = 1
max_battle_elite = 2
min_recruit = 1
max_recruit = 2
min_shop = 1
max_shop = 1
min_event = 1
max_event = 2
min_camp = 1
max_camp = 1
min_battle_ratio = 0.60
max_consecutive_elite_floors = 1
min_shop_gap = 2
min_camp_gap = 2
recruit_forbid_before_boss_floors = 2
```

---

## 11. 合法性检查清单

- 起点节点数量必须为 `1`。
- Boss 层节点数量必须为 `1`。
- 所有节点必须可从起点到达。
- Boss 必须可从任一合法中段路径到达。
- 节点类型数量必须满足约束规则。
- 任何层都不能生成空层。
- 战斗节点占比不得低于配置要求。
