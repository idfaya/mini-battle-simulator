# Feat 卡牌化小队回合制设计稿

## 0. 文档定位

本文定义 `MiniBattle` 的 Feat 卡牌化战斗方案。

本方案的核心目标是把现有「自动回合出手」改为「队伍牌库回合制」：

```text
角色拥有 Feat
→ Feat 生成或修改 Card
→ 上场角色的 Card 合并为队伍牌库
→ 玩家每回合抽取队伍手牌
→ 打出 Card 调用现有 Skill / Timeline 结算
→ 敌方按公开 Intent 行动
```

本方案保留项目现有 5e 风格术语、能力画像、伤害骰与职业构筑资产，不完整保留 5e 桌面规则。所有会削弱卡牌决策确定性的机制必须卡牌化重写。

---

## 1. 设计目标

### 1.1 核心体验

```text
看敌方意图
→ 用整队手牌安排攻防节奏
→ 通过 Feat 改造牌库
→ 在 Roguelike 中构筑一套小队牌组
```

玩家的主要战术判断来自：

- 本回合敌方 Intent 的威胁。
- 当前手牌与队伍能量是否足够处理威胁。
- 是否用输出抢杀、用防御承压、用治疗稳场，或用控制打断。
- 长期牌库是否被基础卡、阵亡角色卡、低价值卡稀释。

### 1.2 保留资产

- 5e 风格 `HP / 护甲 / 抗性 / spell power / damage dice`。
- 现有 `Skill` 作为能力结算单元。
- 现有 `SkillTimeline` 作为动作表现与帧事件单元。
- 现有 `Buff / Debuff`、临时生命、减伤、抗性、控制等语义。
- 现有职业 Feat 路线、Roguelike 升级三选一、装备与 trinket。

### 1.3 新增核心

- 队伍牌库。
- 手牌、抽牌堆、弃牌堆、消耗区。
- 队伍共享能量。
- 敌方 Intent。
- Feat 到 Card 的投影规则。

---

## 2. 核心分层

### 2.1 分层关系

```text
Feat = 唯一成长单位
Card = Feat 的战斗投影
Skill = Card 打出后的结算实现
Timeline = Skill 的表现与帧结算
```

### 2.2 职责边界

| 层 | 职责 | 不负责 |
| --- | --- | --- |
| Feat | 成长选择、前置、路线、授予/修改/替换 Card | 直接写战斗结算 |
| Card | 费用、目标、标签、抽弃牌规则、owner、打出入口 | 自创伤害公式 |
| Skill | 伤害、治疗、Buff、抗性、特殊效果 | 抽牌与能量规则 |
| Timeline | 动画帧、命中帧、弹道、日志事件 | 牌库状态 |

Card 不直接实现伤害逻辑。Card 通过 `skillId` 调用 Skill，Skill 再进入现有 Timeline。

---

## 3. 队伍牌库

### 3.1 牌库来源

队伍牌库由所有上场 Hero 的 Card 合并生成。

```text
上场 Hero A 的 Feat Cards
+ 上场 Hero B 的 Feat Cards
+ 上场 Hero C 的 Feat Cards
...
= Team Deck
```

角色不是独立抽牌单位。抽牌以整队为单位。

### 3.2 归属规则

```text
卡牌属于角色
牌库属于队伍
费用属于队伍
```

每张 Card 必须记录 owner：

```lua
cardInstance = {
    uid = "run_card_001",
    cardId = 80001021,
    featId = 80001021,
    ownerRosterId = 12,
    ownerInstanceId = 10001,
    ownerClassId = 1,
    skillId = 80001013,
    cost = 1,
}
```

打出 Card 时，由 `ownerInstanceId` 对应的 Hero 作为施放者。

### 3.3 默认战斗参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| 起手抽牌 | `5 + 上场人数补正` | 3 人基线为 5；每多 1 名上场成员 +1，手牌上限仍为 10 |
| 每回合抽牌 | `5 + 上场人数补正` | 与起手抽牌一致，保证扩编后手牌选择密度 |
| 队伍能量 | `3 + 上场人数补正` | 3 人基线为 3；每多 1 名上场成员 +1，硬上限 6 |
| 手牌上限 | `10` | 超出时不再抽入手牌 |
| 回合末弃牌 | `true` | 未保留手牌进入弃牌堆 |
| 抽牌堆空 | 洗弃牌堆 | 弃牌堆洗入抽牌堆 |

### 3.4 战斗区

| 区域 | 定义 |
| --- | --- |
| `drawPile` | 抽牌堆 |
| `hand` | 当前手牌 |
| `discardPile` | 弃牌堆 |
| `exhaustPile` | 本场消耗区 |
| `powers` | 本场持续能力 |
| `guard` | 本轮防御值，主要对抗敌方 Intent 伤害 |
| `teamEnergy` | 队伍本回合剩余能量 |
| `baseEnergy` | 队伍每回合基础能量 |
| `maxEnergy` | 队伍当前能量上限 |
| `tempEnergy` | 本回合临时能量 |
| `chargeEnergy` | 可跨回合保留的蓄能 |

---

## 4. 回合流程

### 4.1 战斗开始

```text
BattleStart
→ 根据上场队伍 Feat 编译 Team Deck
→ 应用装备 / trinket / bless 对 Card 的修改
→ 洗牌
→ 抽起手牌
→ 敌方生成首轮 Intent
→ 进入玩家回合
```

### 4.2 玩家回合

```text
PlayerTurnStart
→ 清除上一轮残留 guard
→ teamEnergy 恢复到上限
→ 处理回合开始 Buff / Power
→ 抽牌
→ 玩家打牌
→ 玩家点击结束回合
```

### 4.3 打牌流程

