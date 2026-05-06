local BattleEvent = require("core.battle_event")

local BuildPassiveCommon = {}

local function ensureRuntime(hero)
    if not hero then
        return {}
    end
    hero.passiveRuntime = hero.passiveRuntime or {}
    return hero.passiveRuntime
end

local function getRound()
    local BattleLogic = require("modules.battle_logic")
    return tonumber(BattleLogic.GetCurRound and BattleLogic.GetCurRound()) or 0
end

local function isAlive(unit)
    return unit and not unit.isDead and (unit.isAlive ~= false) and (tonumber(unit.hp) or 0) > 0
end

local function hasSkill(hero, skillId)
    if not hero or not skillId then
        return false
    end
    local instances = hero.skillData and hero.skillData.skillInstances or nil
    if instances and instances[skillId] then
        return true
    end
    for _, skill in ipairs(hero.skills or {}) do
        if tonumber(skill.skillId) == tonumber(skillId) then
            return true
        end
    end
    return false
end

local function sameUnit(a, b)
    if not a or not b then
        return false
    end
    return tonumber(a.instanceId or a.id) == tonumber(b.instanceId or b.id)
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

local function publishPassiveTriggered(hero, skillName, triggerType, extraInfo)
    if not hero then
        return
    end
    BattleEvent.Publish("PassiveSkillTriggered", {
        eventType = "PassiveSkillTriggered",
        heroId = hero.instanceId or hero.id,
        heroName = hero.name,
        skillName = skillName,
        triggerType = triggerType,
        extraInfo = extraInfo,
    })
end

local function publishCombatLog(message, extraPayload)
    if type(message) ~= "string" or message == "" then
        return
    end
    local payload = {
        message = message,
    }
    if type(extraPayload) == "table" then
        for key, value in pairs(extraPayload) do
            payload[key] = value
        end
    end
    BattleEvent.Publish("CombatLog", payload)
end

local function rollDice(expr)
    local Dice = require("core.dice")
    local total = Dice.Roll(expr, { crit = false })
    return math.max(0, math.floor(tonumber(total) or 0))
end

local function applyHeal(hero, amount)
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    if amount > 0 then
        BattleDmgHeal.ApplyHeal(hero, amount, hero)
    end
end

local function applyDirectBonusDamage(hero, target, diceExpr, meta)
    if not isAlive(hero) or not isAlive(target) or type(diceExpr) ~= "string" or diceExpr == "" then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        skipCheck = true,
        kind = (meta and meta.kind) or "physical",
        damageKind = (meta and meta.damageKind) or "direct",
        damageDice = diceExpr,
        noWeapon = meta and meta.noWeapon ~= false or true,
        noAbilityMod = meta and meta.noAbilityMod ~= false or true,
    })
    local damage = math.max(0, math.floor(tonumber(result and result.damage) or 0))
    if damage > 0 then
        BattleDmgHeal.ApplyDamage(target, damage, hero, {
            damageKind = (meta and meta.damageKind) or "direct",
            skillId = meta and meta.skillId or nil,
            skillName = meta and meta.skillName or nil,
        })
    end
    return damage
end

local function getBasicAttackDamageDice(skillId)
    local Skill5eMeta = require("config.skill_5e_meta")
    local meta = Skill5eMeta.Get(skillId)
    local damageDice = tostring(meta and meta.damageDice or "1d8")
    if damageDice == "" then
        return "1d8"
    end
    return damageDice:match("([^;]+)") or "1d8"
end

local function pickAnotherAliveEnemy(hero, excludedTarget)
    local BattleFormation = require("modules.battle_formation")
    local excludedId = tonumber(excludedTarget and (excludedTarget.instanceId or excludedTarget.id)) or 0
    for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
        local enemyId = tonumber(enemy and (enemy.instanceId or enemy.id)) or 0
        if isAlive(enemy) and enemyId ~= excludedId then
            return enemy
        end
    end
    return nil
end

local function pickLowestHpAlly(hero, includeSelf)
    local BattleFormation = require("modules.battle_formation")
    local picked = nil
    local pickedRatio = 1
    for _, ally in ipairs(BattleFormation.GetFriendTeam(hero) or {}) do
        if isAlive(ally) and (includeSelf or not sameUnit(ally, hero)) then
            local maxHp = math.max(1, tonumber(ally.maxHp) or 1)
            local ratio = math.max(0, tonumber(ally.hp) or 0) / maxHp
            if ratio < pickedRatio then
                pickedRatio = ratio
                picked = ally
            end
        end
    end
    return picked
end

local function augmentBasicAttackResolveOpts(hero, target, opts, runtime)
    local modules = {
        "skills.paladin_build_passives",
        "skills.ranger_build_passives",
    }
    for _, moduleName in ipairs(modules) do
        local ok, mod = pcall(require, moduleName)
        if ok and mod and mod.AugmentBasicAttackResolveOpts then
            mod.AugmentBasicAttackResolveOpts(hero, target, opts, runtime)
        end
    end
end

