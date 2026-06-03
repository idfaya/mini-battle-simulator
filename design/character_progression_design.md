# MiniBattle 角色养成系统设计

> 本文档与 [`dungeon_design.md`](./dungeon_design.md) 配套：
> - 本文：角色养成（队伍 EXP / 升级三选一 / Feat 档位 / Run 内死亡与复活）。
> - 地牢文档：层级地牢、房间迷宫、房间类型与奖励矩阵。
> 两份文档共同**取代** `expedition_progression_design.md` / `progression_roguelike_integration_design.md`。
> 上位规则源：`class_system_design.md`（5e 画像）/ `roguelike_feat_skill_fill_sheet.md`（Feat 树节点级 SSOT）。

---

## 1. 设计目标

1. **队伍 EXP + 升级三选一汇总池**：战斗经验只升队伍，队伍升级时玩家从"全队下一级 feat 候选"中随机三选一，选 feat 即同时定向升级对应队员；
2. **取消职业卡 / 进阶 / 挂起进阶**机制；子职 = Lv3 升级时由 feat 选择决定；
3. **Run 内死亡与复活**：HP 归零进入濒死，战斗结束仍倒地视为阵亡；通过商店复活卷轴 / 营地房恢复；
4. **不做跨 Run 永久成长**：装备 / feat / 等级仅在本 Run 内有效，Run 结束全部清空（地牢外、元进度、永久死亡均不在本期）。

---

## 2. 队伍 EXP 池

- 战斗经验全部进入 `state.partyExp`，不再分发到个人 `unit.exp`。
- 当 `partyExp` 达到下一级阈值 → 触发"队伍升级"。
- `partyExp` 阈值与 **PHB 角色升级表**对齐，SSOT：`config/roguelike/exp_5e.lua`（`PARTY_EXP_SCALE` 可整体缩放 Run 节奏）。
- 战斗胜利掉落为 **DMG 按 CR 的遭遇 XP**（`run_encounter_budget.lua` 数量倍率）× 敌方生成等级系数，见 `config/roguelike/battle_exp_reward.lua`。
- 第一章怪物模板按 `CR` 固定强度，`Level` 仅作显示；章节推进通过更高 `CR` 的怪物组合、精英/Boss 配置与 `run_battle_profile.budget` 形成节奏。
- 第一章**队伍** `targetMaxLevel = 8`（`run_chapter_config`），与 5e 遭遇 + 低怪等级下的实测节奏一致；不再以 Boss 前 Lv12 为硬指标。
- 程序实现与回归：[`docs/implementation_guidelines.md`](../docs/implementation_guidelines.md) §5.1；节奏模拟 [`bin/test_roguelike_progression_pacing.lua`](../bin/test_roguelike_progression_pacing.lua)。
- **章节 trinket**（Boss / 隐藏 Boss 发放，非 Feat、非 `equipmentIds`）：见 [`dungeon_design.md`](./dungeon_design.md) §4.7、§3.3；`state.trinketIds` + [`roguelike/trinket.lua`](../roguelike/trinket.lua)。

---

## 3. 升级三选一汇总池

### 3.1 候选规则

- 候选 = 所有存活队员"下一个等级"可选 feat 的并集。
- 阵亡角色不参与候选生成。
- 系统从中随机抽 3 张（保底：每个存活英雄至少有 1 张候选进池）。
- 玩家选中 1 张 → 该队员个人等级 +1 并获得该 feat。
- 子职业 feat 在 Lv3 池中加权 ×1.5；玩家可"跳级"，被忽略的英雄停在前一级。

### 3.2 Feat 档位

| 等级 | feat 档位 | 类型 |
| --- | --- | --- |
| Lv2 | small | 通用 |
| Lv3 | medium | **子职业核心**（解锁子职） |
| Lv4 | medium | 通用 |
| Lv5 | high | **子职业专属 capstone** |

### 3.3 战斗胜利结算顺序

```text
战斗胜利
→ 发放节点金币
→ 结算节点掉落（精英固定掉落；宝箱房随机开出金币 / 装备）
→ 发放战斗经验进入 partyExp
→ 检查升级 → 兑现升级触发的天赋卡三选一（按等级 → 档位映射，不可跳过）
→ 固定恢复
→ 进入下一房间
```

---

## 4. Run 内死亡与复活

