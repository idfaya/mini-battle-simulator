# Roguelike Feat / Skill 填表稿

## 目的

这份文档把当前 `Lv2-Lv10` 的 Roguelike 职业设计，整理成可工程落表的数据草案，面向：

- `config/tables/feats.lua`
- `config/data/skills.json`

这是一份**填表草案**，不是直接可运行的补丁。核心目标是先锁定：

- feat id 与命名风格
- `choiceGroup` 分组方式
- `grant_skill / modify_skill / replace_skill` 的使用意图
- 建议新增的 skill id 与 skill 条目骨架

## 前提

- 成长入口仍然只有 `Feat`
- 每个职业暂时只做 **2 个子职**
- Feat 必须短、易读、战斗中能立刻感知
- 强化优先级：
  - 数值提升
  - 发射物数量提升
  - 小型机制追加
- 尽量复用现有的基础攻击链 / 基础施法链

## ID 约定

### Feat ID

沿用 `feats.lua` 里现有的 `FeatId(level, index)` 模式。

- Rogue: `406xx`~`410xx`
- Fighter: `6xx`~`10xx`
- Monk: `106xx`~`110xx`
- Paladin: `206xx`~`210xx`
- Ranger: `306xx`~`310xx`
- Cleric: `506xx`~`510xx`
- Sorcerer: `706xx`~`710xx`
- Wizard: `806xx`~`810xx`
- Warlock: `906xx`~`910xx`
- Barbarian: `1006xx`~`1010xx`

示例：

```lua
rogue_level6_feat_1 = FeatId(406, 1)
fighter_level9_feat_1 = FeatId(9, 1)
```

### Skill ID

沿用每个职业当前已有的 `classGroup` 号段，继续向后扩展。

- Rogue: `800010xx`
- Fighter: `800020xx`
- Monk: `800030xx`
- Paladin: `800040xx`
- Ranger: `800050xx`
- Cleric: `800060xx`
- Sorcerer: `800070xx`
- Wizard: `800080xx`
- Warlock: `800090xx`
- Barbarian: `800100xx`

推荐用法：

- 现有基础技能 id 不改
- 子职主动优先占用 `...13`、`...14`
- `Lv9` 主动优先占用 `...16`
- 被动 / feature 技能接在当前职业最后一个被动技能之后

## Effect 类型规则

### 使用 `grant_skill`

- 新的被动触发器
- 新的子职主动
- 新的 `Lv9` 主动
- 新的终盘 capstone 被动

### 使用 `modify_skill`

- 伤害提升
- 冷却缩短
- 发射物数量增加
- 弹射次数增加
- 护盾 / 治疗 / 暴击等仍然可以挂在原技能上的数值强化

### 使用 `replace_skill`

- `Lv10` capstone 把 `Lv9` 主动升级成子职终极技能
- 单体主动升格为多段 / 多发 / AOE 变体

## 运行时说明

- `modify_skill.add` 可以安全合并进 `buildState.skillMods`
- 纯数值强化优先补丁到母技能或招牌主动上
- 复杂触发逻辑建议在 `skills.json` 里新增隐藏被动，再通过 `grant_skill` 接入

---

## 盗贼 Rogue

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `rogue_lv2_deep_stab` | `FeatId(402, 1)` | 2 | `rogue_lv2_basic` | `modify_skill` | `80001011` | 基础攻击追加 `+1d6` 偷袭伤害 |
| `rogue_lv2_shadow_step` | `FeatId(402, 2)` | 2 | `rogue_lv2_basic` | `grant_skill` | `80001102` | 每回合第一次攻击无视前排 |
| `rogue_lv2_evasive_roll` | `FeatId(402, 3)` | 2 | `rogue_lv2_basic` | `grant_skill` | `80001112` | 每回合第一次受击伤害 `-2` |
| `rogue_lv3_assassin` | `FeatId(403, 1)` | 3 | `rogue_lv3_subclass` | `grant_skill` | `80001013` | 获得影袭处决，`CD3`；执行一次基础攻击，若目标低于半血，额外造成 `+2d6` |
| `rogue_lv3_shadow_dancer` | `FeatId(403, 2)` | 3 | `rogue_lv3_subclass` | `grant_skill` | `80001014` | 获得影舞飞刃，`CD2`；无视前排攻击后排，命中后额外造成 `+1d6` |
| `rogue_lv4_assassin_mark` | `FeatId(404, 1)` | 4 | `rogue_lv4_mastery` | `grant_skill` | `80001113` | 连续攻击同一目标时，每次命中额外造成 `+2`，最多叠加 `3` 层 |
| `rogue_lv4_smoke_afterimage` | `FeatId(404, 2)` | 4 | `rogue_lv4_mastery` | `grant_skill` | `80001114` | 攻击后直到下回合开始获得 `AC +1` 且第一次受击伤害 `-2` |
| `rogue_lv5_kill_chase` | `FeatId(405, 1)` | 5 | `rogue_lv5_capstone` | `grant_skill` | `80001115` | 每回合第一次击杀后追加追击 |
| `rogue_lv6_exposed_wound` | `FeatId(406, 1)` | 6 | `rogue_lv6_assassin` | `grant_skill` | `80001116` | 对低于半血的目标命中后，额外造成 `+1d8` |
| `rogue_lv6_shadow_cut` | `FeatId(406, 2)` | 6 | `rogue_lv6_shadow` | `grant_skill` | `80001117` | 每回合第一次命中后排目标后，立刻追加一次半伤轻击 |
| `rogue_lv7_uncanny_dodge` | `FeatId(407, 1)` | 7 | `rogue_lv7_survival` | `grant_skill` | `80001108` | 每回合第一次受击伤害减半 |
| `rogue_lv8_lethal_tempo` | `FeatId(408, 1)` | 8 | `rogue_lv8_mastery` | `grant_skill` | `80001118` | 若本回合未受伤，则第一次攻击获得 `hit +1` 且伤害 `+1d6` |
| `rogue_lv8_blood_rush` | `FeatId(408, 2)` | 8 | `rogue_lv8_mastery` | `grant_skill` | `80001119` | 击杀后回复生命 |
| `rogue_lv9_execute` | `FeatId(409, 1)` | 9 | `rogue_lv9_active` | `grant_skill` | `80001016` | `Lv9` 高伤处决主动 |
| `rogue_lv10_assassin_execute_plus` | `FeatId(410, 1)` | 10 | `rogue_lv10_assassin_capstone` | `replace_skill` | `80001016 -> 80001017` | 处决升级为 `CD2`；对半血以下目标额外造成 `+4d6` |
| `rogue_lv10_shadow_blade_storm` | `FeatId(410, 2)` | 10 | `rogue_lv10_shadow_capstone` | `replace_skill` | `80001016 -> 80001018` | 处决升级为三连击；每击造成一次半伤基础攻击 |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `rogue_evasive_roll` | `80001112` | passive | reaction | `damage_reduction` | `rogue,survivability` | 每回合第一次受击伤害 `-2` |
| `rogue_assassin_mark` | `80001113` | passive | feature | `marker` | `rogue,assassin,burst` | 连打同一目标时每层 `+2` 伤害，最多 `3` 层 |
| `rogue_smoke_afterimage` | `80001114` | passive | feature | `marker` | `rogue,shadow,survivability` | 攻击后获得 `AC +1` 且第一次受击伤害 `-2` |
| `rogue_kill_chase` | `80001115` | passive | feature | `followup_attack` | `rogue,tempo,kill` | 每回合第一次击杀触发追击 |
| `rogue_exposed_wound` | `80001116` | passive | feature | `marker` | `rogue,assassin,execute` | 对低血目标造成额外爆发 |
| `rogue_shadow_cut` | `80001117` | passive | feature | `followup_attack` | `rogue,shadow,backline` | 攻击后排目标时追加轻击 |
| `rogue_lethal_tempo` | `80001118` | passive | feature | `marker` | `rogue,burst` | 本回合未受伤时第一次攻击获得 `hit +1` 与 `+1d6` 伤害 |
| `rogue_blood_rush` | `80001119` | passive | feature | `heal_on_kill` | `rogue,survivability,kill` | 击杀后回复生命 |
| `rogue_execute` | `80001016` | active | active | `execute_strike` | `rogue,signature,execute` | `Lv9` 通用处决主动 |
| `rogue_assassin_execute_plus` | `80001017` | active | active | `execute_strike` | `rogue,assassin,ultimate` | `CD2` 单体处决；对半血以下目标额外 `+4d6` |
| `rogue_shadow_blade_storm` | `80001018` | active | active | `multi_strike` | `rogue,shadow,ultimate` | 连续执行 `3` 次半伤基础攻击 |

