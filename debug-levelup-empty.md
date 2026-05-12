[OPEN] levelup-empty

# 调试目标
- 症状：升级奖励中的 feat 和技能显示为空。
- 期望：升级奖励应显示本次升级获得的 feat，以及由 feat 解析出的新技能卡。

# 可证伪假设
1. `lastBattleSummary.levelUps` 在 Lua 侧生成时，`gainedFeats/gainedSkillCards` 就是空数组。
2. Lua 快照到 Web 的序列化过程中，`levelUps` 子字段被丢失或覆写。
3. 前端信息页没有使用最新逻辑，实际展示走了旧路径或旧镜像。
4. 仅跨级升级路径为空，逐级模拟使用的中间对象缺失 `feats/selectedFeatIds` 之一。
5. `gainedFeats` 非空，但由 feat 解析技能卡时命中了隐藏技能或未命中技能配置。

# 计划
- 先加最小化调试日志，记录升级摘要在 Lua 生成、快照输出、前端渲染三个阶段的实际值。
- 复现一次单级/跨级升级，比较日志后再做最小修复。