local function shouldIgnoreFrontProtection(hero, skill)
    local modules = {
        "skills.rogue_build_passives",
    }
    for _, moduleName in ipairs(modules) do
        local ok, mod = pcall(require, moduleName)
        if ok and mod and mod.ShouldIgnoreFrontProtection then
            if mod.ShouldIgnoreFrontProtection(hero, skill) == true then
                return true
            end
        end
    end
    return false
end

function BuildPassiveCommon.EnsureRuntime(hero)
    return ensureRuntime(hero)
end

function BuildPassiveCommon.IsAlive(unit)
    return isAlive(unit)
end

function BuildPassiveCommon.HasSkill(hero, skillId)
    return hasSkill(hero, skillId)
end

function BuildPassiveCommon.SameUnit(a, b)
    return sameUnit(a, b)
end

function BuildPassiveCommon.GetRound()
    return getRound()
end

function BuildPassiveCommon.JoinDiceParts(a, b)
    return joinDiceParts(a, b)
end

function BuildPassiveCommon.PublishPassiveTriggered(hero, skillName, triggerType, extraInfo)
    publishPassiveTriggered(hero, skillName, triggerType, extraInfo)
end

function BuildPassiveCommon.PublishCombatLog(message, extraPayload)
    publishCombatLog(message, extraPayload)
end

function BuildPassiveCommon.RollDice(expr)
    return rollDice(expr)
end

function BuildPassiveCommon.ApplyHeal(hero, amount)
    applyHeal(hero, amount)
end

function BuildPassiveCommon.ApplyDirectBonusDamage(hero, target, diceExpr, meta)
    return applyDirectBonusDamage(hero, target, diceExpr, meta)
end

function BuildPassiveCommon.GetBasicAttackDamageDice(skillId)
    return getBasicAttackDamageDice(skillId)
end

function BuildPassiveCommon.PickAnotherAliveEnemy(hero, excludedTarget)
    return pickAnotherAliveEnemy(hero, excludedTarget)
end

function BuildPassiveCommon.PickLowestHpAlly(hero, includeSelf)
    return pickLowestHpAlly(hero, includeSelf)
end

function BuildPassiveCommon.CreateExtraAttackPassive(context, opts)
    local options = opts or {}
    local self = {
        context = context,
    }

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not isAlive(hero) or not isAlive(target) then
            return
        end
        if tonumber(extraParam.skillId) ~= tonumber(options.basicAttackSkillId) then
            return
        end
        if extraParam.basicAttackIsFollowUp == true then
            return
        end
        local runtime = ensureRuntime(hero)
        local actionToken = tonumber(extraParam.basicAttackActionToken) or 0
        local tokenKey = options.tokenKey or "extraAttackActionToken"
        local inProgressKey = options.inProgressKey or "__inExtraAttack"
        if actionToken <= 0 or runtime[tokenKey] == actionToken or runtime[inProgressKey] then
            return
        end
        runtime[tokenKey] = actionToken
        if (tonumber(extraParam.damageDealt) or 0) > 0 and type(options.onPrimaryHit) == "function" then
            options.onPrimaryHit(hero, target, runtime, extraParam)
        end
        publishCombatLog(string.format("%s 触发额外攻击：对同一目标 %s 追加第二击",
            hero.name or "Unknown",
            target.name or "目标"))
        local castExtra = {
            basicAttackActionToken = actionToken,
            basicAttackActionSource = extraParam.basicAttackActionSource or "normal_action",
            basicAttackIsFollowUp = true,
        }
        if type(options.buildCastExtra) == "function" then
            local custom = options.buildCastExtra(hero, target, runtime, extraParam)
            if type(custom) == "table" then
                for key, value in pairs(custom) do
                    castExtra[key] = value
                end
            end
        end
        local BattleSkill = require("modules.battle_skill")
        runtime[inProgressKey] = true
        BattleSkill.CastSmallSkill(hero, target, castExtra)
        runtime[inProgressKey] = false
    end

    return self
end

function BuildPassiveCommon.AppendPendingBasicAttackBonusDice(hero, diceExpr)
    if type(diceExpr) ~= "string" or diceExpr == "" then
        return
    end
    local runtime = ensureRuntime(hero)
    runtime.pendingBasicAttackBonusDice = joinDiceParts(runtime.pendingBasicAttackBonusDice, diceExpr)
end

function BuildPassiveCommon.AppendPendingBasicAttackIgnoreAc(hero, value, label)
    local amount = math.max(0, math.floor(tonumber(value) or 0))
    if amount <= 0 then
        return
    end
    local runtime = ensureRuntime(hero)
    runtime.pendingBasicAttackIgnoreAc = (tonumber(runtime.pendingBasicAttackIgnoreAc) or 0) + amount
    if type(label) == "string" and label ~= "" then
        runtime.pendingBasicAttackIgnoreAcLabel = label
    end
end

function BuildPassiveCommon.AppendPendingBasicAttackHitBonus(hero, value, label)
    local amount = math.floor(tonumber(value) or 0)
    if amount == 0 then
        return
    end
    local runtime = ensureRuntime(hero)
    runtime.pendingBasicAttackHitBonus = (tonumber(runtime.pendingBasicAttackHitBonus) or 0) + amount
    if type(label) == "string" and label ~= "" then
        runtime.pendingBasicAttackHitBonusLabel = label
    end
