# Feat-Skill 重构程序设计

## 目标

- 本文档用于指导职业成长系统的后续重构，先以战士作为样板职业落地。
- 重构目标不是继续修补现有 `feat_config.lua + class_level_grants.lua + passive_handlers.lua` 的旧链路，而是建立一套统一、可扩展、可追溯的成长与战斗能力模型。
- 新模型必须满足以下要求：
  - 所有成长统一由 `Feat` 承载。
  - 不再使用“槽位解锁”作为额外抽象。
  - 只保留一层能力对象：`skill`。
  - 运行时只区分两类：`active` 与 `passive`。
  - 设计层允许使用 `reaction`、`feature` 语义，但最终都编译为运行时 `passive`。

## 核心结论

- `Feat` 是唯一成长载体。
- `skill` 是唯一能力单元。
- 角色拥有哪些能力、能力如何被强化，只由已获得 `Feat` 决定。
- 运行时不再按 `classId` 硬编码推断职业应有什么被动或质变。

一句话描述新链路：

`职业等级进度 + 已选 Feat -> BuildState -> active/passive skills -> 战斗运行时`

## 概念模型

### 1. Feat

- `Feat` 是角色成长的唯一来源。
- 固定获得、三选一、子职分流、Lv5 质变，全部都是 `Feat`。
- `Feat` 不直接等于“加一点属性”或“升一级技能”，而是授予或修改 `skill`。

### 2. Skill

- `skill` 是唯一能力层。
- `skill` 不再只表示“技能栏按钮”，而是“角色拥有的一个能力单元”。
- 这些都算 `skill`：
  - 主动技能
  - 自动触发被动
  - 反击
  - 额外攻击
  - 规则质变

### 3. 设计层分类

- 设计层允许四类语义：
  - `active`
  - `passive`
  - `reaction`
  - `feature`
- 其作用是方便设计讨论和文档表达。

### 4. 运行时分类

- 运行时只保留两类：
  - `active`
  - `passive`
- 映射规则：
  - `design.active -> runtime.active`
  - `design.passive -> runtime.passive`
  - `design.reaction -> runtime.passive`
  - `design.feature -> runtime.passive`

## 为什么只保留一层 skill

- 若同时保留 `ability` 和 `skill`，系统会变成：

`Feat -> Ability -> Skill -> Runtime`

- 对当前项目来说，这层级过厚，会引入新的中间抽象，增加配置、调试和 UI 展示成本。
- 统一成 `skill` 后，成长和战斗之间的映射关系变成：

`Feat -> skill`

- 这更适合当前项目的实现复杂度，也更适合后续批量迁移其他职业。

## Skill 数据模型

每个 `skill` 至少应包含以下字段：

- `id`
- `runtimeKind`
- `classId`
- `name`
- `hidden`
- `cooldown`
- `trigger`
- `execution`
- `tags`

示意：

```lua
{
  id = "fighter_action_surge",
  runtimeKind = "active",
  classId = 2,
  hidden = false,
  cooldown = 3,
  execution = {
    type = "repeat_basic_attack",
    count = 2,
  },
  tags = { "fighter", "burst" },
}
```

```lua
{
  id = "fighter_extra_attack",
  runtimeKind = "passive",
  classId = 2,
  hidden = true,
  trigger = "after_first_basic_attack_each_turn",
  execution = {
    type = "repeat_basic_attack",
    count = 1,
  },
  tags = { "fighter", "extra_attack" },
}
```

## Feat 数据模型

`Feat` 只保留三种核心操作：

- `grant_skill`
- `modify_skill`
- `replace_skill`

其中：

- `grant_skill`：授予一个新的 `skill`
- `modify_skill`：修改已有 `skill` 的执行或触发规则
- `replace_skill`：用一个新的 `skill` 替换旧 `skill`

不再建议把下面这些继续保留为一等 effect：

- `unlock_skill`
- `upgrade_skill`
- `passive`
- `unlock_feature`

这些都应被统一表达为 `grant_skill / modify_skill / replace_skill`。

示意：

```lua
{
  id = "fighter_lv2_pressure_style",
  classId = 2,
  level = 2,
  effects = {
    {
      type = "modify_skill",
      skill = "fighter_basic_attack",
      add = {
        ignoreAc = 1,
      }
    }
  }
}
```

