# 仓库工程约束

面向 Agent 与开发者的**仓库级**硬约束。Agent 执行准则见 [`AGENTS.md`](../AGENTS.md)；实现细节见 [`implementation_guidelines.md`](./implementation_guidelines.md)。

## 战斗与目录

- **5e 规则**：HP / AC / 命中 / 法术 DC 遵循 D&D 5e 风格；不脱离现有 helper 自造公式。
- **基础武器攻击**：标准攻击为「武器伤害骰 + 对应属性调整值」；除非技能明文授予，不额外叠技能伤害骰。
- **难度模型**：避免 ad-hoc 倍率；优先 `budget.difficulty` 与 `budget.pressureFactor`。
- **目录**：技能 `skills/`；Roguelike `roguelike/`；战斗引擎 `modules/`。
- **Require**：点路径，如 `require("skills.battle_skill_status")`。

## Web 镜像

- `web/public/lua/project/` 由 `npm run export:lua` 生成，**禁止手改**。
- 新增 Lua 源目录须写入 `tools/export_web_lua.mjs` 的 `sourceDirs`。
- Lua 改动后：改源码 → 导出镜像 → Web E2E 自测；**不能只用 `bin/` 脚本代替 Web 验收**。命令见 [`README.md`](../README.md)、[`docs/README.md`](./README.md)。

## 平衡回归（规则）

- 改变 Run 内战斗难度的改动，**必须真战回归**；静态对齐、`autoWinBattles`、路由触达**不能替代**平衡验收。
- 解读 wipe/clear 前先排除流程失败（如 `unknown` / `Other Fail`）；先修流程，再调数值。
- Playwright E2E 验 UI/流程，**不能替代**真战平衡统计。
- 脚本分层、门禁命令、豁免口径见 [`implementation_guidelines.md`](./implementation_guidelines.md) §8.4 与 [`docs/README.md`](./README.md)。

## 文档

- 改代码前读 `design/` 活跃稿与 `docs/` 实现文档。
- `design/legacy/` 仅归档：不读、不维护、不在活跃文档中引用。
- 不做已删除接口/字段/公式的运行时兼容，除非用户明确要求。
- 活跃文档只写当前行为；SSOT 行为变更时同步更新对应 `design/` / `docs/`。

## 配置与技能元数据

- **技能先文档后代码**：行为 / 数值 / Feat 落点变更须先写 `design/` 活跃稿，再改运行时；见 `AGENTS.md` 与 `docs/implementation_guidelines.md` §4.0。
- 大表 EmmyLua 误报：用 `---@alias` / `---@class` / `---@type` 注解，不改运行时行为。
- 技能行为变更：同步 `config/data/skills.json` 与 `config/tables/skill_meta.lua`；schema 变更须改 `skills.json`。

## 安全与卫生

- 不手改 `web/dist/` 等构建产物。
- 不用破坏性 git 命令（如 `reset --hard`），除非用户明确要求。
- 改动尽量小；不为已移除系统写兼容垫片。