```text
PlayCard
→ 校验 Card 是否可用
→ 校验 owner 是否存活
→ 校验 teamEnergy 是否足够
→ 选择目标
→ 扣除 teamEnergy
→ 调用 BattleSkill.StartSkillCastInSeq(owner, target, skillId)
→ SkillTimeline 播放并结算
→ Card 进入 discardPile / exhaustPile / powers
```

### 4.4 敌方回合

```text
EnemyTurnStart
→ 敌方按 Intent 顺序行动
→ 处理敌方 Skill / Timeline
→ 处理回合末 Buff / Power / guard / 临时生命
→ 检查胜负
→ 生成下一轮 Intent
→ 进入玩家回合
```

### 4.5 能量定位

能量是卡牌化战斗的主动作经济，替代旧自动回合制中的「角色轮流出手」和大部分 5e 动作 / 附赠动作 / 反应动作。

```text
队伍每回合获得能量
→ 打出 Card 消耗能量
→ 能量决定本回合能处理多少威胁
```

能量属于队伍，不属于角色。

```text
角色提供 Card
队伍支付能量
owner 执行 Skill
```

队伍能量按上场人数给动作经济补正。卡牌战斗的默认基线是 3 人小队 3 能量；Roguelike 章节扩编后，4 / 5 / 6 人队伍分别获得 4 / 5 / 6 基础能量。该规则保证整队抽牌时，每名上场角色平均至少有一次出牌窗口，同时仍通过 `energyHardCap = 6` 限制后期爆发。

抽牌数同样按上场人数补正。3 人小队每回合 5 抽；4 / 5 / 6 人队伍分别为 6 / 7 / 8 抽。该补正只提升手牌选择密度，不突破 `handLimit = 10`，避免扩编后新增角色卡、治疗牌、污染牌把核心行动挤出手牌。

### 4.6 默认能量参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `baseEnergy` | `3` | 每个玩家回合开始恢复到 3 |
| `maxEnergy` | `3` | 默认上限，Power / trinket 可提高 |
| `tempEnergy` | `0` | 本回合临时增加，回合末清空 |
| `chargeEnergy` | `0` | 少数 Card 可生成，可跨回合保留 |
| 单回合硬上限 | `6` | 防止无限能量链 |

玩家回合开始：

```text
teamEnergy = maxEnergy
teamEnergy += tempEnergyFromTurnStart
teamEnergy = min(teamEnergy, 6)
```

玩家回合结束：

```text
未使用 teamEnergy 清空
tempEnergy 清空
chargeEnergy 保留
```

### 4.7 Card 费用

Card 费用默认范围：

| 费用 | 用途 |
| --- | --- |
| `0` | 低收益、条件触发、过牌、已付出其他代价的 Card |
| `1` | 基础攻击、防御、治疗、常规功能 Card |
| `2` | 强攻击、群体防御、强治疗、关键控制 |
| `3` | 本回合核心行动、强 Power、终结技 |
| `X` | 消耗全部剩余能量，按消耗值缩放 |

设计约束：

- 0 费 Card 必须有低收益、使用限制、exhaust、条件限制或负面代价之一。
- 3 费 Card 应接近「本回合主计划」，不能只是 1 费 Card 的数值放大。
- X 费 Card 必须写清楚每点能量带来的收益。
- 同一张 Card 的费用变化最低降到 0，不允许负费用。

### 4.8 临时能量与返费

临时能量只在当前玩家回合有效。

常见来源：

```text
击杀返还 1 能量
打出某类 Card 后获得 1 临时能量
Power 每回合开始给 1 临时能量
trinket 首回合 +1 能量
```

返费规则：

- 返费进入 `teamEnergy`，本回合可继续使用。
- 返费后仍受单回合硬上限 `6` 限制。
- 击杀返费每张 Card 默认最多触发 1 次，除非 Card 明确写多次触发。
- 连击、弹射、AOE 多杀默认只触发 1 次击杀返费。

### 4.9 蓄能

蓄能是少数构筑使用的跨回合资源，不是默认能量循环。

```lua
chargeEnergy = {
    value = 1,
    max = 3,
    tags = { "rage", "arcane", "divine" },
}
```

设计原则：

- 默认职业不使用蓄能。
- 蓄能必须绑定明确路线，如野蛮人怒气、法师奥术充能、圣骑神圣能量。
- 蓄能不能直接等同于额外 teamEnergy，必须由指定 Card 消耗。
- 蓄能上限默认不超过 3。

### 4.10 大招与 LIMITED 映射

旧大招能量不再作为通用独立系统。

迁移规则：

| 旧机制 | 新机制 |
| --- | --- |
| 大招能量满释放 | 高费 Card / X 费 Card / Power Card |
| 每战限次技能 | `limitedUsesPerBattle` |
| 一次性强技能 | `exhaust = true` |
| 需要蓄力的技能 | `chargeEnergy` 或 `prepare` Card |
| CD 技能 | 费用、exhaust、shuffle delay 或 limited uses |

默认 MVP 不保留旧「受击 / 造成伤害获得大招能量」系统。需要表达怒气、神力、奥术充能时，使用职业专属蓄能。

### 4.11 费用调整

费用调整优先以 Card runtime modifier 表达。

```lua
costMods = {
    flat = -1,
    min = 0,
    until = "turn_end",
    source = "trinket_first_attack_discount",
}
```

叠加规则：

- 费用增加和减少按来源叠加。
- 最终费用最低为 0。
- `costLocked = true` 的 Card 不受费用调整影响。
- `X` 费 Card 不受普通 `cost -1` 影响，除非效果明确写影响 X 费。

### 4.12 能量与 5e 动作经济

旧 5e 动作经济映射为能量和 Card 标签：

| 5e 动作 | 卡牌化表达 |
| --- | --- |
| Action | 1-2 费 Card |
| Bonus Action | 0-1 费 Card，通常有条件 |
| Reaction | 登记型 Card 或敌方回合触发的 Power |
| Free Action | 0 费 Card 或纯 UI 目标选择 |