---

## 战士 Fighter

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `fighter_lv2_precision_stance` | `FeatId(2, 1)` | 2 | `fighter_lv2_style` | `modify_skill` | `80002001` | 命中加值 `+1` |
| `fighter_lv2_heavy_slash` | `FeatId(2, 2)` | 2 | `fighter_lv2_style` | `modify_skill` | `80002001` | 伤害 `+1d4` |
| `fighter_lv2_armor_training` | `FeatId(2, 3)` | 2 | `fighter_lv2_style` | `grant_skill` | `80002111` | 常驻 `AC +1` |
| `fighter_lv3_duelist` | `FeatId(3, 1)` | 3 | `fighter_lv3_subclass` | `grant_skill` | `80002006` | 获得决斗连斩，`CD3`；对当前目标执行一次基础攻击，若命中，再追加一次半伤追击 |
| `fighter_lv3_guardian` | `FeatId(3, 2)` | 3 | `fighter_lv3_subclass` | `grant_skill` | `80002005` | 获得护卫架势，`CD3`；本回合 `AC +2`，并替相邻友军承受第一次近战攻击的 `1/2` 伤害 |
| `fighter_lv4_sweep` | `FeatId(4, 1)` | 4 | `fighter_lv4_mastery` | `grant_skill` | `80002110` | 命中主目标后，对相邻目标造成 `1d4` 溅射伤害 |
| `fighter_lv4_hold_line` | `FeatId(4, 2)` | 4 | `fighter_lv4_mastery` | `grant_skill` | `80002112` | 护卫期间额外获得 `AC +1`，且第一次护卫减伤再 `+2` |
| `fighter_lv5_extra_attack` | `FeatId(5, 1)` | 5 | `fighter_lv5_capstone` | `grant_skill` | `80002109` | 额外攻击 |
| `fighter_lv6_combo_pressure` | `FeatId(6, 1)` | 6 | `fighter_lv6_duelist` | `grant_skill` | `80002113` | 连续命中同一目标时每层 `+2` 伤害，最多 `3` 层 |
| `fighter_lv6_guard_counter_plus` | `FeatId(6, 2)` | 6 | `fighter_lv6_guardian` | `grant_skill` | `80002105` | 护卫反击额外造成 `+1d6` |
| `fighter_lv7_indomitable` | `FeatId(7, 1)` | 7 | `fighter_lv7_survival` | `grant_skill` | `80002101` | 防止一次致死 |
| `fighter_lv8_armor_break` | `FeatId(8, 1)` | 8 | `fighter_lv8_mastery` | `grant_skill` | `80002114` | 第一次命中后施加破甲 |
| `fighter_lv8_weapon_master` | `FeatId(8, 2)` | 8 | `fighter_lv8_mastery` | `modify_skill` | `80002001` | 暴击阈值降低 `1` |
| `fighter_lv9_action_surge_plus` | `FeatId(9, 1)` | 9 | `fighter_lv9_active` | `grant_skill` | `80002007` | `Lv9` 爆发主动 |
| `fighter_lv10_duelist_master` | `FeatId(10, 1)` | 10 | `fighter_lv10_duelist_capstone` | `grant_skill` | `80002115` | 额外攻击由半伤提升为完整基础攻击伤害 |
| `fighter_lv10_iron_bastion` | `FeatId(10, 2)` | 10 | `fighter_lv10_guardian_capstone` | `grant_skill` | `80002116` | 战斗开始时全队第一次受击伤害 `-3` |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `fighter_armor_training` | `80002111` | passive | passive | `marker` | `fighter,defense` | 平铺 AC 加成 |
| `fighter_hold_line` | `80002112` | passive | passive | `marker` | `fighter,guard,defense` | 护卫期间 `AC +1` 且第一次护卫减伤再 `+2` |
| `fighter_combo_pressure` | `80002113` | passive | feature | `marker` | `fighter,duelist,tempo` | 同一目标每层 `+2` 伤害，最多 `3` 层 |
| `fighter_armor_break` | `80002114` | passive | feature | `marker` | `fighter,break` | 第一次命中施加破甲 |
| `fighter_action_surge_plus` | `80002007` | active | active | `basic_attack_action` | `fighter,signature,burst` | 立刻执行 `2` 次基础攻击 |
| `fighter_duelist_master` | `80002115` | passive | feature | `marker` | `fighter,duelist,capstone` | 额外攻击提升为完整基础攻击伤害 |
| `fighter_iron_bastion` | `80002116` | passive | feature | `marker` | `fighter,guard,capstone` | 战斗开始时全队第一次受击伤害 `-3` |

---

