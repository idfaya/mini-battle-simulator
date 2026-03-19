# 最小可运行单机战斗模拟器工程计划

## 项目目标
基于 BattleEditor 创建一个完全独立、纯Lua的最小战斗模拟器工程，支持：
1. 脱离Unity和服务器运行
2. 复用原项目的角色和技能数据
3. 支持技能调试和战斗平衡测试
4. **命令行交互界面** - 实时展示战斗过程

---

## 阶段一：核心基础设施搭建

### 任务1.1：创建工程目录结构
- 创建 `MiniBattleSimulator/` 根目录
- 创建子目录：`core/`, `modules/`, `config/`, `utils/`, `test/`, `skills/`, `ui/`

### 任务1.2：实现基础工具函数
文件：`utils/logger.lua`
- 实现 Log/LogError/LogWarning 函数
- 支持不同日志级别（DEBUG/INFO/WARN/ERROR）
- 支持彩色输出（ANSI颜色码）
- 支持日志写入文件

文件：`utils/inspect.lua`
- 实现 table 格式化打印函数
- 便于调试输出

文件：`utils/json.lua`
- 实现 JsonEncode/JsonDecode
- 支持战斗状态序列化

### 任务1.3：实现核心常量定义
文件：`core/battle_enum.lua`
- 从原项目复制所有枚举常量
- E_SKILL_TYPE, E_BATTLE_STATE, E_CAST_TARGET 等
- 被动技能触发时机常量
- Buff类型常量

文件：`core/battle_types.lua`
- 从原项目复制默认数据结构
- Vector3_Default, DamageData_Default 等

---

## 阶段二：核心战斗系统实现

### 任务2.1：实现战斗计时器
文件：`core/battle_timer.lua`
- 实现 BattleTimer.Init/OnFinal
- 实现 AddTimer/AddTickTimer
- 实现 Update 帧更新
- 一帧 = 30 tick

### 任务2.2：实现战斗事件系统
文件：`core/battle_event.lua`
- 实现 AddListener/RemoveListener
- 实现 Publish 事件发布
- 支持带参数的事件

### 任务2.3：实现随机数系统
文件：`core/battle_math.lua`
- 实现 BattleMath.Init(seedArray)
- 实现 Random/RandomProb
- 实现 Floor/Ceil
- 保证与服务器相同的随机序列

### 任务2.4：实现伤害计算
文件：`core/battle_formula.lua`
- 实现伤害公式
- 实现属性计算
- 支持暴击、格挡等计算

---

## 阶段三：战斗核心模块实现

### 任务3.1：实现阵型管理
文件：`modules/battle_formation.lua`
- 实现 BattleFormation.Init(beginState, fieldInfo)
- 实现英雄创建和初始化
- 实现 FindHeroByInstanceId
- 实现 GetTeams/GetFriendTeam/GetEnemyTeam
- 实现 GetRandomEnemyInstanceId 等目标选择函数
- 实现英雄死亡和复活逻辑

### 任务3.2：实现属性系统
文件：`modules/battle_attribute.lua`
- 实现 BattleAttribute.Init
- 实现 GetHeroCurHp/GetHeroMaxHp
- 实现 SetHpByVal/SetHpByPercent
- 实现 UpdateHeroAttribute
- 实现速度、攻击、防御等属性计算

### 任务3.3：实现Buff系统
文件：`modules/battle_buff.lua`
- 实现 BattleBuff.Init
- 实现 Add/DelBuff
- 实现 GetBuffStackNumBySubType
- 实现 DelBuffBySubType/DelBuffByMainType
- 实现 Buff结算逻辑
- 实现控制状态判断(IsHeroUnderControl)

### 任务3.4：实现技能系统
文件：`modules/battle_skill.lua`
- 实现 BattleSkill.Init
- 实现技能创建和初始化
- 实现 GetSkillCurCoolDown/SetSkillCurCoolDown
- 实现技能释放逻辑(CastSmallSkill/CastSkillInSeq)
- 实现技能目标选择

### 任务3.5：实现技能序列
文件：`modules/battle_skill_seq.lua`
- 实现 BattleSkillSeq.Init
- 实现 AddUltimateSkill
- 实现 GetSkillInSeq
- 实现被动技能队列管理

### 任务3.6：实现被动技能系统
文件：`modules/battle_passive_skill.lua`
- 实现 BattlePassiveSkill.Init
- 实现被动技能触发逻辑
- 实现 InsertPassiveSkill/RemovePassiveSkill
- 实现各时机触发(RunSkillOnBattleBegin等)

### 任务3.7：实现行动顺序
文件：`modules/battle_action_order.lua`
- 实现 BattleActionOrder.Init
- 实现 Run 选择下一个行动英雄
- 实现 OnHeroActionFinish
- 实现 ChangeHeroDistance