```lua
{
  id = "fighter_lv3_champion",
  classId = 2,
  level = 3,
  effects = {
    {
      type = "grant_skill",
      skill = "fighter_action_surge",
    }
  }
}
```

## BuildState

角色进入战斗前，需要先根据职业等级进度和已选 Feat 编译出 `BuildState`。

`BuildState` 至少包含：

- `activeSkills`
- `passiveSkills`
- `skillMods`
- `replacedSkills`
- `grantedTags`

作用：

- 明确当前角色到底拥有哪些能力
- 避免运行时再按 `classId` 推断职业特性
- 使战斗初始化完全由 Build 结果驱动

## 运行时职责

### Active

- 出现在技能栏或主动列表中
- 需要目标选择、CD、手动施放
- 由时间线或主动执行器驱动

### Passive

- 不手动施放
- 负责监听事件并自动触发
- 负责修改已有结算
- 负责改写回合与攻击规则

也就是说，下列设计语义在运行时都归为 `passive`：

- `被动`
- `反击`
- `额外攻击`
- `规则质变`

## 战士样板

以下内容用于指导第一阶段战士重构。

### 战士设计层 skill 列表

- `fighter_basic_attack`
  - 语义：active
  - 运行时：active
  - 来源：`战士训练`

- `fighter_second_wind`
  - 语义：passive
  - 运行时：passive
  - 来源：`二次生命`

- `fighter_pressure_style`
  - 语义：passive
  - 运行时：passive
  - 来源：`压制战法`

- `fighter_second_wind_followup`
  - 语义：passive
  - 运行时：passive
  - 来源：`续战战法`

- `fighter_counter_basic`
  - 语义：reaction
  - 运行时：passive
  - 来源：`反击战法`
  - 触发：每回合首次被近战攻击指定为目标时触发，不要求命中

- `fighter_action_surge`
  - 语义：active
  - 运行时：active
  - 来源：`冠军`

- `fighter_pressure_strike`
  - 语义：active
  - 运行时：active
  - 来源：`战斗大师`

- `fighter_guard_stance`
  - 语义：active
  - 运行时：active
  - 来源：`护卫`

- `fighter_guard_counter`
  - 语义：reaction
  - 运行时：passive
  - 来源：`护卫架势`开启后的反应窗口
  - 触发：护卫架势持续期间，你和友军被攻击时先获得 `AC +2` 与熟练减伤；若攻击者为近战单位，则在该次攻击结算后登记并结算护卫反击，不要求命中

- `fighter_weapon_mastery`
  - 语义：passive
  - 运行时：passive
  - 来源：`武器专精`

- `fighter_second_wind_mastery`
  - 语义：passive
  - 运行时：passive
  - 来源：`续战专精`

- `fighter_signature_mastery`
  - 语义：passive
  - 运行时：passive
  - 来源：`战技专精`

- `fighter_extra_attack`
  - 语义：feature
  - 运行时：passive
  - 来源：`连斩者 / 压制者 / 钢铁护卫`

- `fighter_extra_attack_pressure`
  - 语义：feature
  - 运行时：passive
  - 来源：`压制者`

- `fighter_extra_attack_guard`
  - 语义：feature
  - 运行时：passive
  - 来源：`钢铁护卫`

### 战士 Feat 到 skill 的映射

- `战士训练`
  - `grant_skill(fighter_basic_attack)`

- `二次生命`
  - `grant_skill(fighter_second_wind)`

- `压制战法`
  - `grant_skill(fighter_pressure_style)`

- `续战战法`
  - `grant_skill(fighter_second_wind_followup)`

- `反击战法`
  - `grant_skill(fighter_counter_basic)`

- `冠军`
  - `grant_skill(fighter_action_surge)`

- `战斗大师`
  - `grant_skill(fighter_pressure_strike)`

- `护卫`
  - `grant_skill(fighter_guard_stance)`

- `武器专精`
  - `grant_skill(fighter_weapon_mastery)`

- `续战专精`
  - `grant_skill(fighter_second_wind_mastery)`

- `战技专精`
  - `grant_skill(fighter_signature_mastery)`

- `连斩者`
  - `grant_skill(fighter_extra_attack)`

- `压制者`
  - `grant_skill(fighter_extra_attack)`
  - `grant_skill(fighter_extra_attack_pressure)`

- `钢铁护卫`
  - `grant_skill(fighter_extra_attack)`
  - `grant_skill(fighter_extra_attack_guard)`

