# 技能系统实现文档 (Timeline 版)

> **项目**: Mini Battle Simulator  
> **版本**: 2.0 (Timeline 架构)  
> **更新时间**: 2026-04-14  
> **说明**: 本文档描述技能系统迁移至 Timeline 执行体系后的实际实现

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

### 1.1 架构变迁

技能系统已从旧版 `actData` 关键帧 + `Execute` 分支模式，完全迁移至 **Timeline 执行体系**：

| 维度 | 旧版 | 新版 (Timeline) |
|------|------|-----------------|
| 执行入口 | `Execute` 函数 或 `actData` 关键帧 | `BuildTimeline` 函数 |
| 时序控制 | `TriggerS` 秒级时间戳 | `frame` 逻辑帧序号 |
| 伤害结算 | `DWCommon.DamageData` 字符串解析 | `CalculateDamageWithRate` 直接调用 |
| Buff 施加 | `DWCommon.LaunchBuff` 字符串解析 | `ApplyBuff` / `ApplyFreeze` 直接调用 |
| 表现解耦 | 逻辑与表现混合 | 逻辑帧结算 + 事件派发，表现层异步订阅 |

### 1.2 核心模块

| 模块 | 文件路径 | 职责 |
|------|----------|------|
| SkillTimeline | `core/skill_timeline.lua` | Timeline 执行引擎，排序帧序列、逐帧执行、派发事件 |
| BattleSkill | `modules/battle_skill.lua` | 技能系统主入口，管理技能实例、冷却、释放流程 |
| BattleVisualEvents | `ui/battle_visual_events.lua` | 视觉事件定义与数据构建器 |
| BattlePassiveSkill | `modules/battle_passive_skill.lua` | 被动技能注册、触发分发与运行时状态查询 |
| PassiveDefs | `config/passive/passive_defs.lua` | 被动触发定义表（classId → triggers） |
| PassiveHandlers | `modules/passive_handlers.lua` | 被动处理器工厂，承载脚本型被动逻辑 |
| SkillConfig | `config/skill_config.lua` | 技能配置加载器 |
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
| hit | 命中判定 | 判定闪避/格挡 |
| damage | 伤害结算 | 调用 CalculateDamageWithRate，派发 DAMAGE_DEALT |
| heal | 治疗结算 | 调用 CalculateHeal，派发 HEAL_RECEIVED |
| buff | Buff 施加 | 调用 ApplyBuff / ApplyFreeze，派发 BUFF_ADDED |
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

每个技能由三层配置共同定义，必须保持一致：

### 3.1 JSON 静态配置 (`config/res_skill.json`)

```json
{
    "ID": 80007003,
    "Name": "爆炸火球",
    "Type": 2,
    "CoolDownR": 3,
    "Cost": 0,
    "SkillParam": [10000, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "Buff1": [10000, 0, 2, 870001, 1]
}
```

| 字段 | 说明 |
|------|------|
| ID | 技能 ID，8位：`classId * 10 + level` |
| Type | 1=普攻, 2=主动, 3=大招, 4=被动 |
| CoolDownR | 冷却回合数 |
| Cost | 能量消耗（大招=100，其他=0） |
| SkillParam[1] | 伤害倍率（万分比，10000=100%） |
| Buff1-5 | [概率, 目标类型, 持续回合, BuffID, 叠加层数] |

### 3.2 Lua 技能脚本 (`config/skill/skill_{ID}.lua`)

```lua
local BattleSkill = require("modules.battle_skill")

local skill_80007003 = {}

function skill_80007003.BuildTimeline(hero, targets, skill)
    local timeline = {}
    table.insert(timeline, {
        frame = 0, op = "cast",
        execute = function(ctx, f)
            BattleEvent.Publish(BattleVisualEvents.SKILL_CAST_STARTED, ...)
        end
    })
    table.insert(timeline, {
        frame = 10, op = "damage",
        execute = function(ctx, f)
            for _, target in ipairs(ctx.targets) do
                local damage = BattleSkill.CalculateDamageWithRate(ctx.hero, target, 10000)
                BattleDmgHeal.ApplyDamage(target, damage, ctx.hero)
            end
        end
    })
    table.insert(timeline, {
        frame = 20, op = "buff",
        execute = function(ctx, f)
            for _, target in ipairs(ctx.targets) do
                BattleSkill.ApplyBuff(target, 870001, 2, ctx.hero)
            end
        end
    })
    return timeline
end

return skill_80007003
```

