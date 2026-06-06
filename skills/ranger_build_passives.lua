local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

local RangerBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local RESTRAINED_PROXY_BUFF_ID = 880002
local HUNTER_MARK_BUFF_ID = 890005

local function isAlive(unit)
    return BuildPassiveCommon.IsAlive(unit)
end

local function hasSkill(hero, skillId)
    return BuildPassiveCommon.HasSkill(hero, skillId)
end

local function ensureRuntime(hero)
    return BuildPassiveCommon.EnsureRuntime(hero)
end

local function getRound()
    return BuildPassiveCommon.GetRound()
end

local function isBackRow(unit)
    local wpType = tonumber(unit and unit.wpType) or 0
    return wpType > 3
end

local function pickRandomAliveEnemy(hero)
    local BattleFormation = require("modules.battle_formation")
    local candidates = {}
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        if isAlive(enemy) then
            candidates[#candidates + 1] = enemy
        end
    end
    if #candidates == 0 then
        return nil
    end
    return candidates[math.random(1, #candidates)]
end

local function joinDiceParts(a, b)
    a = tostring(a or ""):gsub("^%s+", ""):gsub("%s+$", "")
    b = tostring(b or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if a == "" then
        return b
    end
    if b == "" then
        return a
    end
    return a .. ";" .. b
end

local function getMarkTable(target)
    local runtime = ensureRuntime(target)
    runtime.rangerMarks = runtime.rangerMarks or {}
    return runtime.rangerMarks
end

local function buildContextState(context)
    return {
        context = context,
    }
end

local function resolveMarkPenalty(hero)
    local penalty = 1
    local extraDice = FeatModHelper.GetSkillMod(hero, IDS.ranger_hunter_mark, "markBonusDice", nil)
    if type(extraDice) == "string" and extraDice ~= "" then
        for _ in extraDice:gmatch("[^;]+") do
            penalty = penalty + 1
        end
    end
    -- §6 markPayoutPerRound：旧版为每回合兑现次数；现映射为额外减益层数（配置值 - 1）。
    local configuredSkillLimit = math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.ranger_hunter_mark, "markPayoutPerRound", 0)))
    local configuredClassLimit = math.max(0, math.floor(tonumber(hero.buildState and hero.buildState.classMods and hero.buildState.classMods.markPayoutPerRound) or 0))
    local configuredLimit = math.max(configuredSkillLimit, configuredClassLimit)
    if configuredLimit > 1 then
        penalty = penalty + (configuredLimit - 1)
    end
    return penalty
end

function RangerBuildPassives.IsTargetMarkedBy(hero, target)
    if not isAlive(hero) or not isAlive(target) then
        return false
    end
    local marks = getMarkTable(target)
    local sourceId = tonumber(hero.instanceId or hero.id) or 0
    local mark = marks[sourceId]
    if not mark then
        return false
    end
    return (tonumber(mark.expireRound) or 0) >= getRound()
end

function RangerBuildPassives.ApplyHunterMark(hero, target)
    if not isAlive(hero) or not isAlive(target) then
        return
    end
    local BattleFormation = require("modules.battle_formation")
    local BattleBuff = require("modules.battle_buff")
    local BattleSkill = require("modules.battle_skill")
    local sourceId = tonumber(hero.instanceId or hero.id) or 0
    local heroRuntime = ensureRuntime(hero)

    -- §6 markSlotMax：默认 1 个印记，feat 可允许同时维持多个。
    local slotMax = 1 + math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.ranger_hunter_mark, "markSlotMax", 0)))
    local classSlot = (hero.buildState and hero.buildState.classMods and tonumber(hero.buildState.classMods.markSlotMax)) or 0
    if classSlot > 0 then
        slotMax = slotMax + math.floor(classSlot)
    end

    -- §6 dotDurationDelta：印记基础持续 1 回合，feat 可延长。
    local durationDelta = math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.ranger_hunter_mark, "dotDurationDelta", 0)))
    local classDuration = (hero.buildState and hero.buildState.classMods and tonumber(hero.buildState.classMods.dotDurationDelta)) or 0
    if classDuration > 0 then
        durationDelta = durationDelta + math.floor(classDuration)
    end

    if slotMax <= 1 then
        -- 旧行为：清除现有印记。
        for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
            local marks = getMarkTable(enemy)
            marks[sourceId] = nil
            BattleBuff.DelBuffByBuffIdAndCaster(enemy, HUNTER_MARK_BUFF_ID, hero)
        end
    else
        -- 多槽：仅当超出槽位上限时清除最早的印记。
        local activeMarks = {}
        for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
            local marks = getMarkTable(enemy)
            local mark = marks[sourceId]
            if mark and (tonumber(mark.expireRound) or 0) >= getRound() then
                activeMarks[#activeMarks + 1] = { enemy = enemy, mark = mark }
            elseif mark then
                marks[sourceId] = nil
                BattleBuff.DelBuffByBuffIdAndCaster(enemy, HUNTER_MARK_BUFF_ID, hero)
            end
        end
        while #activeMarks >= slotMax do
            table.sort(activeMarks, function(a, b)
                local aSeq = math.floor(tonumber(a and a.mark and a.mark.appliedSeq) or 0)
                local bSeq = math.floor(tonumber(b and b.mark and b.mark.appliedSeq) or 0)
                if aSeq ~= bSeq then
                    return aSeq < bSeq
                end
                local aId = tonumber(a and a.enemy and (a.enemy.instanceId or a.enemy.id)) or 0
                local bId = tonumber(b and b.enemy and (b.enemy.instanceId or b.enemy.id)) or 0
                return aId < bId
            end)
            local oldest = table.remove(activeMarks, 1)
            local marks = getMarkTable(oldest.enemy)
            marks[sourceId] = nil
            BattleBuff.DelBuffByBuffIdAndCaster(oldest.enemy, HUNTER_MARK_BUFF_ID, hero)
        end
    end

    heroRuntime.rangerMarkApplySeq = math.floor(tonumber(heroRuntime.rangerMarkApplySeq) or 0) + 1
    local marks = getMarkTable(target)
    marks[sourceId] = {
        expireRound = getRound() + 1 + durationDelta,
        appliedSeq = heroRuntime.rangerMarkApplySeq,
    }
    local markPenalty = resolveMarkPenalty(hero)
    BattleSkill.ApplyBuffFromSkill(hero, target, HUNTER_MARK_BUFF_ID, nil, {
        duration = 2 + durationDelta,
        value = markPenalty,
    })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 对 %s 施加猎人印记（AC -%d，反射 -%d）",
        hero.name or "Unknown",
        target.name or "目标",
        markPenalty,
        markPenalty))