## 武僧 Monk

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `monk_lv2_combo_art` | `FeatId(102, 1)` | 2 | `monk_lv2_basic` | `grant_skill` | `80003102` | 每回合第一次徒手命中后，追加一次半伤轻击 |
| `monk_lv2_guarding_mind` | `FeatId(102, 2)` | 2 | `monk_lv2_basic` | `grant_skill` | `80003103` | 第一次受击减伤 |
| `monk_lv2_swift_focus` | `FeatId(102, 3)` | 2 | `monk_lv2_basic` | `grant_skill` | `80003104` | 每回合第一次攻击获得 `hit +1` |
| `monk_lv3_pulse_school` | `FeatId(103, 1)` | 3 | `monk_lv3_subclass` | `grant_skill` | `80003013` | 获得震脉掌，`CD3`；造成 `1d8` 钝击伤害，并使目标进行一次体质豁免，失败则 `STUN 1` 回合 |
| `monk_lv3_flurry_school` | `FeatId(103, 2)` | 3 | `monk_lv3_subclass` | `grant_skill` | `80003016` | 获得连环拳，`CD3`；连续攻击 `2` 次，每次造成一次半伤基础攻击 |
| `monk_lv4_pulse_pressure` | `FeatId(104, 1)` | 4 | `monk_lv4_mastery` | `grant_skill` | `80003111` | 对受控目标命中后额外造成 `+1d6` |
| `monk_lv4_afterimage_fists` | `FeatId(104, 2)` | 4 | `monk_lv4_mastery` | `grant_skill` | `80003112` | 首次追打必定触发 |
| `monk_lv5_extra_attack` | `FeatId(105, 1)` | 5 | `monk_lv5_capstone` | `grant_skill` | `80003108` | 额外攻击 |
| `monk_lv6_deeper_pulse` | `FeatId(106, 1)` | 6 | `monk_lv6_pulse` | `grant_skill` | `80003109` | 眩晕成功后，目标直到下回合开始前 `AC -1` |
| `monk_lv6_endless_flurry` | `FeatId(106, 2)` | 6 | `monk_lv6_flurry` | `grant_skill` | `80003113` | 再追加一次轻击 |
| `monk_lv7_clear_mind` | `FeatId(107, 1)` | 7 | `monk_lv7_survival` | `grant_skill` | `80003114` | 第一次被控时自动净化 |
| `monk_lv8_flowing_ki` | `FeatId(108, 1)` | 8 | `monk_lv8_mastery` | `modify_skill` | `80003011` | 基础攻击伤害 `+1d4` |
| `monk_lv8_afterstep` | `FeatId(108, 2)` | 8 | `monk_lv8_mastery` | `grant_skill` | `80003115` | 攻击后获得闪避 |
| `monk_lv9_hundred_fists` | `FeatId(109, 1)` | 9 | `monk_lv9_active` | `grant_skill` | `80003017` | `Lv9` 四连打主动 |
| `monk_lv10_pulse_master` | `FeatId(110, 1)` | 10 | `monk_lv10_pulse_capstone` | `grant_skill` | `80003116` | 对眩晕目标额外造成 `+2d6` |
| `monk_lv10_flurry_master` | `FeatId(110, 2)` | 10 | `monk_lv10_flurry_capstone` | `grant_skill` | `80003117` | 所有追击伤害额外 `+2` |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `monk_pulse_school` | `80003013` | active | active | `stunning_strike` | `monk,signature,control` | `CD3`；造成 `1d8` 钝击伤害，并使目标体质豁免失败时 `STUN 1` 回合 |
| `monk_flurry_school` | `80003016` | active | active | `multi_strike` | `monk,signature,combo` | `CD3`；连续攻击 `2` 次，每次造成一次半伤基础攻击 |
| `monk_pulse_pressure` | `80003111` | passive | feature | `marker` | `monk,control` | 对受控目标命中后额外 `+1d6` |
| `monk_afterimage_fists` | `80003112` | passive | feature | `marker` | `monk,combo` | 首次追打必定触发 |
| `monk_endless_flurry` | `80003113` | passive | feature | `extra_attack` | `monk,combo` | 再追加一次轻击 |
| `monk_clear_mind` | `80003114` | passive | passive | `cleanse_control` | `monk,survival` | 第一次被控自动净化 |
| `monk_afterstep` | `80003115` | passive | feature | `marker` | `monk,mobility` | 攻击后获得闪避 |
| `monk_hundred_fists` | `80003017` | active | active | `multi_strike` | `monk,ultimate,combo` | `Lv9` 主动 |
| `monk_pulse_master` | `80003116` | passive | feature | `marker` | `monk,control,capstone` | 对眩晕目标增伤 |
| `monk_flurry_master` | `80003117` | passive | feature | `marker` | `monk,combo,capstone` | 所有追击伤害额外 `+2` |

---

## 圣武士 Paladin

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `paladin_lv2_divine_smite` | `FeatId(202, 1)` | 2 | `paladin_lv2_prayer` | `grant_skill` | `80004101` | 每回合第一次命中追加光耀伤害 |
| `paladin_lv2_holy_touch` | `FeatId(202, 2)` | 2 | `paladin_lv2_prayer` | `modify_skill` | `80004013` | 治疗量 `+2` |
| `paladin_lv2_shelter` | `FeatId(202, 3)` | 2 | `paladin_lv2_prayer` | `grant_skill` | `80004102` | 友军第一次受击减伤 |
| `paladin_lv3_judgement_oath` | `FeatId(203, 1)` | 3 | `paladin_lv3_oath` | `grant_skill` | `80004014` | 获得裁决重击，`CD3`；造成一次基础攻击，命中后额外造成 `+2d8` 光耀伤害 |
| `paladin_lv3_sanctuary_oath` | `FeatId(203, 2)` | 3 | `paladin_lv3_oath` | `grant_skill` | `80004015` | 获得圣域祷言，`CD3`；为全队提供 `4` 点护盾，并使前排 `AC +1` 持续 `1` 回合 |
| `paladin_lv4_judgement_mark` | `FeatId(204, 1)` | 4 | `paladin_lv4_mastery` | `grant_skill` | `80004109` | 对低于半血的目标命中后额外造成 `+1d8` 光耀伤害 |
| `paladin_lv4_sanctuary_barrier` | `FeatId(204, 2)` | 4 | `paladin_lv4_mastery` | `grant_skill` | `80004110` | 施法后提供护盾 |
| `paladin_lv5_extra_attack` | `FeatId(205, 1)` | 5 | `paladin_lv5_capstone` | `grant_skill` | `80004108` | 额外攻击 |
| `paladin_lv6_heavy_smite` | `FeatId(206, 1)` | 6 | `paladin_lv6_judgement` | `grant_skill` | `80004111` | 惩击额外追加伤害骰 |
| `paladin_lv6_guarding_aura` | `FeatId(206, 2)` | 6 | `paladin_lv6_sanctuary` | `grant_skill` | `80004112` | 团队 AC 加成 |
| `paladin_lv7_holy_ward` | `FeatId(207, 1)` | 7 | `paladin_lv7_survival` | `grant_skill` | `80004113` | 第一次受击减伤 |
| `paladin_lv8_cleanse_touch` | `FeatId(208, 1)` | 8 | `paladin_lv8_mastery` | `grant_skill` | `80004114` | 治疗时净化 1 个负面 |
| `paladin_lv8_faith_guard` | `FeatId(208, 2)` | 8 | `paladin_lv8_mastery` | `grant_skill` | `80004115` | 团队首击额外减伤 `+1` |
| `paladin_lv9_divine_judgement` | `FeatId(209, 1)` | 9 | `paladin_lv9_active` | `grant_skill` | `80004016` | `Lv9` 神罚主动 |
| `paladin_lv10_judgement_final` | `FeatId(210, 1)` | 10 | `paladin_lv10_judgement_capstone` | `replace_skill` | `80004016 -> 80004017` | 神罚斩升级为 `CD2`，命中后额外 `+3d8` 光耀伤害 |
| `paladin_lv10_sanctuary_wall` | `FeatId(210, 2)` | 10 | `paladin_lv10_sanctuary_capstone` | `replace_skill` | `80004016 -> 80004018` | 为全队提供 `8` 点护盾，并使第一次受击伤害 `-2` |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `paladin_heavy_smite` | `80004111` | passive | feature | `marker` | `paladin,radiant` | 惩击额外伤害骰 |
| `paladin_guarding_aura` | `80004112` | passive | feature | `marker` | `paladin,aura,defense` | 团队 AC 加成 |
| `paladin_holy_ward` | `80004113` | passive | passive | `damage_reduction` | `paladin,survival` | 第一次受击减伤 |
| `paladin_cleanse_touch` | `80004114` | passive | feature | `marker` | `paladin,heal` | 治疗时净化 1 个负面 |
| `paladin_faith_guard` | `80004115` | passive | feature | `marker` | `paladin,defense` | 团队首击减伤 |
| `paladin_judgement_oath` | `80004014` | active | active | `vengeance_smite` | `paladin,signature,burst` | `CD3`；造成一次基础攻击，命中后额外 `+2d8` 光耀伤害 |
| `paladin_sanctuary_oath` | `80004015` | active | active | `guardian_aura` | `paladin,signature,defense` | `CD3`；为全队提供 `4` 点护盾，并使前排 `AC +1` 持续 `1` 回合 |
| `paladin_divine_judgement` | `80004016` | active | active | `vengeance_smite` | `paladin,ultimate,burst` | `Lv9` 主动 |
| `paladin_judgement_final` | `80004017` | active | active | `vengeance_smite` | `paladin,judgement,ultimate` | 爆发替换版 |
| `paladin_sanctuary_wall` | `80004018` | active | active | `guardian_aura` | `paladin,sanctuary,ultimate` | 护壁替换版 |