不保留每个角色每回合 1 Action 的规则。是否能让某个角色连续出多张 Card，由队伍手牌、teamEnergy 和该角色是否存活共同决定。

---

## 5. Card 定义

### 5.1 Card Schema

```lua
card = {
    cardId = 80001021,
    featId = 80001021,
    ownerScope = "hero",

    name = "护卫",
    desc = "给予一名友军临时生命，并登记本回合护卫。",
    type = "skill",
    cost = 1,
    costType = "fixed",
    costLocked = false,
    rarity = "starter",

    skillId = 80001013,
    targetType = "ally",
    tags = { "defense", "guard" },

    exhaust = false,
    retain = false,
    ethereal = false,
    limitedUsesPerBattle = nil,

    upgraded = false,
    upgradeLevel = 0,
}
```

### 5.2 Card 类型

| 类型 | 定义 | 进入位置 |
| --- | --- | --- |
| `attack` | 攻击、法术伤害、武器攻击 | 打出后进弃牌堆 |
| `skill` | 防御、治疗、控制、功能牌 | 打出后进弃牌堆 |
| `power` | 本场持续能力 | 打出后进 `powers` |
| `status` | 负面/伤口/诅咒类卡 | 通常不可主动打出 |

### 5.3 费用字段

| 字段 | 定义 |
| --- | --- |
| `cost` | 固定费用，`costType=fixed` 时使用 |
| `costType` | `fixed` / `x` / `free` |
| `costLocked` | 是否不受费用调整影响 |
| `limitedUsesPerBattle` | 每场可打出次数，空值表示不限 |

费用类型：

```text
fixed：按 cost 支付
x：消耗全部剩余 teamEnergy，按消耗值缩放
free：不消耗 teamEnergy，但通常需要其他代价
```

### 5.4 Card 标签

标签用于 Feat、装备、trinket 修改 Card。

常用标签：

```text
attack
defense
heal
guard
counter
bless
shelter
fire
frost
poison
mark
melee
ranged
spell
aoe
draw
energy
```

---

## 6. Feat 分类

### 6.1 Card Feat

Card Feat 直接生成一张或多张 Card，进入队伍牌库。

示例：

```text
圣火术
护卫
双连斩
猎人印记
```

### 6.2 Upgrade Feat

Upgrade Feat 强化已有 Card，不自己进入牌库。

示例：

```text
圣火熟练：圣火术伤害骰提升。
护卫熟练：护卫额外提供临时生命。
祝福精通：祝福术额外提供同排护甲减伤。
```

### 6.3 Replace Feat

Replace Feat 替换已有 Card。

示例：

```text
长剑攻击 → 横扫攻击
治愈真言 → 强效治愈真言
```

被替换 Card 从后续战斗牌库中移除。

### 6.4 Rule Feat

Rule Feat 提供常驻规则，不进入牌库。

示例：

```text
所有 attack 标签 Card 穿甲 +1。
每场首次濒死保留 1 HP。
祝福期间获得临时生命。
```

Rule Feat 仍然是 Feat，只是不生成 Card。

---

## 7. Feat Effects Schema

### 7.1 grant_card

```lua
effects = {
    { type = "grant_card", cardId = 80001021 }
}
```

授予一张 Card。默认绑定 Feat 所属 Hero 为 owner。

### 7.2 modify_card

```lua
effects = {
    {
        type = "modify_card",
        cardId = 80001021,
        add = {
        guard = 4,
            counterOnGuard = true,
        }
    }
}
```

修改指定 Card。多个 modify 可以叠加。

### 7.3 replace_card

```lua
effects = {
    {
        type = "replace_card",
        oldCardId = 80001001,
        newCardId = 80001031,
    }
}
```

替换指定 Card。替换后旧 Card 不再进入牌库。

### 7.4 modify_card_by_tag

```lua
effects = {
    {
        type = "modify_card_by_tag",
        tag = "attack",
        add = { armorPierce = 1 }
    }
}
```

修改 owner 牌库中带指定标签的 Card。

### 7.5 旧语义映射

```text
grant_skill   → grant_card(skillId 对应 Card)
modify_skill  → modify_card(cardId / skillId 对应 Card)
replace_skill → replace_card(oldCardId, newCardId)
```

实现上可以短期保留旧字段，但设计语义以 Card 为准。

---

## 8. owner 阵亡与复活

### 8.1 阵亡

owner 阵亡后：

- 手牌中的该 owner Card 变为失效状态。
- 失效 Card 不能打出，仍占据当前手牌。
- 回合结束时，手牌、抽牌堆、弃牌堆中该 owner 的 Card 移出本场战斗。
- `power` 中来自该 owner 的持续效果按具体规则保留或移除；默认移除。

这让角色阵亡直接损坏牌库质量。

### 8.2 复活

owner 复活后：

- 该角色本场被移出的 Card 重新进入弃牌堆。
- 下一次洗牌后重新进入循环。
- 复活不会直接把该角色 Card 加入当前手牌。

---

## 9. 敌方 Intent

### 9.1 定义

敌方不进入牌库系统。敌方每回合生成公开 Intent。

```lua
intent = {
    enemyInstanceId = 2001,
    type = "attack",
    skillId = 90001001,
    targetId = 10001,
    preview = {
        damage = 8,
        armorReduction = 2,
    }
}
```

### 9.2 Intent 类型

| 类型 | 定义 |
| --- | --- |
| `attack` | 攻击目标 |
| `defend` | 获得临时生命、减伤或护甲减伤 |
| `buff` | 强化自己或友军 |
| `debuff` | 施加负面状态 |
| `control` | 控制、打断、沉默、冻结 |
| `summon` | 增援或召唤 |
| `charge` | 蓄力，下回合强行动 |