end

local function tryApplySnare(hero, target, label)
    if not isAlive(hero) or not isAlive(target) then
        return false
    end
    local BattleFormula = require("core.battle_formula")
    local BattleSkill = require("modules.battle_skill")
    local dc = tonumber(hero.spellDC) or 10
    local saveBonus = (tonumber(target.saveRef) or 0)
        + (tonumber(BuildPassiveCommon.GetDefenderSaveBonus(target, "ref")) or 0)
    local saveResult = BattleFormula.RollSave(target, dc, saveBonus, {})
    if saveResult.success then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s 反射豁免成功 (%d vs DC %d)",
            hero.name or "Unknown",
            label or "缠绕",
            target.name or "目标",
            saveResult.total or 0,
            saveResult.dc or dc))
        return false
    end
    BattleSkill.ApplyBuffFromSkill(hero, target, RESTRAINED_PROXY_BUFF_ID, nil, { duration = 1 })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 触发%s：%s 反射豁免失败，冻结 1 回合（近似 Restrained）",
        hero.name or "Unknown",
        label or "缠绕",
        target.name or "目标"))
    return true
end

function RangerBuildPassives.PerformHunterShot(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and RangerBuildPassives.IsTargetMarkedBy(hero, target) then
        local bonusDice = "2d6"
        local extraDice = FeatModHelper.GetSkillMod(hero, IDS.ranger_hunter_shot, "bonusDamageDice", nil)
        if type(extraDice) == "string" and extraDice ~= "" then
            bonusDice = joinDiceParts(bonusDice, extraDice)
        end
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, bonusDice, {
            kind = "physical",
            damageKind = "direct",
            skillId = skill and skill.skillId or IDS.ranger_hunter_shot,
            skillName = skill and skill.name or "狩猎指引",
        })
        damage = damage + bonus
        if bonus > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 发动狩猎指引：对印记目标 %s 追加 %d 点伤害",
                hero.name or "Unknown",
                target.name or "目标",
                bonus))
        end
    end
    local slowDuration = math.max(0, math.floor(tonumber(FeatModHelper.GetSkillMod(hero, IDS.ranger_hunter_shot, "onHitApplySlowDuration", 0)) or 0))
    if damage > 0 and slowDuration > 0 then
        BattleSkill.ApplyBuffFromSkill(hero, target, 880001, skill, { duration = slowDuration })
    end
    return damage
end

function RangerBuildPassives.PerformShadowShot(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and isBackRow(target) then
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "1d8", {
            kind = "physical",
            damageKind = "direct",
            skillId = skill and skill.skillId or IDS.ranger_shadow_shot,
            skillName = skill and skill.name or "暮影射击",
        })
        damage = damage + bonus
        if bonus > 0 then
            BuildPassiveCommon.PublishCombatLog(string.format("%s 发动暮影射击：后排目标 %s 额外受到 %d 伤害",
                hero.name or "Unknown",
                target.name or "目标",
                bonus))
        end
    end
    return damage
