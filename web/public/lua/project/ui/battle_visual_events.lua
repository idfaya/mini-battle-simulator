---
--- Battle Visual Events
--- 战斗可视化事件定义
--- 
--- 该模块定义了所有与渲染相关的战斗事件。
--- 这些事件是纯数据，不包含任何渲染细节。
--- 
--- 不同渲染后端（Console/Web/Unity）可以订阅这些事件，
--- 用自己的方式呈现战斗画面。
---

local BattleVisualEvents = {}

-- ==================== 事件类型定义 ====================

--- 英雄状态变化（HP、能量等属性变化）
BattleVisualEvents.HERO_STATE_CHANGED = "HeroStateChanged"

--- 伤害事件
BattleVisualEvents.DAMAGE_DEALT = "DamageDealt"

--- 治疗事件
BattleVisualEvents.HEAL_RECEIVED = "HealReceived"

--- Buff添加
BattleVisualEvents.BUFF_ADDED = "BuffAdded"

--- Buff移除
BattleVisualEvents.BUFF_REMOVED = "BuffRemoved"

--- Buff层数变化
BattleVisualEvents.BUFF_STACK_CHANGED = "BuffStackChanged"

--- 技能释放开始
BattleVisualEvents.SKILL_CAST_STARTED = "SkillCastStarted"

--- 技能释放完成
BattleVisualEvents.SKILL_CAST_COMPLETED = "SkillCastCompleted"

--- 技能时间线开始
BattleVisualEvents.SKILL_TIMELINE_STARTED = "SkillTimelineStarted"

--- 技能时间线帧事件
BattleVisualEvents.SKILL_TIMELINE_FRAME = "SkillTimelineFrame"

--- 技能时间线完成
BattleVisualEvents.SKILL_TIMELINE_COMPLETED = "SkillTimelineCompleted"

--- 回合开始
BattleVisualEvents.TURN_STARTED = "TurnStarted"

--- 回合结束
BattleVisualEvents.TURN_ENDED = "TurnEnded"

--- 行动顺序变化
BattleVisualEvents.ACTION_ORDER_CHANGED = "ActionOrderChanged"

--- 战斗开始
BattleVisualEvents.BATTLE_STARTED = "BattleStarted"

--- 战斗结束
BattleVisualEvents.BATTLE_ENDED = "BattleEnded"

--- 胜利
BattleVisualEvents.VICTORY = "Victory"

--- 失败
BattleVisualEvents.DEFEAT = "Defeat"

--- 平局
BattleVisualEvents.DRAW = "Draw"

--- 英雄阵亡
BattleVisualEvents.HERO_DIED = "HeroDied"

--- 英雄复活
BattleVisualEvents.HERO_REVIVED = "HeroRevived"

--- 能量变化
BattleVisualEvents.ENERGY_CHANGED = "EnergyChanged"

--- 闪避
BattleVisualEvents.DODGE = "Dodge"

--- 未命中
BattleVisualEvents.MISS = "Miss"

--- 格挡
BattleVisualEvents.BLOCK = "Block"

--- 暴击
BattleVisualEvents.CRIT = "Crit"

-- ==================== 事件数据构建器 ====================

--- 构建英雄状态变化事件数据
---@param hero table 英雄对象
---@return table 事件数据
function BattleVisualEvents.BuildHeroStateChanged(hero)
    return {
        eventType = BattleVisualEvents.HERO_STATE_CHANGED,
        heroId = hero.id,
        heroName = hero.name,
        team = hero.isLeft and "left" or "right",
        hp = hero.hp or 0,
        maxHp = hero.maxHp or 100,
        energy = hero.curEnergy or hero.energy or 0,
        maxEnergy = hero.maxEnergy or 100,
        energyType = hero.energyType,
        isAlive = hero.isAlive and not hero.isDead,
        position = hero.wpType or hero.position,
        isChanting = hero.__pendingCast ~= nil,
        pendingSkillName = hero.__pendingCast and hero.__pendingCast.skillName or nil,
        isConcentrating = hero.__concentrationSkillId ~= nil,
        concentrationSkillId = hero.__concentrationSkillId or nil,
        concentrationSkillName = hero.__concentrationSkillName or nil,
    }