---

## 游侠 Ranger

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `ranger_lv2_precise_archery` | `FeatId(302, 1)` | 2 | `ranger_lv2_basic` | `modify_skill` | `80005011` | 基础攻击伤害 `+1d4` |
| `ranger_lv2_quickshot` | `FeatId(302, 2)` | 2 | `ranger_lv2_basic` | `grant_skill` | `80005112` | 每回合第一次普通攻击额外再射 1 箭 |
| `ranger_lv2_mark_deepen` | `FeatId(302, 3)` | 2 | `ranger_lv2_basic` | `grant_skill` | `80005101` | 你对标记目标造成的伤害额外 `+2` |
| `ranger_lv3_hunter` | `FeatId(303, 1)` | 3 | `ranger_lv3_subclass` | `grant_skill` | `80005013` | 获得猎杀号令，`CD3`；对单体造成一次基础攻击，若目标已被标记，额外造成 `+2d6` |
| `ranger_lv3_arrow_rain` | `FeatId(303, 2)` | 3 | `ranger_lv3_subclass` | `grant_skill` | `80005016` | 获得散华箭雨，`CD3`；发射 `3` 支箭，每支造成 `1d6` 伤害，随机命中敌人 |
| `ranger_lv4_weakpoint_hunt` | `FeatId(304, 1)` | 4 | `ranger_lv4_mastery` | `grant_skill` | `80005113` | 命中标记目标后额外造成 `+1d6` |
| `ranger_lv4_scattershot` | `FeatId(304, 2)` | 4 | `ranger_lv4_mastery` | `grant_skill` | `80005114` | 额外箭矢可以转火 |
| `ranger_lv5_extra_attack` | `FeatId(305, 1)` | 5 | `ranger_lv5_capstone` | `grant_skill` | `80005108` | 额外攻击 |
| `ranger_lv6_hunting_high` | `FeatId(306, 1)` | 6 | `ranger_lv6_hunter` | `grant_skill` | `80005115` | 命中标记目标后再追加 1 箭 |
| `ranger_lv6_multi_arrow` | `FeatId(306, 2)` | 6 | `ranger_lv6_arrow_rain` | `modify_skill` | `80005016` | 发射物数量 `+1` |
| `ranger_lv7_field_endurance` | `FeatId(307, 1)` | 7 | `ranger_lv7_survival` | `grant_skill` | `80005104` | 第一次受击减伤 |
| `ranger_lv8_piercing_arrow` | `FeatId(308, 1)` | 8 | `ranger_lv8_mastery` | `grant_skill` | `80005116` | 箭矢额外穿透 1 个目标 |
| `ranger_lv8_tracker` | `FeatId(308, 2)` | 8 | `ranger_lv8_mastery` | `grant_skill` | `80005117` | 标记持续时间 `+1` 回合 |
| `ranger_lv9_arrow_storm` | `FeatId(309, 1)` | 9 | `ranger_lv9_active` | `grant_skill` | `80005109` | `Lv9` 箭雨主动 |
| `ranger_lv10_godseye` | `FeatId(310, 1)` | 10 | `ranger_lv10_hunter_capstone` | `grant_skill` | `80005118` | 对标记目标的攻击获得 `hit +1` 且伤害 `+1d8` |
| `ranger_lv10_wind_barrage` | `FeatId(310, 2)` | 10 | `ranger_lv10_arrow_rain_capstone` | `modify_skill` | `80005109` | 箭雨发射物数量 `+3` |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `ranger_quickshot` | `80005112` | passive | feature | `extra_attack` | `ranger,ranged,tempo` | 起手额外射 1 箭 |
| `ranger_weakpoint_hunt` | `80005113` | passive | feature | `marker` | `ranger,mark,burst` | 命中标记目标后额外 `+1d6` |
| `ranger_scattershot` | `80005114` | passive | feature | `marker` | `ranger,multi_shot` | 额外箭矢可以转火 |
| `ranger_hunting_high` | `80005115` | passive | feature | `followup_attack` | `ranger,mark` | 命中标记目标后再追加一箭 |
| `ranger_piercing_arrow` | `80005116` | passive | feature | `marker` | `ranger,pierce` | 箭矢额外穿透一个目标 |
| `ranger_tracker` | `80005117` | passive | feature | `marker` | `ranger,mark,utility` | 标记持续时间 `+1` 回合 |
| `ranger_godseye` | `80005118` | passive | feature | `marker` | `ranger,hunter,capstone` | 对标记目标获得 `hit +1` 且伤害 `+1d8` |
| `ranger_hunter_school` | `80005013` | active | active | `hunter_shot` | `ranger,signature,hunter` | `CD3`；对单体执行一次基础攻击，若目标已被标记，额外 `+2d6` |
| `ranger_arrow_rain_school` | `80005016` | active | active | `arrow_rain` | `ranger,signature,multi_shot` | `CD3`；发射 `3` 支箭，每支造成 `1d6` 伤害，随机命中敌人 |

---