### 9.3 Intent 展示原则

Intent 必须让玩家知道本回合主要压力：

```text
谁会行动
行动类型
大致目标
大致伤害或状态
是否蓄力
```

不要求展示完整骰子展开，但必须展示战术上可判断的信息。

---

## 10. 5e 卡牌化改造规则

### 10.1 总原则

5e 在本方案中是术语、职业画像和骰子素材来源，不是完整桌面规则实现。

卡牌战斗要求玩家能根据手牌与 Intent 做稳定判断，因此以下机制必须确定性化：

```text
通用命中检定
通用豁免成败
先攻轮流行动
优势 / 劣势
专注检定
死亡豁免
长休 / 短休动作经济
```

Card 不自创伤害公式。伤害骰、治疗骰、临时生命、减伤、状态结算仍由 Skill 与现有战斗 helper 承担，但随机闸门默认关闭。

### 10.2 默认攻击

默认 attack Card 不做 d20 命中检定。目标合法即命中并结算伤害。

```text
默认攻击伤害 = damage dice + 现有加成 - 护甲减伤
```

只有明确写 `accuracyCheck = true` 的 Card 才使用旧命中检定。

适合保留命中检定的场景：

```text
高倍率赌博牌
Boss 机制牌
带强控制的高风险牌
特定 Feat 明确围绕命中检定构筑
```

基础攻击、常规攻击牌、常规技能牌不做随机 miss。

### 10.3 AC 与护甲减伤

AC 在卡牌化战斗中保留为角色防护画像字段，但战斗内主要作用是换算为护甲减伤。

默认换算：

```text
armorReduction = max(0, floor((AC - 10) / 2))
```

示例：

| AC | 护甲减伤 |
| --- | --- |
| 10-11 | 0 |
| 12-13 | 1 |
| 14-15 | 2 |
| 16-17 | 3 |
| 18-19 | 4 |

护甲减伤规则：

- 默认只减免武器攻击、物理攻击和 `attack` 类型 Card 的直接伤害。
- 法术类 Card 默认不受护甲减伤影响，除非 Card 明确写 `affectedByArmor = true`。
- 伤害减到 0 以下时，若原始伤害大于 0，最低造成 1 点伤害，除非目标有免疫。
- `armorPierce` 先抵消护甲减伤，再结算伤害。
- `ignoreArmor = true` 的 Card 跳过护甲减伤。

旧 `AC +N` 效果在新口径下仍可保留，但其实际收益来自护甲换算。设计新 Feat 时优先直接写「护甲减伤 +N」或「本回合护甲减伤 +N」，避免玩家误解为提高闪避率。

### 10.4 豁免与抗性

默认法术和状态 Card 不做 d20 豁免成败。旧 `con / dex / wis` 豁免改为三类抗性：

| 旧字段 | 新语义 | 主要对抗 |
| --- | --- | --- |
| `saveCon` | 体质抗性 | 中毒、流血、疾病、强制位移、专注类干扰 |
| `saveDex` | 敏捷抗性 | 火焰、爆炸、范围伤害、陷阱 |
| `saveWis` | 感知抗性 | 盲目、恐惧、魅惑、精神干扰 |

默认换算：

```text
resistance = max(0, floor(saveBonus / 2))
```

Card 可配置：

```lua
saveType = "con" | "dex" | "wis"
resistPierce = 0
ignoreResistance = false
```

结算规则：

- 伤害类法术：按对应抗性减少伤害，最低 1 点。
- DoT 类状态：按对应抗性减少当次跳伤，最低 1 点。
- 软控制：按对应抗性减少持续或层数，最低 1 回合 / 1 层。
- 硬控制：不默认使用抗性随机抵消，必须设计为明确 Card 机制。

只有明确写 `saveCheck = true` 的 Card 才使用旧 `d20 + saveBonus vs spell DC`。

适合保留豁免检定的场景：

```text
Boss 大招
一次性硬控
高收益诅咒
事件 / 地牢检定
```

### 10.5 Spell DC 与 spell power

`spell DC` 不再默认作为 d20 豁免目标值，而是转为法术强度画像。

默认换算：

```text
spellPower = max(0, floor((spellDC - 10) / 2))
```

spellPower 用于：

- 增加法术 Card 的基础伤害或治疗。
- 抵消目标抗性。
- 提高状态层数或持续。
- 作为 `saveCheck = true` Card 的 DC 来源。

设计新 Card 时优先显式写数值收益，不把 spellPower 暗藏为复杂公式。

### 10.6 熟练加值与能力值

熟练加值和能力值仍用于角色画像与卡牌缩放，但不再驱动每次行动的通用 d20 检定。

保留用途：

```text
HP 派生
护甲画像
武器伤害加值
法术强度画像
抗性画像
Card 升级或 Feat 前置
```

不再作为默认用途：

```text
每次 attack Card 命中
每次 spell Card 豁免
先攻轮流行动
```

### 10.7 先攻与行动顺序

旧 5e 先攻不再决定战斗主循环。

新顺序固定为：

```text
玩家回合
→ 敌方 Intent 行动
→ 下一玩家回合
```

敌方内部执行顺序由 Intent 生成时确定。默认排序：

```text
前排威胁
→ 后排威胁
→ 精英 / Boss
→ instanceId
```

若需要体现敏捷或先攻，改为 Card / Feat 效果：

```text
起手多抽 1 张
第一回合能量 +1
某张 Card retain
战斗开始获得临时生命
敌方首轮 Intent 伤害 -N
```

### 10.8 优势与劣势

旧 d20 优势 / 劣势不作为通用机制。

迁移规则：

| 旧机制 | 新机制 |
| --- | --- |
| 优势 | 抽 1、下张 Card 费用 -1、伤害 +N、穿甲 +N、升级本回合一张 Card |
| 劣势 | 弃 1、下张 attack 伤害 -N、无法打出指定标签 Card、抽牌减少 |

