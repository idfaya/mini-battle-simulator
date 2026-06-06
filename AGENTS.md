# AGENTS.md

编码 Agent 的**行为准则**。仓库工程约束见 [`docs/repo_constraints.md`](docs/repo_constraints.md)；项目入口见 [`README.md`](README.md)。

## 执行原则

- **先想清楚再写**：假设写清楚；有歧义且会阻塞正确实现时再问。
- **够用就好**：最小改动解决问题；不预支抽象、不堆无效防御。
- **手术式修改**：只动任务相关代码，风格与周边一致。
- **可验证再收工**：多步任务先定验收标准，能跑检查就不要停在「看起来对」。

## 工作方式

- **做完再停**：除非方向性歧义或不可逆决策，否则一次闭环完成再汇报。
- **少要权限**：能 Read/Edit/Grep 完成的不要 Shell；可合并的命令合并跑。
- **危险操作后置**：删除、`git reset`、大面积覆盖等放最后，并先说明影响。
- **大改动要 Web E2E**：跨模块 / SSOT / 新系统完成后须 Web 端到端回归；**仅 `bin/` 不算验收完成**。
- **提交节奏**：完成后不自动 commit；用户确认后再 commit，commit 后自动 push。

## 改代码前读什么

| 文档 | 用途 |
| --- | --- |
| [`docs/repo_constraints.md`](docs/repo_constraints.md) | 5e、目录、镜像、平衡、文档、元数据 |
| [`docs/implementation_guidelines.md`](docs/implementation_guidelines.md) | 实现规范与测试口径 |
| [`design/README.md`](design/README.md) | 策划规则（活跃稿） |
