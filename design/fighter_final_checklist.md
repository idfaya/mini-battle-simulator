# 战士树最终落地清单

## 最终等级树

- `Lv1` 固定：`战士训练`、`二次生命`
- `Lv2` 固定：`额外攻击`
- `Lv3` 二选一：`动作激增 / 护卫`
- `Lv4` 二选一：`精准攻击 / 反击战法`
- `Lv5` 二选一：`横扫攻击 / 续战专精`

## Feat ID

| Feat | ID |
| --- | --- |
| 战士训练 | `2100101` |
| 二次生命 | `2100102` |
| 额外攻击 | `2100201` |
| 动作激增 | `2100301` |
| 护卫 | `2100302` |
| 精准攻击 | `2100401` |
| 反击战法 | `2100402` |
| 横扫攻击 | `2100501` |
| 续战专精 | `2100502` |

## Skill ID

| Skill | ID |
| --- | --- |
| 基础武器攻击 | `80002001` |
| 动作激增 | `80002003` |
| 护卫架势 | `80002005` |
| 二次生命 | `80002101` |
| 精准攻击 | `80002102` |
| 反击战法 | `80002104` |
| 护卫反击 | `80002105` |
| 续战专精 | `80002107` |
| 额外攻击 | `80002109` |
| 横扫攻击 | `80002110` |

## 技能语义

- `额外攻击`：每回合第一次基础武器攻击后，再追加 `1` 次基础武器攻击。
- `动作激增`：`CD3`，立刻追加 `1` 次基础武器攻击，目标重新选择。
- `护卫`：`CD3`，开启护卫架势；自己和友军获得 `AC +2`、熟练减伤，近战攻击者会被登记护卫反击。
- `精准攻击`：基础武器攻击忽略目标 `2` 点 AC。
- `反击战法`：每回合 `1` 次，被近战攻击指定为目标时，攻击结算后反击。
- `横扫攻击`：基础武器攻击命中主目标后，对另一名敌人追加横扫伤害。
- `续战专精`：`二次生命` 额外再回复 `1d10`。

## 推荐 Build

- 爆发线：`2100301,2100401,2100501`
- 守线：`2100302,2100402,2100502`

## 关键文件

- 设计文档：`design/fighter_build_design.md`
- 程序设计：`design/feat_skill_refactor_program_design.md`
- Web 用例文档：`design/fighter_web_test_cases.md`
- 最终清单：`design/fighter_final_checklist.md`
- Feat 配置：`config/feat_build_config.lua`
- 等级进度：`config/class_build_progression.lua`
- Runtime skill 配置：`config/skill_runtime_config.lua`
- 被动实现：`skills/fighter_build_passives.lua`
- Web 回归：`web/tests/fighter-web-smoke.spec.ts`

## 单战验证 URL

### Lv3 动作激增

```text
/?mode=single-battle&heroes=900005&enemies=910004&level=3&fighterFeats=2100301&seed=101001
```

### Lv4 反击战法

```text
/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=4&fighterFeats=2100301,2100402&seed=101001
```

### Lv5 混编验证

```text
/?mode=single-battle&heroes=900005,900005,900005&enemies=910003,910003,910003&level=5&fighterFeatsByHero=2100302,2100402,2100502|2100301,2100401,2100501|2100301,2100401,2100501&seed=101001
```

## 已覆盖的 Web 可观测性

- `动作激增`：主动施放日志存在。
- `反击战法`：登记日志先于反击出手。
- `护卫`：登记护卫反击日志先于对应受击结果。
- `横扫攻击`：基础攻击伤害、横扫追加伤害、横扫被动提示三段链路可见。
- `续战专精`：治疗日志与 `二次生命` 被动提示数值一致。

## 完整回归命令

```bash
cd web
npm run export:lua
```

```bash
lua bin/test_fighter_build_pipeline.lua
```

```bash
lua bin/test_fighter_build_runtime.lua
```

```bash
lua bin/test_roguelike_act1.lua
```

```bash
cd web
npm run test:playwright -- tests/smoke.spec.ts
```

```bash
cd web
npm run test:playwright -- tests/fighter-web-smoke.spec.ts
```

```bash
cd web
npm run test:playwright -- tests/roguelike-act1.spec.ts
```

## 当前结论

- 战士树已经完成从文档、配置、运行时到 Web 可视化断言的闭环。
- 这版可以直接作为后续职业树改造的样板。