## 牧师 Cleric

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `cleric_lv2_radiant_prayer` | `FeatId(502, 1)` | 2 | `cleric_lv2_prayer` | `modify_skill` | `80006011` | 神圣火花伤害 `+1d8` |
| `cleric_lv2_healing_prayer` | `FeatId(502, 2)` | 2 | `cleric_lv2_prayer` | `modify_skill` | `80006012` | 治疗量 `+2` |
| `cleric_lv2_shelter_prayer` | `FeatId(502, 3)` | 2 | `cleric_lv2_prayer` | `grant_skill` | `80006103` | 团队首次受击减伤 |
| `cleric_lv3_light_domain` | `FeatId(503, 1)` | 3 | `cleric_lv3_domain` | `grant_skill` | `80006014` | 获得圣焰裁断，`CD3`；对单体造成 `2d8` 光耀伤害，并附加 `1` 层灼烧 |
| `cleric_lv3_life_domain` | `FeatId(503, 2)` | 3 | `cleric_lv3_domain` | `grant_skill` | `80006013` | 获得生命祷言，`CD3`；治疗全队 `1d8+施法修正`，并为最低血目标额外回复 `+2` |
| `cleric_lv4_holy_flame` | `FeatId(504, 1)` | 4 | `cleric_lv4_mastery` | `grant_skill` | `80006109` | 你每回合第一次进攻型神术额外造成 `+1d8` 光耀伤害 |
| `cleric_lv4_mercy_spread` | `FeatId(504, 2)` | 4 | `cleric_lv4_mastery` | `grant_skill` | `80006110` | 额外多跳一次治疗 |
| `cleric_lv5_higher_prayer` | `FeatId(505, 1)` | 5 | `cleric_lv5_capstone` | `modify_skill` | `80006013` | 群体治疗额外 `+1d8` |
| `cleric_lv5_holy_verdict_plus` | `FeatId(505, 2)` | 5 | `cleric_lv5_capstone` | `modify_skill` | `80006014` | 主目标额外 `+2d6` |
| `cleric_lv6_burning_light` | `FeatId(506, 1)` | 6 | `cleric_lv6_light` | `grant_skill` | `80006111` | 光明领域追加更多灼烧 |
| `cleric_lv6_restoration` | `FeatId(506, 2)` | 6 | `cleric_lv6_life` | `grant_skill` | `80006112` | 第一次治疗附带护盾 |
| `cleric_lv7_divine_guard` | `FeatId(507, 1)` | 7 | `cleric_lv7_survival` | `grant_skill` | `80006113` | 每名友军每场第一次受到 `STUN/FROZEN/SILENT` 时，改为只受到 `SLOW 1` 回合 |
| `cleric_lv8_long_prayer` | `FeatId(508, 1)` | 8 | `cleric_lv8_mastery` | `grant_skill` | `80006114` | 持续回合 `+1` |
| `cleric_lv8_holy_vessel` | `FeatId(508, 2)` | 8 | `cleric_lv8_mastery` | `grant_skill` | `80006115` | 自身第一次受击减伤 |
| `cleric_lv9_divine_nova` | `FeatId(509, 1)` | 9 | `cleric_lv9_active` | `grant_skill` | `80006016` | `Lv9` 攻疗二选一型新星主动 |
| `cleric_lv10_bishop_of_light` | `FeatId(510, 1)` | 10 | `cleric_lv10_light_capstone` | `replace_skill` | `80006016 -> 80006017` | 新星升级为 `CD3`；对全体敌人造成 `4d6` 光耀伤害，并附加 `1` 层灼烧 |
| `cleric_lv10_bishop_of_mercy` | `FeatId(510, 2)` | 10 | `cleric_lv10_life_capstone` | `replace_skill` | `80006016 -> 80006018` | 新星升级为 `CD3`；治疗全队 `2d8+施法修正`，并提供 `4` 点护盾 |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `cleric_burning_light` | `80006111` | passive | feature | `marker` | `cleric,light,damage` | 进攻型神术追加灼烧 |
| `cleric_restoration` | `80006112` | passive | feature | `marker` | `cleric,life,heal` | 第一次治疗附带护盾 |
| `cleric_divine_guard` | `80006113` | passive | feature | `marker` | `cleric,support,defense` | 每名友军每场第一次受到 `STUN/FROZEN/SILENT` 时改为 `SLOW 1` 回合 |
| `cleric_long_prayer` | `80006114` | passive | feature | `marker` | `cleric,utility` | 持续时间 `+1` 回合 |
| `cleric_holy_vessel` | `80006115` | passive | passive | `damage_reduction` | `cleric,survival` | 自身第一次受击减伤 |
| `cleric_light_domain` | `80006014` | active | active | `radiant_blast` | `cleric,signature,light` | `CD3`；对单体造成 `2d8` 光耀伤害，并附加 `1` 层灼烧 |
| `cleric_life_domain` | `80006013` | active | active | `group_heal` | `cleric,signature,life` | `CD3`；治疗全队 `1d8+施法修正`，并为最低血目标额外回复 `+2` |
| `cleric_divine_nova` | `80006016` | active | active | `divine_nova` | `cleric,ultimate,holy` | `CD4`；在对全体敌人造成 `3d6` 光耀伤害或治疗全队 `1d8+施法修正` 之间二选一 |
| `cleric_bishop_of_light` | `80006017` | active | active | `divine_nova` | `cleric,light,ultimate` | `CD3`；对全体敌人造成 `4d6` 光耀伤害，并附加 `1` 层灼烧 |
| `cleric_bishop_of_mercy` | `80006018` | active | active | `divine_nova` | `cleric,life,ultimate` | `CD3`；治疗全队 `2d8+施法修正`，并提供 `4` 点护盾 |

---

