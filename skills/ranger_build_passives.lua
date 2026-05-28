local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local FeatModHelper = require("skills.feat_mod_helper")

local RangerBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local RESTRAINED_PROXY_BUFF_ID = 880002
local HUNTER_MARK_BUFF_ID = 890005
local WILD_ENDURANCE_BUFF_ID = 890010

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

local function syncWildEnduranceBuff(hero)
    local BattleBuff = require("modules.battle_buff")
    local BattleSkill = require("modules.battle_skill")
    if not isAlive(hero) then
        return
    end
    if not hasSkill(hero, IDS.ranger_wild_endurance) and not hasSkill(hero, IDS.ranger_survival_mastery) then
        return
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    local used = runtime.rangerReduceRound == round
    local buff = BattleBuff.GetBuff(hero, WILD_ENDURANCE_BUFF_ID)
    if used then
        if buff then
            BattleBuff.DelBuffByBuffIdAndCaster(hero, WILD_ENDURANCE_BUFF_ID, hero, 1)
        end
        return
    end
    if not buff then
        BattleSkill.ApplyBuffFromSkill(hero, hero, WILD_ENDURANCE_BUFF_ID, nil, { duration = 1 })
    end
end

local function applyMarkedBonusDamage(hero, target)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    -- §6 markPayoutPerRound：默认每回合 1 次，feat 可叠加更多次。
    local maxPerRound = 1 + math.max(0, math.floor(FeatModHelper.GetSkillMod(hero, IDS.ranger_hunter_mark, "markPayoutPerRound", 0)))
    local classExtra = (hero.buildState and hero.buildState.classMods and tonumber(hero.buildState.classMods.markPayoutPerRound)) or 0
    if classExtra > 0 then
        maxPerRound = maxPerRound + math.floor(classExtra)
    end
    if runtime.rangerMarkedDamageRoundKey ~= round then
        runtime.rangerMarkedDamageRoundKey = round
        runtime.rangerMarkedDamageCount = 0
    end
    if (tonumber(runtime.rangerMarkedDamageCount) or 0) >= maxPerRound then
        return 0
    end
    runtime.rangerMarkedDamageCount = (tonumber(runtime.rangerMarkedDamageCount) or 0) + 1
    runtime.rangerMarkedDamageRound = round
    local diceExpr = "1d4"
    if hasSkill(hero, IDS.ranger_tracking_skill) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
    end
    if hasSkill(hero, IDS.ranger_mark_mastery) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
    end
    local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, diceExpr, {
        kind = "physical",
        damageKind = "direct",
        skillId = IDS.ranger_hunter_mark,
        skillName = "猎人印记",
    })
    if bonus > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发猎人印记：对 %s 追加 %d 点追猎伤害",
            hero.name or "Unknown",
            target.name or "目标",
            bonus))
    end
    return bonus
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
            local oldest = table.remove(activeMarks, 1)
            local marks = getMarkTable(oldest.enemy)
            marks[sourceId] = nil
            BattleBuff.DelBuffByBuffIdAndCaster(oldest.enemy, HUNTER_MARK_BUFF_ID, hero)
        end
    end

    local marks = getMarkTable(target)
    marks[sourceId] = {
        expireRound = getRound() + 1 + durationDelta,
    }
    BattleSkill.ApplyBuffFromSkill(hero, target, HUNTER_MARK_BUFF_ID, nil, { duration = 2 + durationDelta })
    BuildPassiveCommon.PublishCombatLog(string.format("%s 对 %s 施加猎人印记",
        hero.name or "Unknown",
        target.name or "目标"))
end

function RangerBuildPassives.AugmentBasicAttackResolveOpts(hero, target, opts, runtime)
    if not isAlive(hero) or not isAlive(target) then
        return
    end
    if hasSkill(hero, IDS.ranger_precise_shot) and RangerBuildPassives.IsTargetMarkedBy(hero, target) then
        opts.attackBonus = (tonumber(opts.attackBonus) or 0) + 1
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发精准射击：对 %s 命中 +1",
            hero.name or "Unknown",
            target.name or "目标"))
    end
end

local function tryApplySnare(hero, target, label)
    if not isAlive(hero) or not isAlive(target) then
        return false
    end
    local BattleFormula = require("core.battle_formula")
    local BattleSkill = require("modules.battle_skill")
    local dc = tonumber(hero.spellDC) or 10
    local saveBonus = tonumber(target.saveRef) or 0
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

