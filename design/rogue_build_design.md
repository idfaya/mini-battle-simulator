# 盗贼 Build 设计稿

## 规则源

- 本文档记录 `盗贼（技巧）` 的职业设计，并以 `design/newbattle/physical_class_core_skill_design.md` 为规则源。
- 当前职业成长按 `low / mid / high` 三阶子职业结构实现，不再采用旧 `Lv2/Lv4` 分支选择。

## 三阶结构

| 阶段 | 授予 Feat | 技能槽 | 规则定义 |
| --- | --- | --- | --- |
| `low` | `盗贼训练` + `伏击` | `basic_attack_slot` + `core_slot` | 获得轻巧近战攻击；当目标被他人牵制、被控制或夹击成立时，本次攻击造成额外伤害。 |
| `mid` | `影袭处决` | `mid_slot` | `CD3`，对后排或低血量目标发动 1 次攻击；该次攻击视为满足伏击条件。 |
| `high` | `直觉闪避` | `high_slot` | 每回合第一次被攻击命中时，受到伤害减半。 |

## 实现映射

| 能力 | Feat ID Symbol | Skill ID | Runtime |
| --- | --- | --- | --- |
| 轻巧刺击 | `rogue_training` | `80001011` | 主动，基础轻巧近战攻击 |
| 伏击 | `rogue_sneak_attack` | `80001101` | 被动，条件附伤 |
| 影袭处决 | `rogue_execute_strike` | `80001013` | 主动，强制伏击窗口 |
| 直觉闪避 | `rogue_executioner` | `80001108` | 被动，首次受击减半 |

## 语义边界

- 伏击是附加伤害，不是额外攻击。
- 影袭处决可以稳定制造一次伏击窗口。
- 直觉闪避只承担高阶生存，不再携带旧 capstone 分支增伤。
