# Web E2E 测试

通过 `npm run test:playwright` 运行（见 `web/scripts/run-playwright.mjs` 浏览器路径解析）。

## 共享 helper

| 路径 | 用途 |
| --- | --- |
| `helpers/client-errors.ts` | 收集 page/console 错误并过滤已知噪声 |
| `helpers/battle-log.ts` | 战斗日志行检索 |
| `helpers/battle-runtime.ts` | 运行时查单位、强制击杀、归位检测 |
| `helpers/reaction-holds.ts` | 反击/护卫 hold、拦截位移观测 |

## 专项用例

| 文件 | 覆盖 |
| --- | --- |
| `reaction-hold-death.spec.ts` | 反击/护卫 reactor 死亡后立即解除 source 攻击者 hold |
| `fighter-web-smoke.spec.ts` | 战士反击/护卫流程、动画节奏、日志顺序 |

## 常用命令

```bash
cd web && npm run test:playwright
cd web && npm run test:playwright -- tests/reaction-hold-death.spec.ts
cd web && npm run test:playwright -- tests/fighter-web-smoke.spec.ts
PW_REUSE_SERVER=1 npm run test:playwright
```
