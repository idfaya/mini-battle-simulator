# 技能系统实现文档 (Timeline 版)

> **项目**: Mini Battle Simulator  
> **版本**: 2.0 (Timeline 架构)  
> **更新时间**: 2026-05-24  
> **说明**: 技能 Timeline 执行、5e 伤害结算与配置三层结构的程序 SSOT

---

## 目录

1. [系统概述](#1-系统概述)
2. [Timeline 执行体系](#2-timeline-执行体系)
3. [技能配置三层架构](#3-技能配置三层架构)
4. [技能 ID 编码规则](#4-技能-id-编码规则)
5. [技能释放完整流程](#5-技能释放完整流程)
6. [技能脚本开发规范](#6-技能脚本开发规范)
7. [Buff 系统实现](#7-buff-系统实现)
8. [敌人技能体系](#8-敌人技能体系)
9. [视觉事件系统](#9-视觉事件系统)
10. [核心 API 清单](#10-核心-api-清单)

---

## 1. 系统概述

技能以 **Timeline** 为唯一执行路径：每个主动技能脚本实现 `BuildTimeline`，返回按 `frame` 排序的帧序列；`SkillTimeline.Execute` 逐帧执行，伤害/治疗/Buff 在帧内结算，表现通过 `BattleVisualEvents` 订阅。

| 能力 | 实现要点 |
|------|----------|
| 时序 | `frame` 逻辑帧序号（升序） |
| 伤害/豁免 | `BattleSkill.ResolveScaledDamage` + `config.tables.skill_meta`（`attackMode`、`damageDice`、`saveType` 等） |
| 编译型 Timeline | `skills/skill_timeline_compiler.lua` 的 `Build` + `skills/skill_effect_registry.lua` 标签 |
| Buff | `BattleSkill.ApplyBuffFromSkill` + `config/data/buffs.json` |
| 被动 | `config/data/passives.json` → `battle_passive_skill` / `passive_handlers`（不走 Timeline） |

### 1.1 核心模块

| 模块 | 文件路径 | 职责 |
|------|----------|------|
| SkillTimeline | `core/skill_timeline.lua` | Timeline 执行引擎，排序帧序列、逐帧执行、派发事件 |
| BattleSkill | `modules/battle_skill.lua` | 技能系统主入口，管理技能实例、冷却、释放流程 |
| BattleVisualEvents | `ui/battle_visual_events.lua` | 视觉事件定义与数据构建器 |
| BattlePassiveSkill | `modules/battle_passive_skill.lua` | 被动技能注册、触发分发与运行时状态查询 |
| PassiveDefs | `config/tables/passives.lua` | 被动触发定义加载器，从 `config/data/passives.json` 读取触发表 |
| PassiveHandlers | `modules/passive_handlers.lua` | 被动处理器工厂，承载脚本型被动逻辑 |
| SkillTimelineCompiler | `skills/skill_timeline_compiler.lua` | 声明式帧定义 → 可执行 Timeline；帧内调用 `ResolveScaledDamage` |
| SkillEffectRegistry | `skills/skill_effect_registry.lua` | Timeline 帧 `tags` 的 pre/post 扩展 |
| SkillConfig | `config/skill_config.lua` | 技能配置薄封装，转发到 `config/tables/skills.lua` |
| BattleHeroFactory | `modules/battle_hero_factory.lua` | 英雄/敌人工厂，含技能类型转换 |
| HeroData | `config/hero_data.lua` | 英雄属性与技能配置 |
| EnemyData | `config/enemy_data.lua` | 敌人属性与技能配置 |

---

## 2. Timeline 执行体系

### 2.1 核心概念

Timeline 体系将技能执行抽象为**逻辑帧序列**，每帧包含：
- `frame`: 帧序号（整数，按升序执行）
- `op`: 操作类型（cast/hit/damage/heal/buff/effect）
- `execute`: 帧执行函数，接收 `context` 和 `frameCopy` 两个参数

### 2.2 SkillTimeline.Execute 流程

```lua
function SkillTimeline.Execute(hero, targets, skill, timeline)
    -- 1. 克隆帧序列（避免污染原始定义）
    -- 2. 按 frame 升序排序
    -- 3. 派发 SKILL_TIMELINE_STARTED 事件
    -- 4. 逐帧执行 frame.execute(context, frameCopy)
    --    - pcall 保护执行
    --    - 累计 totalDamage / totalHeal
    --    - 派发 SKILL_TIMELINE_FRAME 事件
    -- 5. 派发 SKILL_TIMELINE_COMPLETED 事件
    -- 6. 返回 succeeded, result
end
```

### 2.3 帧事件类型

| op | 说明 | 典型操作 |
|----|------|----------|
| cast | 技能释放 | 派发 SKILL_CAST_STARTED，设置动画状态 |
| hit | 命中判定 | 5e d20+命中 vs AC（由编译器或脚本触发） |
| damage / chain_damage | 伤害结算 | `ResolveScaledDamage` → `BattleDmgHeal.ApplyDamage` |
| heal | 治疗结算 | `CalculateHealDice` → `ApplyHeal` |
| buff | Buff 施加 | `ApplyBuffFromSkill` 或 `skill_effect_registry` 标签 |
| effect | 特效触发 | 纯表现层事件，逻辑层无操作 |

### 2.4 Context 结构

```lua
context = {
    hero = hero,           -- 施法者
    targets = targets,     -- 目标列表
    skill = skill,         -- 技能实例
    timeline = frames,     -- 排序后的帧序列
    totalDamage = 0,       -- 累计伤害
    totalHeal = 0,         -- 累计治疗
}
```

---

## 3. 技能配置三层架构

每个技能由三层共同定义，修改任一层时需同步其余层：

### 3.1 JSON 静态配置 (`config/data/skills.json`)

权威字段示例（完整表以 JSON 为准）：

```json
{
  "id": 80003011,
  "symbol": "monk_basic_attack",
  "skillType": 1,
  "cooldown": 0,
  "luaFile": "config.skill.skill_80003011",
  "rules": {
    "damageDice": "",
    "kind": "physical",
    "attackMode": "physical_attack"
  }
}
```

| 字段 | 说明 |
|------|------|
| `id` | 8 位技能 ID，对应 `config/skill/skill_{id}.lua` |
| `classGroupId` | 流派组（如 `8000300`），用于归类与推导 `classId` |
| `skillType` | 1 普攻 / 2 主动 / 3 大招 / 4 被动 |
| `rules` | 策划向规则：`damageDice`、`healDice`、`attackMode`、`saveType` 等 |
| `execution` | Build 管线专用：`basic_weapon_attack`、`execute_strike` 等 |
| `buffs` | 可选：`[概率, 目标类型, 持续回合, buffId, 层数]` |
| `skillParam` | 遗留数值数组；新技能优先写 `rules`，由 `skill_meta` 与运行时读取 |

运行时由 `config/tables/skills.lua` 规范化，并与 `config/tables/skill_meta.lua`（与 JSON `rules` 同步）对齐。

### 3.2 Lua 技能脚本 (`config/skill/skill_{id}.lua`)

推荐通过 **SkillTimelineCompiler** 声明帧，由编译器注入 `ResolveScaledDamage`：

```lua
local SkillTimelineCompiler = require("skills.skill_timeline_compiler")

function skill_80003001.BuildTimeline(hero, targets, skill)
    return SkillTimelineCompiler.Build(hero, targets, skill, {
        id = 80003001,
        frames = {
            { frame = 0, op = "cast", effect = "skill_80003001_cast", targetRef = "selected" },
            { frame = 24, op = "damage", targetRef = "selected", tags = { { tag = "combo_additional_damage", phase = "post" } } },
        },
    })
end
```

也可手写 `execute` 帧，但须与编译器路径一致地调用 `ResolveScaledDamage` / `ApplyBuffFromSkill`。

### 3.3 Buff 定义 (`config/data/buffs.json` + `skills/buff_effect_registry.lua`)

Buff 以 `buffId` 索引；持续伤害/控制等行为在 `buff_effect_registry` 与 `skills/battle_skill_status.lua` 实现。详见 [buff_system_implementation.md](./buff_system_implementation.md)。

### 3.4 三层一致性要求

| 参数 | `skills.json` | Lua Timeline / `skill_meta` | Buff JSON |
|------|---------------|-----------------------------|-----------|
| 伤害骰 / 攻击模式 | `rules.damageDice`、`rules.attackMode` | 帧 `op=damage` + `skill_meta` | — |
| Buff 概率/持续 | `buffs` 数组 | `skill_effect_registry` 标签或 `ApplyBuffFromSkill` | `duration`、`maxStack` |
| 豁免法术 | `rules.saveType`、`rules.onSaveSuccess` | `ResolveScaledDamage` + `RollSave` | — |

**修改技能参数时，三层与 `skill_meta.lua` 须同步更新。**

---

## 4. 技能 ID 与加载

- 技能 ID 为 **8 位整数**，在 `config/data/skills.json` 的 `id` 字段声明，并作为 `require("config.skill.skill_{id}")` 的文件名。
- `classGroupId`（如 `8000100`）标识流派组；`config/tables/skills.lua` 的 `deriveClassId` 从 `classGroupId` 或 `id` 推导战斗用 `classId`。
- 加载顺序：`SkillsTable.GetSkillConfig(id)` → 若存在 `luaFile` 或磁盘上的 `skill_{id}.lua` → `BuildTimeline`。
- 无脚本或 `BuildTimeline` 失败时，战斗层回退默认普攻路径（见 `BattleSkill.CastSkillInSeq` 日志）。

---

## 5. 技能释放完整流程

```
BattleMain.ExecuteHeroAction
  └─ SelectAvailableSkill(hero)
       ├─ 优先选择大招 (ULTIMATE, 能量≥100)
       ├─ 其次选择主动技能 (ACTIVE, CD=0)
       └─ 最后选择普攻 (NORMAL)
  └─ BattleSkill.CastSkillInSeq(hero, target, skillId)
       ├─ 检查技能条件 (CD, 能量, 沉默等)
       ├─ BattleSkill.SelectTarget(hero, skill)
       ├─ BattleSkill.LoadSkillLua(skillId)
       │    └─ require("config.skill.skill_{ID}")
       ├─ skillScript.BuildTimeline(hero, targets, skill)
       ├─ SkillTimeline.Execute(hero, targets, skill, timeline)
       │    ├─ 排序帧序列
       │    ├─ 逐帧执行
       │    └─ 派发视觉事件
       ├─ 扣除能量 / 设置冷却
       └─ 返回执行结果
```

---

## 6. 技能脚本开发规范

### 6.1 必须实现 BuildTimeline

所有技能脚本必须实现 `BuildTimeline(hero, targets, skill)` 函数，返回帧数组。

### 6.2 帧序号约定

| 帧范围 | 用途 |
|--------|------|
| 0 | cast 释放 |
| 5-10 | hit 命中判定 |
| 10-20 | damage 伤害结算 |
| 20-30 | buff 施加 |
| 30+ | effect 特效 / 后续效果 |

### 6.3 伤害与治疗 API

```lua
local damageResult = BattleSkill.ResolveScaledDamage(attacker, defender, {
    skill = skill,
    meta = metaFromSkill5eMeta,  -- 可选，默认从 skillId 查 skill_meta
    damageDice = "2d8",          -- 可选，覆盖 meta
    damageKind = "direct",       -- direct / spell 等
})
local damage = damageResult and damageResult.damage or 0
BattleDmgHeal.ApplyDamage(defender, damage, attacker)

local heal = BattleSkill.CalculateHealDice(healer, target, "2d8+3")
BattleDmgHeal.ApplyHeal(target, heal, healer)

BattleSkill.ApplyBuffFromSkill(caster, target, buffId, skill, { duration = 2 })
-- 冻结/减速等封装见 skills/battle_skill_status.lua
```

---

## 6.5 被动技能统一框架

### 6.5.1 架构说明

| 层级 | 文件 | 职责 |
|------|------|------|
| 被动定义 | `config/tables/passives.lua` | 被动定义加载器，负责把 `config/data/passives.json` 转成运行时触发表 |
| 被动逻辑 | `modules/passive_handlers.lua` | 实现被动处理器工厂，返回具名回调对象 |
| 调度入口 | `modules/battle_passive_skill.lua` | 注册触发器、派发回调、维护 `hero.passiveRuntime` |

### 6.5.2 被动定义格式

```lua
local PassiveDefs = {
    [8000300] = {
        triggers = {
            {
                luaFuncName = "OnBattleBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,
            },
        },
    },
}
```

### 6.5.3 处理器格式

```lua
local function CreateComboMasterPassive(context)
    local self = BuildContextState(context)

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        hero.passiveRuntime = hero.passiveRuntime or {}
        hero.passiveRuntime.comboMasterMinRate = 5000
    end

    return self
end
```

### 6.5.4 运行时状态

统一框架允许被动将数值状态写入 `hero.passiveRuntime`，供主动技能和通用结算逻辑读取：

| key | 说明 | 来源 |
|-----|------|------|
| `comboMasterMinRate` | 连击精通的最低连击概率 | `8000300` |
| `iceDamageBonusPct` | 冰系伤害加成 | `8000800` |
| `iceFreezeChanceBonus` | 冰系冻结概率加成 | `8000800` |
| `thunderChainChanceBonus` | 雷系连锁概率加成 | `8000900` |
| `thunderChainDecayReductionPct` | 雷系弹射衰减减免预留值 | `8000900` |

读取统一通过：

```lua
local minRate = BattlePassiveSkill.GetPassiveValue(hero, "comboMasterMinRate", 0)
local chance = BattleSkill.GetPassiveAdjustedChance(hero, 5000, "iceFreezeChanceBonus")
```

### 6.5.5 当前被动分类

| ClassID | 名称 | 类型 | 框架状态 |
|---------|------|------|----------|
| 8000020 | 格挡 | 脚本型 | 已接入统一 handler |
| 8000100 | 追击 | 脚本型 | 已接入统一 handler |
| 8000200 | 格挡/反击 | 脚本型 | 已接入统一 handler |
| 8000300 | 连击精通 | 运行时状态型 | 已接入统一 handler |
| 8000400 | 战意 | 脚本型 | 已接入统一 handler |
| 8000500 | 感染 | 脚本型 | 已接入统一 handler |
| 8000600 | 亲和 | 脚本型 | 已接入统一 handler |
| 8000700 | 火焰亲和 | 脚本型 | 已接入统一 handler |
| 8000800 | 寒冰亲和 | 运行时状态型 | 已接入统一 handler |
| 8000900 | 雷电亲和 | 运行时状态型 | 已接入统一 handler |

---

## 7. Buff 系统实现

Buff 完整 SSOT 见 [buff_system_implementation.md](./buff_system_implementation.md)。本节仅列与技能 Timeline 的交叉点。

### 7.1 技能系统视角下的 Buff 要点

从技能系统角度，只需要掌握以下几点：

- Buff 统一通过 `BattleSkill.ApplyBuffFromSkill(caster, target, buffId, skill, override)` 施加
- Buff 静态配置统一放在 `config/data/buffs.json`，运行时通过 `config/tables/buffs.lua` 加载并按 `buffId` 索引
- Timeline 技能优先通过 `skills/skill_effect_registry.lua` 中的标签复用已有状态逻辑
- 中毒、燃烧、流血、减速、冻结、静电印记等常见状态封装在 `skills/battle_skill_status.lua`
- 回合开始由 `BattleSkillTurnHooks.ProcessTurnStartStatus()` 触发 `OnRoundBegin` 与控制判定
- 回合结束由 `BattleMain.FinalizeHeroTurn()` 触发 `OnRoundEnd`、持续时间递减与过期移除

### 7.2 开发约定

- 修改状态行为时同步：`config/data/buffs.json`、`config/tables/buffs.lua`、`skills/buff_effect_registry.lua`、`skills/battle_skill_status.lua`、`skills/skill_effect_registry.lua`、`ui/battle_visual_events.lua`。
- 控制是否阻断行动：以 `mainType == CONTROL` 及控制子类型为准，不以 Buff 名称推断。
- 回合行动顺序：当前为等速轮替，无独立 `speed` 行动条。

### 7.3 交叉引用

| 主题 | 文档 |
|------|------|
| Buff 生命周期 | [buff_system_implementation.md](./buff_system_implementation.md) |
| Timeline | 本文 §2–§6 |
| 视觉事件 | 本文 §9 |

---

## 8. 敌人技能体系

### 8.1 敌人技能来源

敌人使用与英雄相同的九流派技能脚本，通过 `EnemyData.ConvertToHeroData` 分配技能。

### 8.2 敌人技能类型映射

`BattleHeroFactory.CreateEnemy` 中的类型转换规则：

| 原始 skillType | 条件 | 映射结果 |
|----------------|------|----------|
| PASSIVE (4) | - | 保持 PASSIVE |
| ACTIVE (2) | - | 保持 ACTIVE |
| 3 或 skillCost>0 | - | ULTIMATE (3) |
| 其他 | - | NORMAL (1) |

### 8.3 敌人战斗属性

敌人属性在 `config/enemy_data.lua` 按 **5e 能力值** 生成：

- `ENEMY_ABILITY_SCORES` + `Ability5e.Calculate5eHp` → HP
- 职业模板（`ClassRoleConfig`）+ `MONSTER_TYPE_TEMPLATES`（`acDelta` / `hitDelta` / `spellDCDelta` / `saveDelta`）→ AC、命中、法术 DC、豁免
- `HeroBuild` / Feat 默认分支与 Roguelike 预算（`roguelike_battle_bridge`）在战前叠加

不存在独立的 `def` / `atkGrowthRate` / `hpGrowthRate` 乘法成长表。

---

## 9. 视觉事件系统

### 9.1 事件类型

| 事件常量 | 说明 |
|----------|------|
| SKILL_TIMELINE_STARTED | Timeline 开始执行 |
| SKILL_TIMELINE_FRAME | 帧执行完成 |
| SKILL_TIMELINE_COMPLETED | Timeline 执行完成 |
| SKILL_CAST_STARTED | 技能释放开始 |
| SKILL_CAST_COMPLETED | 技能释放完成 |
| DAMAGE_DEALT | 伤害事件 |
| HEAL_RECEIVED | 治疗事件 |
| BUFF_ADDED | Buff 添加 |
| BUFF_REMOVED | Buff 移除 |
| HERO_STATE_CHANGED | 英雄状态变化 |
| TURN_STARTED | 回合开始 |
| TURN_ENDED | 回合结束 |
| HERO_DIED | 英雄阵亡 |
| ENERGY_CHANGED | 能量变化 |

### 9.2 渲染后端订阅

不同渲染后端（Console/Web/Unity）订阅 `BattleVisualEvents` 事件，用自己的方式呈现战斗画面。逻辑层与表现层完全解耦。

---

## 10. 核心 API 清单

### 10.1 BattleSkill

| 函数 | 说明 |
|------|------|
| `Init(hero, skillsConfig)` | 初始化英雄技能 |
| `CastSkillInSeq(hero, target, skillId)` | 释放技能（Timeline 路径） |
| `SelectAvailableSkill(hero)` | 选择可用技能（大招→主动→普攻） |
| `SelectTarget(hero, skill)` | 选择技能目标 |
| `LoadSkillLua(skillId)` | 加载技能 Lua 脚本 |
| `ResolveScaledDamage(attacker, defender, opts)` | 5e 命中/豁免 + 骰伤，返回 `damage`、`save`、`damageRoll` 等 |
| `CalculateHealDice(healer, target, healDice)` | 治疗骰表达式 |
| `ApplyBuffFromSkill(caster, target, buffId, skill, override)` | 从技能施加 Buff |
| `GetPassiveAdjustedRate(hero, baseRate, passiveKey)` | 被动运行时倍率修正 |
| `GetPassiveAdjustedChance(hero, baseChance, passiveKey)` | 被动运行时概率修正 |
| `GetSkillCurCoolDown(hero, skillId)` | 获取技能冷却 |
| `SetSkillCurCoolDown(hero, skillId, cd)` | 设置技能冷却 |
| `GetHeroSkills(hero)` | 获取英雄所有技能 |
| `GetSkillsByType(hero, skillType)` | 按类型获取技能 |

### 10.2 SkillTimeline

| 函数 | 说明 |
|------|------|
| `Execute(hero, targets, skill, timeline)` | 执行 Timeline 帧序列 |

### 10.3 BattlePassiveSkill

| 函数 | 说明 |
|------|------|
| `RegisterHeroSkills(hero)` | 注册英雄被动触发器 |
| `RunSkillOnBattleBegin()` | 触发战斗开始类被动 |
| `RunSkillOnSelfTurnBegin(hero)` | 触发自身回合开始被动 |
| `RunSkillOnSelfTurnEnd(hero)` | 触发自身回合结束被动 |
| `GetPassiveValue(hero, key, defaultValue)` | 读取统一被动运行时状态 |

### 10.4 BattleDmgHeal

| 函数 | 说明 |
|------|------|
| `ApplyDamage(target, damage, attacker)` | 施加伤害 |
| `ApplyHeal(target, amount, healer)` | 施加治疗 |

---

*文档结束*


