# MiniBattle Class 进阶文档

## 1. 文档范围

- 本文档定义战后职业卡与职业单位成长阶段之间的映射规则。
- 本文档采用 `roguelike_run_system_design.md`、`physical_class_core_skill_design.md`、`caster_class_core_skill_design.md` 作为规则来源。
- 本文档只描述职业卡、职业单位持有状态、阶段晋升和映射关系。

---

## 2. 核心定义

### 2.1 职业卡

- 战后奖励只产出 `职业卡`。
- 每张职业卡只对应 `1` 个职业单位。
- 职业卡本身不区分“招募卡”“进阶卡”。
- 职业卡的最终结果由玩家当前持有状态决定。
- 职业卡不产出 `装备`、`祝福` 或 `金币`。
- 职业卡不负责经验与等级提升；经验升级在职业卡出现前自动结算。

### 2.2 职业单位状态

每个职业单位统一采用 `class_system_design.md` §12.1 的 `team_state` 枚举：

- `active`：已持有并上阵
- `bench`：已持有并候补
- `dead`：已持有但 Run 内死亡

"未持有"不是 `team_state` 的取值：未持有意味着该 `class_id` 不存在于 Run 持有表，由外层的 `is_owned` 布尔入参或查表结果表达。

### 2.3 职业阶段

每个职业单位统一采用 `class_system_design.md` §3 的 `promotion_stage` 枚举：

- `low`：低阶
- `mid`：中阶
- `high`：高阶

"未持有"不是 `promotion_stage` 的取值：未持有时该职业不在 Run 持有表中，无 `promotion_stage` 字段。

---

## 3. 职业卡结算规则

### 3.1 首次获得

当职业单位处于 `未持有` 状态时：

```text
获得该职业卡
→ 职业单位加入玩家持有列表
→ promotion_stage = low
```

### 3.2 重复获得

当职业单位已经被玩家持有时：

```text
再次获得该职业卡
→ 该卡自动结算为同职业进阶
```

重复获得的阶段映射如下：

```text
已持有低阶
→ 升至中阶

已持有中阶
→ 升至高阶
```

### 3.3 已达高阶

当职业单位已经处于 `高阶` 时：

```text
该职业单位不再进入职业卡候选池
```

---

## 4. 职业卡与队伍位置映射

### 4.1 队伍未满

当玩家选择一张 `未持有职业卡`，且队伍未满时：

```text
新职业单位
→ 直接加入队伍
→ promotion_stage = low
```

### 4.2 队伍已满

当玩家选择一张 `未持有职业卡`，且队伍已满时：

```text
新职业单位
→ 进入候补
→ promotion_stage = low
```

### 4.3 已持有职业单位

当玩家选择一张 `已持有职业卡` 时：

```text
职业卡
→ 不新增单位
→ 直接提升该职业阶段
```

该规则同时适用于：

- 当前上阵职业单位
- 当前候补职业单位

---

## 5. 阶段晋升规则

### 5.1 阶段顺序

所有职业单位统一采用：

```text
低阶
→ 中阶
→ 高阶
```

### 5.2 晋升次数

单个职业单位的职业卡获取次数与阶段映射如下：

| 职业卡获取次数 | 结算结果 | 当前阶段 |
| --- | --- | --- |
| 第 1 张 | 首次获得职业单位 | 低阶 |
| 第 2 张 | 重复职业进阶 | 中阶 |
| 第 3 张 | 重复职业进阶 | 高阶 |

### 5.3 晋升结果

阶段晋升只改变该职业单位的职业阶段，不生成新的同名单位。

---

## 6. 三阶职业映射规则

### 6.1 低阶

- 职业单位首次加入队伍时，统一进入 `低阶`。
- `低阶` 负责建立该职业单位的基础职业身份。

### 6.2 中阶

- 第一次重复获得该职业单位时，统一晋升为 `中阶`。
- `中阶` 负责补足该职业单位的关键动作或联动。

### 6.3 高阶

- 第二次重复获得该职业单位时，统一晋升为 `高阶`。
- `高阶` 负责兑现该职业单位的终局高光。

---

## 7. 职业卡展示映射

每张职业卡需要展示以下信息：

- 职业头像
- 职业名称
- 当前结算类型
- 当前阶段
- 结算后阶段
- 本次新增能力摘要

职业卡展示结果统一为以下两类：

### 7.1 新职业单位

```text
结果类型：新职业单位
当前阶段：无
结算后阶段：低阶
```

### 7.2 重复进阶

```text
结果类型：重复进阶
当前阶段：低阶 / 中阶
结算后阶段：中阶 / 高阶
```

---

## 8. 候选池过滤规则

### 8.1 可进入候选池

以下职业单位可以进入职业卡候选池：

- 当前未持有的职业单位
- 当前已持有且阶段为低阶的职业单位
- 当前已持有且阶段为中阶的职业单位

### 8.2 不进入候选池

以下职业单位不进入职业卡候选池：

- 当前已持有且阶段为高阶的职业单位

### 8.3 结算有效性

每次职业卡三选一必须满足：

- 至少 `1` 张卡能够立即生效
- 不出现 `3` 张都无效的情况

---

## 9. 物理职业映射表

