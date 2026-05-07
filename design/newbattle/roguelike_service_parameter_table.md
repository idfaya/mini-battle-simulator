# MiniBattle Roguelike 服务节点参数表

## 1. 招募表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 招募表编号 |
| `name` | string | 文本 | 招募表名称 |
| `candidate_count` | integer | `2` / `3` | 候选数量 |
| `allow_new_class` | boolean | `true` / `false` | 是否允许新职业单位 |
| `allow_owned_class` | boolean | `true` / `false` | 是否允许已持有职业 |
| `prefer_missing_role` | boolean | `true` / `false` | 是否优先补缺位 |
| `allow_bench_entry` | boolean | `true` / `false` | 队伍满时是否进入候补 |

---

## 2. 商店表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 商店编号 |
| `name` | string | 文本 | 商店名称 |
| `equip_count` | integer | `2~6` | 装备栏位数量 |
| `service_count` | integer | `0~4` | 服务栏位数量 |
| `refresh_once` | boolean | `true` / `false` | 是否提供一次刷新 |
| `price_factor` | number | 正数 | 价格系数 |

---

## 3. 事件表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 事件编号 |
| `name` | string | 文本 | 事件名称 |
| `option_count` | integer | `2` / `3` | 选项数量 |
| `result_type_1` | enum | `gold` / `equip` / `battle` / `recruit` / `state` | 选项 1 结果类型 |
| `result_type_2` | enum | 同上 | 选项 2 结果类型 |
| `result_type_3` | enum | 同上或空 | 选项 3 结果类型 |

---

## 4. 营地表

| 字段 | 类型 | 取值 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 唯一值 | 营地编号 |
| `name` | string | 文本 | 营地名称 |
| `revive_count` | integer | `0` / `1` | 可复活数量 |
| `heal_mode` | enum | `full_team` / `active_only` | 恢复模式 |
| `clear_negative_state` | boolean | `true` / `false` | 是否清负面状态 |
| `extra_buff_count` | integer | `0~2` | 额外祝福数量 |

---

## 5. 对外接口

### 5.1 节点表接入

```text
roguelike_node_parameter_table.type = recruit
→ recruit_id
→ 招募表.id

roguelike_node_parameter_table.type = shop
→ shop_id
→ 商店表.id

roguelike_node_parameter_table.type = event
→ event_id
→ 事件表.id

roguelike_node_parameter_table.type = camp
→ camp_id
→ 营地表.id
```

### 5.2 招募到职业卡

```text
recruit.id
→ 生成职业单位候选
→ 玩家选择
→ 进入 Run 持有表
```

### 5.3 商店到装备

```text
shop.id
→ 生成装备与服务列表
→ 金币结算
→ 更新队伍状态
```

### 5.4 事件到结果

```text
event.id
→ 展示选项
→ 玩家选择
→ 应用结果
```

### 5.5 营地到修复

```text
camp.id
→ 复活 / 恢复 / 清状态
→ 更新队伍状态
```

---

## 6. 模板

### 6.1 recruit

| 字段 | 推荐值 |
| --- | --- |
| `candidate_count` | `3` |
| `allow_new_class` | `true` |
| `allow_owned_class` | `true` |
| `prefer_missing_role` | `true` |
| `allow_bench_entry` | `true` |

### 6.2 shop

| 字段 | 推荐值 |
| --- | --- |
| `equip_count` | `3` |
| `service_count` | `2` |
| `refresh_once` | `true` |
| `price_factor` | `1.0` |

### 6.3 event

| 字段 | 推荐值 |
| --- | --- |
| `option_count` | `2` 或 `3` |
| `result_type_1` | 任意有效结果 |
| `result_type_2` | 任意有效结果 |
| `result_type_3` | 任意有效结果或空 |

### 6.4 camp

| 字段 | 推荐值 |
| --- | --- |
| `revive_count` | `1` |
| `heal_mode` | `full_team` |
| `clear_negative_state` | `true` |
| `extra_buff_count` | `0` 或 `1` |

---

## 7. Act 1 示例

### 7.1 招募表

```text
id = recruit_basic_01
name = 基础招募
candidate_count = 3
allow_new_class = true
allow_owned_class = true
prefer_missing_role = true
allow_bench_entry = true
```

### 7.2 商店表

```text
id = shop_act1_01
name = Act1 商店
equip_count = 3
service_count = 2
refresh_once = true
price_factor = 1.0
```

### 7.3 事件表

```text
id = event_act1_01
name = 破损祭坛
option_count = 3
result_type_1 = gold
result_type_2 = equip
result_type_3 = battle
```

### 7.4 营地表

```text
id = camp_basic_01
name = 基础营地
revive_count = 1
heal_mode = full_team
clear_negative_state = true
extra_buff_count = 0
```

---

## 8. 一页结论

服务节点参数表只定义四类入口：

```text
recruit
shop
event
camp
```

节点主表统一通过：

```text
recruit_id / shop_id / event_id / camp_id
```

接入对应配置表。