end

--- 构建伤害事件数据
---@param attacker table 攻击者
---@param target table 目标
---@param damage number 伤害值
---@param params table 额外参数
---@return table 事件数据
function BattleVisualEvents.BuildDamageDealt(attacker, target, damage, params)
    params = params or {}
    return {
        eventType = BattleVisualEvents.DAMAGE_DEALT,
        attackerId = attacker and (attacker.instanceId or attacker.id),
        attackerName = attacker and attacker.name,
        targetId = target.instanceId or target.id,
        targetName = target.name,
        damage = damage,
        isCrit = params.isCrit or false,
        isDodged = params.isDodged or false,
        isBlocked = params.isBlocked or false,
        damageType = params.damageType or 1,
        skillId = params.skillId,
        skillName = params.skillName,
        attackRoll = params.attackRoll,
        saveRoll = params.saveRoll,
        damageRoll = params.damageRoll,
    }
end

--- 构建治疗事件数据
---@param healer table 治疗者
---@param target table 目标
---@param healAmount number 治疗量
---@param params table 额外参数
---@return table 事件数据
function BattleVisualEvents.BuildHealReceived(healer, target, healAmount, params)
    params = params or {}
    return {
        eventType = BattleVisualEvents.HEAL_RECEIVED,
        healerId = healer and (healer.instanceId or healer.id),
        healerName = healer and healer.name,
        targetId = target.instanceId or target.id,
        targetName = target.name,
        healAmount = healAmount,
        isCrit = params.isCrit or false,
        skillId = params.skillId,
        skillName = params.skillName,
    }
end

--- 构建Buff事件数据
---@param eventType string 事件类型
---@param caster table 施法者
---@param target table 目标
---@param buff table Buff数据
---@return table 事件数据
function BattleVisualEvents.BuildBuffEvent(eventType, caster, target, buff)
    return {
        eventType = eventType,
        casterId = caster and caster.id,
        casterName = caster and caster.name,
        targetId = target.id,
        targetName = target.name,
        buffId = buff.buffId,
        buffName = buff.name,
        buffIcon = buff.icon,
        buffType = buff.mainType,
        stackCount = buff.stackCount or 1,
        value = buff.value,
        displayMode = buff.displayMode,
        duration = buff.duration,
    }
end

--- 构建技能释放事件数据
---@param eventType string 事件类型
---@param hero table 施法者
---@param skill table 技能数据
---@param targets table 目标列表
---@return table 事件数据
function BattleVisualEvents.BuildSkillCastEvent(eventType, hero, skill, targets)
    local targetData = {}
    if targets then
        for _, target in ipairs(targets) do
            table.insert(targetData, {
                id = target.instanceId or target.id,
                name = target.name,
            })
        end
    end
    
    return {
        eventType = eventType,
        heroId = hero.instanceId or hero.id,
        heroName = hero.name,
        skillId = skill.skillId,
        skillName = skill.name,
        skillIcon = skill.icon,
        skillType = skill.skillType,
        targets = targetData,
    }
end

--- 构建技能时间线开始事件
---@param hero table 施法者
---@param skill table 技能数据
---@param timeline table 时间线数据
---@return table
function BattleVisualEvents.BuildSkillTimelineStarted(hero, skill, timeline)
    return {
        eventType = BattleVisualEvents.SKILL_TIMELINE_STARTED,
        heroId = hero and (hero.instanceId or hero.id),
        heroName = hero and hero.name,
        skillId = skill and skill.skillId,
        skillName = skill and skill.name,
        totalFrames = timeline and #timeline or 0,
    }
end

