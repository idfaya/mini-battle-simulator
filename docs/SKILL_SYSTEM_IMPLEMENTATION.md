# 技能系统实现文档

> **项目**: Mini Battle Simulator  
> **版本**: 1.0  
> **生成时间**: 2026-03-29  
> **说明**: 本文档基于源代码分析生成，描述技能系统的实际实现细节

---

## 目录

1. [系统概述](#1-系统概述)
2. [系统架构图](#2-系统架构图)
3. [数据流图](#3-数据流图)
4. [配置格式规范](#4-配置格式规范)
5. [API清单](#5-api清单)
6. [典型技能示例](#6-典型技能示例)
7. [实现与设计文档的差异](#7-实现与设计文档的差异)

---

## 1. 系统概述

Mini Battle Simulator 的技能系统采用**分层架构**，将配置、执行、机制分离，支持复杂的技能效果组合。系统核心特性包括：

- **技能类型支持**: 普通攻击、主动技能、大招、被动技能
- **多层范围系统**: 射程 → 范围 → 目标选择
- **关键帧执行**: 基于时间线的技能效果触发
- **Buff/Debuff系统**: 完整的状态效果支持
- **技能脚本**: 支持自定义Lua脚本扩展

### 1.1 核心模块

| 模块 | 文件路径 | 职责 |
|------|----------|------|
| BattleSkill | `modules/battle_skill.lua` | 技能系统主入口，管理技能实例、冷却、释放流程 |
| BattleArea | `modules/battle_area.lua` | 技能范围计算（单体、横排、纵列、十字等） |
| BattleRange | `modules/battle_range.lua` | 射程系统兼容层 |
| SkillExecutor | `core/skill_executor.lua` | 技能执行器，解析并执行技能关键帧效果 |
| BattleScriptExp | `core/battle_script_exp.lua` | 技能脚本API层 |
| SkillLoader | `core/skill_loader.lua` | 技能Lua脚本加载器 |
| SkillConfig | `config/skill_config.lua` | 技能配置加载，管理res_skill.json |

---

## 2. 系统架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              技能系统架构                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        应用层 (UI/表现)                              │   │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │   │
│  │   │ BattleVisual │  │ BattleEvent  │  │    Logger                │ │   │
│  │   │ Events       │  │              │  │                          │ │   │
│  │   └──────────────┘  └──────────────┘  └──────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ▲                                              │
│                              │                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        系统层 (Skill System)                         │   │
│  │   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │   │
│  │   │   BattleSkill    │  │   BattleArea     │  │  BattleRange     │ │   │
│  │   │   (技能主模块)    │  │   (范围系统)      │  │  (射程系统)       │ │   │
│  │   └──────────────────┘  └──────────────────┘  └──────────────────┘ │   │
│  │          │                      │                      │            │   │
│  │   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │   │
│  │   │  SkillExecutor   │  │  SkillLoader     │  │  SkillConfig     │ │   │
│  │   │  (技能执行器)     │  │  (脚本加载器)     │  │  (配置管理)       │ │   │
│  │   └──────────────────┘  └──────────────────┘  └──────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ▲                                              │
│                              │                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        机制层 (Mechanics)                            │   │
│  │   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │   │
│  │   │ SkillMechanics   │  │ BattleDmgHeal    │  │  BattleBuff      │ │   │
│  │   │ (技能机制)        │  │ (伤害治疗)        │  │  (Buff系统)       │ │   │
│  │   └──────────────────┘  └──────────────────┘  └──────────────────┘ │   │
│  │   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │   │
│  │   │ BattleFormula    │  │BattleAttribute   │  │ BattleFormation  │ │   │
│  │   │ (战斗公式)        │  │ (属性系统)        │  │  (阵型系统)       │ │   │
│  │   └──────────────────┘  └──────────────────┘  └──────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ▲                                              │
│                              │                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        脚本层 (Scripting)                            │   │
│  │   ┌──────────────────┐  ┌──────────────────┐                        │   │
│  │   │ BattleScriptExp  │  │  自定义技能脚本   │                        │   │
│  │   │ (脚本API)         │  │  (skill_XXX.lua) │                        │   │
│  │   └──────────────────┘  └──────────────────┘                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              ▲                                              │
│                              │                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        配置层 (Configuration)                        │   │
│  │   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────┐  │   │
│  │   │ res_skill.json│ │ skill_*.lua  │ │ spell_*.lua  │ │buff_*.lua│  │   │
│  │   │ (技能基础配置)│ │ (技能动作数据)│ │ (技能效果配置)│ │(Buff配置)│  │   │
│  │   └──────────────┘ └──────────────┘ └──────────────┘ └──────────┘  │   │
│  │   ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐  │   │
│  │   │ skill_area_  │ │ move_*.lua   │ │ skill_data.lua           │  │   │
│  │   │ configs.lua  │ │ (动作配置)    │ │ (技能数据)                │  │   │
│  │   └──────────────┘ └──────────────┘ └──────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.1 模块依赖关系

```
BattleSkill (主入口)
    ├── SkillConfig (配置加载)
    ├── SkillLoader (脚本加载)
    ├── SkillExecutor (执行器)
    ├── BattleArea (范围系统)
    ├── BattleRange (射程系统)
    ├── SkillMechanics (机制层)
    └── BattleScriptExp (脚本API)
        ├── BattleDmgHeal (伤害治疗)
        ├── BattleBuff (Buff系统)
        ├── BattleAttribute (属性)
        ├── BattleFormation (阵型)
        └── BattleEnergy (能量)
```

---

## 3. 数据流图

### 3.1 技能释放完整流程

```
┌─────────────┐     ┌─────────────────────────────────────────────────────────────┐
│   触发条件   │     │                    技能释放流程                              │
│  (回合/手动) │────▶│                                                             │
└─────────────┘     │  ┌───────────┐   ┌───────────┐   ┌───────────┐              │
                    │  │ 1.检查能量 │──▶│ 2.检查冷却 │──▶│ 3.选择目标 │              │
                    │  └───────────┘   └───────────┘   └───────────┘              │
                    │       │              │              │                       │
                    │       ▼              ▼              ▼                       │
                    │  ┌───────────────────────────────────────────────────────┐  │
                    │  │ 4.验证射程 (BattleRange.IsInRange)                   │  │
                    │  └───────────────────────────────────────────────────────┘  │
                    │                              │                               │
                    │                              ▼                               │
                    │  ┌───────────────────────────────────────────────────────┐  │
                    │  │ 5.加载技能Lua (SkillLoader.Load / BattleSkill.Load)  │  │
                    │  └───────────────────────────────────────────────────────┘  │
                    │                              │                               │
                    │                              ▼                               │
                    │  ┌───────────────────────────────────────────────────────┐  │
                    │  │ 6.执行技能逻辑                                         │  │
                    │  │    ├─ 有Execute函数? ──▶ 执行自定义脚本               │  │
                    │  │    └─ 无Execute函数? ──▶ SkillExecutor执行关键帧      │  │
                    │  └───────────────────────────────────────────────────────┘  │
                    │                              │                               │
                    │                              ▼                               │
                    │  ┌───────────────────────────────────────────────────────┐  │
                    │  │ 7.解析actData关键帧                                    │  │
                    │  │    ├─ DamageData ──▶ 造成伤害                          │  │
                    │  │    ├─ LaunchBuff ──▶ 施加Buff                          │  │
                    │  │    ├─ HealData ────▶ 治疗                              │  │
                    │  │    ├─ LaunchSpell ─▶ 执行法术技能                      │  │
                    │  │    ├─ EffectData ──▶ 播放特效                          │  │
                    │  │    └─ TokenData ───▶ 召唤单位                          │  │
                    │  └───────────────────────────────────────────────────────┘  │
                    │                              │                               │
                    │                              ▼                               │
                    │  ┌───────────────────────────────────────────────────────┐  │
                    │  │ 8.应用效果                                             │  │
                    │  │    ├─ BattleDmgHeal.ApplyDamage (伤害)                │  │
                    │  │    ├─ BattleDmgHeal.ApplyHeal (治疗)                  │  │
                    │  │    └─ BattleBuff.Add (Buff)                           │  │
                    │  └───────────────────────────────────────────────────────┘  │
                    │                              │                               │
                    │                              ▼                               │
                    │  ┌───────────────────────────────────────────────────────┐  │
                    │  │ 9.触发UI事件                                           │  │
                    │  │    ├─ SKILL_CAST_STARTED                              │  │
                    │  │    ├─ DAMAGE_DEALT                                    │  │
                    │  │    ├─ HEAL_RECEIVED                                   │  │
                    │  │    └─ HERO_STATE_CHANGED                              │  │
                    │  └───────────────────────────────────────────────────────┘  │
                    │                              │                               │
                    │                              ▼                               │
                    │  ┌───────────┐   ┌───────────┐   ┌───────────┐              │
                    │  │ 10.扣能量 │──▶│ 11.设冷却 │──▶│ 12.返回结果 │              │
                    │  └───────────┘   └───────────┘   └───────────┘              │
                    │                                                             │
                    └─────────────────────────────────────────────────────────────┘
```

### 3.2 技能配置加载流程

```
res_skill.json (技能基础配置表)
    │
    ├── SkillConfig.LoadSkillConfig() ──▶ 解析JSON建立ID映射
    │
    ├── SkillConfig.GetSkillLuaPath(skillId)
    │       │
    │       ├── 9位ID ──▶ 直接查找
    │       └── 7位ID ──▶ 补"01"转9位 (ClassID + "01")
    │
    └── 返回: config.skill.skill_{ID}

skill_{ID}.lua (技能动作配置)
    │
    ├── BattleSkill.LoadSkillLua(skillId)
    │       │
    │       ├── 检查缓存
    │       ├── require加载Lua文件
    │       └── 从_G[skill_{ID}]获取数据
    │
    └── 返回: skillData = { actData, targetsSelections, ... }

spell_{ID}.lua (技能效果配置)
    │
    └── SkillExecutor.LoadSpellLua(spellId)
        │
        ├── require加载
        └── 返回: spellData = { NewAttackDrop, Trigger, ... }
```

---

## 4. 配置格式规范

### 4.1 技能基础配置 (res_skill.json)

```json
{
  "ID": 131010101,
  "ClassID": 1310101,
  "SkillLevel": 1,
  "Type": 1,
  "SkillParam": [10000, 0, 0, 0],
  "Buff1": [],
  "Buff2": [],
  "Buff3": [],
  "Buff4": [],
  "Buff5": [],
  "CoolDownR": 0,
  "Cost": 0
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| ID | number | 完整技能ID (9位) |
| ClassID | number | 技能类ID (7位) |
| SkillLevel | number | 技能等级 |
| Type | number | 技能类型: 1=普通, 2=主动, 3=大招, 4=被动 |
| SkillParam | array | 技能参数数组 (伤害倍率等) |
| Buff1-5 | array | 技能附带的Buff配置 |
| CoolDownR | number | 冷却回合 |
| Cost | number | 能量消耗 |

### 4.2 技能动作配置 (skill_{ID}.lua)

```lua
skill_131010101 = {
    Class = 2,
    LuaFile = "",                    -- 额外脚本文件名
    keepRotation = false,
    
    -- 目标选择配置
    targetsSelections = {
        castTarget = 1,              -- 目标类型: 0=自己, 1=敌方, 2=友方
        tSConditions = {
            Num = 0,
            measureType = 3,         -- 选择策略
            conditionDirection = 1,
            tSFilter = { ... }
        }
    },
    
    -- 动作数据 (关键帧序列)
    actData = {
        [1] = {
            -- 动作条件
            actConditionn = {
                NotU1 = false,
                campType = 0
            },
            
            -- 动画配置
            cartoon = {
                animationPath = "Assets/...",
                animationname = "An_B_101_Skill_N_01",
                animatorname = "Skill",
                during = 1.4,
                triggerS = 0,
                TotalS = 0.8666667
            },
            
            -- 移动配置
            LaunchMove = {
                MoveID = 10101,
                isMoveBack = false,
                moveOffsetDis = -1.5,
                triggerTimeS = 0.3666667
            },
            
            -- 关键帧数据
            keyFrameDatas = {
                -- 伤害关键帧
                {
                    TriggerS = 0.4666667,        -- 触发时间(秒)
                    DuringS = 0,
                    datatype = "DWCommon.DamageData",
                    data = "{...}",              -- JSON字符串
                    targetsSelections = { ... }
                },
                -- Buff关键帧
                {
                    TriggerS = 0.5,
                    datatype = "DWCommon.LaunchBuff",
                    data = "{...}",
                    targetsSelections = { ... }
                },
                -- 特效关键帧
                {
                    TriggerS = 0.4333333,
                    datatype = "DWCommon.EffectData",
                    data = "{...}",
                    targetsSelections = { ... }
                },
                -- 音效关键帧
                {
                    TriggerS = 0,
                    datatype = "DWCommon.SoundData",
                    data = "{...}"
                },
                -- Lua脚本关键帧
                {
                    TriggerS = 1.2,
                    datatype = "DWCommon.LuaData",
                    data = "{ FunctionName = 'a_skill_13148_02_enemyHit', ... }"
                }
            }
        }
    }
}
```

### 4.3 关键帧数据类型

| 数据类型 | 说明 | 关键字段 |
|----------|------|----------|
| DWCommon.DamageData | 伤害数据 | attackType, damageType, hitType, cSVSkillAssociate |
| DWCommon.LaunchBuff | Buff施加 | AssociateBuff, targetsSelections |
| DWCommon.HealData | 治疗数据 | HealValue, HealType |
| DWCommon.LaunchSpell | 法术/范围技能 | SpellID, targetsSelections |
| DWCommon.EffectData | 特效播放 | effectpath, BoneData, target |
| DWCommon.SoundData | 音效播放 | soundid, triggerS |
| DWCommon.CameraData | 镜头震动 | CameraShakeName, IsShake |
| DWCommon.LuaData | Lua脚本调用 | FunctionName, LuaName |
| DWCommon.TokenData | 召唤单位 | TokenAssociate |
| DWCommon.TimelineData | Timeline播放 | timelineA |
| DWCommon.FlagData | 标记设置 | FlagType |
| DWCommon.MoveData | 移动 | MoveID, isMoveBack |

### 4.4 技能效果配置 (spell_{ID}.lua)

```lua
spell_10000 = {
    Name = "测试专用",
    Title = "测试专用",
    
    -- 新攻击落点配置
    NewAttackDrop = {
        damageData = {
            attackType = 1,          -- 攻击类型
            damageType = 1,          -- 伤害类型
            hitType = 0,             -- 命中类型
            cSVSkillAssociate = 0,   -- 关联技能
            Sender = { IDS = {} },
            Target = { IDS = {} }
        },
        healData = { ... },
        energyData = { ... },
        dispelData = { ... },
        targetsSelections = { ... },
        triggerType = 0
    },
    
    -- 触发配置
    Trigger = {
        damageData = { ... },
        healData = { ... },
        ...
    },
    
    -- 目标特效
    TargetEffect = {
        effectpath = "Assets/...",
        BoneData = { ... },
        target = 1
    },
    
    -- Buff配置
    launchBuff = {
        AssociateBuff = 0,
        targetsSelections = { ... }
    },
    
    -- 其他配置
    IntervalTimeS = 1,
    IsHitExplosion = true,
    MotionType = 0,
    flip = false
}
```

### 4.5 Buff配置 (buff_{ID}.lua)

```lua
buff_10001 = {
    Name = "",
    IconTexture = { IconPath = "" },
    
    -- 开始特效
    SEstart = {
        effectpath = "Assets/Content/Prefab/SFX/...",
        BoneData = { AttachType = 0, BoneName = "", ... },
        binding = 0,
        target = 2,
        soundData = { ... }
    },
    
    -- 循环特效
    SEloop = {
        effectpath = "",
        binding = 1,
        target = 2
    },
    
    -- 间隔特效
    SEIntervals = { ... },
    
    -- 结束特效
    SEend = { ... },
    
    -- 开始音效
    SDstart = { soundid = "", triggerS = 0 },
    
    -- 结束音效
    SDend = { soundid = "", triggerS = 0 },
    
    -- 模型变更
    ChgModelInfo = {}
}
```

### 4.6 范围配置 (skill_area_configs.lua)

```lua
SkillAreaConfigs[skillId] = {
    areaType = AREA_TYPE.SINGLE,      -- 范围类型
    targetCamp = TARGET_CAMP.ENEMY,   -- 目标阵营
    targetCount = 1,                  -- 目标数量
    respectFormation = true,          -- 是否遵守阵型保护
    damageDecay = 0.3,                -- 伤害衰减率
    mainTargetBonus = 0.2,            -- 主目标加成
    splashDamage = 0.5,               -- 溅射伤害比例
    bounceCount = 1,                  -- 弹射次数
    radius = 1,                       -- 圆形范围半径
    targetMin = 1,                    -- 随机范围最小数
    targetMax = 3                     -- 随机范围最大数
}
```

### 4.7 范围类型枚举

```lua
AREA_TYPE = {
    SINGLE = "SINGLE",           -- 单体
    ROW = "ROW",                 -- 一排（横向）
    COLUMN = "COLUMN",           -- 一列（纵向）
    CROSS = "CROSS",             -- 十字（5人）
    CHAIN = "CHAIN",             -- 链式弹射
    FULL = "FULL",               -- 全体
    RANDOM = "RANDOM",           -- 随机N个
    RANDOM_RANGE = "RANDOM_RANGE", -- 随机1-N个
    FRONT_ROW = "FRONT_ROW",     -- 前排
    BACK_ROW = "BACK_ROW",       -- 后排
    CIRCLE = "CIRCLE",           -- 圆形
    NEAREST = "NEAREST",         -- 最近
    FARTHEST = "FARTHEST",       -- 最远
    LOWEST_HP = "LOWEST_HP",     -- 最低血量
    HIGHEST_HP = "HIGHEST_HP",   -- 最高血量
    SELF = "SELF"                -- 自己
}

TARGET_CAMP = {
    ENEMY = "ENEMY",             -- 敌方
    ALLY = "ALLY",               -- 友方（不含自己）
    ALL = "ALL",                 -- 全体
    SELF = "SELF",               -- 自己
    SELF_TEAM = "SELF_TEAM"      -- 自己队伍
}
```

### 4.8 技能类型枚举

```lua
E_SKILL_TYPE = {
    NORMAL = 1,      -- 普通攻击
    ACTIVE = 2,      -- 主动技能
    ULTIMATE = 3,    -- 大招
    PASSIVE = 4      -- 被动技能
}

E_CAST_TARGET = {
    Self = 0,                -- 自己
    Enemy = 1,               -- 敌方
    Alias = 2,               -- 友方
    EveryOne = 3,            -- 所有人
    AlliesExcludeSelf = 4,   -- 友方（不含自己）
    EveryOneExcludeSelf = 5  -- 所有人（不含自己）
}
```

---

## 5. API清单

### 5.1 BattleScriptExp - 技能脚本API

#### 数学函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `Rand()` | - | number | 生成0-1随机浮点数 |
| `RandInt(min, max)` | min, max: number | number | 生成[min, max]随机整数 |
| `Floor(x)` | x: number | number | 向下取整 |
| `Ceil(x)` | x: number | number | 向上取整 |

#### 伤害/治疗函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `MakeDmg(srcId, destId, atkType, dmgParam, tempAttr, hitType)` | ... | table | 造成伤害 |
| `MakeDmgPlus(srcId, destId, atkType, dmgParam)` | ... | table | 额外伤害 |
| `MakeHeal(srcId, destId, healVal)` | ... | number | 治疗目标 |
| `MakeRecovery(srcId, destId, healVal)` | ... | number | 恢复生命(不受加成影响) |
| `PayHP(instanceId, percent)` | ... | number | 消耗HP百分比 |

#### Buff函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `AddBuff(srcId, destId, buff)` | buff: table | boolean | 添加Buff |
| `DelBuffByMainType(instanceId, mainType)` | ... | number | 按主类型删除Buff |
| `DelBuffBySubType(instanceId, subType, num)` | ... | number | 按子类型删除Buff |
| `GetBuffStackNumByMainType(instanceId, mainType)` | ... | number | 获取Buff层数(主类型) |
| `GetBuffStackNumBySubType(instanceId, subType)` | ... | number | 获取Buff层数(子类型) |

#### 属性函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `GetCurHp(instanceId)` | ... | number | 获取当前HP |
| `GetMaxHp(instanceId)` | ... | number | 获取最大HP |
| `GetHpPercent(instanceId)` | ... | number | 获取HP百分比 |
| `SetHp(instanceId, hpVal)` | ... | - | 设置HP |
| `SetHpPercent(instanceId, percent)` | ... | - | 设置HP百分比 |
| `GetHeroAttribute(instanceId, attrId)` | ... | number | 获取属性值 |
| `ModifyAttribute(instanceId, attrId, attrValue)` | ... | - | 修改属性 |

#### 技能函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `GetSkillCurCoolDown(instanceId, skillId)` | ... | number | 获取技能冷却 |
| `SetSkillCurCoolDown(instanceId, skillId, cd)` | ... | - | 设置技能冷却 |
| `CastHideSkill(srcId, destId, classId)` | ... | boolean | 释放隐藏技能 |
| `AddUltimateSkillNoCost(srcId, destId)` | ... | boolean | 释放无消耗大招 |
| `GetUltimateSkillCost(instanceId)` | ... | number | 获取大招消耗 |

#### 目标选择函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `GetRandomEnemyInstanceId(instanceId)` | ... | number/nil | 随机敌人ID |
| `GetRandomFriendInstanceId(instanceId, includeSelf)` | ... | number/nil | 随机友军ID |
| `GetEnemySortByAttrId(instanceId, attrId)` | ... | table | 按属性排序敌人 |
| `GetFriendSortByAttrId(instanceId, attrId, includeSelf)` | ... | table | 按属性排序友军 |
| `GetInstanceIdByWpType(isLeft, wpType)` | ... | number/nil | 通过位置获取ID |

#### 能量函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `AddEnergyBar(instanceId, energyPoint)` | ... | - | 添加能量条 |
| `AddEnergyPoint(instanceId, point)` | ... | - | 添加能量点 |

#### 召唤/复活函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `CreateToken(instanceId, tokenId, life, wpType)` | ... | number/nil | 创建召唤物 |
| `DestroyToken(instanceId, hideImmediately)` | ... | - | 销毁召唤物 |
| `ReviveHero(instanceId, wpType, hpRate, actionOrderRate)` | ... | boolean | 复活英雄 |

#### 事件/工具函数

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `PublishEvent(eventName, ...)` | ... | - | 发布事件 |
| `DelayExec(duration, callback)` | ... | - | 延迟执行 |
| `Log(msg)` | msg: string | - | 输出日志 |
| `LogError(msg)` | msg: string | - | 输出错误日志 |

### 5.2 BattleSkill - 技能模块API

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `InitModule()` | - | - | 初始化模块 |
| `Init(hero, skillsConfig)` | ... | - | 初始化英雄技能 |
| `CreateSkillInstance(skillId, skillConfig)` | ... | table | 创建技能实例 |
| `GetSkillCurCoolDown(hero, skillId)` | ... | number | 获取技能冷却 |
| `SetSkillCurCoolDown(hero, skillId, cd)` | ... | - | 设置技能冷却 |
| `ReduceCoolDown(hero, amount)` | ... | - | 减少所有技能冷却 |
| `CastSmallSkill(hero, target)` | ... | boolean | 释放普通攻击 |
| `CastSkillInSeq(hero, target, skillId)` | ... | boolean | 释放指定技能 |
| `SelectTarget(hero, skill)` | ... | table | 选择技能目标 |
| `CheckSkillCondition(hero, skill)` | ... | boolean | 检查释放条件 |
| `LoadSkillLua(skillId)` | ... | table/nil | 加载技能Lua |
| `ResetAllCoolDowns(hero)` | ... | - | 重置所有冷却 |
| `GetHeroSkills(hero)` | ... | table | 获取英雄所有技能 |
| `GetSkillsByType(hero, skillType)` | ... | table | 按类型获取技能 |

### 5.3 BattleArea - 范围模块API

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `GetTargetsInArea(caster, skillConfig, mainTarget)` | ... | table | 获取范围内目标 |
| `IsTargetInArea(caster, target, areaConfig)` | ... | boolean | 检查目标是否在范围 |
| `GetSkillAreaConfig(skillId)` | ... | table | 获取技能范围配置 |
| `GetDefaultConfig()` | ... | table | 获取默认配置 |
| `CreateConfig(overrides)` | ... | table | 创建自定义配置 |
| `Init()` | - | - | 初始化模块 |

### 5.4 SkillExecutor - 技能执行器API

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `ExtractSkillEffects(skillData)` | ... | table | 提取技能效果 |
| `ExecuteDamage(hero, targets, damageConfig, skillParam)` | ... | boolean | 执行伤害 |
| `ExecuteBuff(hero, targets, buffConfig)` | ... | boolean | 执行Buff |
| `ExecuteHeal(hero, targets, healConfig)` | ... | boolean | 执行治疗 |
| `ExecuteSpell(hero, targets, spellConfig)` | ... | boolean | 执行法术 |
| `ExecuteSkill(hero, targets, skillData, skillConfig)` | ... | boolean | 执行完整技能 |

### 5.5 SkillLoader - 技能加载器API

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `Load(skillId)` | ... | table/nil, string/nil | 加载技能脚本 |
| `LoadSkillConfig(skillId)` | ... | table/nil, string/nil | 加载技能配置 |
| `Reload(skillId)` | ... | table/nil, string/nil | 热重载技能 |
| `Unload(skillId)` | ... | boolean | 卸载技能 |
| `ClearCache()` | - | - | 清除缓存 |
| `GetCacheInfo()` | - | table | 获取缓存统计 |
| `IsCached(skillId)` | ... | boolean | 检查是否在缓存 |

---

## 6. 典型技能示例

### 6.1 示例1: 普通攻击技能 (skill_131010101)

**技能特点**: 超人普通攻击，包含位移、伤害、Buff、特效

```lua
-- 技能配置结构
skill_131010101 = {
    Class = 2,                      -- 技能类别
    LuaFile = "",                   -- 无额外脚本
    keepRotation = false,
    
    -- 目标选择: 敌方
    targetsSelections = {
        castTarget = 1,             -- E_CAST_TARGET.Enemy
        tSConditions = { ... }
    },
    
    -- 动作序列
    actData = {
        -- 第1段: 攻击动作
        [1] = {
            -- 移动到目标
            LaunchMove = {
                MoveID = 10101,
                moveOffsetDis = -1.5,      -- 向前移动1.5单位
                triggerTimeS = 0.3666667
            },
            
            -- 动画
            cartoon = {
                animationname = "An_B_101_Skill_N_01",
                during = 1.4,
                TotalS = 0.8666667
            },
            
            -- 关键帧
            keyFrameDatas = {
                -- 关键帧1: 播放特效 (0.433秒)
                {
                    TriggerS = 0.4333333,
                    datatype = "DWCommon.EffectData",
                    data = "{ effectpath = 'Assets/.../FX_B_Superman_M02@Skill_N_03.prefab', ... }"
                },
                
                -- 关键帧2: 造成伤害 (0.467秒)
                {
                    TriggerS = 0.4666667,
                    datatype = "DWCommon.DamageData",
                    data = "{ attackType = 1, damageType = 1, hitType = 2, ... }"
                },
                
                -- 关键帧3: 施加Buff (0.5秒)
                {
                    TriggerS = 0.5,
                    datatype = "DWCommon.LaunchBuff",
                    data = "{ AssociateBuff = 1, ... }"
                },
                
                -- 关键帧4: 屏幕震动
                {
                    TriggerS = 0.4943333,
                    datatype = "DWCommon.CameraData",
                    data = "{ CameraShakeName = 'CameraShakeCfg_N_jitui', IsShake = true }"
                },
                
                -- 关键帧5: 播放音效
                {
                    TriggerS = 0,
                    datatype = "DWCommon.SoundData",
                    data = "{ soundid = 'SE_Hero_Superman_Skill_N' }"
                }
            }
        },
        
        -- 第2段: 返回原位
        [2] = {
            LaunchMove = {
                MoveID = 10103,             -- 后退移动
                isMoveBack = true
            },
            cartoon = {
                animationname = "An_B_101_MoveBwd"  -- 后退动画
            }
        }
    }
}
```

**执行流程**:
1. 动画触发(0s) → 音效播放
2. 位移触发(0.367s) → 英雄前移
3. 特效触发(0.433s) → 播放攻击特效
4. 伤害触发(0.467s) → 计算并造成伤害
5. Buff触发(0.5s) → 施加Buff(可能是增伤或减防)
6. 震动触发(0.494s) → 屏幕震动反馈
7. 后退触发 → 返回原位

### 6.2 示例2: 大招技能 (skill_131480201)

**技能特点**: 企鹅人大招(U1)，多段动画、条件分支、范围法术

```lua
skill_131480201 = {
    Class = 4,
    LuaFile = "13148",              -- 有额外脚本支持
    
    actData = {
        -- 第1段: 条件检查 (NotU1=true, campType=1)
        [1] = {
            actConditionn = { NotU1 = true, campType = 1 },
            keyFrameDatas = {
                -- 调用外部Lua函数
                {
                    datatype = "DWCommon.LuaData",
                    data = "{ FunctionName = 'g_actdata_combox', LuaName = 'WarEvent/130000001.lua' }"
                }
            }
        },
        
        -- 第2段: 开始特效 (NotU1=true, campType=2)
        [2] = {
            actConditionn = { NotU1 = true, campType = 2 },
            keyFrameDatas = {
                -- 黑屏特效
                {
                    datatype = "DWCommon.EffectData",
                    data = "{ effectpath = '.../FX_UI_Common_Heiping_01.prefab', target = 4 }"
                },
                -- 音效
                {
                    datatype = "DWCommon.SoundData",
                    data = "{ soundid = 'SE_Battle_Skill_U' }"
                }
            }
        },
        
        -- 第3段: 动画1 (NotU1=false, campType=1)
        [3] = {
            actConditionn = { NotU1 = false, campType = 1 },
            cartoon = {
                animationname = "An_B_148_Skill_U_01_0",
                during = 1.5
            },
            keyFrameDatas = {
                -- Timeline播放
                {
                    datatype = "DWCommon.TimelineData",
                    data = "{ timelineA = { during = 1.6, timelinePath = '.../148_U1_1' } }"
                },
                -- 条件动作
                {
                    datatype = "DWCommon.ActionforceData",
                    contidion = { FunctionName = "a_skill_13148_03_vfx_remove" }
                }
            }
        },
        
        -- 第4段: 动画2 (NotU1=false, campType=2)
        [4] = { ... },
        
        -- 第5段: 主要技能释放
        [5] = {
            cartoon = {
                animationname = "An_B_148_Skill_U_03",
                during = 1.4
            },
            keyFrameDatas = {
                -- 法术技能 (范围攻击)
                {
                    TriggerS = 0,
                    datatype = "DWCommon.LaunchSpell",
                    data = "{ SpellID = 131480201, ... }"
                },
                -- 命中特效
                {
                    TriggerS = 1.2,
                    datatype = "DWCommon.EffectData",
                    data = "{ effectpath = '.../FX_B_148_Skill_U03_02.prefab' }"
                },
                -- Lua回调: 敌人受击
                {
                    TriggerS = 1.2,
                    datatype = "DWCommon.LuaData",
                    data = "{ FunctionName = 'a_skill_13148_02_enemyHit' }"
                },
                -- Lua回调: 治疗
                {
                    TriggerS = 1.866667,
                    datatype = "DWCommon.LuaData",
                    data = "{ FunctionName = 'a_skill_13148_02_heal' }"
                }
            }
        }
    }
}
```

**特殊机制**:
1. **条件分支**: 通过 `actConditionn` 实现不同条件下的动作分支
2. **外部脚本**: 使用 `LuaData` 调用 `WarEvent/130000001.lua` 等外部脚本
3. **法术技能**: 使用 `LaunchSpell` 触发范围伤害效果
4. **自定义回调**: 使用 `a_skill_13148_02_enemyHit` 等函数处理特殊逻辑

### 6.3 示例3: 召唤技能 (skill_212060301)

**技能特点**: BOSS召唤小怪，多位置召唤、多阶段

```lua
skill_212060301 = {
    Class = 8,
    LuaFile = "21206",              -- 有额外脚本
    keepRotation = true,
    
    -- 目标选择: 自己
    targetsSelections = {
        castTarget = 2,             -- 友方
        tSConditions = { Num = 9, conditionDirection = 3, measureType = 2 }
    },
    
    actData = {
        -- 第1段: 前置条件检查
        [1] = {
            contidion = { FunctionName = "a_skill_21206_tokenSummon_pre" },
            targetsSelections = { castTarget = 2 }
        },
        
        -- 第2段: 第一波召唤 (位置4和5)
        [2] = {
            contidion = { FunctionName = "a_skill_21206_tokenSummon_1" },
            cartoon = {
                animationname = "An_B_21206_Skill_S_01",
                during = 3.066667
            },
            keyFrameDatas = {
                -- 召唤Token (位置4)
                {
                    TriggerS = 1.966667,
                    datatype = "DWCommon.TokenData",
                    data = "{ TokenAssociate = 1 }",
                    targetsSelections = { 
                        castTarget = 15,  -- 特殊目标类型
                        tSConditions = { wpType = 4 }  -- 位置4
                    }
                },
                -- 召唤Token (位置5)
                {
                    TriggerS = 1.5,
                    datatype = "DWCommon.TokenData",
                    data = "{ TokenAssociate = 1 }",
                    targetsSelections = { tSConditions = { wpType = 5 } }
                },
                -- 多个位置特效
                {
                    TriggerS = 1.5,
                    datatype = "DWCommon.EffectData",
                    data = "{ effectpath = '.../FX_B_21206_Skill_S01_04.prefab', fieldData = { placeType = 4 } }"
                },
                {
                    TriggerS = 1.5,
                    datatype = "DWCommon.EffectData",
                    data = "{ effectpath = '.../FX_B_21206_Skill_S01_04.prefab', fieldData = { placeType = 5 } }"
                }
            }
        },
        
        -- 第3段: 第二波召唤 (位置4,5,6,8)
        [3] = {
            contidion = { FunctionName = "a_skill_21206_tokenSummon_2" },
            keyFrameDatas = {
                -- 位置4
                { TriggerS = 1.333333, datatype = "DWCommon.TokenData", targetsSelections = { tSConditions = { wpType = 4 } } },
                -- 位置5
                { TriggerS = 1.6, datatype = "DWCommon.TokenData", targetsSelections = { tSConditions = { wpType = 5 } } },
                -- 位置6
                { TriggerS = 1.8, datatype = "DWCommon.TokenData", targetsSelections = { tSConditions = { wpType = 6 } } },
                -- 位置8
                { TriggerS = 2.066667, datatype = "DWCommon.TokenData", targetsSelections = { tSConditions = { wpType = 8 } } }
            }
        }
    }
}
```

**召唤机制**:
1. **TokenAssociate**: 关联召唤物配置ID
2. **wpType**: 指定召唤位置 (4,5,6,8分别对应不同站位)
3. **分阶段召唤**: 通过不同act段实现分批召唤
4. **前置检查**: 使用 `a_skill_21206_tokenSummon_pre` 检查召唤条件

---

## 7. 实现与设计文档的差异

### 7.1 对比表

| 特性 | 设计文档 | 实际实现 | 差异说明 |
|------|----------|----------|----------|
| **技能配置格式** | 简洁的Lua表配置 | JSON + Lua混合格式 | 实际使用res_skill.json作为基础配置，skill_{ID}.lua作为动作配置 |
| **技能释放流程** | 简单三步:检查→扣除→应用 | 复杂的多阶段流程 | 实际有12个阶段，包含关键帧解析、Lua脚本执行等 |
| **范围系统** | 三层:射程→范围→目标 | 已实现，但略有不同 | 实际增加了阵型保护、伤害衰减等高级特性 |
| **关键帧系统** | 未提及 | 核心机制 | 实际使用actData关键帧来控制技能时序 |
| **技能脚本** | Execute函数形式 | 两种形式并存 | 既支持全局表形式也支持Execute函数形式 |
| **Buff配置** | 简洁的table | 复杂的特效配置 | 实际Buff包含SEstart/SEloop/SEend等多个特效阶段 |
| **技能类型** | 设计为4种 | 实际映射 | Type 1=普通, 2=主动, 3=大招, 4=被动 |
| **能量系统** | 简单计算公式 | 完整模块 | 实际有BattleEnergy独立模块管理 |
| **被动技能** | 有示例说明 | 框架预留 | 实际被动技能框架已预留，但具体效果需通过Buff系统实现 |
| **技能标签** | PREVENT_COUNTER等 | 未完全实现 | 设计文档中的标签系统在实际中部分通过hitType实现 |

### 7.2 重要实现细节

#### 7.2.1 技能ID编码规则

**设计文档**: 未明确说明

**实际实现**:
```
完整技能ID (9位) = ClassID (7位) * 100 + SkillLevel
示例: 131010101 = 1310101 * 100 + 1

Lua文件名: skill_{完整技能ID}.lua
示例: skill_131010101.lua

脚本缓存Key: 使用9位完整ID
```

#### 7.2.2 关键帧数据解析

**设计文档**: 未提及

**实际实现**:
```lua
-- 关键帧data字段是JSON字符串，需要解析
local function StrToTable(str)
    local success, result = pcall(function()
        return load("return " .. str)()
    end)
    return success and result or nil
end
```

#### 7.2.3 技能脚本双模式支持

**设计文档**: 单一Execute函数模式

**实际实现**:
```lua
-- 模式1: 全局表形式 (原工程)
skill_131010101 = { ... }
-- 加载后从 _G["skill_131010101"] 获取

-- 模式2: Execute函数形式 (扩展)
local Skill = {}
function Skill.Execute(hero, targets, skill)
    -- 自定义逻辑
end
return Skill
```

#### 7.2.4 范围系统增强

**设计文档**: 基本的三层范围系统

**实际实现**:
```lua
-- 增加了更多范围类型
AREA_TYPE = {
    SINGLE = "SINGLE",
    ROW = "ROW",
    COLUMN = "COLUMN",
    CROSS = "CROSS",
    CHAIN = "CHAIN",           -- 链式弹射
    FULL = "FULL",
    RANDOM = "RANDOM",
    RANDOM_RANGE = "RANDOM_RANGE",
    FRONT_ROW = "FRONT_ROW",   -- 前排
    BACK_ROW = "BACK_ROW",     -- 后排
    CIRCLE = "CIRCLE",         -- 圆形
    ...
}

-- 增加了阵型保护规则
respectFormation = true  -- 前排存活时只能攻击前排

-- 增加了伤害衰减
damageDecay = 0.3  -- 每目标衰减30%
mainTargetBonus = 0.2  -- 主目标额外20%伤害
```

#### 7.2.5 技能效果数据类型

**设计文档**: 简单的damageRate配置

**实际实现**:
```lua
-- 从SkillParam获取伤害倍率
local damageRate = skillParam and skillParam[1] or 10000  -- 默认100%
-- 倍率是万分比: 10000 = 100%

-- 复杂的伤害数据结构
damageData = {
    attackType = 1,      -- 攻击类型
    damageType = 1,      -- 伤害类型
    hitType = 0,         -- 命中类型 (0=普通, 1=暴击, 2=格挡等)
    cSVSkillAssociate = 1,
    Sender = { IDS = {} },
    Target = { IDS = {} }
}
```

#### 7.2.6 被动技能实现

**设计文档**: 完整的被动技能示例

**实际实现**:
```lua
-- 被动技能框架已预留
E_SKILL_TYPE_PASSIVE = 4

-- 但实际被动效果主要通过Buff系统实现
-- 被动技能的触发需要在战斗逻辑中添加对应的事件监听
-- 例如: 吸血效果可以通过在造成伤害时触发Buff来实现
```

### 7.3 设计建议

基于实现与设计的差异，提出以下改进建议：

1. **统一配置格式**: 考虑统一使用Lua配置，避免JSON和Lua混用
2. **完善被动技能**: 添加完整的被动技能触发框架
3. **技能标签系统**: 实现设计文档中的PREVENT_COUNTER等技能标签
4. **文档同步**: 更新设计文档，包含关键帧系统等实际实现的重要机制

### 7.4 架构问题与重构建议

#### 7.4.1 battle_skill.lua 代码量过大问题

**问题描述**:
- `modules/battle_skill.lua` 当前约 4300 行代码，职责混杂
- 包含技能实例管理、冷却系统、释放流程、目标选择、Lua加载等多个职责
- 违背了单一职责原则，维护困难

**参考方案** (借鉴 battle_range 拆分模式):

battle_range 已成功拆分为三层架构：
- `battle_range_rules.lua` - 规则层: 常量定义、位置判断规则
- `battle_range_mechanics.lua` - 机制层: 距离计算、射程检查算法
- `battle_range.lua` - 兼容层: 向后兼容的 API 聚合

**建议拆分方案**:

| 新文件 | 职责 | 预估行数 |
|--------|------|----------|
| `battle_skill_system.lua` | 系统层: 技能实例管理、冷却系统、释放流程编排 | ~1200 行 |
| `battle_skill_mechanics.lua` | 机制层: 目标选择算法、条件检查、技能效果计算 | ~1000 行 |
| `battle_skill_rules.lua` | 规则层: 技能类型常量、释放规则、验证规则 | ~800 行 |
| `battle_skill.lua` | 兼容层: 保留原有 API，委托给新模块 | ~500 行 |

**拆分的具体收益**:
1. **可测试性**: 各层可独立单元测试
2. **可维护性**: 修改目标选择逻辑不影响冷却系统
3. **可复用性**: 规则层可被 AI 决策模块复用
4. **团队协作**: 不同开发者可同时修改不同层

---

## 附录

### A.1 目录结构

```
mini-battle-simulator/
├── bin/                        # 完整集成测试脚本
│   ├── test_level_battle.lua   # 等级输入随机战斗测试
│   ├── test_random_battle.lua  # 随机战斗测试
│   └── test_viewport_battle.lua # Viewport 2D渲染战斗测试
├── tests/                      # 快速单元测试
│   ├── phase1_test.lua         # 第一阶段功能验证
│   ├── quick_test.lua          # 快速功能测试
│   └── test_area.lua           # 范围系统测试
├── config/
│   ├── skill/              # 技能动作配置
│   │   ├── skill_131010101.lua
│   │   └── ...
│   ├── spell/              # 技能效果配置
│   │   ├── spell_10000.lua
│   │   └── ...
│   ├── buff/               # Buff配置
│   │   ├── buff_10001.lua
│   │   └── ...
│   ├── move/               # 移动配置
│   │   └── move_10101.lua
│   ├── skills/
│   │   └── skill_area_configs.lua  # 范围配置
│   ├── skill_config.lua    # 技能配置加载器
│   ├── skill_data.lua      # 技能数据
│   └── res_skill.json      # 技能基础配置表
├── core/
│   ├── skill_executor.lua  # 技能执行器
│   ├── battle_script_exp.lua   # 脚本API
│   └── skill_loader.lua    # 技能加载器
├── modules/
│   ├── battle_skill.lua    # 技能系统核心
│   ├── battle_area.lua     # 范围系统
│   └── battle_range.lua    # 射程系统
└── design/
    └── 02-核心系统/
        └── 技能系统.md      # 设计文档
```

### A.2 测试体系说明

项目采用双层测试架构：

#### 完整集成测试 (bin/test_*.lua)

位于 `bin/` 目录，需要完整游戏环境，用于验证端到端功能：

| 测试文件 | 功能描述 | 使用场景 |
|----------|----------|----------|
| `test_level_battle.lua` | 等级输入随机战斗测试，支持自定义等级、英雄/敌人数量、更新速度 | 验证平衡性、模拟真实战斗场景 |
| `test_random_battle.lua` | 基础随机战斗测试，快速验证战斗流程 | 回归测试、快速验证 |
| `test_viewport_battle.lua` | Viewport 2D渲染战斗测试，展示标准回合制表现 | UI验证、视觉效果测试 |

**运行方式**:
```bash
cd bin
lua test_level_battle.lua 50 3 4 500    # 等级50, 3英雄, 4敌人, 500ms延迟
lua test_random_battle.lua 60 3 4       # 等级60, 3英雄, 4敌人
lua test_viewport_battle.lua 50 3 4 500 # Viewport模式战斗
```

#### 快速单元测试 (tests/*.lua)

位于 `tests/` 目录，轻量级测试，用于快速验证特定模块：

| 测试文件 | 功能描述 | 使用场景 |
|----------|----------|----------|
| `phase1_test.lua` | 第一阶段功能验证测试 | 里程碑验证 |
| `quick_test.lua` | 快速功能测试集，覆盖核心功能点 | 开发中快速验证 |
| `test_area.lua` | 范围系统专用测试，验证各种范围类型计算 | 范围系统迭代验证 |

**运行方式**:
```bash
cd tests
lua quick_test.lua      # 快速测试
lua test_area.lua       # 范围系统测试
```

#### 测试分层对比

| 特性 | bin/test_*.lua (集成测试) | tests/*.lua (单元测试) |
|------|---------------------------|------------------------|
| 依赖范围 | 完整游戏环境 | 单个模块 |
| 运行速度 | 较慢 (模拟完整战斗) | 快 (秒级) |
| 覆盖范围 | 端到端流程 | 单一功能点 |
| 使用阶段 | 回归测试、发布前验证 | 开发迭代、调试 |
| 失败定位 | 问题范围大 | 精准定位 |

### A.3 关键术语表

| 术语 | 英文 | 说明 |
|------|------|------|
| 关键帧 | KeyFrame | 技能时间线上的触发点 |
| 动作数据 | actData | 技能的动作序列配置 |
| 范围类型 | AreaType | 技能影响的目标范围 |
| 目标阵营 | TargetCamp | 目标所属阵营(敌方/友方) |
| 技能参数 | SkillParam | 技能的伤害倍率等参数 |
| 万分比 | 1/10000 | 伤害倍率的单位 |
| Token | Token | 召唤物 |
| ClassID | ClassID | 技能类ID(7位) |

---

### A.3 battle_skill.lua 代码组织

**项目定位说明**: Mini Battle Simulator 是独立小游戏，不追求过度工程化。

#### 当前状态

| 指标 | 数值 | 评估 |
|------|------|------|
| 代码行数 | ~1,191 行 | ✅ 可接受 (< 2000行) |
| 模块复杂度 | 中等 | ✅ 无需拆分 |

#### 内部组织结构

当前 `battle_skill.lua` 内部按 Lua table 组织：

```lua
-- battle_skill.lua 内部结构
local BattleSkill = {}       -- 对外接口
local SkillSystem = {}       -- 系统层逻辑（生命周期、冷却）
local SkillMechanics = {}    -- 机制层逻辑（目标选择、条件检查）
local SkillUtils = {}        -- 工具函数

-- 对外暴露
function BattleSkill.Cast(...) ... end
function BattleSkill.GetCoolDown(...) ... end

return BattleSkill
```

#### 何时考虑拆分

| 条件 | 当前状态 | 决策 |
|------|----------|------|
| 行数 > 2000 | 1,191 | ❌ 不拆分 |
| 多模块复用 | 仅 skill 使用 | ❌ 不拆分 |
| 测试困难 | 可测试 | ❌ 不拆分 |
| 维护困难 | 可读性良好 | ❌ 不拆分 |

**结论**: 保持单文件，用 table 内部组织即可。

#### 如需未来拆分

参考 `battle_range` 模式（已拆三层是出于历史复用需求）：
- `battle_skill_rules.lua` - 常量定义
- `battle_skill_mechanics.lua` - 机制实现  
- `battle_skill.lua` - 系统层 + 兼容入口

---

*文档结束*