若 Card 使用 `accuracyCheck = true` 或 `saveCheck = true`，可以保留旧优势 / 劣势掷骰，但只限该 Card。

### 10.9 暴击

默认 attack Card 不掷 d20 命中，因此默认不再通过 `nat20` 触发暴击。

暴击改为 Card / Feat 规则：

```text
critRange：指定 Card 的暴击范围或暴击条件
critOnVulnerable：目标处于指定状态时暴击
critBonusDice：暴击时追加骰
```

若 Card 明确使用 `accuracyCheck = true`，则可继续使用旧 d20 命中与 `nat20` 暴击规则。

旧 `hit bonus +N` 效果不再作为通用收益使用。迁移时按语义转换为：

| 旧效果 | 新效果 |
| --- | --- |
| 命中 +N | 伤害 +N、穿甲 +N、或特定 Card 的 accuracyCheck +N |
| 敌方 AC -N | 敌方护甲减伤 -N 或受到 attack Card 伤害 +N |
| 盲目命中 -N | attack Card 伤害 -N、弃牌、或无法使用 accuracyCheck Card |

### 10.10 专注

旧 5e 专注检定不保留为通用规则。

专注类能力改为 `focus` Power：

```lua
cardType = "power"
focus = true
focusSlot = "cleric_bless"
```

规则：

- 每个 owner 默认只能维持 1 个 focus Power。
- 打出新的 focus Power 会替换旧 focus Power。
- focus Power 可被明确写有 `dispelFocus`、`interruptFocus` 的敌方 Intent 或 Card 移除。
- 受到伤害不触发随机专注检定。

这样保留「持续能力会被处理」的战术点，但不把每次受伤都变成隐藏随机。

### 10.11 死亡豁免与濒死

旧 5e 死亡豁免不进入战斗内循环。

默认规则：

```text
HP <= 0 → owner 阵亡
owner Card 失效
战斗胜利后按 Run 规则处理死亡 / 复活 / 整备
```

濒死保护只能来自明确 Card / Feat / trinket：

```text
每场首次降至 0 HP 时保留 1 HP
复活一名阵亡队友
战斗结束后复活
```

### 10.12 长休与短休

长休 / 短休不作为战斗内 5e 机制。

对应关系：

| 5e 机制 | 项目机制 |
| --- | --- |
| 短休恢复 | 营地、事件、战后固定恢复 |
| 长休恢复 | 章节整备、Boss 前整备 |
| 法术位恢复 | Card 重新洗牌、exhaust、limited 次数 |
| 每休恢复能力 | 每战次数、每章次数、trinket 触发 |

### 10.13 防御表达

使用 5e 风格术语，但按卡牌规则落地：

- `guard / 防御值`：本轮吸收层，主要来自防御 Card。
- `临时生命`：吸收层。
- `减伤`：直接减少受到伤害。
- `护甲减伤 +N`：稳定减少物理类伤害。
- `穿甲 +N`：抵消目标护甲减伤。
- `抗性 +N`：减少对应法术 / 状态效果。

不使用「护罩」作为新术语。

### 10.14 guard / 本轮防御

`guard` 是卡牌化战斗中的主要防御资源，对标杀戮尖塔的 Block。

默认规则：

- guard 吸收本轮即将受到的伤害。
- 玩家侧 guard 在玩家回合通过 Card 获得，用于抵挡随后敌方 Intent。
- 敌方 guard 来自 `defend` Intent 或敌方 Skill。
- guard 不跨完整轮次保留；默认在下一次该阵营回合开始时清除。
- guard 可被 Card 明确保留、转化或消耗。

伤害层级：

```text
原始伤害
→ 护甲减伤 / 抗性 / 减伤
→ guard
→ 临时生命
→ HP
```

设计原则：

- 常规防御 Card 优先给 guard。
- 临时生命用于稀有防护、牧师援助、trinket 或跨回合保护。
- 不允许大量低费 Card 同时给高额 guard 和高额输出。

### 10.15 临时生命

临时生命是持久吸收层，不是常规防御主资源。

默认规则：

- 临时生命不叠加，取较高值，除非 Card 明确写叠加。
- 玩家回合结束不清除。
- 战斗结束清除。

临时生命设计约束：

- 低费常规防御 Card 不应大量提供临时生命。
- 临时生命适合表达援助、庇护、圣术、trinket 或战斗奖励。
- 临时生命与 guard 同时存在时，guard 先消耗。

---

## 11. 职业样板

### 11.1 战士

路线：

```text
攻击线：高效攻击、击杀返费、横扫
护卫线：防御、替队友承伤、登记反击
连击线：多段攻击、抽牌、费用返还
回气线：自疗、清负面、濒危保命
```

基础 Card：

| Card | 类型 | 费用 | 规则 |
| --- | --- | --- | --- |
| 长剑攻击 | attack | 1 | 基础武器攻击 |
| 防御姿态 | skill | 1 | 自身获得临时生命 |
| 护卫 | skill | 1 | 指定友军获得保护，登记本回合护卫 |
| 回气 | skill | 0 | 限每战 1 次，自疗 |

设计原则：

- 战士攻击类 Card 优先复用基础武器攻击链。
- 护卫必须提供防护收益，不能只做反击。
- 反击优先采用登记语义，等待敌方动作结束后结算。

### 11.2 牧师

路线：

```text
圣火线：法术伤害、追加骰、驱散联动
治疗线：治疗、复苏、低血加成
祝福线：Power Card，穿甲/抗性/护甲减伤增益
庇护线：临时生命、减伤、净化
```

基础 Card：

