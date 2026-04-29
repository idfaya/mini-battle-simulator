# 战士 Web 单战测试用例

## 目的

- 固化 `single-battle` 入口下战士 Build 的浏览器验证方式。
- 统一记录 `fighterFeats` 与 `fighterFeatsByHero` 的参数格式。
- 提供可直接复制的 URL，用于本地手工验证和 Playwright 回归。

## 参数说明

- `mode=single-battle`
  - 进入单场战斗入口。
- `heroes`
  - 左侧英雄 ID，按槽位顺序填写，逗号分隔。
- `enemies`
  - 右侧敌人 ID，按槽位顺序填写，逗号分隔。
- `level`
  - 本场战斗统一等级。
- `seed`
  - 固定随机种子，便于复现。
- `fighterFeats`
  - 给本场所有战士注入同一组 Build Feat。
  - 格式：`fighterFeats=2100201,2100301`
- `fighterFeatsByHero`
  - 按英雄槽位分别注入 Build Feat。
  - 组内用 `,` 分隔，组与组之间用 `|` 分隔。
  - 格式：`fighterFeatsByHero=2100201,2100303|2100201,2100301|2100203,2100302`
  - 优先级高于 `fighterFeats` 的公共配置；未提供的槽位会回退到 `fighterFeats`。
  - 仅战士消费该参数，其他职业忽略。

## 用例 1

- 名称：`Lv3 冠军动作激增`
- 目的：验证战士重构后的主动技能名与 `动作激增` 链路。
- URL：

```text
/?mode=single-battle&heroes=900005&enemies=910004&level=3&fighterFeats=2100201,2100301&seed=101001
```

- 期望：
  - 日志包含 `Tank 使用 动作激增`
  - 日志不再出现旧技能名 `盾击`、`顺劈`、`旋风`

## 用例 2

- 名称：`Lv2 反击战法登记日志`
- 目的：验证反击在“登记反击”时就给出反馈，而不是等真正出手才显示。
- URL：

```text
/?mode=single-battle&heroes=900005&enemies=910003,910003,910003&level=2&fighterFeats=2100101,2100102,2100203&seed=101001
```

- 期望：
  - 日志包含 `Tank 触发被动 反击战法：登记反击 将对 Orc 发动反击`
  - 后续日志包含 `Tank 使用 基础武器攻击`
  - 顺序为：
    - `Orc 使用 基础武器攻击`
    - `Tank 触发被动 反击战法：登记反击 ...`
    - `Orc 的 基础武器攻击 对 Tank ...`
    - `Tank 使用 基础武器攻击`

## 用例 3

- 名称：`Lv3 护卫架势与护卫反击`
- 目的：验证 `fighterFeatsByHero` 按槽位注入后，多战士混编下的护卫链路。
- URL：

```text
/?mode=single-battle&heroes=900005,900005,900005&enemies=910003,910003,910003&level=3&fighterFeatsByHero=2100201,2100303|2100201,2100301|2100203,2100302&seed=101001
```

- 槽位说明：
  - 槽位 1：`2100201,2100303`，压制战法 + 护卫
  - 槽位 2：`2100201,2100301`，压制战法 + 冠军
  - 槽位 3：`2100203,2100302`，反击战法 + 战斗大师
- 期望：
  - 日志包含 `Tank 使用 护卫架势`
  - 日志包含 `Tank 的 护卫架势 未产生效果`
  - 日志包含 `Tank 触发被动 护卫架势：登记护卫反击 将对 Orc 发动护卫反击`
  - 登记日志出现在对应攻击结果之前

## 备注

- 若只需要给单个战士快速塞一套 Build，优先用 `fighterFeats`。
- 若需要同时验证多个战士走不同分支，必须用 `fighterFeatsByHero`。
- 当前正式 Playwright 用例位于 `web/tests/fighter-web-smoke.spec.ts`。
