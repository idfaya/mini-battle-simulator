# MiniBattle Class 系统设计文档

## 1. 文档范围

- 本文档定义 `MiniBattle` 的 Class 系统总规则。
- 本文档采用 `minibattle_combat_design_document_v_1.md` 作为上位规则源。
- 本文档定义：
  - Class 单位
  - 属性
  - 经验
  - 等级
  - 进阶
  - 转职
  - 技能
  - 装备
  - 站位
  - 与 Run 和战斗的接口

---

## 2. 核心对象

### 2.1 Class

- `Class` 是职业规则主体。
- `Class` 决定：
  - 基础属性模板
  - 推荐站位
  - 可用技能包
  - 可进阶路径
  - 可转职路径

### 2.2 Class 单位

- `Class` 单位是玩家实际持有、上阵、成长和结算的单位对象。
- 每个 Class 单位独立持有：
  - `class_id`
  - `level`
  - `exp`
  - `promotion_stage`
  - `equipment`
  - `battle_slot`
  - `team_state`

### 2.3 职业卡

- `职业卡` 是 Run 内获得 Class 单位或推动 Class 单位进阶的入口。
- `职业卡` 规则由 `class_promotion_design.md` 定义。
- `职业卡` 不直接提供等级提升。
- `职业卡` 不直接替代转职入口。

### 2.4 技能

- `技能` 是 Class 单位的能力单元。
- 技能统一分为：
  - `普攻`
  - `被动`
  - `主动`
  - `高阶能力`

### 2.5 装备

- `装备` 是挂在 Class 单位上的外部成长部件。
- 装备可修改：
  - 属性
  - 技能
  - 站位适配

---

## 3. Class 单位结构

每个 Class 单位统一包含以下数据：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `unit_id` | string | 单位唯一编号 |
| `class_id` | string | 当前职业编号 |
| `character_group` | enum | `physical` / `caster` |
| `level` | integer | 当前等级 |
| `exp` | integer | 当前经验 |
| `promotion_stage` | enum | `low` / `mid` / `high` |
| `team_state` | enum | `active` / `bench` / `dead` |
| `battle_slot` | enum | `front` / `back` / `none` |
| `recommended_slot` | enum | `front` / `back` / `flex` |
| `str` | integer | 力量 |
| `dex` | integer | 敏捷 |
| `con` | integer | 体质 |
| `int` | integer | 智力 |
| `wis` | integer | 感知 |
| `cha` | integer | 魅力 |
| `skill_package_id` | string | 当前技能包编号 |
| `equip_weapon` | string | 武器槽内容 |
| `equip_armor` | string | 防具槽内容 |
| `equip_accessory` | string | 饰品槽内容 |

补充约定：

- `promotion_stage` 的数据值统一为 `low` / `mid` / `high`；展示层可渲染为 `低阶` / `中阶` / `高阶`，但配置、存档、接口一律使用英文值。
- `team_state` 的数据值统一为 `active` / `bench` / `dead`。
- `character_group` 数据值统一为 `physical` / `caster`，决定职业核心技文档归属。

---

## 4. 属性系统

### 4.1 5e 六项基础属性

每个 Class 单位持有 5e 标准六项基础属性：

| 字段 | 含义 | 取值范围 | 默认值 |
| --- | --- | --- | --- |
| `str` | 力量 Strength | `[1, 30]` | `10` |
| `dex` | 敏捷 Dexterity | `[1, 30]` | `10` |
| `con` | 体质 Constitution | `[1, 30]` | `10` |
| `int` | 智力 Intelligence | `[1, 30]` | `10` |
| `wis` | 感知 Wisdom | `[1, 30]` | `10` |
| `cha` | 魅力 Charisma | `[1, 30]` | `10` |

Modifier 统一采用 5e 公式 `floor((score - 10) / 2)`，并以 `strMod / dexMod / conMod / intMod / wisMod / chaMod` 字段缓存派生结果，作为战斗参与方共用接口。

### 4.2 派生属性

每个 Class 单位统一派生以下战斗属性：

