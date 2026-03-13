# Mini Battle Simulator

一个基于 Lua 的轻量级战斗模拟器，用于快速测试和验证游戏战斗逻辑。

## 项目概述

Mini Battle Simulator 是一个独立的战斗模拟系统，旨在帮助开发者在不依赖完整游戏客户端的情况下测试和调试战斗相关功能。它完整实现了游戏战斗的核心逻辑，包括技能释放、伤害计算、Buff 系统、能量系统等。

### 主要特性

- **完整的战斗系统**：支持回合制战斗、行动顺序、技能释放、伤害计算等核心功能
- **模块化设计**：各功能模块独立，便于测试和扩展
- **命令行界面**：无需图形界面即可运行和测试
- **可复现的战斗结果**：通过种子控制随机数，确保战斗结果可复现
- **丰富的配置支持**：支持英雄、技能、Buff 等多种配置
- **技能脚本支持**：提供 BattleScriptExp API 层，支持技能脚本编写

## 项目结构

```
MiniBattleSimulator/
├── main.lua                    # 主入口文件
├── core/                       # 核心系统
│   ├── battle_enum.lua         # 战斗枚举定义
│   ├── battle_types.lua        # 战斗类型定义
│   ├── battle_math.lua         # 数学工具（随机数生成）
│   ├── battle_event.lua        # 事件系统
│   ├── battle_timer.lua        # 计时器系统
│   ├── battle_formula.lua      # 战斗公式
│   ├── battle_script_exp.lua   # 技能脚本 API 层
│   └── skill_loader.lua        # 技能加载器
├── modules/                    # 战斗模块
│   ├── battle_main.lua         # 战斗主控制
│   ├── battle_formation.lua    # 阵型管理
│   ├── battle_action_order.lua # 行动顺序
│   ├── battle_attribute.lua    # 属性管理
│   ├── battle_skill.lua        # 技能系统
│   ├── battle_buff.lua         # Buff 系统
│   ├── battle_energy.lua       # 能量系统
│   ├── battle_dmg_heal.lua     # 伤害/治疗
│   ├── battle_passive_skill.lua# 被动技能
│   ├── battle_logic.lua        # 战斗逻辑
│   └── battle_skill_seq.lua    # 技能序列
├── config/                     # 配置数据
│   ├── hero_data.lua           # 英雄配置
│   ├── skill_data.lua          # 技能配置
│   ├── buff/                   # Buff 配置目录
│   ├── move/                   # 移动配置目录
│   └── spell/                  # 法术配置目录
├── utils/                      # 工具库
│   ├── logger.lua              # 日志工具
│   ├── inspect.lua             # 数据检查工具
│   └── json.lua                # JSON 处理
└── test/                       # 测试
    ├── test_simple_battle.lua  # 简单战斗测试
    └── test_battle_config.lua  # 战斗配置测试
```

## 安装

### 环境要求

- **Lua 5.3+** 或 **LuaJIT 2.0+**

### 运行方式

```bash
# 进入项目目录
cd MiniBattleSimulator

# 运行主程序
lua main.lua
```

## 使用方法

### 启动模拟器

运行 `main.lua` 后将显示交互式菜单：

```
========================================
    Mini Battle Simulator v1.0
========================================

请选择操作:
  1. 运行简单战斗测试
  2. 运行完整战斗模拟
  3. 退出

请输入选项 (1-3):
```

### 运行测试

```bash
# 运行简单战斗测试
lua test/test_simple_battle.lua
```

### 创建自定义战斗

参考 `test/test_simple_battle.lua` 创建自定义战斗：

```lua
-- 1. 加载模块
local BattleMain = require("battle_main")

-- 2. 定义英雄
local hero = {
    configId = 1001,
    name = "测试英雄",
    hp = 5000,
    maxHp = 5000,
    atk = 800,
    def = 300,
    speed = 120,
    skills = {1001},
}

-- 3. 创建战斗配置
local battleBeginState = {
    teamLeft = {hero},
    teamRight = {enemy},
    seedArray = {123456789, 362436069, 521288629, 88675123},
}

-- 4. 启动战斗
BattleMain.Start(battleBeginState, function(result)
    print("战斗结束，获胜方：" .. result.winner)
end)

-- 5. 运行战斗循环
while not BattleMain.GetBattleResult().isFinished do
    BattleMain.Update()
end
```

