# 实现新技能设计计划

## 概述

根据 `design/skill.md` 中的最新技能树设计，将 9 大流派（物理6系 + 法术3系）的完整技能体系同步到代码和配置中。

## 当前状态分析

### 现有文件结构
- `config/res_skill_rgl.json` - RGL 技能定义（当前有旧数据）
- `config/res_rgl_hero.json` - 英雄配置（8个英雄）
- `config/skill_rgl_config.lua` - 技能配置加载器
- `modules/battle_skill.lua` - 技能执行逻辑
- `modules/battle_passive_skill.lua` - 被动技能处理

### 新设计要求
- **9 大流派**: A1追击、D1格挡、S1连击、B1战意、T1毒爆、H1圣光、M1火法、M2冰法、M3雷法
- **每派系4层**: L1普攻(Normal) → L2被动(Passive) → L3主动(Active/CD) → L4大招(Ultimate/100E)
- **Type映射**: Type=1(Normal), Type=2(Active), Type=3(Ultimate), Type=4(Passive)
- **资源规则**: 普攻cost=0回能20/回合, 被动常驻, 主动CD不耗能量, 大招cost=100能量

---

## 实施步骤

### Phase 1: 更新 res_skill_rgl.json（核心配置）

**目标**: 创建完整的 9 流派 × 4 层 = 36 个技能定义

#### 1.1 定义 ClassID 分配规则
```
A1 追击流:   ClassID 8000100 (攻击系)
D1 格挡流:   ClassID 8000200 (防御系)  
S1 连击流:   ClassID 8000300 (速度系)
B1 战意流:   ClassID 8000400 (增益系)
T1 毒爆流:   ClassID 8000500 (状态系)
H1 圣光流:   ClassID 8000600 (治疗系)
M1 火法:     ClassID 8000700 (法术-爆发)
M2 冰法:     ClassID 8000800 (法术-控制)
M3 雷法:     ClassID 8000900 (法术-连锁)
```

#### 1.2 每个 ClassID 下创建 4 个 Level
```
Level 1 = Normal (Type=1)  -> ID = ClassID * 10 + 1
Level 2 = Passive (Type=4) -> ID = ClassID * 10 + 2  
Level 3 = Active  (Type=2) -> ID = ClassID * 10 + 3
Level 4 = Ultimate(Type=3) -> ID = ClassID * 10 + 4
```

#### 1.3 关键字段说明
```json
{
  "ID": 80001001,
  "ClassID": 8000100,
  "SkillLevel": 1,
  "Name": "刺击",
  "Type": 1,
  "Power": 110,
  "Description": "110%伤害，+20%暴击率",
  "SkillParam": [11000, 2000],  // [伤害倍率(万分比), 特殊参数]
  "CoolDownR": 0,
  "Cost": 0,
  "Buff1": [],  // Buff配置
  "Condition": 0
}
```

### Phase 2: 更新 res_rgl_hero.json（英雄配置）

**目标**: 为每个英雄分配符合角色设定的流派技能

#### 2.1 英雄-流派映射
| 英雄 | 名称 | 职业 | 主流派 | 备选流派 |
|:----:|:-----|:----:|:------:|:--------:|
| 900001 | ComboWarrior | 战士 | S1 连击流 | D1 格挡流 |
| 900002 | FireMage | 法师 | M1 火法 | B1 战意流 |
| 900003 | IceMage | 法师 | M2 冰法 | T1 毒爆流 |
| 900004 | ThunderMage | 法师 | M3 雷法 | S1 连击流 |
| 900005 | Tank | 坦克 | D1 格挡流 | H1 圣光流 |
| 900006 | Assassin | 刺客 | A1 追击流 | S1 连击流 |
| 900007 | Healer | 牧师 | H1 圣光流 | B1 战意流 |
| 900008 | PoisonMage | 法师 | T1 毒爆流 | M2 冰法 |

#### 2.2 SkillIDs 结构
```json
{
  "SkillIDs": [
    {"array": [ClassID, 1]},  // L1 Normal
    {"array": [ClassID, 2]},  // L2 Passive
    {"array": [ClassID, 3]},  // L3 Active
    {"array": [ClassID, 4]}   // L4 Ultimate
  ],
  "InitializeSkills": [
    {"array": [ClassID, 1]}   // 初始技能为L1
  ]
}
```