- `max_hp` / `current_hp`
- `ac`
- `hit_bonus`
- `spell_dc`
- `save_fort` / `save_ref` / `save_will`
- `speed`
- `energy`

### 4.3 属性来源

Class 单位的属性由以下部分共同决定：

```text
Class 基础模板
→ 等级成长
→ 进阶修正
→ 装备修正
```

### 4.4 5e 口径

派生属性统一走 5e 公共规则：

- `HP = hit_die + conMod` 累加至当前等级。
- `AC` 由职业 `armor_formula` 结合敏捷/感知/体质修正得出。
- `hit_bonus = proficiency + primary_ability_mod`。
- `spell_dc = 8 + proficiency + spell_ability_mod`。
- `save_X = ability_mod + (proficient ? proficiency : 0)`。

所有派生字段必须经由公共 5e 模块计算，禁止各职业各自实现。

### 4.5 职业属性画像

每个职业由以下 4 个字段定义其 5e 画像：

| 字段 | 含义 |
| --- | --- |
| `primary_ability` | 主属性，用于攻击命中与物理伤害加值 |
| `spell_ability` | 施法属性，用于法术 DC；`none` 表示无施法 |
| `armor_formula` | AC 计算公式类型 |
| `save_proficiency` | 精通豁免集合，`fort` / `ref` / `will` 的子集 |

`armor_formula` 枚举值：

| 枚举 | 计算公式 |
| --- | --- |
| `heavy_fixed` | 固定 `17` |
| `unarmored_str_con` | `10 + conMod`（预留，barbarian） |
| `unarmored_dex_wis` | `10 + dexMod + wisMod` |
| `medium_capped` | `13 + min(2, dexMod)` |
| `light_11_dex` | `11 + dexMod` |
| `light_12_dex` | `12 + dexMod` |
| `robe_dex` | `10 + dexMod` |

当前实装 9 职业具体映射（`classId 10` 野蛮人待后续实现）：

| classId | 职业 | `primary_ability` | `spell_ability` | `armor_formula` | `save_proficiency` |
| --- | --- | --- | --- | --- | --- |
| `1` | Rogue | `dex` | `none` | `light_11_dex` | `ref` |
| `2` | Fighter | `str` | `none` | `heavy_fixed` | `fort` / `will` |
| `3` | Monk | `dex` | `wis` | `unarmored_dex_wis` | `fort` / `ref` |
| `4` | Paladin | `str` | `cha` | `medium_capped` | `fort` |
| `5` | Ranger | `dex` | `wis` | `light_12_dex` | `ref` / `will` |
| `6` | Cleric | `str` | `wis` | `medium_capped` | `will` |
| `7` | Sorcerer | `int` | `int` | `robe_dex` | `will` |
| `8` | Wizard | `int` | `int` | `robe_dex` | `fort` / `will` |
| `9` | Warlock | `int` | `int` | `robe_dex` | `ref` / `will` |

约束：

- hero 侧与 enemy 侧必须共用同一份职业画像映射，禁止各自维护一份。
- 修改画像必须在公共 5e 模块落地，`physical_class_core_skill_design.md` 与 `caster_class_core_skill_design.md` 的职业段首"5e 画像"锚点必须同步更新。

### 4.6 战斗标签

每个 Class 单位统一带有以下战斗标签：

- `attack_type`
  - `melee`
  - `ranged`
  - `spell`
- `slot_type`
  - `front`
  - `back`
  - `flex`
- `role_tag`
  - `tank`
  - `damage`
  - `support`
  - `control`

---

## 5. 经验系统

### 5.1 经验持有

- 每个 Class 单位独立持有经验。
- 经验不在不同 Class 单位之间共享。

### 5.2 经验来源

Class 单位可从以下来源获得经验：

- 战斗胜利
- 章节结算
- 事件结果

### 5.3 经验结算对象

- 当前上阵的存活 Class 单位获得完整经验。
- 当前上阵但战斗中死亡的 Class 单位获得基础经验。
- 候补 Class 单位不获得战斗经验。

### 5.4 满级处理

- 已达等级上限的 Class 单位不再获得经验。

---

## 6. 等级系统

### 6.1 等级范围

Class 单位统一采用：