| Card | 类型 | 费用 | 规则 |
| --- | --- | --- | --- |
| 圣火术 | attack | 1 | 法术伤害，按目标抗性减免 |
| 治愈真言 | skill | 1 | 治疗一名友军 |
| 祝福术 | power | 1 | 本场或数回合提高穿甲、抗性或护甲减伤 |
| 庇护 | skill | 1 | 临时生命或减伤 |

设计原则：

- 牧师不承担圣骑式常驻光环定位。
- 牧师主轴是庇护、治疗、驱散和战斗内稳场。
- 祝福与援助应明确区分：祝福偏穿甲 / 抗性 / 护甲减伤，援助偏临时生命。

---

## 12. Roguelike 奖励

### 12.1 升级三选一

升级奖励从「选择 Feat 节点」改为「选择 Feat 对牌库的影响」。

可选项：

```text
获得一张 Card Feat
升级一张已有 Card
替换一张 Card
删除一张基础 Card
获得一条 Rule Feat
```

### 12.2 招募

招募新 Hero 时：

- 新 Hero 加入上场或候补。
- 若上场，则其 starter Cards 加入队伍牌库。
- 新角色提供新能力，但稀释关键 Card 抽取概率。

招募不再是纯收益，而是牌库质量与阵容能力的取舍。

### 12.3 装备与 trinket

装备与 trinket 优先通过 Card 修改表达：

```text
指定标签 Card +1 damage dice
第一张 attack Card 费用 -1
每场首次 heal Card 额外治疗
抽到 guard 标签 Card 时获得临时生命
```

装备不直接改变牌库数量，除非明确为特殊装备。

---

## 13. 杀戮尖塔对照与补缺

### 13.1 已采纳的核心

| 杀戮尖塔机制 | 本方案对应 |
| --- | --- |
| 抽牌堆 / 手牌 / 弃牌堆 | `drawPile` / `hand` / `discardPile` |
| 消耗 | `exhaustPile` / `exhaust = true` |
| 每回合能量 | `teamEnergy` |
| 敌方意图 | `Intent` |
| Block | `guard` |
| Power | `power` Card / `powers` |
| 遗物 | `trinket` |
| 卡牌升级 | `Upgrade Feat` / `modify_card` |
| 删牌 | Roguelike 奖励 / 商店 / 事件 |

### 13.2 刻意改造的部分

| 杀戮尖塔 | 本方案 |
| --- | --- |
| 单角色牌库 | 小队共享牌库 |
| 卡牌无 owner | Card 绑定 owner，owner 阵亡会污染手牌 |
| Block 全部来自卡牌 | guard 来自 Card，护甲减伤来自角色画像 |
| 固定职业套牌 | 上场 Hero 的 Feat Card 合并 |
| 遗物主导被动构筑 | Feat / trinket 共同承担构筑 |
| 随机命中极少 | 默认取消通用命中 / 豁免随机闸门 |

### 13.3 Starter Deck

每个上场 Hero 必须提供 starter card package。

MVP 默认：

```text
每名 Hero 贡献 4 张 starter Card 实例
2 张基础攻击
1 张基础防御
1 张职业功能牌
```

4 人起手队伍默认牌库大小：

```text
4 Hero × 4 Card = 16 Card 实例
```

starter Card 不是永久废卡，但应明显弱于升级后的职业 Card。其作用是：

- 保证任何队伍都有基础攻防。
- 提供删牌、替换、升级的长期构筑目标。
- 让招募新角色有「能力增加 + 牌库稀释」的真实代价。

### 13.4 Card 实例与重复牌

队伍牌库保存 Card 实例，不只保存 Card 定义。

```lua
cardInstance = {
    uid = "run_card_001",
    cardId = 80001001,
    ownerInstanceId = 10001,
    upgraded = false,
}
```

同一 `cardId` 可以存在多个实例。升级、删除、复制默认作用于实例，不作用于所有同名 Card，除非效果明确写 `allCopies = true`。

当前实现落点：

- Run 状态保存 `cardLibrary.cards`，作为跨战斗的永久队伍牌库。
- `cardLibrary` 的初始内容仍由上场 Hero 的 Lv1 Feat / 已选 Feat 投影生成，保证 Feat 仍是成长来源。
- 每张 `Card` 持有稳定 `uid` 与 `sourceKey = ownerRosterId:featId:skillId`。升级、删除默认作用于 `uid` 对应实例。
- 当玩家后续获得新 Feat 时，只补齐新出现的 `sourceKey`，不重建已有实例，避免覆盖已升级或已删除的牌。
- 删除仅把实例标记为 `removed = true`，战斗构筑时过滤；这样后续调试和快照仍能追踪来源。

### 13.5 奖励跳过

升级或战斗奖励中的 Card 选择必须允许跳过。

```text
三选一 Card / Feat
→ 可以选择一项
→ 也可以跳过
```

原因：

- 防止牌库被迫膨胀。
- 让「不拿弱牌」成为有效决策。
- 支持小而精牌库构筑。

跳过默认不给补偿。若后续需要，可由 trinket 或事件提供「跳过得金币」等特殊规则。

### 13.6 升级规则

默认每张 Card 实例最多升级 1 次。

```text
未升级：base
已升级：upgraded
```

多段升级只允许由明确 Feat 路线开放：

```lua
maxUpgradeLevel = 1 -- 默认
maxUpgradeLevel = 2 -- 特定路线 / trinket
```

升级必须改变 Card 决策价值，不能只做无感小数值：

- 降费。
- 增加 guard / 伤害 / 治疗。
- 增加抽牌 / 返费。
- 增加 retain / exhaust / ethereal。
- 改变目标、范围或触发时机。

### 13.7 删牌规则

删牌是核心构筑手段，必须有稳定来源，但不能过于廉价。

来源：

```text
商店付费删牌
事件删牌
营地特殊选项
少数高级 Feat / trinket
```

限制：

- 默认不能删除最后一张属于某个存活 owner 的可打出 Card。
- 默认不能删除 status / curse，除非来源明确允许。
- owner 阵亡后移出的 Card 不等于删牌，复活后仍会回流。