### 任务3.8：实现能量系统
文件：`modules/battle_energy.lua`
- 实现 BattleEnergy.Init
- 实现 AddPoint/AddEnergy
- 实现能量条计算

### 任务3.9：实现伤害治疗
文件：`modules/battle_dmg_heal.lua`
- 实现 MakeDmg 伤害计算
- 实现 MakeHeal 治疗
- 实现 MakeDmgPlus 额外伤害
- 实现吸血逻辑(Bloodthirsty)

---

## 阶段四：战斗主控实现

### 任务4.1：实现战斗逻辑主控
文件：`modules/battle_logic.lua`
- 实现 BattleLogic.Init
- 实现 BattleLogic.Start
- 实现 BeginNextAction 核心循环
- 实现 CastSmallSkill 普通攻击
- 实现 CastHeroSkillInSeq 技能释放
- 实现 BattleLogic.Pause/Resume
- 实现 OnBattleResult 战斗结算

### 任务4.2：实现战斗主入口
文件：`modules/battle_main.lua`
- 实现 BattleMain.Start
- 实现 Update 帧更新调用
- 实现 Pause/Resume/Quit
- 实现战斗状态管理

---

## 阶段五：BattleScriptExp API实现

### 任务5.1：实现核心API
文件：`core/battle_script_exp.lua`
- 实现所有 BattleScriptExp API
- 包括：伤害、治疗、Buff、属性、技能、能量、目标选择等
- 保持与原项目相同的接口

### 任务5.2：实现技能加载器
文件：`core/skill_loader.lua`
- 实现技能脚本的动态加载
- 实现 require 技能文件
- 管理技能Lua模块缓存

---

## 阶段六：配置数据准备

### 任务6.1：创建英雄配置
文件：`config/hero_data.lua`
- 定义英雄基础属性
- 定义英雄技能列表
- 导出原项目英雄数据

### 任务6.2：创建技能配置
文件：`config/skill_data.lua`
- 定义技能基础数据
- 定义技能效果参数
- 关联技能Lua文件