| 职业 | 第 1 张卡 | 第 2 张卡 | 第 3 张卡 |
| --- | --- | --- | --- |
| 战士 | 低阶：战技斩击 + 反击 | 中阶：护卫架势 | 高阶：不屈之风 |
| 武僧 | 低阶：徒手打击 + 连击 | 中阶：震劲掌 | 高阶：明镜止水 |
| 盗贼 | 低阶：轻巧刺击 + 伏击 | 中阶：影袭处决 | 高阶：直觉闪避 |
| 游侠 | 低阶：猎弓射击 + 标记 | 中阶：狩猎指引 | 高阶：箭雨 |
| 圣骑 | 低阶：圣武斩击 + 神圣庇护 | 中阶：破邪斩 | 高阶：圣手 |
| 野蛮人 | 低阶：狂斧劈砍 + 狂怒 | 中阶：重击 | 高阶：狂暴 |

---

## 10. 法系职业映射表

| 职业 | 第 1 张卡 | 第 2 张卡 | 第 3 张卡 |
| --- | --- | --- | --- |
| 法师 | 低阶：寒霜射线 + 寒霜迟滞 | 中阶：冻结新星 | 高阶：暴风雪 |
| 术士 | 低阶：火焰弹 + 余烬点燃 | 中阶：灰烬爆燃 | 高阶：烈焰风暴 |
| 牧师 | 低阶：神术裁决 + 神恩庇护 | 中阶：治愈之言 | 高阶：圣域祷言 |
| 邪术师 | 低阶：邪能冲击 + 静电印记 | 中阶：雷链 | 高阶：雷暴 |

---

## 11. 统一结算顺序

玩家选择职业卡后，统一按以下顺序结算：

```text
读取职业标识
→ 检查是否已持有
→ 若未持有：加入队伍或候补，阶段设为低阶
→ 若已持有且为低阶：升为中阶
→ 若已持有且为中阶：升为高阶
→ 刷新职业卡展示结果
```

职业卡结算不得修改：

- `level`
- `exp`
- 装备槽
- 祝福列表

---

## 12. 最小数据字段

职业卡进阶至少需要以下字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `class_id` | string | 职业唯一编号 |
| `class_name` | string | 职业名称 |
| `character_group` | enum | `physical` / `caster` |
| `team_state` | enum | `active` / `bench` / `dead` |
| `promotion_stage` | enum | `low` / `mid` / `high` |
| `str` | integer | 力量 |
| `dex` | integer | 敏捷 |
| `con` | integer | 体质 |
| `int` | integer | 智力 |
| `wis` | integer | 感知 |
| `cha` | integer | 魅力 |
| `promotion_low_label` | string | 低阶名称 |
| `promotion_mid_label` | string | 中阶名称 |
| `promotion_high_label` | string | 高阶名称 |
| `promotion_low_summary` | string | 低阶摘要 |
| `promotion_mid_summary` | string | 中阶摘要 |
| `promotion_high_summary` | string | 高阶摘要 |

---

### 12.1 进阶属性调整

`promotion_stage` 每提升一级，对该单位的 6 项基础属性追加固定修正：

| 晋升路径 | 属性调整规则 |
| --- | --- |
| `low → mid` | `primary_ability` 与 `con` 各 `+1` |
| `mid → high` | `primary_ability` `+2`，`spell_ability`（若非 `none`）`+1`，`con` `+1` |

约束：

- 属性调整对 `str / dex / con / int / wis / cha` 合计 `≤ 5`，单项合计 `≤ 6`，叠加后仍受 `[1, 30]` 截断。
- 调整结果写回 Run 持有表的 6 项属性字段；派生属性 `hp / ac / hit / spell_dc / saves` 由 `ability_5e` 公共模块即时重算。

---

## 13. 结算输入与输出

### 13.1 结算输入

职业卡结算统一读取以下输入：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `class_id` | string | 职业编号 |
| `is_owned` | boolean | 当前是否已持有该职业单位（查 Run 持有表） |
| `team_state` | enum | `active` / `bench` / `dead`；`is_owned = false` 时不传 |
| `promotion_stage` | enum | `low` / `mid` / `high`；`is_owned = false` 时不传 |
| `team_has_free_slot` | boolean | 当前队伍是否有空位 |

### 13.2 结算输出

职业卡结算统一输出以下结果：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `result_type` | enum | `new_class_unit` / `class_promotion` |
| `class_id` | string | 职业编号 |
| `team_state` | enum | `active` / `bench` / `dead` |
| `promotion_stage_before` | enum | `low` / `mid` / `high`；`result_type = new_class_unit` 时不传 |
| `promotion_stage_after` | enum | `low` / `mid` / `high` |
| `summary_key` | string | 本次新增能力摘要键 |

### 13.3 结算关系

```text
roguelike_run_system_design.md
→ 职业卡三选一
→ 传入 class_id / is_owned / team_state / promotion_stage / team_has_free_slot
→ class_promotion_design.md
→ 输出 result_type / team_state / promotion_stage_before / promotion_stage_after / summary_key
```

---

## 14. 一页结论

职业卡进阶统一为：

```text
第 1 张同职业卡
→ 获得该职业单位
→ promotion_stage = low

第 2 张同职业卡
→ promotion_stage = mid

第 3 张同职业卡
→ promotion_stage = high

高阶后
→ 不再进入职业卡池
```

职业卡的结算结果只允许两种：

```text
新职业单位
重复进阶
```