```text
Lv1
→ Lv2
→ Lv3
→ Lv4
→ Lv5
```

### 6.2 初始等级

- 新获得的 Class 单位初始等级统一为 `Lv1`。

### 6.3 升级结果

Class 单位升级时，统一执行：

- 提升基础属性
- 刷新等级成长记录

### 6.4 等级职责

- `等级` 只负责数值成长。
- `等级` 不负责职业形态变化。
- `等级` 不直接决定进阶与转职。
- `等级` 不改变 `class_id`。
- `等级` 不替换技能槽结构。

---

## 7. 进阶系统

### 7.1 进阶阶段

Class 单位统一采用以下阶段：

```text
low
→ mid
→ high
```

### 7.2 进阶来源

Class 单位可通过以下入口进入进阶结算：

- 职业卡重复获得
- 招募节点进阶结果
- 事件节点进阶结果

### 7.3 进阶结果

Class 单位进阶时，统一执行：

- 保留 `unit_id`
- 保留当前 `level`
- 保留当前 `exp`
- 替换当前技能包
- 应用进阶属性修正

### 7.4 进阶职责

- `进阶` 负责职业阶段变化。
- `进阶` 负责技能包扩展。
- `进阶` 不重置等级。
- `进阶` 不改变 `class_id`。
- `进阶` 不新增同名单位。

---

## 8. 转职系统

### 8.1 转职定义

- `转职` 是 Class 单位从当前 `class_id` 切换到目标 `class_id` 的成长结算。

### 8.2 转职入口

Class 单位可通过以下入口触发转职：

- 高阶进阶分支
- 指定事件结果
- 指定系统结算

### 8.3 转职结果

Class 单位转职时，统一执行：

- 保留 `unit_id`
- 替换 `class_id`
- 保留当前 `level`
- 保留当前 `exp`
- 替换技能包
- 重新计算职业属性模板
- 保留已装备物品，按目标职业可用规则重新校验

### 8.4 转职与进阶关系

- `进阶` 是同职业内阶段推进。
- `转职` 是职业编号切换。
- 转职后 Class 单位继续参与等级成长与装备结算。

### 8.5 转职结果约束

- `转职` 后重新进入目标职业的阶段规则。
- `转职` 后当前 `promotion_stage` 由转职规则定义。
- `转职` 后技能槽结构保持统一，只替换技能内容。

---

## 9. 技能系统

### 9.1 技能槽结构

每个 Class 单位统一采用以下技能槽：

- `basic_attack_slot`
- `core_slot`
- `mid_slot`
- `high_slot`

### 9.2 阶段与技能槽启用关系

#### low

- 启用：
  - `basic_attack_slot`
  - `core_slot`

#### mid

- 启用：
  - `basic_attack_slot`
  - `core_slot`
  - `mid_slot`

#### high

- 启用：
  - `basic_attack_slot`
  - `core_slot`
  - `mid_slot`
  - `high_slot`

### 9.3 技能槽语义

- `basic_attack_slot` 对应基础出手技能。
- `core_slot` 对应低阶核心能力。
- `mid_slot` 对应中阶新增能力。
- `high_slot` 对应高阶终局能力。

### 9.4 技能来源

Class 单位的技能由以下部分决定：

```text
Class
→ promotion_stage
→ skill_package_id
→ equipment modifier
```

### 9.5 技能职责

- `普攻` 负责基础出手。
- `被动` 负责常驻机制。
- `主动` 负责主动触发机制。
- `高阶能力` 负责高阶阶段能力兑现。

### 9.6 技能实现接口

- 职业技能规则由：
  - `physical_class_core_skill_design.md`
  - `caster_class_core_skill_design.md`
  定义。
- 运行时统一落到 `Feat -> Skill`。

---

## 10. 装备系统

### 10.1 装备槽

每个 Class 单位统一持有以下装备槽：

- `equip_weapon`
- `equip_armor`
- `equip_accessory`

### 10.2 装备效果类型

装备统一通过以下方式作用于 Class 单位：

- 修改属性
- 修改技能
- 追加战斗标签

### 10.3 装备与职业关系

