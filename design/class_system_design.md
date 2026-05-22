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

### 2.3 Run 内成长（Feat）

- 战后经验进入 `partyExp`；升级时从存活英雄的下一级 Feat 汇总池三选一。
- 规则见 [`character_progression_design.md`](./character_progression_design.md)。**无职业卡、无 Run 内招募。**

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
| `promotion_stage` | enum | `low` / `mid` / `high`（已 deprecated；HeroData 仍保留默认值用于向后兼容） |
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
| `run_equipment_effects` | derived | 由 Run 级全局装备池在战斗前桥接得到，不作为逐角色持久化字段 |

补充约定：

- `promotion_stage` 已 deprecated（从 character_progression_design.md 阶段 3 起）：进阶逻辑由 partyExp + FeatPicker 替代；HeroData 默认值保留只为向后兼容老存档读写，不再驱动任何运行时行为。
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
- 章节结算（预留）
- 事件结果（预留）

### 5.3 经验结算对象

- 当前上阵且战斗结束时存活的 Class 单位获得完整经验。
- 当前上阵但战斗中死亡的 Class 单位不获得战斗经验。
- 候补 Class 单位不获得战斗经验。

### 5.4 满级处理

- 已达等级上限的 Class 单位不再获得经验。

### 5.5 战后经验结算

战斗胜利后按以下顺序处理经验（partyExp + FeatPicker 模型，参见 character_progression_design.md §3）：

```text
读取 battle.exp_reward
→ 累加到 state.partyExp（不再写 unit.exp）
→ FeatPicker.BeginSession 检查跨阈值
→ 若产生升级会话则进入三选一 reward
→ 玩家选中后对应英雄 +1 级 + 写入 feat
→ 刷新 5e 派生属性
→ 再进入固定恢复与节点奖励
```

经验采用累计值（state.partyExp）。UI 通过 `next_level_exp - level_progress_exp` 显示距离下一级差值。挂起进阶 / promotion_pending_target 已废弃。

---

## 6. 等级系统

### 6.1 等级范围

Class 单位统一采用：

```text
Lv1
→ Lv2
→ Lv3
→ Lv4
→ ...
→ Lv10
```

### 6.2 初始等级

- 开局 starter 单位初始等级统一为 `Lv1`。
- Run 中后续获得的新职业单位按当前队伍均级抬升，最低不低于 `Lv1`。

### 6.3 升级结果

Class 单位升级时，统一执行：

- 提升等级
- 通过公共 5e 模块刷新 HP / AC / 命中 / DC / 豁免等派生属性
- 当前生命按最大生命增量补偿，死亡单位不因升级复活
- 刷新等级成长记录

### 6.4 等级职责

- `等级` 只负责数值成长。
- `等级` 不负责职业形态变化。
- `等级` 不直接决定进阶与转职。
- `等级` 不改变 `class_id`。
- `等级` 不替换技能槽结构。

### 6.5 等级与进阶边界（已 deprecated）

`promotion_stage` 与 `promotion_pending_target` 体系已 deprecated（character_progression_design.md 阶段 3）。
新的进阶通过 partyExp + FeatPicker 三选一驱动，详见 character_progression_design.md §3 / §9。
HeroData 仍保留 `promotion_stage` 默认值用于向后兼容老存档。

---

## 7. 子职业与能力解锁（Feat）

> 原「职业卡 / promotion_stage 进阶 / 转职」已废弃，见 [`character_progression_design.md`](./character_progression_design.md)。勿读 `design/legacy/`。

- **子职业**：英雄在 **Lv3** 选中该职业的子职核心 Feat 后锁定分支；**Lv5** Feat 为该子职 capstone。
- **能力单元**：所有战斗内能力由 Feat 授予或修改 `skill`，战前编译为 `BuildState`（[`docs/implementation_guidelines.md`](../docs/implementation_guidelines.md)）。
- **技能槽语义**（`basic_attack_slot` / `core_slot` / `mid_slot` / `high_slot`）仍用于描述职业结构；具体启用哪条技能由已选 Feat 决定，不由 `promotion_stage` 驱动。
- **本期**：Run 内固定 4 名起手英雄，无招募、无转职换 `class_id`。

---

## 8. 转职系统

**本期不实现。** 若未来加入，须单独立稿并修订总纲术语表。

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

### 10.1 当前装备模型

当前版本不为 Class 单位提供逐角色装备槽。

装备统一采用 `Run 级全局被动装备池`：

- Run 持有装备列表
- 装备通过职业过滤对符合条件的 Class 单位生效
- 生效时机为进入战斗前的统一桥接

### 10.2 装备效果类型

装备统一通过以下方式作用于 Class 单位：

- 修改属性
- 修改命中 / AC / 豁免 / Spell DC
- 提供武器额外伤害

### 10.3 装备与职业关系

- 装备不附着在单个 Class 单位上。
- Class 单位进阶不改变 Run 已持有装备列表。
- 生效时只校验当前职业是否命中装备 `classIds`。

### 10.4 装备结算时机

- 进入战斗前结算装备效果。
- 离开战斗后保留 Run 装备持有状态。
- Run 节点之间不存在“调整装备归属”操作。

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
| `promotion_stage` | enum | `low` / `mid` / `high`（已 deprecated；HeroData 默认值） |
| `level` | integer | 当前等级 |
| `exp` | integer | 当前经验 |
| `current_hp` | integer | 当前生命 |
| `battle_slot` | enum | `front` / `back` / `none` |
| `skill_package_id` | string | 当前技能包编号 |
| `run_equipment_effects` | derived | 战斗前由 Run 全局装备池桥接得到 |

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
| `等级`（个人） | 5e 派生属性、已选 Feat 档位 | `class_id` |
| `Feat` | 授予 / 修改 / 替换 `skill`、子职分支 | `unit_id`、`class_id` |
| `装备` / `bless` | Run 级 Build 修正 | 跨 Run 保留 |

## 15. 文档关系

见 [`README.md`](./README.md)。`design/legacy/` 禁止阅读维护。

---

## 16. 一页结论

Class 单位统一采用以下成长结构：

```text
起手 4 名 Class 单位（Lv1 + 底盘 Feat）
→ 战斗 → partyExp
→ 升级 → Feat 三选一（Lv3 锁子职 / Lv5 capstone）
→ 装备 / bless 修正 Build
→ hero_build 编译 → 进入下一场战斗
```
