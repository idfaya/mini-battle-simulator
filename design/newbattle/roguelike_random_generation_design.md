# MiniBattle Roguelike 随机生成系统策划案

## 1. 文档范围

- 本文档定义 `MiniBattle` 的 Roguelike 随机生成方案。
- 本文档是 `roguelike_run_system_design.md` 的扩展设计，用于把当前固定章节图升级为 `全随机地图 + 受控随机关卡 + 预算化随机怪物`。
- 本文档不改动上位规则：
  - 5e 属性、命中、AC、豁免、法术 DC 仍遵循现有战斗规则。
  - Roguelike 压强仍由 `budget.difficulty` 与 `budget.pressureFactor` 主导。
  - 等级 `level` 负责 5e 数值成长，进阶 `promotion_stage` 负责功能解锁。

---

## 2. 设计目标

### 2.1 核心目标

- 让每次 Run 都生成一张新的章节地图。
- 让玩家获得明确的路线选择感，而不是记忆固定答案图。
- 让普通战、精英战、事件战与 Boss 战在随机条件下仍保持可控难度。
- 让同一 `chapterId + seed + mapVersion` 始终生成同一局内容，便于调试、测试、存档与复盘。

### 2.2 设计原则

- 随机不等于失控，必须始终服从章节节奏。
- 地图、关卡、怪物三层解耦，不直接把所有内容混成一张大随机池。
- 优先控制节点分布、恢复间隔、精英密度，再谈随机惊喜。
- Boss 战保持高识别度，不做完全无约束随机。
- 第一版采用 `受控随机`，不追求无限自由拓扑。

---

## 3. 系统分层

Roguelike 随机生成统一分为三层：

```text
地图层
→ 决定本局章节图结构、节点数量、分支关系、节点类型分布

关卡层
→ 决定某个战斗节点实际使用哪种战斗模板

怪物层
→ 决定该战斗模板下本场实际刷出的怪物编成
```

### 3.1 地图层

- 负责生成 `节点实例`。
- 输出：
  - 层数
  - 每层节点数
  - 连线关系
  - 节点类型
  - 节点的内容池引用

### 3.2 关卡层

- 负责为战斗节点分配 `战斗模板`。
- 战斗模板定义的是战斗规则壳子，而不是具体怪物名单。
- 输出：
  - `battle_template_id`
  - `wave_group_pool_id`
  - `encounter_pool_id`
  - 经验奖励
  - 胜负规则
  - 波次列表规则
  - 增援刷新规则

### 3.3 怪物层

- 负责在关卡模板约束下生成实际怪物。
- 输出：
  - `wave_group`
  - `wave_group_ids`
  - 每波敌军编组
  - Boss 波次与护卫关系
  - 金币与初始能量等战斗实例参数

---

## 4. 地图随机规则

### 4.1 基础结构

- 每章统一存在唯一起点。
- 每章统一存在唯一期末 Boss 节点。
- 地图按层推进，玩家只能从当前层选择已连接的下一层节点。
- 每个节点至少存在 1 条合法后继路径，Boss 必须从起点可达。
- 不允许出现孤立节点、死路节点或无法到达 Boss 的伪分支。

### 4.2 第一版推荐层级

- Act 1 保持 `8` 层。
- 第 1 层固定为起点普通战。
- 第 8 层固定为 Boss。
- 第 2~7 层采用随机节点分布。

推荐节点数量：

| 层级 | 推荐节点数 |
| --- | --- |
| L1 | 1 |
| L2 | 2 |
| L3 | 2~3 |
| L4 | 2~3 |
| L5 | 2~3 |
| L6 | 2 |
| L7 | 1 |
| L8 | 1 |

### 4.3 拓扑规则

- 允许 `分叉后汇合`。
- 不允许连续两层都出现过多节点膨胀。
- 相邻层之间的连线应优先满足：
  - 每个下一层节点至少有 1 个前驱。
  - 每个当前层节点至少有 1 个后继。
  - 总体分支数量可控，避免视觉噪音。

### 4.4 节点类型配额

每章至少包含以下节点：

- 普通战若干
- 精英战至少 1 个
- 招募至少 1 个
- 商店至少 1 个
- 营地至少 1 个
- 事件至少 1 个
- Boss 1 个

### 4.5 节点类型约束

- 第 1 层固定 `normal_battle`。
- 最后一层固定 `boss_battle`。
- Boss 前 1~2 层不出现 `recruit`。
- `camp` 不允许连续两层出现。
- `shop` 与 `camp` 不允许同时高度密集，避免中后段资源断档或过饱和。
- 精英战最多连续出现 1 次，不允许连续两层双精英。
- 战斗节点总占比不低于 `60%`。

