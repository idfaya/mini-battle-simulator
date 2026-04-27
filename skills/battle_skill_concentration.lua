---
--- Battle Skill Concentration Module
--- 管理专注 (Concentration) 施法状态：
---   * SetConcentration / ClearConcentration —— 进入/退出专注
---   * IsConcentrationBuff —— 判定某 buff 是否属于当前专注技能
---
--- 从 modules/battle_skill.lua [3] 区拆出（2026-04-27），后迁移到 skills/ 目录。
--- 外部契约：battle_skill.lua 仍保留 BattleSkill.SetConcentration 等同名接口作为转发。
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")

local BattleSkillConcentration = {}

--- 专注技能 → 对应 buff id 列表。
--- 当前仅两个技能进入专注体系（Bless / Bane），显式表驱动，后续拓展时在此新增。
local function GetConcentrationBuffIds(skillId)
    local sid = tonumber(skillId) or 0
    if sid == 80004003 then
        return { 840002 }
    end
    if sid == 80004004 then
        return { 840003 }
    end
    return nil
end

--- 判定某 buff 是否属于指定专注技能。
---@param skillId integer
---@param buffId integer
---@return boolean
function BattleSkillConcentration.IsConcentrationBuff(skillId, buffId)
    local buffIds = GetConcentrationBuffIds(skillId)
    if not buffIds then
        return false
    end
    local targetBuffId = tonumber(buffId) or 0
    for _, id in ipairs(buffIds) do
        if tonumber(id) == targetBuffId then
            return true
        end
    end
    return false
end

--- 结束 hero 当前的专注：清除其施加到友军的专注 buff，并重置 hero 上的专注标记。
---@param hero table
---@param reason string|nil 用于日志
---@return boolean 是否真的清除了一次专注
function BattleSkillConcentration.ClearConcentration(hero, reason)
    if not hero or not hero.__concentrationSkillId then
        return false
    end

    local activeSkillId = hero.__concentrationSkillId
    local buffIds = GetConcentrationBuffIds(activeSkillId)
    if buffIds then
        local BattleBuff = require("modules.battle_buff")
        local BattleFormation = require("modules.battle_formation")
        for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
            if ally and not ally.isDead then
                for _, buffId in ipairs(buffIds) do
                    BattleBuff.DelBuffByBuffIdAndCaster(ally, buffId, hero)
                end
            end
        end
    end

    Logger.Log(string.format("[CONC] %s 结束专注: %s (%s)",
        hero.name or "Unknown",
        tostring(hero.__concentrationSkillName or activeSkillId),
        tostring(reason or "clear")))
    hero.__concentrationSkillId = nil
    hero.__concentrationSkillName = nil
    BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(hero))
    return true
end

--- 进入专注：若 hero 已在别的专注里会先清理，再注册新的 skillId。
--- 调用 clear 路径时会透传 "replace"，保持旧行为。
---@param hero table
---@param skillId integer
---@param skill table|nil
---@return boolean
function BattleSkillConcentration.SetConcentration(hero, skillId, skill)
    if not hero then
        return false
    end

    local sid = tonumber(skillId) or 0
    if sid <= 0 then
        return false
    end

    if hero.__concentrationSkillId and hero.__concentrationSkillId ~= sid then
        BattleSkillConcentration.ClearConcentration(hero, "replace")
    end
    hero.__concentrationSkillId = sid
    hero.__concentrationSkillName = skill and skill.name or tostring(skillId)
    Logger.Log(string.format("[CONC] %s 进入专注: %s", hero.name or "Unknown", tostring(hero.__concentrationSkillName)))
    BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(hero))
    return true
end

return BattleSkillConcentration