end

function BuildPassiveCommon.BuildBasicAttackResolveOpts(hero, target, skill)
    local runtime = ensureRuntime(hero)
    local ignoreAc = (tonumber(runtime.basicAttackIgnoreAc) or 0) + (tonumber(runtime.pendingBasicAttackIgnoreAc) or 0)
    local attackBonus = (tonumber(runtime.basicAttackHitBonus) or 0) + (tonumber(runtime.pendingBasicAttackHitBonus) or 0)
    local opts = {
        skill = skill,
        damageKind = "direct",
    }
    if ignoreAc > 0 then
        local originalAc = tonumber(target and target.ac) or 0
        opts.targetAC = math.max(0, originalAc - ignoreAc)
        publishCombatLog(string.format("%s 触发%s：%s AC %d -> %d",
            hero and hero.name or "Unknown",
            runtime.pendingBasicAttackIgnoreAcLabel or "精准攻击",
            target and target.name or "目标",
            originalAc,
            opts.targetAC), {
            heroId = hero and (hero.instanceId or hero.id) or nil,
            targetId = target and (target.instanceId or target.id) or nil,
        })
    end
    if attackBonus ~= 0 then
        opts.attackBonus = attackBonus
        publishCombatLog(string.format("%s 触发%s：对 %s 命中 %+d",
            hero and hero.name or "Unknown",
            runtime.pendingBasicAttackHitBonusLabel or "命中修正",
            target and target.name or "目标",
            attackBonus), {
            heroId = hero and (hero.instanceId or hero.id) or nil,
            targetId = target and (target.instanceId or target.id) or nil,
        })
    end
    augmentBasicAttackResolveOpts(hero, target, opts, runtime)
    return opts
end

function BuildPassiveCommon.ApplyBasicAttackBonusDamage(hero, target)
    local runtime = ensureRuntime(hero)
    local bonusDice = tostring(runtime.basicAttackBonusDice or "")
    if runtime.pendingBasicAttackBonusDice then
        bonusDice = joinDiceParts(bonusDice, runtime.pendingBasicAttackBonusDice)
    end
    if bonusDice == "" then
        return 0
    end
    return applyDirectBonusDamage(hero, target, bonusDice, {
        kind = "physical",
        damageKind = "direct",
        noWeapon = true,
        noAbilityMod = true,
    })
end

function BuildPassiveCommon.AfterBasicAttackResolved(hero, target, damage)
    local runtime = ensureRuntime(hero)
    runtime.lastBasicAttackHit = (tonumber(damage) or 0) > 0
    runtime.lastBasicAttackTargetId = target and (target.instanceId or target.id) or nil
    runtime.pendingBasicAttackBonusDice = nil
    runtime.pendingBasicAttackIgnoreAc = nil
    runtime.pendingBasicAttackIgnoreAcLabel = nil
    runtime.pendingBasicAttackHitBonus = nil
    runtime.pendingBasicAttackHitBonusLabel = nil
end

function BuildPassiveCommon.ResolveQueuedReactions(attacker)
    local ok, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
    if ok and FighterBuildPassives and FighterBuildPassives.ResolveQueuedReactions then
        FighterBuildPassives.ResolveQueuedReactions(attacker)
    end
end

function BuildPassiveCommon.GetDefenderAcBonus(defender, attacker)
    local total = 0
    local okFighter, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
    if okFighter and FighterBuildPassives and FighterBuildPassives.GetGuardStanceAcBonus then
        total = total + (tonumber(FighterBuildPassives.GetGuardStanceAcBonus(defender, attacker)) or 0)
    end
    local okPaladin, PaladinBuildPassives = pcall(require, "skills.paladin_build_passives")
    if okPaladin and PaladinBuildPassives and PaladinBuildPassives.GetAuraAcBonus then
        total = total + (tonumber(PaladinBuildPassives.GetAuraAcBonus(defender, attacker)) or 0)
    end
    local okBattleBuff, BattleBuff = pcall(require, "modules.battle_buff")
    if okBattleBuff and BattleBuff and BattleBuff.GetBuffValueBySubType then
        total = total - (tonumber(BattleBuff.GetBuffValueBySubType(defender, 880004)) or 0)
    end
    return total
end

function BuildPassiveCommon.ShouldIgnoreFrontProtection(hero, skill)
    return shouldIgnoreFrontProtection(hero, skill)
end

function BuildPassiveCommon.ApplyTeamProtections(defender, extraParam)
    local okFighter, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
    if okFighter and FighterBuildPassives and FighterBuildPassives.ApplyGuardStanceProtection then
        FighterBuildPassives.ApplyGuardStanceProtection(defender, extraParam)
    end
    local okPaladin, PaladinBuildPassives = pcall(require, "skills.paladin_build_passives")
    if okPaladin and PaladinBuildPassives and PaladinBuildPassives.ApplyPaladinProtections then
        PaladinBuildPassives.ApplyPaladinProtections(defender, extraParam)
    end
end

return BuildPassiveCommon
