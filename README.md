# Mini Battle Simulator 使用指南

## 快速开始

### 1. 运行主程序
```bash
cd MiniBattleSimulator
lua55 main.lua
```

### 2. 可用的测试脚本

#### 查看英雄属性（含Prop数组）
```bash
lua55 test_prop.lua
```

#### 测试战斗属性传递
```bash
lua55 test_battle_attrs.lua
```

#### 运行完整战斗模拟
```bash
lua55 test_main_battle.lua
```

#### 运行带技能选择的战斗
```bash
lua55 run_skill_battle.lua
```

#### 调试行动顺序
```bash
lua55 test_debug_action.lua
```

### 3. 模块说明

#### 核心模块 (core/)
- `battle_types.lua` - 战斗类型定义
- `battle_enum.lua` - 战斗枚举值
- `battle_default_types.lua` - 默认类型

#### 配置模块 (config/)
- `ally_data.lua` - 英雄数据加载（从res_ally_info.json读取属性）
- `enemy_data.lua` - 敌人数据加载
- `skill_data.lua` - 技能数据加载
- `buff_data.lua` - Buff数据加载

#### 战斗模块 (modules/)
- `battle_main.lua` - 战斗主控制器
- `battle_formation.lua` - 战斗阵型管理
- `battle_attribute.lua` - 战斗属性系统
- `battle_action_order.lua` - 行动顺序系统
- `battle_round.lua` - 回合管理
- `battle_skill.lua` - 技能系统
- `battle_buff.lua` - Buff系统
- `battle_damage.lua` - 伤害计算
- `battle_formula.lua` - 战斗公式

### 4. 创建自定义战斗

```lua
local BattleMain = require("modules.battle_main")
local HeroData = require("config.hero_data")
local EnemyData = require("config.enemy_data")

-- 初始化数据
HeroData.Init()
EnemyData.Init()

-- 创建战斗配置
local beginState = {
    teamLeft = {},   -- 左侧队伍（英雄）
    teamRight = {},  -- 右侧队伍（敌人）
    seedArray = {123456789, 362436069, 521288629, 88675123}  -- 随机种子
}

-- 添加英雄（heroId, level, star）
local hero = HeroData.ConvertToHeroData(13101, 60, 5)
table.insert(beginState.teamLeft, hero)

-- 添加敌人（enemyId, level）
local enemy = EnemyData.CreateEnemyBattleData(20701, 60)
table.insert(beginState.teamRight, enemy)

-- 启动战斗
BattleMain.Start(beginState, function(result)
    print("战斗结果: " .. (result.isWin and "胜利" or "失败"))
    print("总回合: " .. result.totalRound)
end)
```

### 5. 属性系统

#### 标准属性（从Prop数组读取）
- `spd` - 速度（属性ID 18）
- `crt` - 暴击率（属性ID 21）
- `crtd` - 暴击伤害（属性ID 22）
- `hit` - 命中率（属性ID 24）
- `res` - 闪避率（属性ID 25）
- `blk` - 格挡率（属性ID 26）

#### 额外属性（保存但不参与战斗）
- 152, 153, 171, 181等 - 用于战力计算，不直接影响战斗

### 6. 战斗流程

1. **初始化阶段**
   - 加载英雄/敌人数据
   - 解析Prop数组属性
   - 初始化BattleAttribute系统

2. **战斗阶段**
   - 行动顺序排序（基于速度）
   - 回合循环
   - 技能释放
   - 伤害计算

3. **结束阶段**
   - 判断胜负
   - 返回战斗结果

## 注意事项

1. 所有属性名称使用小写（atk, def, hp, spd, crt等）
2. 速度从res_ally_info.json的Prop数组中读取（属性ID 18）
3. 战斗公式使用简化版本：damage = atk - def