### 3.3 Buff 定义 (`config/buff/buff_{ID}.lua`)

```lua
local buff_870001 = {
    buffId = 870001,
    mainType = E_BUFF_MAIN_TYPE.BAD,
    subType = 870001,
    name = "燃烧",
    initialStack = 1,
    maxStack = 99,
    duration = 2,
    canStack = true,
    stackRule = "add",
    effects = {
        {
            timing = 3,  -- ON_ROUND_BEGIN
            type = "custom",
            func = function(buff, hero, effect)
                local damage = math.max(1, math.floor((hero.maxHp or 0) * 0.05 * buff.stackCount))
                BattleDmgHeal.ApplyDamage(hero, damage, buff.caster or hero)
            end
        }
    }
}
```

### 3.4 三层一致性要求

| 参数 | JSON | Lua 脚本 | Buff 定义 |
|------|------|----------|-----------|
| 伤害倍率 | SkillParam[1] | CalculateDamageWithRate 参数 | - |
| Buff 持续 | Buff[3] | ApplyBuff 参数 | duration |
| Buff 叠加 | Buff[5] | ApplyBuff 参数 | canStack/maxStack |
| 冻结持续 | Buff[3] | ApplyFreeze 参数 | duration |

**修改技能参数时，三层必须同步更新。**

---

## 4. 技能 ID 编码规则

```
actualSkillId = classId * 10 + level

classId 范围: 8000100 ~ 8000900 (九流派)
level 范围: 1~4 (普攻/被动/主动/大招)

示例:
  8000101 = 8000100 * 10 + 1  → 刺客 L1 普攻
  8000103 = 8000100 * 10 + 3  → 刺客 L3 主动
  8000704 = 8000700 * 10 + 4  → 火法 L4 大招
```

**禁止使用** `classId * 100 + level`（产生9位ID导致加载失败回退默认普攻）。

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

### 6.2 禁止使用 Execute

旧版 `Execute` 分支已移除，`CastSkillInSeq` 仅处理 `BuildTimeline` 结果。

### 6.3 帧序号约定

| 帧范围 | 用途 |
|--------|------|
| 0 | cast 释放 |
| 5-10 | hit 命中判定 |
| 10-20 | damage 伤害结算 |
| 20-30 | buff 施加 |
| 30+ | effect 特效 / 后续效果 |

### 6.4 伤害计算 API

```lua
-- 标准伤害计算
local damage = BattleSkill.CalculateDamageWithRate(attacker, target, damageRate)
-- damageRate: 万分比，10000 = 100%

-- 治疗计算
local healAmount = BattleSkill.CalculateHeal(healer, target, healRate)

-- 施加 Buff
BattleSkill.ApplyBuff(target, buffId, duration, caster)

-- 施加冻结
BattleSkill.ApplyFreeze(target, duration, chance, caster)
```

---

## 6.5 被动技能统一框架

### 6.5.1 架构说明

被动技能已从旧版 `event_*.lua + war_*.lua` 双文件模式，整合为统一框架：

| 层级 | 文件 | 职责 |
|------|------|------|
| 被动定义 | `config/passive/passive_defs.lua` | 定义每个 `classId` 的触发时机和回调名 |
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

### 7.1 Buff 触发时机