local function applyFirstHitReduction(hero, label)
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.rangerReduceRound == round then
        return 0
    end
    local diceExpr = ""
    if hasSkill(hero, IDS.ranger_wild_endurance) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d6")
    end
    if hasSkill(hero, IDS.ranger_survival_mastery) then
        diceExpr = BuildPassiveCommon.JoinDiceParts(diceExpr, "1d4")
    end
    if diceExpr == "" then
        return 0
    end
    runtime.rangerReduceRound = round
    syncWildEnduranceBuff(hero)
    local reduction = BuildPassiveCommon.RollDice(diceExpr)
    if reduction > 0 then
        BuildPassiveCommon.PublishPassiveTriggered(hero, label or "野外坚忍", "首次受击减伤", string.format("减免 %d 伤害", reduction))
    end
    return reduction
end

local function applySubclassMasteryDamage(hero, target, skill)
    if not hasSkill(hero, IDS.ranger_subclass_mastery) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local round = getRound()
    if runtime.rangerSubclassMasteryRound == round then
        return 0
    end
    runtime.rangerSubclassMasteryRound = round
    local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "1d6", {
        kind = "physical",
        damageKind = "direct",
        skillId = IDS.ranger_subclass_mastery,
        skillName = "子职专精",
    })
    if bonus > 0 then
        BuildPassiveCommon.PublishCombatLog(string.format("%s 触发子职专精：对 %s 追加 %d 点伤害",
            hero.name or "Unknown",
            target.name or "目标",
            bonus))
    end
    return bonus
end

function RangerBuildPassives.PerformHunterShot(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local ok, result = BattleSkill.CastSmallSkillWithResult(hero, target)
    local damage = ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0
    if damage > 0 and RangerBuildPassives.IsTargetMarkedBy(hero, target) then
        local bonus = BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, "2d6", {
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
    return damage + applySubclassMasteryDamage(hero, target, skill)
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
    return damage + applySubclassMasteryDamage(hero, target, skill)
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
    return damage + applySubclassMasteryDamage(hero, target, skill)
end

function RangerBuildPassives.PerformArrowRain(hero, skill)
    if not isAlive(hero) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
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

    BuildPassiveCommon.PublishCombatLog(string.format("%s 发动箭雨：连续射出 %d 支箭矢",
        hero.name or "Unknown", totalShots))
    for shotIndex = 1, totalShots do
        local target = pickRandomAliveEnemy(hero)
        if not isAlive(target) then
            break
        end
        local targetId = tonumber(target.instanceId or target.id) or 0
        local hitCount = hitCounts[targetId] or 0
        local multiplier = 1 / (2 ^ hitCount)
        if multiplier ~= 1 then
            BuildPassiveCommon.SetPendingBasicAttackDamageMultiplier(hero, multiplier, "箭雨")
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
        if (tonumber(extraParam.damageDealt) or 0) <= 0 then
            return
        end
        local runtime = ensureRuntime(hero)
        local round = getRound()
        if runtime.rangerMarkApplyRound ~= round then
            runtime.rangerMarkApplyRound = round
            RangerBuildPassives.ApplyHunterMark(hero, target)
        end
        if RangerBuildPassives.IsTargetMarkedBy(hero, target) then
            applyMarkedBonusDamage(hero, target)
        end
    end

    return self
end

function RangerBuildPassives.CreateWildEndurancePassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        local hero = self.context and self.context.src or nil
        local runtime = ensureRuntime(hero)
        runtime.rangerReduceRound = nil
        syncWildEnduranceBuff(hero)
    end

    function self:OnSelfTurnBegin()
        local hero = self.context and self.context.src or nil
        local runtime = ensureRuntime(hero)
        if runtime then
            runtime.rangerReduceRound = nil
        end
        syncWildEnduranceBuff(hero)
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) then
            return
        end
        local reduction = applyFirstHitReduction(hero, "野外坚忍")
        if reduction > 0 then
            extraParam.damage = math.max(0, (tonumber(extraParam.damage) or 0) - reduction)
        end
        syncWildEnduranceBuff(hero)
    end

    return self
end

function RangerBuildPassives.CreateExtraAttackPassive(context)
    return BuildPassiveCommon.CreateExtraAttackPassive(context, {
        basicAttackSkillId = IDS.ranger_basic_attack,
        tokenKey = "rangerExtraAttackToken",
    })
end

return RangerBuildPassives