--- 构建技能时间线帧事件
---@param hero table 施法者
---@param skill table 技能数据
---@param frameData table 帧数据
---@param index number 帧索引
---@return table
function BattleVisualEvents.BuildSkillTimelineFrame(hero, skill, frameData, index)
    local targets = {}
    local function AppendTarget(target)
        if not target then
            return
        end
        table.insert(targets, {
            id = target.instanceId or target.id,
            name = target.name,
        })
    end

    AppendTarget(frameData and frameData.target)
    if frameData and frameData.targets then
        for _, target in ipairs(frameData.targets) do
            AppendTarget(target)
        end
    end

    return {
        eventType = BattleVisualEvents.SKILL_TIMELINE_FRAME,
        heroId = hero and (hero.instanceId or hero.id),
        heroName = hero and hero.name,
        skillId = skill and skill.skillId,
        skillName = skill and skill.name,
        frameIndex = index or 0,
        frame = frameData and frameData.frame or 0,
        op = frameData and frameData.op,
        effect = frameData and frameData.effect,
        damage = frameData and frameData.damage,
        healAmount = frameData and frameData.healAmount,
        buffId = frameData and frameData.buffId,
        -- 5e-style roll meta (optional). Intended for UI/log readability.
        rollMeta = frameData and frameData.__hitMetaByTarget,
        savedTargets = frameData and frameData.__savedTargets,
        targets = targets,
    }
end

--- 构建技能时间线完成事件
---@param hero table 施法者
---@param skill table 技能数据
---@param timeline table 时间线数据
---@param result table 执行结果
---@return table
function BattleVisualEvents.BuildSkillTimelineCompleted(hero, skill, timeline, result)
    result = result or {}
    return {
        eventType = BattleVisualEvents.SKILL_TIMELINE_COMPLETED,
        heroId = hero and (hero.instanceId or hero.id),
        heroName = hero and hero.name,
        skillId = skill and skill.skillId,
        skillName = skill and skill.name,
        totalFrames = timeline and #timeline or 0,
        totalDamage = result.totalDamage or 0,
        succeeded = result.succeeded ~= false,
    }
end

--- 构建回合事件数据
---@param eventType string 事件类型
---@param round number 回合数
---@param hero table 当前行动英雄
---@return table 事件数据
function BattleVisualEvents.BuildTurnEvent(eventType, round, hero)
    local initiative = { roll = 0, mod = 0, total = 0 }
    if hero then
        local ok, BattleActionOrder = pcall(require, "modules.battle_action_order")
        if ok and BattleActionOrder and BattleActionOrder.GetHeroInitiative then
            initiative = BattleActionOrder.GetHeroInitiative(hero) or initiative
        end
    end

    return {
        eventType = eventType,
        round = round,
        hero = hero, -- 传递完整的英雄对象以供详细显示
        heroId = hero and (hero.instanceId or hero.id),
        heroName = hero and hero.name,
        team = hero and (hero.isLeft and "left" or "right"),
        initiativeRoll = initiative.roll or 0,
        initiativeMod = initiative.mod or 0,
        initiativeTotal = initiative.total or 0,
    }
end

--- 构建战斗结果事件数据
---@param eventType string 事件类型
---@param winner string 获胜方
---@param stats table 统计数据
---@return table 事件数据
function BattleVisualEvents.BuildBattleResultEvent(eventType, winner, stats)
    return {
        eventType = eventType,
        winner = winner, -- "left", "right", "draw"
        stats = stats or {},
    }
end

--- 构建行动顺序变化事件数据
---@param actionOrder table 行动顺序列表
---@return table 事件数据
function BattleVisualEvents.BuildActionOrderChanged(actionOrder)
    local heroes = {}
    for _, hero in ipairs(actionOrder) do
        table.insert(heroes, {
            id = hero.id,
            name = hero.name,
            team = hero.isLeft and "left" or "right",
            actionForce = hero.actionForce,
        })
    end
    
    return {
        eventType = BattleVisualEvents.ACTION_ORDER_CHANGED,
        heroes = heroes,
    }
end

--- 构建闪避/格挡/暴击事件数据
---@param eventType string 事件类型
---@param attacker table 攻击者
---@param target table 目标
---@param params table 额外参数
---@return table 事件数据
function BattleVisualEvents.BuildCombatEvent(eventType, attacker, target, params)
    params = params or {}
    return {
        eventType = eventType,
        attackerId = attacker and (attacker.instanceId or attacker.id),
        attackerName = attacker and attacker.name,
        targetId = target.instanceId or target.id,
        targetName = target.name,
        skillId = params.skillId,
        skillName = params.skillName,
        attackRoll = params.attackRoll,
        saveRoll = params.saveRoll,
    }
end

return BattleVisualEvents