## 模块划分建议

### 新增模块

- `config/skill_runtime_config.lua`
  - 定义新的统一 `skill` 数据

- `config/feat_build_config.lua`
  - 定义新的 Feat 配置

- `config/class_build_progression.lua`
  - 定义每个职业在 Lv1-Lv5 固定 Feat 与候选 Feat 组

- `modules/hero_build.lua`
  - 根据职业等级进度和已选 Feat 生成 `BuildState`

- `modules/skill_runtime.lua`
  - 根据 `BuildState` 注册 active/passive skills

### 待改造模块

- `config/feat_config.lua`
  - 未来可被新 `feat_build_config.lua` 取代

- `config/class_level_grants.lua`
  - 未来应只保留基础等级底盘，不再承担职业玩法发放

- `modules/passive_handlers.lua`
  - 未来不再按 `classId` 聚合职业玩法，而改为按已注册的 passive skills 工作

- `config/skill/skill_80002001.lua`
  - 需从“盾击”重写为战士标准基础武器攻击

- `config/skill/skill_80002003.lua`
  - 不再继续承载旧“顺劈斩”语义

- `config/skill/skill_80002004.lua`
  - 不再继续承载旧“旋风斩”语义

- `config/skill_5e_meta.lua`
  - 需与新语义同步

## 分阶段实施

### 阶段 1：建立新 Build 基础设施

- 新增 `feat_build_config.lua`
- 新增 `class_build_progression.lua`
- 新增 `hero_build.lua`
- 新增统一的运行时 `skill` 注册入口

目标：

- 不改旧职业
- 只让系统具备“根据 Feat 组装 skill”的能力

### 阶段 2：战士接入新系统

- 用战士替代旧职业硬编码链路
- 战士升级后，能力完全来自新 BuildState
- 其他职业继续走旧实现

目标：

- 新旧系统可并存
- 先证明战士样板成立

### 阶段 3：重写战士 skill

- 重写基础武器攻击
- 实现二次生命
- 实现反击战法
- 实现动作激增
- 实现压制打击
- 实现护卫架势
- 实现额外攻击

目标：

- 战士在运行时完全脱离旧的 `classId -> passive` 硬编码

### 阶段 4：清理旧战士语义

- 移除旧战士 Feat
- 移除旧战士聚合被动
- 移除旧“盾击/顺劈/旋风”语义依赖

目标：

- 战士完全切换到新系统

### 阶段 5：向其他职业扩展

## Web 单战调试参数

- `single-battle` 入口支持通过 URL 参数给战士注入 Build Feat。
- `fighterFeats`
  - 作用：给本场战斗里的所有战士注入同一组 Feat。
  - 格式：单组 ID，逗号分隔。
  - 示例：`fighterFeats=2100201,2100301`
- `fighterFeatsByHero`
  - 作用：按英雄槽位分别注入 Feat，适合多战士混编验证。
  - 格式：每个英雄一组，组内用 `,` 分隔，组与组之间用 `|` 分隔。
  - 示例：`fighterFeatsByHero=2100201,2100303|2100201,2100301|2100203,2100302`
- 优先级
  - 若某个槽位在 `fighterFeatsByHero` 中提供了 Feat，则该槽位优先使用这一组。
  - 若该槽位未提供，则回退到公共的 `fighterFeats`。
  - 只有战士会消费这两个参数，其他职业会忽略。
- 典型用法
  - 三个战士分别测试 `护卫 / 冠军 / 战斗大师`：
    - `/?mode=single-battle&heroes=900005,900005,900005&enemies=910003,910003,910003&level=3&fighterFeatsByHero=2100201,2100303|2100201,2100301|2100203,2100302&seed=101001`

- 盗贼优先
- 牧师其次
- 再扩展其他职业

## 非目标

- 本次重构不要求一次性改完全部职业
- 本次重构不引入完整法术位系统
- 本次重构不引入完整动作经济系统
- 本次重构不引入跨职业技能拼装
- 本次重构不要求先改 UI 展示层

## 验收标准

- 战士的所有能力来源都能追溯到 Feat
- 战士的运行时只依赖 active/passive skill 注册结果
- 战士不再通过 `classId` 隐式获得 `Second Wind`、`Action Surge`、`Extra Attack`
- `Lv2/Lv3/Lv4/Lv5` 的三选一对玩法有明确影响
- 其他职业在战士重构阶段保持可运行