### 4.6 路线表达

虽然地图变为随机，但章节仍保留两类路线体验：

- `稳健路线`
  - 普通战更多
  - 商店 / 营地出现概率更高
  - 招募更早
  - 更适合修复队伍状态
- `高压路线`
  - 精英战更多
  - 事件与高收益节点更多
  - 更适合追求强度上限

随机地图不要求在配置上强制预先标记完整固定路线，但生成结果必须确保玩家在中段至少能做出一次明确的风险收益取舍。

### 4.7 地图信息揭示

第一版保留 `node_type_only` 规则：

- 未进入节点可显示节点类型。
- 未进入节点不显示完整标题与具体战斗编号。
- 已揭示但未进入节点可以显示图标与基础类型。
- 已进入节点显示完整内容信息。

后续如需强化探索感，可扩展 `?` 未知节点模式，但不纳入第一版强制范围。

---

## 5. 关卡随机规则

### 5.1 定义

`关卡随机` 指的是：

- 地图节点先确定自己是普通战、精英战、Boss 战或事件战。
- 节点再从对应的 `战斗模板池` 中抽取一个战斗模板。
- 战斗模板只定义战斗规则和目标体验，不直接写死完整怪物列表。

### 5.2 关卡模板职责

战斗模板负责定义：

- `kind`
- `exp_reward`
- `wave_count_min`
- `wave_count_max`
- `refresh_turns`
- `refresh_on_clear`
- `spawn_order`
- `win_rule`
- `lose_rule`
- `boss_rule`
- `wave_group_pool_id`
- `encounter_pool_id`

### 5.3 节点与关卡关系

固定图时代使用：

```text
node.id
→ battle_id
→ single_battle_parameter_table.id
```

随机图时代改为：

```text
node_instance.id
→ battle_pool_id
→ battle_template_id
→ encounter_pool_id
```

### 5.4 关卡池分层

战斗模板池必须按以下维度分层：

- `chapter`
- `floor_range`
- `kind`
- `difficulty_band`

示例：

- `act1_early_normal`
- `act1_mid_normal`
- `act1_mid_elite`
- `act1_boss`
- `act1_event_battle`

### 5.5 关卡抽取规则

- 普通战节点只从普通战模板池抽取。
- 精英战节点只从精英池抽取。
- Boss 节点只从 Boss 池抽取。
- 事件触发的战斗只从事件战池抽取。
- 同一 Run 内避免相邻层重复同一 `battle_template_id`。
- 同一 Run 内允许重复模板，但不应高频连续重复。

### 5.6 节奏要求

- 前期普通战偏教学与低损耗。
- 中段普通战开始承担真实资源压力。
- 精英战必须是中段与后段的压力拐点。
- Boss 前至少存在一次能够影响资源判断的中高压节点。

---

## 6. 怪物随机规则

### 6.1 定义

`怪物随机` 指的是：

- 战斗模板确定后，不直接读取固定 `enemyIds`。
- 系统根据 `encounter_pool`、`wave_group_pool`、`formation_profile` 与怪物候选池，生成本场实际敌方波次列表。

### 6.2 怪物层职责

怪物层需要决定：

- 总波次数
- 每波的前后排分布
- 波次间增援关系
- 护卫单位
- Boss 所在波次与阶段编成

### 6.3 怪物生成原则

- 仍以 `budget.difficulty` 与 `budget.pressureFactor` 为核心压强控制。
- 不允许通过叠加额外倍率制造难度。
- `enemyScale` 仅保留轻度语义化修正。
- 怪物随机优先通过：
  - 角色构成
  - 敌人数量
  - 站位分布
  - 候补顺序
  - 内容池权重
  来塑造差异。

### 6.4 怪物编成模板

怪物编成模板统一定义：

- 单波前排槽位数
- 单波后排槽位数
- 单波编组容量
- 单场可用波次数范围
- 前排槽位数
- 后排槽位数
- 必需角色标签
- 禁止角色标签
- 同怪最大重复数
- Boss 是否必带护卫

### 6.5 怪物候选标签

怪物候选池建议按语义标签组织：

- `frontliner`
- `backliner`
- `caster`
- `summoner`
- `undead`
- `beast`
- `guard`
- `boss`
- `elite_only`

### 6.6 怪物抽取约束