## 架构说明

### 核心系统

| 模块 | 说明 |
|------|------|
| battle_math | 随机数生成器，支持可复现的随机序列 |
| battle_event | 发布-订阅模式的事件系统 |
| battle_timer | 延迟执行和定时任务管理 |
| battle_formula | 伤害、治疗等计算公式 |

### 战斗模块

| 模块 | 说明 |
|------|------|
| battle_formation | 管理战斗双方阵型，处理英雄位置关系 |
| battle_action_order | 根据速度计算行动顺序 |
| battle_attribute | 英雄属性管理，支持动态修改 |
| battle_skill | 技能释放、冷却管理 |
| battle_buff | Buff 添加、移除、效果计算 |
| battle_energy | 能量条/能量点系统 |
| battle_dmg_heal | 伤害计算、治疗、恢复逻辑 |
| battle_passive_skill | 被动技能触发管理 |

### API 层 (BattleScriptExp)

为技能脚本提供的统一接口：

- **Math**: `Rand()`, `RandInt()`, `Floor()`, `Ceil()`
- **Damage/Heal**: `MakeDmg()`, `MakeHeal()`, `MakeRecovery()`, `PayHP()`
- **Buff**: `AddBuff()`, `DelBuffByMainType()`, `GetBuffStackNumBySubType()`
- **Attribute**: `GetCurHp()`, `GetMaxHp()`, `ModifyAttribute()`
- **Target**: `GetRandomEnemyInstanceId()`, `GetEnemySortByAttrId()`
- **Energy**: `AddEnergyBar()`, `GetUltimateSkillCost()`

## 配置说明

### 英雄配置 (config/hero_data.lua)

```lua
[1001] = {
    id = 1001,
    name = "狂战士·格罗姆",
    hp = 5000,
    atk = 200,
    def = 150,
    speed = 100,
    critRate = 0.15,
    critDmg = 1.5,
    skills = {1001, 1002},
}
```

### 技能配置 (config/skill_data.lua)

```lua
[1001] = {
    skillId = 1001,
    name = "普通攻击",
    skillType = 1,        -- 1=普通攻击, 2=必杀技
    damageRate = 1.0,     -- 伤害倍率
    cooldown = 0,         -- 冷却回合
    targetType = 1,       -- 目标类型
    energyCost = 0,       -- 能量消耗
    energyGain = 10,      -- 能量获取
}
```

### Buff 配置 (config/buff/)

Buff 配置文件命名格式：`buff_{buffId}.lua`

```lua
-- buff_10001.lua
return {
    buffId = 10001,
    name = "攻击提升",
    mainType = 1,         -- 1=增益, 2=减益, 3=控制
    subType = 10101,
    duration = 3,         -- 持续回合
    effects = {
        {type = "atk", value = 100},
    },
}
```

## 测试

### 运行所有测试

```bash
lua test/test_simple_battle.lua
```

### 测试覆盖范围

- 模块加载测试
- 英雄创建与配置
- 战斗初始化
- 技能释放系统
- 伤害计算
- 战斗结束检测
- 资源清理

## 开发指南

### 添加新模块

1. 在 `modules/` 目录创建新模块文件
2. 实现 `Init()` 和 `OnFinal()` 函数
3. 在 `battle_main.lua` 中注册模块

### 添加新技能

1. 在 `config/skill_data.lua` 中添加技能配置
2. 如需自定义逻辑，在 `config/spell/` 创建技能脚本

### 添加新 Buff

1. 在 `config/buff/` 创建 `buff_{id}.lua` 文件
2. 定义 Buff 属性和效果

## 许可证

MIT License

Copyright (c) 2024 Mini Battle Simulator Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