### 13.8 Status 与 Curse

需要保留杀戮尖塔式的牌库污染机制。

| 类型 | 定义 | 来源 |
| --- | --- | --- |
| `status` | 战斗内临时污染，通常本场结束清除 | 敌方 Intent、伤害、事件 |
| `curse` | Run 级污染，跨战斗保留 | 高风险事件、强力 trinket 代价 |

示例：

```text
Wound：不可打出，占手牌。
Dazed：回合结束自动 exhaust。
Burn：回合结束造成伤害后进入弃牌堆。
Weakness：打出后本回合 attack 伤害 -N。
```

status / curse 默认不绑定 Hero owner，使用 `ownerScope = "team"`。

当前实现落点：

- `status` 先落 MVP 伤口牌：敌方 Intent 对我方造成实际伤害后，向当前战斗弃牌堆加入 1 张 `Wound / 伤口`。
- `status` 是战斗内临时污染，只进入 `cardBattle.drawPile / hand / discardPile / exhaustPile`，不写入 Run 级 `cardLibrary`。
- `Wound` 默认不可打出，占手牌；回合结束按普通手牌进入弃牌堆。
- `curse` 落 Run 级污染 MVP：写入永久 `cardLibrary`，跨战斗进入牌堆；默认不可打出，占手牌。
- `curse` 当前来源先接“贪婪复制”卡牌奖励：复制 1 张已有 Card，同时加入 1 张 `Doubt / 疑惧`。

### 13.8.1 战后卡牌奖励 MVP

普通战胜利后，如果没有更高优先级的升级/精英装备奖励，会进入 `card_reward`：

```text
获得 1 张新 Card：从显式 Card pool 配置中按当前 active 队伍过滤生成
贪婪复制：复制 1 张已有可打出 Card + 加入 1 张 Curse
跳过
```

新 Card 来源使用 `config/roguelike/run_card_reward_pool.lua` 的显式白名单，不扫描全量技能表。池条目必须引用现有 active Skill，并通过 `ownerPolicy = "class"` 绑定到当前 active 队伍中对应 `classId` 的英雄；若队伍没有可用 owner，该条目不进入候选。生成结果写入 Run 级 `cardLibrary`，但仍以 `Card -> Skill -> Timeline` 结算，不新增独立结算链路。

内容池规模不能只满足功能验证。Act1 MVP 至少覆盖所有职业的基础行动牌和主要主动 / 限次技能，形成约 30 张的显式 Card pool；稀有度只控制奖励权重与展示，不改变底层 Skill 结算。后续扩展优先补每职业 2-3 张“战术变体卡”，再考虑新增 Skill runtime。

### 13.8.2 Card 效果变体 V1

只把 Skill 包成 Card 不够。卡牌层必须提供独立决策价值，否则玩家只是把旧技能按钮换成卡面。V1 先引入低风险的卡牌层效果：

| 字段 | 规则 | 设计用途 |
| --- | --- | --- |
| `drawCards` | 打出并成功结算后抽 N 张牌，不超过 `handLimit` | 形成过牌、找核心牌、处理污染的决策 |
| `energyGain` | 打出并成功结算后回复 N 点队伍能量，受 `energyHardCap` 限制 | 形成 0 费 / 返费 / 连段节奏 |
| `guardValue` | 在 Skill 结算外额外获得队伍 Guard | 让防御牌不只依赖旧 Skill 语义 |
| `retain` | 回合结束保留在手牌 | 让治疗、控制、爆发牌可以等窗口 |
| `exhaust` | 打出后本场消耗 | 支撑强力一次性牌和爆发牌 |

这些效果都属于 Card 层，不新增独立伤害链。打出流程为：

```text
校验目标与费用
→ 调用原 Skill / Timeline
→ 扣除能量
→ 结算 Card 层 Guard / 回能 / 抽牌
→ 按 exhaust / power / discard 归档
```

奖励池卡必须优先做“战术变体”，而不是只改名字。例如同一个基础攻击可以做成 `抽 1` 的循环牌，爆发牌可以 `exhaust`，治疗/控制牌可以 `retain`，高节奏职业可提供 `energyGain`。这一步先不做 `vulnerable / weak / poison` 等新 Debuff，避免把范围扩大到 Buff 系统。

### 13.9 Retain / Ethereal / Exhaust

关键卡牌关键词必须定义清楚：

| 关键词 | 规则 |
| --- | --- |
| `retain` | 回合结束不弃置，留在手牌 |
| `ethereal` | 回合结束仍在手牌则 exhaust |
| `exhaust` | 打出后进入消耗区，本场不再洗回 |

默认限制：

- retain Card 仍占手牌上限。
- ethereal 与 retain 同时存在时，retain 优先；除非 Card 明确写 `etherealIgnoresRetain = true`。
- exhaust Card 不进入弃牌堆。

### 13.10 营地与商店

营地不只恢复，应承担牌库维护。

营地默认选项：

```text
恢复 HP
升级 1 张 Card
删除 1 张 starter Card（稀有或付代价）
净化 1 张 curse（稀有）
```

商店默认售卖：

```text
Card / Feat 奖励
trinket
消耗品
删牌服务
治疗或复活服务
```

当前实现落点：

- 商店 `净化仪式` 服务会净化 1 张未移除的 `curse`。
- 营地新增 `净化` 动作，会净化 1 张未移除的 `curse`；没有 curse 时该动作不可用。
- 净化采用 `removed = true` 标记，保留永久牌库历史，不再进入后续战斗牌堆。

### 13.11 消耗品

杀戮尖塔的药水机制可作为后续扩展。

MVP 不做完整药水栏，但保留设计入口：

```text
consumable = 一次性战斗道具
不进牌库
不消耗 teamEnergy
每场使用后移除
```