- 同一场战斗必须满足编成模板要求。
- 同一敌人不应超过配置的最大重复数。
- Boss 本体不得从普通池抽取。
- Boss 护卫优先从护卫池抽取。
- 不允许出现违背战斗语义的组合，例如：
  - 无前排却要求前排承压的阵型
  - 教学战直接生成高压远程集火组合
  - Boss 战缺失 Boss 本体

### 6.7 Boss 规则

- Boss 第一版采用 `模板随机 + 本体受控`。
- 即：
  - Boss 节点可以从多个 Boss 模板中抽 1 个。
  - 每个 Boss 模板内部仍固定 Boss 本体来源。
  - 护卫、附属波次与阶段小怪允许有限随机。

### 6.8 事件战规则

- 事件战独立于普通战和精英战。
- 事件战不混入普通战池。
- 事件战以“代价换收益”或“风险换捷径”为主要职责，不承担纯数值灌压。

---

## 7. 推荐配置结构

### 7.1 地图生成配置

建议新增 `map_gen_profile`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 地图生成配置编号 |
| `chapter_id` | string | 所属章节 |
| `floor_count` | integer | 总层数 |
| `node_count_by_floor` | table | 每层节点数范围 |
| `required_node_types` | table | 本章保底节点类型 |
| `type_weights_by_floor` | table | 各层节点类型权重 |
| `special_rules` | table | 招募禁层、营地间隔、商店间隔等 |
| `route_style_weights` | table | 稳健 / 高压风格权重 |
| `map_seed_version` | integer | 地图规则版本 |

### 7.2 战斗模板池

建议新增 `battle_pool`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 战斗池编号 |
| `chapter_id` | string | 所属章节 |
| `floor_min` | integer | 最低层 |
| `floor_max` | integer | 最高层 |
| `kind` | enum | `normal` / `elite` / `boss` / `event_battle` |
| `entries` | table[] | 模板与权重列表 |

### 7.3 战斗模板

建议新增 `battle_template`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 模板编号 |
| `kind` | enum | 战斗类型 |
| `exp_reward` | integer | 经验奖励 |
| `wave_count_min` | integer | 最少波次数 |
| `wave_count_max` | integer | 最多波次数 |
| `refresh_turns` | integer | 刷新轮次 |
| `refresh_on_clear` | boolean | 清屏是否刷新 |
| `spawn_order` | enum | 刷怪顺序 |
| `win_rule` | enum | 胜利规则 |
| `lose_rule` | enum | 失败规则 |
| `boss_rule` | table | Boss 附加规则 |
| `wave_group_pool_id` | string | 波次组池入口 |
| `encounter_pool_id` | string | 遭遇池入口 |

### 7.4 遭遇池

建议新增 `encounter_pool`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 遭遇池编号 |
| `chapter_id` | string | 所属章节 |
| `kind` | enum | 战斗类型 |
| `budget` | table | `difficulty` 与 `pressureFactor` |
| `initial_energy` | table | 初始能量范围 |
| `gold` | table | 金币范围 |
| `formation_entries` | table[] | 编成模板列表 |
| `player_scale` | table | 玩家侧轻量修正 |
| `enemy_scale` | table | 敌人侧轻量修正 |

### 7.5 怪物编成模板

建议新增 `formation_profile`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 编成模板编号 |
| `front_slots` | integer | 前排数量 |
| `back_slots` | integer | 后排数量 |
| `wave_unit_cap` | integer | 单波最大单位数 |
| `required_tags` | string[] | 必须出现的标签 |
| `forbidden_tags` | string[] | 禁止出现的标签 |
| `max_same_enemy` | integer | 单怪最大重复数 |
| `front_pool_id` | string | 前排候选池 |
| `back_pool_id` | string | 后排候选池 |
| `guard_pool_id` | string | 护卫候选池 |
| `reinforce_pool_id` | string | 增援候选池 |

### 7.6 怪物候选池

建议新增 `enemy_pick_pool`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 候选池编号 |
| `entries` | table[] | 怪物、权重、标签、层级限制 |

---

## 8. Run 层接口口径

### 8.1 节点实例结构

随机地图不再直接使用固定节点编号作为内容编号。

每个节点实例至少包含：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `node_instance_id` | string | 本局节点实例编号 |
| `chapter_id` | string | 所属章节 |
| `floor` | integer | 所在层 |
| `lane` | integer | 所在列 |
| `node_type` | enum | 节点类型 |
| `route_style` | enum | `safe` / `high_pressure` |
| `content_pool_id` | string | 内容池编号 |
| `next_node_ids` | string[] | 下一跳节点实例 |
| `revealed` | boolean | 是否已揭示 |
| `visited` | boolean | 是否已进入 |

### 8.2 战斗节点运行流程