## 术士 Sorcerer

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `sorcerer_lv2_ember` | `FeatId(702, 1)` | 2 | `sorcerer_lv2_core` | `modify_skill` | `80007001` | 基础法术伤害 `+1d4` |
| `sorcerer_lv2_spark_split` | `FeatId(702, 2)` | 2 | `sorcerer_lv2_core` | `modify_skill` | `80007001` | 发射物数量 `+1` |
| `sorcerer_lv2_burn_linger` | `FeatId(702, 3)` | 2 | `sorcerer_lv2_core` | `grant_skill` | `80007101` | 点燃持续时间 `+1` 回合 |
| `sorcerer_lv3_burner` | `FeatId(703, 1)` | 3 | `sorcerer_lv3_subclass` | `grant_skill` | `80007003` | 获得灰烬爆燃，`CD3`；造成 `2d8` 火焰伤害，若目标已点燃，额外 `+1d8` |
| `sorcerer_lv3_flame_tide` | `FeatId(703, 2)` | 3 | `sorcerer_lv3_subclass` | `grant_skill` | `80007005` | 获得流火分射，`CD3`；对最多 `3` 名目标各造成 `1d8` 火焰伤害 |
| `sorcerer_lv4_scorch` | `FeatId(704, 1)` | 4 | `sorcerer_lv4_mastery` | `grant_skill` | `80007102` | 点燃层数 `+1` |
| `sorcerer_lv4_fireflow` | `FeatId(704, 2)` | 4 | `sorcerer_lv4_mastery` | `grant_skill` | `80007103` | 扩大溅射范围 |
| `sorcerer_lv5_flame_storm_plus` | `FeatId(705, 1)` | 5 | `sorcerer_lv5_capstone` | `modify_skill` | `80007004` | AOE 伤害 `+1d6` |
| `sorcerer_lv6_explode_burn` | `FeatId(706, 1)` | 6 | `sorcerer_lv6_burner` | `grant_skill` | `80007104` | 命中已点燃目标时追加爆燃 |
| `sorcerer_lv6_three_sparks` | `FeatId(706, 2)` | 6 | `sorcerer_lv6_flame_tide` | `modify_skill` | `80007001` | 发射物数量再次 `+1` |
| `sorcerer_lv7_fire_coat` | `FeatId(707, 1)` | 7 | `sorcerer_lv7_survival` | `grant_skill` | `80007105` | 施法后获得护盾 |
| `sorcerer_lv8_overheat` | `FeatId(708, 1)` | 8 | `sorcerer_lv8_mastery` | `modify_skill` | `80007001` | 法术攻击加值 `+1` |
| `sorcerer_lv8_chain_ignite` | `FeatId(708, 2)` | 8 | `sorcerer_lv8_mastery` | `grant_skill` | `80007106` | 未点燃目标被命中后附加点燃 |
| `sorcerer_lv9_inferno` | `FeatId(709, 1)` | 9 | `sorcerer_lv9_active` | `grant_skill` | `80007006` | `Lv9` 大范围火焰主动 |
| `sorcerer_lv10_burner_king` | `FeatId(710, 1)` | 10 | `sorcerer_lv10_burner_capstone` | `grant_skill` | `80007107` | 对已点燃目标额外造成 `+1d8` |
| `sorcerer_lv10_fire_tide_king` | `FeatId(710, 2)` | 10 | `sorcerer_lv10_flame_tide_capstone` | `grant_skill` | `80007108` | 所有火系技能额外溅射 |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `sorcerer_burn_linger` | `80007101` | passive | feature | `marker` | `sorcerer,burn` | 点燃持续时间 `+1` 回合 |
| `sorcerer_scorch` | `80007102` | passive | feature | `marker` | `sorcerer,burn` | 点燃层数 `+1` |
| `sorcerer_fireflow` | `80007103` | passive | feature | `marker` | `sorcerer,aoe` | 扩大溅射范围 |
| `sorcerer_explode_burn` | `80007104` | passive | feature | `marker` | `sorcerer,burn,burst` | 命中已点燃目标时追加爆燃 |
| `sorcerer_fire_coat` | `80007105` | passive | feature | `shield_on_cast` | `sorcerer,survival` | 施法后获得护盾 |
| `sorcerer_chain_ignite` | `80007106` | passive | feature | `marker` | `sorcerer,burn` | 命中未点燃目标时附加点燃 |
| `sorcerer_burner_king` | `80007107` | passive | feature | `marker` | `sorcerer,burn,capstone` | 对已点燃目标额外造成 `+1d8` |
| `sorcerer_fire_tide_king` | `80007108` | passive | feature | `marker` | `sorcerer,aoe,capstone` | 火系技能额外溅射 |
| `sorcerer_flame_tide` | `80007005` | active | active | `ash_burst` | `sorcerer,fire,splash` | `CD3`；对最多 `3` 名目标各造成 `1d8` 火焰伤害 |
| `sorcerer_inferno` | `80007006` | active | active | `flame_storm` | `sorcerer,ultimate,fire` | `CD4`；对范围内所有敌人造成 `4d6` 火焰伤害并附加 `1` 层点燃 |

---

## 法师 Wizard

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `wizard_lv2_frost_boost` | `FeatId(802, 1)` | 2 | `wizard_lv2_core` | `modify_skill` | `80008001` | 基础法术伤害 `+1d4` |
| `wizard_lv2_ice_shard` | `FeatId(802, 2)` | 2 | `wizard_lv2_core` | `modify_skill` | `80008001` | 发射物数量 `+1` |
| `wizard_lv2_chill_air` | `FeatId(802, 3)` | 2 | `wizard_lv2_core` | `grant_skill` | `80008101` | 命中后额外施加 `speed -2`，持续 `1` 回合 |
| `wizard_lv3_evoker` | `FeatId(803, 1)` | 3 | `wizard_lv3_subclass` | `grant_skill` | `80008003` | 获得奥术新星，`CD3`；对小范围敌人造成 `2d6` 力场伤害 |
| `wizard_lv3_frost_mage` | `FeatId(803, 2)` | 3 | `wizard_lv3_subclass` | `grant_skill` | `80008005` | 获得冰霜新星，`CD3`；对小范围敌人造成 `1d8` 冰冷伤害并施加 `SLOW 1` 回合 |
| `wizard_lv4_expansion` | `FeatId(804, 1)` | 4 | `wizard_lv4_mastery` | `grant_skill` | `80008102` | 扩大 AOE 半径 |
| `wizard_lv4_shatter_ice` | `FeatId(804, 2)` | 4 | `wizard_lv4_mastery` | `grant_skill` | `80008103` | 对减速或冻结目标额外造成 `+1d6` |
| `wizard_lv5_blizzard_plus` | `FeatId(805, 1)` | 5 | `wizard_lv5_capstone` | `modify_skill` | `80008004` | AOE 伤害 `+1d6` |
| `wizard_lv6_arcane_echo` | `FeatId(806, 1)` | 6 | `wizard_lv6_evoker` | `grant_skill` | `80008104` | AOE 额外再回响一次半伤 |
| `wizard_lv6_frost_prison` | `FeatId(806, 2)` | 6 | `wizard_lv6_frost` | `grant_skill` | `80008105` | 冻结持续时间 `+1` 回合 |
| `wizard_lv7_spell_shield` | `FeatId(807, 1)` | 7 | `wizard_lv7_survival` | `grant_skill` | `80008106` | 施法后获得护盾 |
| `wizard_lv8_break_ice` | `FeatId(808, 1)` | 8 | `wizard_lv8_mastery` | `grant_skill` | `80008107` | 对冻结目标追加伤害 |
| `wizard_lv8_cold_front` | `FeatId(808, 2)` | 8 | `wizard_lv8_mastery` | `modify_skill` | `80008001` | 发射物数量 `+1` |
| `wizard_lv9_absolute_zero` | `FeatId(809, 1)` | 9 | `wizard_lv9_active` | `grant_skill` | `80008006` | 获得绝对零度，`CD4`；对全体敌人造成 `3d6` 冰冷伤害，并对主目标施加 `FROZEN 1` 回合 |
| `wizard_lv10_evoker_master` | `FeatId(810, 1)` | 10 | `wizard_lv10_evoker_capstone` | `grant_skill` | `80008108` | 所有范围法术额外造成 `+1d8` |
| `wizard_lv10_frost_master` | `FeatId(810, 2)` | 10 | `wizard_lv10_frost_capstone` | `grant_skill` | `80008109` | 对冻结目标额外造成 `+1d8` |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `wizard_chill_air` | `80008101` | passive | feature | `marker` | `wizard,slow` | 命中后额外施加 `speed -2`，持续 `1` 回合 |
| `wizard_expansion` | `80008102` | passive | feature | `marker` | `wizard,aoe` | 扩大 AOE 半径 |
| `wizard_shatter_ice` | `80008103` | passive | feature | `marker` | `wizard,ice,burst` | 对减速或冻结目标额外 `+1d6` |
| `wizard_arcane_echo` | `80008104` | passive | feature | `marker` | `wizard,aoe` | AOE 再回响一次半伤 |
| `wizard_frost_prison` | `80008105` | passive | feature | `marker` | `wizard,freeze,control` | 冻结持续时间 `+1` 回合 |
| `wizard_spell_shield` | `80008106` | passive | feature | `shield_on_cast` | `wizard,survival` | 施法后获得护盾 |
| `wizard_break_ice` | `80008107` | passive | feature | `marker` | `wizard,freeze,burst` | 对冻结目标追加伤害 |
| `wizard_evoker_master` | `80008108` | passive | feature | `marker` | `wizard,aoe,capstone` | 所有范围法术额外造成 `+1d8` |
| `wizard_frost_master` | `80008109` | passive | feature | `marker` | `wizard,freeze,capstone` | 对冻结目标额外造成 `+1d8` |
| `wizard_frost_school_burst` | `80008005` | active | active | `freezing_nova` | `wizard,ice,control` | `CD3`；对小范围敌人造成 `1d8` 冰冷伤害并施加 `SLOW 1` 回合 |
| `wizard_absolute_zero` | `80008006` | active | active | `blizzard` | `wizard,ultimate,ice` | `CD4`；对全体敌人造成 `3d6` 冰冷伤害，并对主目标施加 `FROZEN 1` 回合 |