| timing | 枚举 | 说明 |
|--------|------|------|
| 1 | ON_ADD | 获得瞬间触发 |
| 2 | ON_REMOVE | 移除瞬间触发 |
| 3 | ON_ROUND_BEGIN | 回合开始触发（DOT/HOT） |
| 4 | ON_ROUND_END | 回合结束触发 |
| 5 | ON_ATTACK | 发起攻击时触发 |
| 6 | ON_DEFEND | 被攻击时触发 |
| 7 | ON_DAMAGE | 造成伤害时触发 |
| 8 | ON_RECEIVE_DAMAGE | 受到伤害时触发 |
| 11 | ON_KILL | 击杀目标时触发 |
| 12 | ON_DEATH | 自身死亡时触发 |

### 7.2 Buff 效果类型

| type | 说明 | 参数 |
|------|------|------|
| custom | 自定义回调 | func(buff, hero, effect) |
| damage | DOT 持续伤害 | value, damageType |
| heal | HOT 持续治疗 | value, percent |
| attr_change | 属性变更 | attr, value |
| dispel | 驱散 | targetType |

### 7.3 九流派 Buff 清单

| Buff ID | 名称 | mainType | 持续 | 叠加 | DOT/效果 |
|---------|------|----------|------|------|----------|
| 820001 | 挑衅 | BAD | 1回合 | 不可叠 | 强制攻击施法者 |
| 820002 | 反击姿态 | GOOD | 永久 | 不可叠 | 受击必反击150% |
| 820003 | 盾墙 | GOOD | 2回合 | 不可叠 | 100%格挡+反击 |
| 840001 | 战意 | GOOD | 永久 | 可叠5层 | 每层攻/防/速+5% |
| 840002 | 全军突击 | GOOD | 3回合 | 不可叠 | 全体攻击+20% |
| 840003 | 战神降临 | GOOD | 3回合 | 不可叠 | 全体攻/防/速+50% |
| 850001 | 中毒 | BAD | 永久 | 可叠99层 | 每层每回合2%最大生命DOT |
| 860001 | 亲和 | GOOD | 永久 | 不可叠 | 每回合回复10%最大生命 |
| 870001 | 燃烧 | BAD | 2回合 | 可叠99层 | 每层每回合5%最大生命DOT |
| 870002 | 火焰亲和 | GOOD | 永久 | 不可叠 | 火焰伤害+15% |
| 880001 | 减速 | BAD | 2回合 | 不可叠 | 速度-30% |
| 880002 | 冻结 | CONTROL | 1回合 | 不可叠 | 无法行动 |

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

### 8.3 敌人属性成长

```lua
-- 成长率（比英雄高约2倍）
hpGrowthRate  = 0.12 + quality * 0.015
atkGrowthRate = 0.095 + quality * 0.012
defGrowthRate = 0.075 + quality * 0.010

-- 乘法叠加
qualityMultipliers = {1.0, 1.06, 1.12, 1.18, 1.26, 1.34}
typeMultipliers = {[0]=1.0, [1]=1.15, [2]=1.35}  -- 普通/Elite/BOSS
starMultiplier = 1.0 + (star-1) * 0.15

totalMultiplier = qualityMultiplier * typeMultiplier * starMultiplier
atkMultiplier = 1.0 + (totalMultiplier - 1.0) * 0.45  -- ATK 衰减系数

hp  = (baseHp + hpGrowth) * totalMultiplier
atk = (baseAtk + atkGrowth) * atkMultiplier
def = (baseDef + defGrowth) * totalMultiplier
```

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
| `CalculateDamageWithRate(attacker, target, rate)` | 计算伤害 |
| `CalculateHeal(healer, target, rate)` | 计算治疗量 |
| `GetPassiveAdjustedRate(hero, baseRate, passiveKey)` | 读取统一被动状态并调整倍率 |
| `GetPassiveAdjustedChance(hero, baseChance, passiveKey)` | 读取统一被动状态并调整概率 |
| `ApplyBuff(target, buffId, duration, caster)` | 施加 Buff |
| `ApplyFreeze(target, duration, chance, caster)` | 施加冻结 |
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