> 本期只做"Run 内死亡 + Run 内复活"，不涉及跨 Run 永久死亡。

### 4.1 死亡判定

- 战斗中 HP 归零 → 该角色进入 `downed`（倒地）状态，本场战斗退场。
- 战斗结束时仍处于 `downed` → 标记为 `dead`，进入"阵亡名册"，**不能上阵**，不参与升级三选一候选。
- 一场战斗内 4 名角色全部倒地 → Run 直接失败，进度清空。

### 4.2 复活通道（Run 内）

| 通道 | 出现位置 | 代价 | 复活效果 |
| --- | --- | --- | --- |
| 商店复活卷轴 | 商店房（必备货品） | 高额金币 | 复活 1 名阵亡角色（50% HP） |
| 营地房 | 营地房（一次性） | 无 | 全队回满 + 清状态 + 复活 1 名（满血） |

- 复活后的角色保留死亡前的等级 / feat / 装备 / bless。
- 复活角色重新进入升级三选一候选池。

### 4.3 阵亡角色的状态

- `dead` 状态在 Run 内持续，不会自动消失。
- 阵亡角色不影响"升级三选一"的池子构成（只用存活英雄候选）。
- Run 结束（胜利或失败）→ 阵亡名册清空（本期没有跨 Run 数据）。

---

## 5. 装备 / Bless 与养成的关系

> 装备 / Bless 的房间掉落规则详见 [`dungeon_design.md`](./dungeon_design.md) §5。

- 装备 / Bless 永久绑定到 Run 结束（不跨 Run）。
- `modules/hero_build.lua` 在战斗开始前将 `feat / 装备 / bless` 注入运行时被动；本文不重复装备数值规则。
- 数值约束：`mutually_exclusive_group` + 同 tag 上限 + bless 总数上限 6（防止三层叠加爆表）。

---

## 6. 数据 / 模块影响矩阵

| 类别 | 文件 | 修改 | 说明 |
| --- | --- | --- | --- |
| 配置（新增） | `config/data/feat_cards.json` | 新增 | 天赋卡静态数据（实际复用 `feats.lua` schema 升级） |
| 配置（新增） | `config/data/equipments.json` | 新增 | 装备静态数据 |
| 配置（新增） | `config/data/blesses.json` | 新增 | Bless 静态数据 |
| 配置（修改） | `config/tables/feats.lua` | 修改 | 补 `tier` / `tags` 字段，导出按档位查询 API |
| 配置（修改） | `config/tables/skill_meta.lua` | 修改 | 同步天赋卡引用的 skill 元数据 |
| Run 层（新增） | `roguelike/feat_picker.lua` | 新增 | 升级三选一会话 |
| Run 层（修改） | `roguelike/roguelike_run.lua` | 修改 | Run 持有表新增 `partyExp` / 阵亡名册 |
| Run 层（修改） | `roguelike/roguelike_battle_resolver.lua` | 修改 | 战斗胜利后挂入升级三选一 / 阵亡判定 |
| Run 层（修改） | `roguelike/roguelike_reward.lua` | 修改 | 装备 / bless 掉落 |
| 战斗层（修改） | `modules/hero_build.lua` | 修改 | 解析 feat / 装备 / bless 注入运行时被动 |
| 战斗层（修改） | `modules/battle_passive_skill.lua` | 修改 | 支持装备 / bless 来源的被动 |
| Web | `web/app/lua/LuaBattleHost.ts` | 修改 | 暴露升级 / 复活事件 |
| Web | `web/tests/*.spec.ts` | 修改 | 新增升级三选一 / 复活回归 |

---

## 7. 落地路线（养成相关）

> 地牢相关阶段（4~6）见 [`dungeon_design.md`](./dungeon_design.md) §7。

### 7.1 阶段 1：升级三选一通道（最小可行）

- **不动**地牢结构与节点系统。
- 仅给 6 就绪职业的既有 `*_lv2 / *_lv3 / *_lv4 / *_lv5` 三选一接入"升级触发"。
- `BuildFeatDef` 补 `tier` / `tags`；`feats.lua` 暴露按档位查询 API。
- `roguelike_battle_resolver.lua` 战斗胜利结算流程加入升级三选一。
- 回归：`bin/test_roguelike_act1.lua` + Web smoke。

### 7.2 阶段 2：精英战 = 装备 + bless