---

## 邪术师 Warlock

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `warlock_lv2_static_mark` | `FeatId(902, 1)` | 2 | `warlock_lv2_core` | `grant_skill` | `80009002` | 命中后附加印记 |
| `warlock_lv2_dual_blast` | `FeatId(902, 2)` | 2 | `warlock_lv2_core` | `modify_skill` | `80009001` | 发射物数量 `+1` |
| `warlock_lv2_conductive` | `FeatId(902, 3)` | 2 | `warlock_lv2_core` | `grant_skill` | `80009101` | 每次弹射的伤害衰减减少 `2` |
| `warlock_lv3_hex_raider` | `FeatId(903, 1)` | 3 | `warlock_lv3_subclass` | `grant_skill` | `80009005` | 获得咒袭雷矢，`CD3`；造成 `1d10` 雷电伤害，若目标带印记，你回复 `1d6` 生命 |
| `warlock_lv3_storm_pact` | `FeatId(903, 2)` | 3 | `warlock_lv3_subclass` | `grant_skill` | `80009003` | 获得雷契链击，`CD3`；对主目标造成 `2d6` 雷电伤害，并额外弹射 `1` 次 |
| `warlock_lv4_hex_wound` | `FeatId(904, 1)` | 4 | `warlock_lv4_mastery` | `grant_skill` | `80009102` | 对带印记目标额外造成 `+1d6` |
| `warlock_lv4_wide_chain` | `FeatId(904, 2)` | 4 | `warlock_lv4_mastery` | `grant_skill` | `80009103` | 弹射优先命中本次技能尚未命中过的目标 |
| `warlock_lv5_storm_chain_plus` | `FeatId(905, 1)` | 5 | `warlock_lv5_capstone` | `modify_skill` | `80009003` | 链伤害 `+1d6` |
| `warlock_lv6_drain_hex` | `FeatId(906, 1)` | 6 | `warlock_lv6_hex_raider` | `grant_skill` | `80009104` | 命中带印记目标时，回复 `1d6` 生命 |
| `warlock_lv6_thunder_swarm` | `FeatId(906, 2)` | 6 | `warlock_lv6_storm_pact` | `modify_skill` | `80009001` | 额外增加一次弹射 |
| `warlock_lv7_void_shell` | `FeatId(907, 1)` | 7 | `warlock_lv7_survival` | `grant_skill` | `80009105` | 每回合第一次受击伤害 `-2` |
| `warlock_lv8_overload` | `FeatId(908, 1)` | 8 | `warlock_lv8_mastery` | `grant_skill` | `80009106` | 对带印记目标的暴击阈值降低 `1` |
| `warlock_lv8_aftershock` | `FeatId(908, 2)` | 8 | `warlock_lv8_mastery` | `grant_skill` | `80009107` | 每回合第一次雷电命中后，对同一目标再造成 `1d4` 雷电伤害 |
| `warlock_lv9_stormburst` | `FeatId(909, 1)` | 9 | `warlock_lv9_active` | `grant_skill` | `80009004` | `Lv9` 雷暴主动 |
| `warlock_lv10_hex_lord` | `FeatId(910, 1)` | 10 | `warlock_lv10_hex_raider_capstone` | `grant_skill` | `80009108` | 对带印记目标额外造成 `+1d8` |
| `warlock_lv10_endless_storm` | `FeatId(910, 2)` | 10 | `warlock_lv10_storm_pact_capstone` | `modify_skill` | `80009004` | 弹射次数 `+1` |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `warlock_conductive` | `80009101` | passive | feature | `marker` | `warlock,chain` | 每次弹射的伤害衰减减少 `2` |
| `warlock_hex_wound` | `80009102` | passive | feature | `marker` | `warlock,mark,burst` | 对带印记目标额外造成 `+1d6` |
| `warlock_wide_chain` | `80009103` | passive | feature | `marker` | `warlock,chain` | 弹射优先命中本次技能尚未命中过的目标 |
| `warlock_drain_hex` | `80009104` | passive | feature | `heal_on_hit` | `warlock,mark,sustain` | 命中带印记目标时回复 `1d6` 生命 |
| `warlock_void_shell` | `80009105` | passive | passive | `damage_reduction` | `warlock,survival` | 每回合第一次受击伤害 `-2` |
| `warlock_overload` | `80009106` | passive | feature | `marker` | `warlock,mark,crit` | 对带印记目标的暴击阈值降低 `1` |
| `warlock_aftershock` | `80009107` | passive | feature | `marker` | `warlock,thunder` | 每回合第一次雷电命中后，对同一目标再造成 `1d4` 雷电伤害 |
| `warlock_hex_lord` | `80009108` | passive | feature | `marker` | `warlock,mark,capstone` | 对带印记目标额外造成 `+1d8` |
| `warlock_hex_raider` | `80009005` | active | active | `eldritch_blast` | `warlock,hex,signature` | `CD3`；造成 `1d10` 雷电伤害，若目标带印记，你回复 `1d6` 生命 |

---

## 野蛮人 Barbarian

### feats.lua 填表行