## 最终定稿

- 只保留一层能力对象：`skill`
- 运行时只保留两类：`active` 与 `passive`
- 设计语义中的 `reaction`、`feature` 最终都编译为运行时 `passive`
- `Feat` 是唯一成长来源，负责授予或修改 `skill`
- 战士作为第一批样板职业，先完成这套链路的验证，再推广到其他职业

## 接手上下文

### 已确认的设计决策

- 本轮重构不要受现有战士实现语义束缚，旧“盾击 / 顺劈 / 旋风 / 聚合被动”只作为兼容参考，不作为新方案约束。
- 所有成长统一由 `Feat` 承载。
- 不使用“槽位解锁”作为额外抽象。
- `skill` 是唯一能力层，不再保留 `ability`。
- 运行时只保留 `active` 与 `passive` 两类。
- 设计语义中的 `reaction`、`feature` 只保留在文档和配置表达层，进入运行时后统一编译为 `passive`。
- `Lv2` 只给基础倾向，不抢 `Lv3` 子职身份。
- `Lv4` 只做单点机制强化，不放纯属性成长。
- `Lv5` 用一次三选一完成统一质变，不采用“固定给一个再额外三选一”的结构。
- Feat 文案和设计表达尽量使用 5e 风格的离散规则，不优先使用百分比。

### 战士最终设计依据

- 战士职业设计文档见 [fighter_build_design.md](file:///c:/work/MiniBattleSimulator/design/fighter_build_design.md)。
- 程序重构应以该文档中的 `Lv1-Lv5 Build 表` 为准，不以旧 `feat_config.lua` 中的战士条目为准。
- 当前确定的战士主轴是：
  - `基础武器攻击`
  - `二次生命`
  - `冠军 / 战斗大师 / 护卫`
  - `额外攻击` 质变

### 相关设计文档

- [fighter_build_design.md](file:///c:/work/MiniBattleSimulator/design/fighter_build_design.md)
- [rogue_build_design.md](file:///c:/work/MiniBattleSimulator/design/rogue_build_design.md)
- [monk_build_design.md](file:///c:/work/MiniBattleSimulator/design/monk_build_design.md)
- [paladin_build_design.md](file:///c:/work/MiniBattleSimulator/design/paladin_build_design.md)
- [ranger_build_design.md](file:///c:/work/MiniBattleSimulator/design/ranger_build_design.md)
- [cleric_build_design.md](file:///c:/work/MiniBattleSimulator/design/cleric_build_design.md)
- [sorcerer_build_design.md](file:///c:/work/MiniBattleSimulator/design/sorcerer_build_design.md)
- [wizard_build_design.md](file:///c:/work/MiniBattleSimulator/design/wizard_build_design.md)
- [warlock_build_design.md](file:///c:/work/MiniBattleSimulator/design/warlock_build_design.md)

### 旧系统边界

- 旧系统当前的主要入口在：
  - `config/feat_config.lua`
  - `config/class_level_grants.lua`
  - `config/hero_data.lua`
  - `modules/passive_handlers.lua`
  - `modules/battle_skill.lua`
- 旧系统可继续作为过渡兼容层存在，但不应继续扩写旧语义的战士条目。
- 新对话开始实现时，默认策略应为：
  - 新增新管线
  - 战士优先切到新管线
  - 其他职业暂时保留旧管线

### 第一阶段推荐落点

- 第一阶段优先新增：
  - `config/feat_build_config.lua`
  - `config/class_build_progression.lua`
  - `config/skill_runtime_config.lua`
  - `modules/hero_build.lua`
  - `modules/skill_runtime.lua`
- 第一阶段目标不是做完战士全部数值平衡，而是先验证：
  - Feat 能授予 skill
  - Feat 能修改 skill
  - BuildState 能生成 active/passive 注册结果
  - 战士能脱离 `classId -> passive` 的旧硬编码链路

### 新对话实现时的注意事项

- 先保住战士样板最小闭环，不要一开始同时迁移多个职业。
- 优先做“可运行的结构正确”，再做“技能细节完全齐全”。
- 新旧系统并存期间，避免修改非战士职业的现有行为。
- 若需要暂时复用旧 `skillId`，可以复用执行器，但不要继续沿用旧技能语义命名。