- 装备附着在 Class 单位上。
- 进阶不移除装备。
- 转职后重新校验装备适配性。

### 10.4 装备结算时机

- 进入战斗前结算装备效果。
- 离开战斗后保留装备状态。
- 在 Run 节点之间允许调整装备归属。

---

## 11. 站位系统

### 11.1 站位类型

Class 单位统一存在以下站位：

- `front`
- `back`

### 11.2 推荐站位

每个 Class 单位统一持有：

- `recommended_slot`

推荐取值为：

- `front`
- `back`
- `flex`

### 11.3 上阵规则

- 单场战斗最多上阵 `6` 个 Class 单位。
- 前排最多 `3` 个。
- 后排最多 `3` 个。
- 每个上阵单位占用 `1` 个站位。

### 11.4 站位与职业关系

- `melee` 单位默认推荐前排。
- `ranged` 单位默认推荐后排。
- `spell` 单位按职业规则决定推荐排位。

---

## 12. 队伍系统接口

### 12.1 队伍状态

每个 Class 单位只存在以下队伍状态：

- `active`
- `bench`
- `dead`

### 12.2 Run 持有规则

- Run 持有列表记录全部已持有 Class 单位。
- 当前上阵单位属于 `active`。
- 当前未上阵但已持有单位属于 `bench`。
- 当前战斗死亡但仍被 Run 记录的单位属于 `dead`。

### 12.3 职业卡接口

```text
职业卡
→ 新获得 Class 单位
或
→ 已持有 Class 单位进阶
```

### 12.4 招募接口

```text
招募节点
→ 生成 Class 单位候选
→ 玩家选择
→ 加入 active 或 bench
```

### 12.5 Run 最小持有字段

Run 层至少保留以下字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `unit_id` | string | 单位唯一编号 |
| `class_id` | string | 职业编号 |
| `team_state` | enum | `active` / `bench` / `dead` |
| `promotion_stage` | enum | `low` / `mid` / `high` |
| `level` | integer | 当前等级 |
| `exp` | integer | 当前经验 |
| `current_hp` | integer | 当前生命 |
| `battle_slot` | enum | `front` / `back` / `none` |
| `skill_package_id` | string | 当前技能包编号 |
| `equip_weapon` | string | 武器槽 |
| `equip_armor` | string | 防具槽 |
| `equip_accessory` | string | 饰品槽 |

---

## 13. 战斗系统接口

### 13.1 入场数据

Class 单位进入战斗时，统一带入以下数据：

- `class_id`
- `level`
- `promotion_stage`
- `current_hp`
- `battle_slot`
- `skill_package_id`
- `equipment`
- `attribute_snapshot`

### 13.2 战斗中结算

战斗中统一结算：

- 属性
- 技能
- 装备修正
- 站位

### 13.3 战斗后回写

战斗结束后，统一回写以下结果：

- `current_hp`
- `dead / survive`
- `exp_gain`
- `level_up_result`

---

## 14. 成长职责对照

| 系统 | 改变内容 | 不改变内容 |
| --- | --- | --- |
| `等级` | 属性数值、等级成长记录 | `class_id`、职业阶段、技能槽结构 |
| `进阶` | 职业阶段、技能包、进阶修正 | `unit_id`、`class_id`、当前等级 |
| `转职` | `class_id`、职业模板、技能包 | `unit_id`、当前等级、当前经验 |

## 15. 文档关系

- `class_system_design.md`
  - 定义 Class 系统总规则
- `class_promotion_design.md`
  - 定义职业卡与进阶规则
- `physical_class_core_skill_design.md`
  - 定义物理职业能力包
- `caster_class_core_skill_design.md`
  - 定义法系职业能力包
- `roguelike_run_system_design.md`
  - 定义 Run、节点和奖励入口
- `single_battle_design.md`
  - 定义单场战斗规则

---

## 16. 一页结论

Class 单位统一采用以下成长结构：

```text
获得职业卡
→ 获得 Class 单位
→ 战斗获取经验
→ 等级提升
→ 重复职业卡触发进阶
→ 指定入口触发转职
→ 装备持续修正单位能力
→ 进入下一场战斗
```