- 新增 `equipments.json` / `blesses.json` 与对应 Lua 加载层。
- 精英战必掉装备 + 概率 bless；普通战完全不掉装备。
- 回归：`bin/test_*_build_pipeline.lua` 全套 + 平衡测试。

### 7.3 阶段 3：Feat 进阶通道收口

- 进阶统一由 Lv3 / Lv5 feat 选择驱动。
- 子职完全靠 Lv3 feat 选择驱动。
- 回归：`bin/test_roguelike_progression_gate.lua`。

### 7.4 阶段 7：4 缺口职业 Feat 补齐

- 写 24 张 P0 + 8 张 P1 Feat 把野蛮人 / 三系法师拉进体系。
- 写 6~9 张通用 `classId=0` 卡。

---

## 8. 验收口径

- **节奏密度**：每场战斗结束 1 秒内有「队伍升级三选一」或「装备入库」反馈，至少二选一发生。
- **升级反馈率**：MVP 配置下，单 Run 内队伍升级 ≥ 12 次（覆盖 4 名英雄各 3 级以上的预期分发）。
- **构筑分化**：同职业不同 Run 的「已选 feat + 装备 + bless」组合重合度 ≤ 30%（自动统计）。
- **子职业触达**：单 Run 内 ≥ 75% 的存活英雄能在通关前选中 Lv3 子职业核心 feat。
- **测试覆盖**：
  - `bin/` 新增至少 2 个回归脚本（汇总池三选一 / 复活流程）。
  - `web/tests/` 新增 e2e 用例覆盖升级 + 复活。

---

## 9. 风险与对策

| 风险 | 表现 | 对策 |
| --- | --- | --- |
| 汇总池抽不到目标英雄 | 玩家想升的人始终不出卡 | 按英雄分组保底（每个存活英雄至少 1 张候选进池）+ 同英雄连续命中后降权 |
| Lv3 子职业 feat 被忽略 | 玩家专挑通用 feat | 子职业 feat 在 Lv3 池子里加权 ×1.5；允许跳级 |
| 4 缺口职业卡池枯水 | 野蛮人 / 法系玩家无 build | 阶段 1~6 仅启用 6 就绪职业，阶段 7 写完缺口 feat 再放出 |
| 数值溢出 | 升级 + 装备 + bless 三层叠加爆表 | `mutually_exclusive_group` + 同 tag 上限 + bless 总数上限 6 |
| 与现有代码冲突 | `unit.exp` / `promotion_pending_target` / 职业卡掉落分散在多文件 | 阶段 1 引入 `state.partyExp` 时同步把 `unit.exp` 写入路径全部改为 no-op；阶段 3 集中删除字段 |

---

## 10. 暂不纳入的范畴

以下内容本期**不设计、不实现**：

- 元进度（账号成长 / 解锁 / 永久强化）。
- 角色永久成长（跨 Run 等级 / 装备 / 经验保留）。
- 跨 Run 永久死亡 / 遗志 / 怪癖。
- 角色招募 / 转职扩编（起手 4 名固定，Run 内不增减）。

---

## 11. 一页结论

```text
养成（核心）
  战斗经验 → 队伍 EXP 池（不再分发到个人）
  队伍升级 → 弹出汇总池三选一
    候选 = 所有存活队员「下一个等级」可选 feat 的并集
    选中 = 该队员个人等级 +1 并获得该 feat
    Lv2/Lv4 出通用 feat，Lv3/Lv5 出子职业相关 feat
  子职业由 Lv3 选中的子职业核心 feat 锁定（无独立进阶节点）
  装备 / bless：本 Run 内永久绑定，Run 结束清空
  子职业与能力结构由 Lv3 / Lv5 feat 选择驱动

死亡与复活（Run 内）
  HP 归零 → 倒地 → 战斗结束仍倒地 → 阵亡（不能上阵）
  复活通道：商店复活卷轴（金币）/ 营地房（一次性，附带回满 + 清状态）
  复活角色保留死亡前的等级 / feat / 装备 / bless
  全队倒下 → Run 直接失败，进度清空

落地（养成相关阶段）
  阶段 1：队伍 EXP + 汇总池三选一
  阶段 2：精英战 = 装备 + bless
  阶段 3：删除职业卡 / 进阶系统残留
  阶段 7：4 缺口职业 Feat
```