### 任务6.3：复制原项目数据
- 复制 SpellLua/*.lua 到 config/spell/
- 复制 MoveLua/*.lua 到 config/move/
- **完整复制 BuffLua/*.lua 到 config/buff/**
  - BuffLua 包含大量 Unity 特效/音效配置（SEstart, SEend, effectpath, soundid 等）
  - 在纯 Lua 环境下这些字段会被忽略
  - 保留完整数据结构，便于后续扩展

---

## 阶段七：命令行UI实现

### 任务7.1：实现命令行渲染器
文件：`ui/console_renderer.lua`
- 实现清屏功能
- 实现光标定位
- 实现颜色输出（ANSI转义码）
- 实现进度条绘制

### 任务7.2：实现战斗画面展示
文件：`ui/battle_display.lua`
- 实现血条可视化（ASCII图形）
```
英雄A [████████░░] 80/100  ⚔️ [大招就绪]
英雄B [██████░░░░] 60/100  ⏳ [普攻CD:1]
```
- 实现队伍对比展示（左右分栏）
- 实现回合信息展示
- 实现行动顺序条展示

### 任务7.3：实现战斗事件动画
文件：`ui/battle_animation.lua`
- 实现技能释放文字动画
```
>>> 英雄A 使用 【终极技能-烈焰风暴】！
    🔥 对 敌人X 造成 150 点暴击伤害！
    💀 敌人X 倒下了！
```
- 实现伤害数字飘字效果（控制台字符动画）
- 实现Buff添加/移除提示

### 任务7.4：实现交互菜单
文件：`ui/battle_menu.lua`
- 实现主菜单（开始战斗、加载配置、查看英雄、释放技能等）
- 实现英雄选择菜单
- 实现技能选择菜单
- 实现确认/取消交互

### 任务7.5：实现实时状态面板
文件：`ui/status_panel.lua`
- 实现顶部状态栏（回合数、战斗状态）
- 实现底部操作提示
- 实现快捷键提示

### 任务7.6：实现BattleEditor命令行版
文件：`ui/battle_editor_cli.lua`
- 实现 StartEditor 启动战斗
- 实现 DoSkill 手动释放技能（交互式选择）
- 实现 DoAuto 自动/手动切换
- 实现 GetHeroAttrTable 获取属性（表格展示）
- 实现 GetHeroSkillList 获取技能列表
- 实现 DoSkillReload 热重载技能
- 实现实时战斗监控（自动刷新画面）

### 任务7.7：实现测试工具
文件：`ui/battle_tester_cli.lua`
- 实现批量战斗测试（进度条展示）
- 实现战斗结果统计（表格输出）
- 实现伤害输出分析（排行榜）

---

## 阶段八：测试验证

### 任务8.1：编写单元测试
文件：`test/test_battle_core.lua`
- 测试计时器系统
- 测试事件系统
- 测试属性计算
- 测试Buff系统

### 任务8.2：编写集成测试
文件：`test/test_simple_battle.lua`
- 测试完整战斗流程
- 测试技能释放
- 测试战斗结算

### 任务8.3：验证原项目技能兼容性
- 加载原项目技能脚本
- 验证技能效果
- 修复兼容性问题

### 任务8.4：UI交互测试
- 测试菜单导航
- 测试实时画面刷新
- 测试键盘快捷键

---

## 阶段九：文档和优化

### 任务9.1：编写使用文档
- 编写 README.md
- 编写 API 文档
- 编写技能开发指南
- 编写命令行操作手册

### 任务9.2：性能优化
- 优化高频调用函数
- 减少内存分配
- 添加性能统计
- 优化画面刷新性能

---

## 技术要点

### 依赖处理
| 原依赖 | 替代方案 |
|--------|----------|
| UnityEngine.Time | 自己维护帧计数器 |
| UnityEngine.GameObject | 使用纯数据模型 |
| SceneManager | 直接初始化 |
| UIManager | **命令行UI替代** |
| AudioManager | 移除音效（或用字符提示替代） |
| BattleAvatarMgr | 移除模型加载 |
| BattleRender | **命令行渲染器替代** |
| BattleEffectMgr | **文字动画替代** |

### 命令行UI设计

#### 主界面布局
```
┌─────────────────────────────────────────────────────────────┐
│  BattleEditor v1.0                    回合: 5/30  [进行中]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [左方队伍]                              [右方队伍]         │
│  ┌─────────────────────────┐            ┌─────────────────┐ │
│  │ 英雄A [████████░░] 80%  │            │ 敌人X [████░░░░] │ │
│  │       [大招⚡] [Buff🔥] │            │       [眩晕💫]   │ │
│  ├─────────────────────────┤            ├─────────────────┤ │
│  │ 英雄B [██████░░░░] 60%  │            │ 敌人Y [████████] │ │
│  │       [普攻⏳ CD:1]     │            │       [中毒☠️]   │ │
│  └─────────────────────────┘            └─────────────────┘ │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  >>> 英雄A 使用 【烈焰斩】 攻击 敌人X                         │
│      造成 125 点暴击伤害！💥                                  │
│      敌人X 触发被动 【反击】！                                │
├─────────────────────────────────────────────────────────────┤
│  [1]开始 [2]暂停 [3]自动 [4]技能 [5]加速 [Q]退出              │
└─────────────────────────────────────────────────────────────┘
```

#### 交互流程
```
1. 启动 -> 显示主菜单
2. 选择"开始战斗" -> 加载配置 -> 进入战斗画面
3. 战斗画面实时刷新（每500ms或每次事件后）
4. 按键交互：
   - 数字键1-8: 选择英雄位置
   - S键: 释放技能（弹出技能菜单）
   - A键: 切换自动/手动
   - P键: 暂停/继续
   - +/-: 加速/减速
   - Q键: 退出
```

#### 颜色方案
```lua
Colors = {
    RESET = "\27[0m",
    RED = "\27[31m",      -- 敌方、伤害
    GREEN = "\27[32m",    -- 我方、治疗
    YELLOW = "\27[33m",   -- 警告、能量
    BLUE = "\27[34m",     -- 技能、Buff
    MAGENTA = "\27[35m",  -- 暴击、特殊
    CYAN = "\27[36m",     -- 信息
    WHITE = "\27[37m",    -- 默认
    BOLD = "\27[1m",      -- 高亮
}
```

### 关键设计决策
1. **数据驱动**：所有配置使用Lua表，便于热更新
2. **API兼容**：BattleScriptExp 保持与原项目一致
3. **模块化**：每个系统独立，便于测试和维护
4. **可扩展**：预留接口支持后续功能扩展
5. **命令行优先**：纯文本界面，无需GUI库依赖

---

## 验收标准

1. ✅ 可以启动一场完整战斗
2. ✅ 可以手动释放技能
3. ✅ 可以自动运行战斗
4. ✅ 可以加载原项目技能脚本
5. ✅ 战斗结果与预期一致
6. ✅ 支持批量战斗测试
7. ✅ **命令行界面美观、交互流畅**
8. ✅ **实时展示战斗过程（血条、技能、伤害）**
9. ✅ 代码结构清晰，易于维护

---

## 预计工作量

| 阶段 | 预计时间 |
|------|----------|
| 阶段一：基础设施 | 4小时 |
| 阶段二：核心系统 | 8小时 |
| 阶段三：战斗模块 | 16小时 |
| 阶段四：战斗主控 | 8小时 |
| 阶段五：API实现 | 8小时 |
| 阶段六：配置数据 | 4小时 |
| 阶段七：命令行UI | **8小时** |
| 阶段八：测试验证 | 8小时 |
| 阶段九：文档优化 | 4小时 |
| **总计** | **约68小时** |