适合表达：

- 立即治疗。
- 获得临时 guard。
- 抽牌。
- 本回合能量 +1。
- 清除 status / curse。

### 13.12 当前缺口结论

对照杀戮尖塔后，必须补齐的核心项：

```text
guard 作为本轮防御
starter deck 数量与重复牌规则
奖励允许跳过
升级上限
稳定删牌来源
status / curse 污染牌库
retain / ethereal / exhaust 明确定义
营地 / 商店承担牌库维护
```

不进入 MVP 的项：

```text
完整药水栏
Ascension 类难度阶梯
复杂卡牌预览 / 拖拽
全职业完整卡池
```

---

## 14. Web 表现需求

### 14.1 战斗 HUD

战斗界面必须展示：

- 当前 `teamEnergy`。
- 当前 `guard`。
- 手牌 Card。
- 抽牌堆数量。
- 弃牌堆数量。
- 消耗区数量。
- 敌方 Intent。
- 结束回合按钮。

### 14.2 Card 展示字段

Card 至少展示：

```text
费用
名称
owner 头像或职业标识
类型
核心效果
目标类型
标签图标（可选）
关键词：retain / ethereal / exhaust
```

owner 阵亡时，Card 灰置并显示「失效」。

### 14.3 交互流程

```text
点击 Card
→ 高亮合法目标
→ 点击目标
→ 播放 SkillTimeline
→ 更新手牌、能量、单位状态
```

不需要在 MVP 做复杂拖拽。点击式交互足够。

---

## 15. MVP 范围

第一阶段只实现最小闭环：

```text
战士 + 牧师
队伍牌库
抽牌 / 弃牌 / 消耗
guard 本轮防御
teamEnergy
敌方 Intent
打牌调用现有 Skill / Timeline
Roguelike 升级三选一改为 Card/Feat 奖励
```

第一阶段不做：

```text
全职业一次性重构
敌人卡牌化
每角色独立抽牌
即时并行
复杂遗物
完整拖拽交互
完整卡牌动画特效
```

---

## 16. 配置与运行时落点

### 16.1 配置文件

需要新增或调整：

```text
config/data/cards.json
config/tables/cards.lua
config/data/feats.json
config/tables/feats.lua
config/data/skills.json
config/tables/skill_meta.lua
```

### 16.2 运行时模块

建议新增：

```text
modules/battle_card.lua
modules/battle_deck.lua
modules/battle_intent.lua
modules/card_runtime.lua
```

建议调整：

```text
modules/battle_main.lua
modules/hero_build.lua
modules/battle_skill.lua
roguelike/feat_picker.lua
roguelike/roguelike_reward.lua
runtime/browser_battle_runtime.lua
```

### 16.3 Web 模块

需要调整：

```text
web/app/types/battle.ts
web/app/state/battleStore.ts
web/app/render/BattleScene.ts
web/app/ui/domControls.ts
web/app/lua/LuaBattleHost.ts
```

---

## 17. 验收口径

### 17.1 Lua 回归

MVP 至少需要：

```text
卡牌编译测试
抽牌 / 洗牌 / 弃牌测试
starter deck 编译测试
奖励跳过测试
升级上限测试
删牌限制测试
status / curse 洗牌测试
retain / ethereal / exhaust 关键词测试
guard 吸收与清除测试
费用校验测试
费用调整叠加测试
X 费 Card 结算测试
临时能量回合末清空测试
蓄能跨回合保留测试
limitedUsesPerBattle 测试
owner 阵亡失效测试
owner 复活回流测试
打牌调用 Skill 测试
敌方 Intent 生成与执行测试
战士卡牌样板测试
牧师卡牌样板测试
```

### 17.2 Web 验收

需要验证：

```text
手牌正常展示
guard 正常展示与清除
费用扣除正确
X 费与费用调整展示正确
临时能量 / 蓄能展示正确
目标选择正确
敌方 Intent 可见
结束回合进入敌方行动
owner 阵亡 Card 灰置
战斗结算后 Roguelike 奖励正常进入升级选择
```

### 17.3 平衡验收

战斗输入模式变化后，Act 1 / Act 2 平衡必须重新验证。

真战平衡测试需要按新「脚本打牌策略」重写，不再沿用旧自动战斗 AI 结论。

---

## 18. 风险与约束

### 18.1 主要风险

- Feat 从 skill 导向转为 card 导向，配置迁移量大。
- Web 战斗输入区需要重做。
- 旧自动战斗测试会大面积失效。
- 招募扩编会稀释牌库，Act 2 / Act 3 难度需要重估。
- 若缺少删牌 / 跳过奖励，牌库会被迫膨胀，构筑体验会崩。
- 若 guard 数值过高，会把敌方 Intent 压力抹平。
- Rule Feat 容易变成隐藏数值堆叠，需要严格控制数量。

### 18.2 设计约束

- Feat 仍是唯一成长入口。
- Card 不直接写伤害公式。
- Skill 仍是唯一能力结算单元。
- 不新增独立 Ability 层。
- 5e 术语优先，不发明新防御口语。
- 第一阶段只做战士和牧师，不全职业铺开。

---

## 19. 一页结论

```text
Feat 是构筑单位
Card 是 Feat 的战斗投影
Skill 是 Card 的结算实现
Timeline 是 Skill 的表现

整队共享牌库
整队共享能量
默认每回合 3 能量，单回合硬上限 6
guard 是本轮防御主资源
玩家每回合抽 5 打牌
敌人公开 Intent 后行动

角色提供 Card
Feat 修改 Card
Roguelike 奖励改造牌库
奖励可以跳过，牌库可以删除和升级
status / curse 可以污染牌库
角色死亡会污染并削弱队伍牌库
```

设计名：

```text
Feat Card Battle
Feat 卡牌化小队回合制
```