| feat_key | feat_id | 等级 | choiceGroup | effect | 目标技能 | 填表意图 |
| --- | ---: | ---: | --- | --- | --- | --- |
| `barbarian_lv2_rage_deepen` | `FeatId(1002, 1)` | 2 | `barbarian_lv2_core` | `grant_skill` | `80010101` | 狂暴伤害 `+2` |
| `barbarian_lv2_iron_skin` | `FeatId(1002, 2)` | 2 | `barbarian_lv2_core` | `grant_skill` | `80010104` | 狂暴期间减伤 |
| `barbarian_lv2_brutal_strike` | `FeatId(1002, 3)` | 2 | `barbarian_lv2_core` | `modify_skill` | `80010011` | 暴击阈值降低 `1` |
| `barbarian_lv3_berserker` | `FeatId(1003, 1)` | 3 | `barbarian_lv3_subclass` | `grant_skill` | `80010013` | 获得狂怒连斩，`CD3`；执行一次基础攻击，若本次暴击，再追加一次完整基础攻击 |
| `barbarian_lv3_iron_body` | `FeatId(1003, 2)` | 3 | `barbarian_lv3_subclass` | `grant_skill` | `80010105` | 狂暴期间额外获得 `AC +1`，且每回合第一次受击伤害 `-1` |
| `barbarian_lv4_bloodfrenzy` | `FeatId(1004, 1)` | 4 | `barbarian_lv4_mastery` | `grant_skill` | `80010106` | 对低于半血目标额外造成 `+1d8` |
| `barbarian_lv4_hard_bone` | `FeatId(1004, 2)` | 4 | `barbarian_lv4_mastery` | `grant_skill` | `80010107` | 第一次受击额外减伤 |
| `barbarian_lv5_extra_attack` | `FeatId(1005, 1)` | 5 | `barbarian_lv5_capstone` | `grant_skill` | `80010108` | 额外攻击 |
| `barbarian_lv6_rage_chain` | `FeatId(1006, 1)` | 6 | `barbarian_lv6_berserker` | `grant_skill` | `80010109` | 暴击追击后再追加一次挥击 |
| `barbarian_lv6_rebound` | `FeatId(1006, 2)` | 6 | `barbarian_lv6_iron_body` | `grant_skill` | `80010110` | 近战受击后反震 |
| `barbarian_lv7_refuse_fall` | `FeatId(1007, 1)` | 7 | `barbarian_lv7_survival` | `grant_skill` | `80010111` | 第一次致死伤害后保留 1 HP |
| `barbarian_lv8_rage_pressure` | `FeatId(1008, 1)` | 8 | `barbarian_lv8_mastery` | `grant_skill` | `80010112` | 狂暴伤害额外 `+2` |
| `barbarian_lv8_intimidate` | `FeatId(1008, 2)` | 8 | `barbarian_lv8_mastery` | `grant_skill` | `80010113` | 命中后降低目标伤害 |
| `barbarian_lv9_earthbreaker` | `FeatId(1009, 1)` | 9 | `barbarian_lv9_active` | `grant_skill` | `80010014` | `Lv9` 重击主动 |
| `barbarian_lv10_endless_rage` | `FeatId(1010, 1)` | 10 | `barbarian_lv10_berserker_capstone` | `grant_skill` | `80010103` | 移除狂暴每战次数限制 |
| `barbarian_lv10_steel_tyrant` | `FeatId(1010, 2)` | 10 | `barbarian_lv10_iron_body_capstone` | `grant_skill` | `80010114` | 狂暴期间受到的所有伤害再 `-2` |

### skills.json 填表行

| skill_key | skill_id | runtimeKind | designKind | execution.type | tags | 说明 |
| --- | ---: | --- | --- | --- | --- | --- |
| `barbarian_iron_skin` | `80010104` | passive | feature | `marker` | `barbarian,rage,defense` | 狂暴期间减伤 |
| `barbarian_iron_body` | `80010105` | passive | feature | `marker` | `barbarian,defense` | 狂暴期间额外获得 `AC +1`，且每回合第一次受击伤害 `-1` |
| `barbarian_bloodfrenzy` | `80010106` | passive | feature | `marker` | `barbarian,burst` | 对低于半血目标额外造成 `+1d8` |
| `barbarian_hard_bone` | `80010107` | passive | passive | `damage_reduction` | `barbarian,survival` | 第一次受击额外减伤 |
| `barbarian_extra_attack` | `80010108` | passive | feature | `extra_attack` | `barbarian,tempo` | 额外攻击 |
| `barbarian_rage_chain` | `80010109` | passive | feature | `followup_attack` | `barbarian,crit,berserk` | 暴击追击后再挥击一次 |
| `barbarian_rebound` | `80010110` | passive | reaction | `counter_basic` | `barbarian,defense,reaction` | 近战受击后反震 |
| `barbarian_refuse_fall` | `80010111` | passive | passive | `lethal_prevent` | `barbarian,survival` | 第一次致死后保留 1 HP |
| `barbarian_rage_pressure` | `80010112` | passive | feature | `marker` | `barbarian,rage,damage` | 狂暴伤害额外 `+2` |
| `barbarian_intimidate` | `80010113` | passive | feature | `marker` | `barbarian,debuff` | 命中后降低目标伤害 |
| `barbarian_steel_tyrant` | `80010114` | passive | feature | `marker` | `barbarian,rage,capstone` | 狂暴期间受到的所有伤害再 `-2` |
| `barbarian_earthbreaker` | `80010014` | active | active | `barbarian_heavy_strike` | `barbarian,ultimate,aoe` | `Lv9` 重击主动 |

---

## 落地顺序

推荐分阶段接入：

1. 先在 `feats.lua` 里补齐 `Lv6-Lv10` 的 id 和 `choiceGroup`
2. 再在 `skills.json` 里补被动 / 主动技能条目骨架
3. 纯数值型优先用 `modify_skill`
4. 新触发逻辑再去 `skills/` 里补隐藏被动处理
5. 最后再接 Web 侧的奖励展示与预览文案

## 当前优先级

建议最先落地这四个职业：

- Barbarian
- Sorcerer
- Wizard
- Warlock

原因：

- 这四个职业当前构筑最薄
- Roguelike 式强化的感知最强
- 发射物 / 弹射 / AOE 提升最容易在 Web 环境验证

## 5e 风格改写规则

避免使用下面这类百分比表达：

- `+10% hit chance`
- `+20% heal`
- `+30% damage`

统一改写成更接近 5e 的表达：

- `hit bonus +1`
- `spell DC +1`
- `AC +1`
- `damage +1d4 / +1d6 / +2`
- `healing +2 / +1d8`
- `crit threshold improves by 1`
- `echoes for half damage`
- `one additional projectile / bounce / target`

## 风险

- 上面部分 `modify_skill` 仍然是**意图描述**，不是最终运行时字段名
- `Lv10` 的 `replace_skill` 依赖前面先存在可替换的 `Lv9` 主动
- 团队减伤类效果要保持克制，避免叠层爆炸
- 发射物数量增加需要和 Web 侧时间线 / VFX 表现保持一致