```text
进入战斗节点
→ 根据 node_instance.content_pool_id 获取 battle_pool
→ 抽取 battle_template
→ 根据 template.wave_group_pool_id 确定波次组数量与波次主题
→ 根据 template.encounter_pool_id 获取 encounter_pool
→ 按每个 wave_group 抽取 formation_profile
→ 按标签与预算生成各波敌军编组
→ 组装 battle_instance
→ 进入战斗
```

### 8.3 结算规则

- 战斗胜利后结算顺序不变：
  - 金币
  - 掉落
  - 经验
  - 固定恢复
  - 职业卡三选一
- 经验仍只发给战斗结束时存活且在上阵队伍中的 Class 单位。
- 随机地图不改变职业卡、等级、进阶、装备、祝福的基本规则。

---

## 9. Act 1 第一版建议

### 9.1 地图规则

- 总层数固定 `8`。
- 起点固定普通战。
- Boss 固定第 `8` 层。
- 第 `2~6` 层为主要分歧层。
- 第 `7` 层为收束层。

### 9.2 节点配额建议

- 普通战：`4~5`
- 精英战：`1~2`
- 招募：`1~2`
- 商店：`1`
- 事件：`1~2`
- 营地：`1`
- Boss：`1`

### 9.3 难度带建议

| 层级 | 推荐战斗难度 |
| --- | --- |
| L1 | `easy` |
| L2 | `easy` |
| L3 | `easy` / `medium` |
| L4 | `medium` |
| L5 | `medium` / `hard` |
| L6 | `medium` / `hard` |
| L7 | `hard` 或功能收束 |
| L8 | `deadly` |

### 9.4 招募与恢复建议

- 招募优先出现在 L2~L5。
- 营地优先出现在 L4 或 L5。
- 商店优先出现在 L3~L6。
- Boss 前不安排过于慷慨的连续恢复链。

### 9.5 Boss 建议

- Boss 允许从多个 Boss 模板中随机选择。
- 每个 Boss 模板必须保证：
  - 明确 Boss 本体
  - 明确 Boss 所在波次
  - 明确胜利条件
  - 明确增援与护卫关系
  - 不会因错误配置导致 Boss 开场缺失或提前结算

---

## 10. 随机性与复现要求

### 10.1 统一要求

- 相同 `chapterId + seed + mapVersion` 必须产出同一张地图与同一套节点内容。
- 不同 seed 应高概率生成不同地图和不同战斗分布。

### 10.2 RNG 分流要求

建议至少拆分以下随机流：

- `mapRng`
- `battleTemplateRng`
- `enemyCompRng`
- `rewardRng`

目的：

- 避免地图生成影响奖励序列。
- 避免奖励抽取影响怪物生成。
- 保证测试与复盘稳定。

---

## 11. 验收标准

### 11.1 地图合法性

- 所有节点都在合法层级。
- 起点到 Boss 必定可达。
- 不存在孤立节点。
- 不存在无法进入或无法退出的节点。

### 11.2 节奏合法性

- 本章保底节点类型均出现。
- 精英、营地、商店、招募满足间隔规则。
- Boss 前存在有效的资源压力与路线选择。

### 11.3 战斗合法性

- 普通战、精英战、事件战、Boss 战均只从对应池中抽取。
- Boss 战一定生成合法 Boss 本体。
- 怪物编成满足模板约束与预算约束。

### 11.4 体验合法性

- 玩家能在中段感受到一次以上明确的风险收益分歧。
- 不出现连续空档导致无压力推进。
- 不出现异常高压导致大多数局在中前期稳定暴毙。

---

## 12. 分期建议

### 12.1 第一阶段

- 完成随机地图实例生成。
- 普通战接入战斗模板池。
- 普通战接入基础怪物编成池。
- 保留现有 UI 表现方式，但改为读取真实连线。

### 12.2 第二阶段

- 精英战与事件战接入随机模板。
- 商店 / 营地 / 招募位置平衡调优。
- 补充更多怪物标签与编成模板。

### 12.3 第三阶段

- Boss 模板扩容。
- 引入更多章节与章节专属怪物池。
- 根据运营目标再决定是否加入更强的未知节点与特殊事件机制。

---

## 13. 结论

- Roguelike 的正确随机化方向不是简单把现有节点表洗牌，而是建立 `地图层 -> 关卡层 -> 怪物层` 的三层受控随机结构。
- 地图负责路线分化，关卡负责战斗语义，怪物负责内容变化。
- 在此结构下，Run 的随机性、可玩性、平衡性与可维护性可以同时成立。