### Phase 3: 扩展 battle_skill.lua（技能执行逻辑）

**目标**: 支持新设计的特殊效果

#### 3.1 需要新增的机制
1. **追击系统** (A1 追击流)
   - 击杀后触发额外攻击
   - 斩杀：对最低血量目标的200%伤害
   - 收割：全场斩杀

2. **格挡反击系统** (D1 格挡流)
   - 挑衅：强制目标攻击自己
   - 格挡：概率减伤并反击
   - 盾墙：100%格挡且反击

3. **连击系统** (S1 连击流)
   - 连击概率：25%/50%
   - 多目标连击：随机选择目标
   - 连击风暴：6次随机分配

4. **中毒/感染系统** (T1 毒爆流)
   - 中毒层数管理
   - 感染：自动加深层数
   - 毒性爆发：引爆所有中毒目标

5. **治疗系统** (H1 圣光流)
   - 双向技能：敌伤/己回血
   - 精准群疗：最少血优先
   - 全体治疗+清负面

6. **增益系统** (B1 战意流)
   - 属性提升：攻防速+
   - 叠加机制：可叠加5层
   - 全体增益

7. **法术三系** (M1/M2/M3)
   - 燃烧效果（持续伤害）
   - 冰冻控制（无法行动）
   - 连锁弹射

#### 3.2 修改点
- `BattleSkill.CastSkillInSeq()`: 增加特殊效果触发
- `BattleSkill.ExecuteDefaultAttackWithPassive()`: 支持连击/追击
- 新增 `BattleSkill.ProcessSpecialEffects()` 统一处理特殊效果

### Phase 4: 扩展 battle_passive_skill.lua（被动技能）

**目标**: 实现各流派的被动效果

#### 4.1 被动技能注册增强
- 追击 (A1): 注册到 DmgMakeKill 触发器
- 格挡 (D1): 注册到 DefBeforeDmg 触发器
- 连击精通 (S1): 修改连击概率
- 感染 (T1): 注册到 RoundStart 触发器
- 亲和 (H1): 注册到 RoundStart 触发器
- 战意沸腾 (B1): 注册到 DmgMakeKill 触发器
- 火焰/寒冰/雷电亲和 (M1/M2/M3): 注册到对应触发器

### Phase 5: 测试验证

**目标**: 确保9大流派技能正常工作

#### 5.1 单元测试
- 每个流派的4层技能独立测试
- 特殊效果测试（追击、连击、中毒等）

#### 5.2 集成测试
- 英雄技能循环测试
- 战斗流程完整性测试

---

## 文件修改清单

### 必须修改的文件
1. ✅ `config/res_skill_rgl.json` - 重写36个技能定义
2. ✅ `config/res_rgl_hero.json` - 更新8个英雄的技能分配
3. ✅ `modules/battle_skill.lua` - 增加特殊效果支持
4. ✅ `modules/battle_passive_skill.lua` - 增强被动触发器

### 可能需要新建的文件
5. 📝 `modules/battle_special_effects.lua` - 特殊效果统一处理（可选，也可集成到battle_skill.lua）

---

## 优先级排序

### P0 (必须完成)
- [ ] Phase 1: res_skill_rgl.json 完整配置
- [ ] Phase 2: res_rgl_hero.json 英雄技能分配
- [ ] Phase 3: 核心战斗逻辑适配

### P1 (重要优化)
- [ ] Phase 4: 被动技能完善
- [ ] Phase 5: 测试验证

---

## 风险与注意事项

1. **向后兼容**: 保持现有接口不变，只扩展功能
2. **性能考虑**: 特殊效果使用事件驱动，避免每帧轮询
3. **数值平衡**: 新技能的伤害/效果需要实际测试调整
4. **配置热更**: JSON配置支持运行时加载，无需重启

---

## 预期成果

完成后将实现：
- ✅ 9 大流派 × 4 层 = 36 个完整技能
- ✅ 8 个英雄各有独特流派定位
- ✅ 丰富的战斗机制（追击、连击、中毒、治疗等）
- ✅ 清晰的技能进化链路