end

function RangerBuildPassives.PerformSnareShot(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 then
        tryApplySnare(hero, target, "缠绕箭")
    end
    return damage
end

function RangerBuildPassives.PerformArrowRain(hero, skill)
    if not isAlive(hero) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleFormation = require("modules.battle_formation")
    local totalDamage = 0
    local hitCounts = {}

    -- §6 chainCountDelta：箭雨基础 4 箭，feat 可叠加更多。
    local skillIdForMods = (skill and (skill.skillId or skill.id)) or IDS.ranger_hunter_mastery
    local extraShots = math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, skillIdForMods, "chainCountDelta", 0)))
    local classExtra = (hero.buildState and hero.buildState.classMods and tonumber(hero.buildState.classMods.chainCountDelta)) or 0
    if classExtra > 0 then
        extraShots = extraShots + math.floor(classExtra)
    end
    local totalShots = 4 + extraShots
    local firstRepeatMultiplier = tonumber(FeatModHelper.GetSkillMod(hero, skillIdForMods, "firstRepeatDamageMultiplier", 0)) or 0
    local prioritizeMarkedTargets = FeatModHelper.HasFlag(hero, skillIdForMods, "prioritizeMarkedTargets")
    local firstHitMarkedBonusDice = FeatModHelper.GetSkillMod(hero, skillIdForMods, "firstHitMarkedBonusDice", nil)

    BuildPassiveCommon.PublishCombatLog(string.format("%s 发动箭雨：连续射出 %d 支箭矢",
        hero.name or "Unknown", totalShots))
    for shotIndex = 1, totalShots do
        local target = nil
        local markedCandidates = {}
        local normalCandidates = {}
        for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
            if isAlive(enemy) then
                normalCandidates[#normalCandidates + 1] = enemy
                if prioritizeMarkedTargets and RangerBuildPassives.IsTargetMarkedBy(hero, enemy) then
                    markedCandidates[#markedCandidates + 1] = enemy
                end
            end
        end
        local pool = (#markedCandidates > 0) and markedCandidates or normalCandidates
        if #pool > 0 then
            target = pool[math.random(1, #pool)]
        end
        if not isAlive(target) then
            break
        end
        local targetId = tonumber(target.instanceId or target.id) or 0
        local hitCount = hitCounts[targetId] or 0
        local multiplier = 1 / (2 ^ hitCount)
        if hitCount == 1 and firstRepeatMultiplier > 0 and firstRepeatMultiplier < 1 then
            multiplier = firstRepeatMultiplier
        end
        if multiplier ~= 1 then
            BuildPassiveCommon.SetPendingBasicAttackDamageMultiplier(hero, multiplier, "箭雨")
        end
        if hitCount == 0 and type(firstHitMarkedBonusDice) == "string" and firstHitMarkedBonusDice ~= ""
            and RangerBuildPassives.IsTargetMarkedBy(hero, target) then
            BuildPassiveCommon.AppendPendingBasicAttackBonusDice(hero, firstHitMarkedBonusDice)
        end
        BuildPassiveCommon.PublishCombatLog(string.format("%s 的箭雨第 %d 箭锁定 %s%s",
            hero.name or "Unknown",
            shotIndex,
            target.name or "目标",
            hitCount > 0 and string.format("（同目标第 %d 次命中，伤害按 %.1f%% 结算）", hitCount + 1, multiplier * 100) or ""))
        local ok, result = BattleSkill.CastBasicAttackAction(hero, target, {
            basicAttackActionSource = "arrow_rain_active",
            basicAttackIsFollowUp = true,
        })
        local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
        totalDamage = totalDamage + damage
        if damage > 0 and targetId ~= 0 then
            hitCounts[targetId] = hitCount + 1
        end
    end
    return totalDamage
end

function RangerBuildPassives.CreateHunterMarkPassive(context)
    local self = buildContextState(context)

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not isAlive(hero) or not isAlive(target) then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.ranger_basic_attack then
            return
        end
        local runtime = ensureRuntime(hero)
        if runtime.lastBasicAttackRollHit ~= true then
            return
        end
        local targetId = tonumber(target.instanceId or target.id) or 0
        local resolvedTargetId = tonumber(runtime.lastBasicAttackTargetId) or 0
        if targetId ~= 0 and resolvedTargetId ~= 0 and targetId ~= resolvedTargetId then
            return
        end
        local round = getRound()
        if runtime.rangerMarkApplyRound ~= round then
            runtime.rangerMarkApplyRound = round
            RangerBuildPassives.ApplyHunterMark(hero, target)
        end
    end

    return self
end

return RangerBuildPassives
