---
--- Battle Skill Turn Hooks Module
--- 管理与「回合生命周期」挂钩的技能逻辑：
---   * ReviveLatestDeadAlly —— 复活最近阵亡的友军，附带复活虚弱（__revivePenalty）
---   * ProcessTurnStartStatus —— 回合起始状态处理（OnRoundBegin / 跳过行动 / 复活虚弱倒数 / 控制状态检测）
---
--- 从 modules/battle_skill.lua [11] 区拆出（2026-04-27），后迁移到 skills/ 目录。
--- 外部契约：battle_skill.lua 仍保留 BattleSkill.ReviveLatestDeadAlly / ProcessTurnStartStatus
--- 作为转发接口，兼容现有 battle_main.lua、skill_effect_registry.lua、test_timeline_passive.lua。
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")

local BattleSkillTurnHooks = {}

--- 复活最近阵亡的友军（依据 __deadOrder 判断「最近」）。
--- @param hero table 触发复活的单位（用于定位友方队伍）
--- @param optsOrPct table|number|nil
---   * table: { hpPct, atkMul, defMul, speedMul, turns }
---   * number: 简化写法，等价 { hpPct = number }
--- @return table|nil 被复活的目标
function BattleSkillTurnHooks.ReviveLatestDeadAlly(hero, optsOrPct)
    local BattleFormation = require("modules.battle_formation")
    local BattleAttribute = require("modules.battle_attribute")

    local allies = BattleFormation.GetFriendTeam(hero) or {}
    local latestDead = nil
    local bestOrder = -1
    for _, ally in ipairs(allies) do
        if ally and (ally.isDead or not ally.isAlive or (tonumber(ally.hp) or 0) <= 0) then
            local ord = tonumber(ally.__deadOrder) or -1
            if ord > bestOrder then
                bestOrder = ord
                latestDead = ally
            elseif bestOrder < 0 then
                -- Fallback: no dead order info; keep "last in array" behavior.
                latestDead = ally
            end
        end
    end
    if not latestDead then
        return nil
    end

    local opts = {}
    if type(optsOrPct) == "table" then
        opts = optsOrPct
    else
        opts.hpPct = optsOrPct
    end

    local maxHp = tonumber(latestDead.maxHp) or 1
    local reviveHpPct = tonumber(opts.hpPct)
    if reviveHpPct == nil then
        reviveHpPct = 0.20
    end
    local reviveHp = math.max(1, math.floor(maxHp * reviveHpPct))
    BattleAttribute.SetHpByVal(latestDead, reviveHp)
    latestDead.isAlive = true
    latestDead.isDead = false
    latestDead.__deadOrder = nil

    -- Revival sickness: apply as an attribute-layer multiplier so it stacks with other bonuses.
    latestDead.__revivePenalty = {
        atkMul = tonumber(opts.atkMul) or 0.75,
        defMul = tonumber(opts.defMul) or 0.75,
        speedMul = tonumber(opts.speedMul) or 0.80,
        remainingTurns = tonumber(opts.turns) or 2,
    }
    latestDead.__skipNextAction = true
    if latestDead.attributes
        and latestDead.attributes.base
        and latestDead.attributes.base[BattleAttribute.ATTR_ID.HP]
    then
        BattleAttribute.UpdateHeroAttribute(latestDead)
    end

    BattleEvent.Publish(BattleVisualEvents.HERO_REVIVED, {
        eventType = BattleVisualEvents.HERO_REVIVED,
        heroId = latestDead.id,
        heroName = latestDead.name,
        team = latestDead.isLeft and "left" or "right",
        hp = latestDead.hp,
        maxHp = latestDead.maxHp or maxHp,
    })
    BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(latestDead))
    return latestDead
end

--- 回合起始状态流水线：
---   1) 分发 OnRoundBegin 给 buff 系统
---   2) 若 hero 标记了跳过本次行动（刚复活）→ 清标记并返回 false
---   3) 复活虚弱倒数 remainingTurns，到期时重刷属性
---   4) 若仍处于硬控（冻结等）则返回 false
--- @param hero table
--- @return boolean 是否可以继续本回合行动
function BattleSkillTurnHooks.ProcessTurnStartStatus(hero)
    if not hero or hero.isDead then
        return false
    end

    local BattleBuff = require("modules.battle_buff")
    BattleBuff.OnRoundBegin(hero)

    if hero.__skipNextAction then
        hero.__skipNextAction = false
        Logger.Log(string.format("[ProcessTurnStartStatus] %s 因复活虚弱跳过行动", hero.name or "Unknown"))
        return false
    end

    if hero.__revivePenalty and (hero.__revivePenalty.remainingTurns or 0) > 0 then
        hero.__revivePenalty.remainingTurns = hero.__revivePenalty.remainingTurns - 1
        if hero.__revivePenalty.remainingTurns <= 0 then
            local BattleAttribute = require("modules.battle_attribute")
            hero.__revivePenalty = nil
            if hero.attributes
                and hero.attributes.base
                and hero.attributes.base[BattleAttribute.ATTR_ID.HP]
            then
                BattleAttribute.UpdateHeroAttribute(hero)
            end
        end
    end

    if BattleBuff.IsHeroUnderControl(hero) then
        Logger.Log(string.format("[ProcessTurnStartStatus] %s 因冻结跳过行动", hero.name or "Unknown"))
        return false
    end

    return hero.isAlive and not hero.isDead
end

return BattleSkillTurnHooks
