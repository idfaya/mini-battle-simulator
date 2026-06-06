local BattleEvent = require("core.battle_event")
local FeatModHelper = require("skills.feat_mod_helper")

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

-- 5e 风格：当 hero 上挂着 __bonusDamageBucket 时，所有附加伤害只 roll dice、累加到 bucket，
-- 不立即 ApplyDamage、不发可视化事件，由 bucket 持有方统一与主伤害合并后进行一次减伤+扣血+飘字。
-- 使用栈式存储以便嵌套子普攻（如 monk 连击、fighter 额外攻击）能安全地 push/pop 自己的 bucket。
local function getActiveBucket(hero, target)
    if not hero then
        return nil
    end
    local stack = hero.__bonusDamageBucketStack
    if type(stack) ~= "table" or #stack == 0 then
        return nil
    end
    local top = stack[#stack]
    if type(top) ~= "table" then
        return nil
    end
    if top.target ~= nil and target ~= nil and top.target ~= target then
        return nil
    end
    return top
end

local function tryAccumulateToBucket(hero, target, diceExpr, meta)
    local bucket = getActiveBucket(hero, target)
    if not bucket then
        return false, 0
    end
    local BattleSkill = require("modules.battle_skill")
    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        skipCheck = true,
        kind = (meta and meta.kind) or "physical",
        damageKind = (meta and meta.damageKind) or "direct",
        damageDice = diceExpr,
        noWeapon = meta and meta.noWeapon ~= false or true,
        noAbilityMod = meta and meta.noAbilityMod ~= false or true,
    })
    local damage = math.max(0, math.floor(tonumber(result and result.damage) or 0))
    bucket.totalRaw = (tonumber(bucket.totalRaw) or 0) + damage
    if damage > 0 then
        bucket.entries = bucket.entries or {}
        bucket.entries[#bucket.entries + 1] = {
            damage = damage,
            skillId = meta and meta.skillId or nil,
            skillName = meta and meta.skillName or nil,
            damageKind = (meta and meta.damageKind) or "direct",
            damageRoll = result and result.damageRoll or nil,
        }
    end
    return true, damage
end

local function applyDirectBonusDamage(hero, target, diceExpr, meta)
    if not isAlive(hero) or not isAlive(target) or type(diceExpr) ~= "string" or diceExpr == "" then
        return 0
    end
    -- 5e 一次伤害事件：若 bucket 已开，把附加伤害合并进主伤害扣血流程，避免逐项独立减伤、逐项独立飘字。
    local bucketed, bucketDamage = tryAccumulateToBucket(hero, target, diceExpr, meta)
    if bucketed then
        return bucketDamage
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
            preferSkillColor = meta and ((meta.preferSkillColor == true) or meta.skillId ~= nil or meta.skillName ~= nil) or false,
        })
    end
    return damage
end

-- 开/关 bonus damage bucket：调用方用 OpenBonusDamageBucket → 触发附加伤害 hooks → CloseBonusDamageBucket 取出累加 raw。
local function openBonusDamageBucket(hero, target)
    if not hero then
        return nil
    end
    hero.__bonusDamageBucketStack = hero.__bonusDamageBucketStack or {}
    local bucket = {
        target = target,
        totalRaw = 0,
        entries = {},
    }
    table.insert(hero.__bonusDamageBucketStack, bucket)
    return bucket
end

local function closeBonusDamageBucket(hero)
    if not hero then
        return 0, nil
    end
    local stack = hero.__bonusDamageBucketStack
    if type(stack) ~= "table" or #stack == 0 then
        return 0, nil
    end
    local bucket = table.remove(stack, #stack)
    if #stack == 0 then
        hero.__bonusDamageBucketStack = nil
    end
    if type(bucket) ~= "table" then
        return 0, nil
    end
    return math.max(0, math.floor(tonumber(bucket.totalRaw) or 0)), bucket
end

local function getBasicAttackDamageDice(skillId)
    local Skill5eMeta = require("config.tables.skill_meta")
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

-- §6 mod 查询：技能级 + 职业级求和（数值字段）。
-- 当 skillMods[skillId][key] 与 classMods[key] 均缺失时返回 0。
---@param hero table|nil
---@param skillId integer|string|nil
---@param key string
---@return number
function BuildPassiveCommon.GetSkillOrClassMod(hero, skillId, key)
    local fromSkill = tonumber(FeatModHelper.GetSkillMod(hero, skillId, key, 0)) or 0
    local fromClass = tonumber(FeatModHelper.GetClassMod(hero, key, 0)) or 0
    return fromSkill + fromClass
end

---@param hero table|nil
---@param skillId integer|string|nil
---@param key string
---@return boolean
function BuildPassiveCommon.HasSkillOrClassFlag(hero, skillId, key)
    if FeatModHelper.HasFlag(hero, skillId, key) then
        return true
    end
    if not hero or type(hero.buildState) ~= "table" then
        return false
    end
    local classMods = hero.buildState.classMods
    if type(classMods) ~= "table" then
        return false
    end
    return classMods[key] == true
end

function BuildPassiveCommon.GetClassMod(hero, key, default)
    return FeatModHelper.GetClassMod(hero, key, default)
end

function BuildPassiveCommon.GetSkillMod(hero, skillId, key, default)
    return FeatModHelper.GetSkillMod(hero, skillId, key, default)
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

local SAVE_TYPE_LABELS = {
    fort = "强韧",
    ref = "反射",
    will = "意志",
}

local function formatSigned(value)
    local numberValue = tonumber(value) or 0
    if numberValue >= 0 then
        return "+" .. tostring(numberValue)
    end
    return tostring(numberValue)
end

function BuildPassiveCommon.FormatAttackRollForLog(attackRoll)
    if type(attackRoll) ~= "table" then
        return nil
    end
    if attackRoll.targetAC == nil then
        return nil
    end
    local roll = tonumber(attackRoll.roll) or 0
    local bonus = tonumber(attackRoll.bonus) or 0
    local total = tonumber(attackRoll.total) or 0
    return string.format(
        "攻击检定 d20 %d%s=%d vs AC %d",
        roll,
        formatSigned(bonus),
        total,
        tonumber(attackRoll.targetAC) or 0)
end

function BuildPassiveCommon.FormatSaveRollForLog(saveRoll, saveType, opts)
    if type(saveRoll) ~= "table" then
        return nil
    end
    opts = opts or {}
    local label = SAVE_TYPE_LABELS[saveType] or "豁免"
    local roll = tonumber(saveRoll.roll) or 0
    local bonus = tonumber(saveRoll.bonus) or 0
    local total = tonumber(saveRoll.total) or 0
    local dc = tonumber(saveRoll.dc) or 0
    local outcome = saveRoll.success and "成功" or "失败"
    if saveRoll.success and opts.onSaveSuccess == "half" then
        outcome = "成功（半伤）"
    elseif saveRoll.success and opts.onSaveSuccess == "none" then
        outcome = "成功（无伤）"
    end
    return string.format(
        "%s豁免%s d20 %d%s=%d vs DC %d",
        label,
        outcome,
        roll,
        formatSigned(bonus),
        total,
        dc)
end

local function mergeDamageRollParts(partsA, partsB)
    local merged = {}
    if type(partsA) == "table" then
        for _, part in ipairs(partsA) do
            merged[#merged + 1] = part
        end
    end
    if type(partsB) == "table" then
        for _, part in ipairs(partsB) do
            merged[#merged + 1] = part
        end
    end
    return merged
end

function BuildPassiveCommon.MergeDamageRolls(primary, secondary)
    if type(secondary) ~= "table" then
        return primary
    end
    if type(primary) ~= "table" then
        return secondary
    end
    return {
        expr = joinDiceParts(tostring(primary.expr or ""), tostring(secondary.expr or "")),
        total = (tonumber(primary.total) or 0) + (tonumber(secondary.total) or 0),
        scaledTotal = (tonumber(primary.scaledTotal) or tonumber(primary.total) or 0)
            + (tonumber(secondary.scaledTotal) or tonumber(secondary.total) or 0),
        parts = mergeDamageRollParts(primary.parts, secondary.parts),
        crit = primary.crit == true or secondary.crit == true,
    }
end

function BuildPassiveCommon.MergeBucketDamageRolls(entries)
    if type(entries) ~= "table" then
        return nil
    end
    local merged = nil
    for _, entry in ipairs(entries) do
        if type(entry) == "table" and type(entry.damageRoll) == "table" then
            merged = BuildPassiveCommon.MergeDamageRolls(merged, entry.damageRoll)
        end
    end
    return merged
end

function BuildPassiveCommon.FormatDamageRollForLog(damageRoll)
    if type(damageRoll) ~= "table" then
        return nil
    end
    local expr = tostring(damageRoll.expr or "dice")
    local total = tonumber(damageRoll.total) or 0
    return string.format("伤害骰 %s=%d", expr, total)
end

function BuildPassiveCommon.BuildDamageEventRollParams(damageResult, meta)
    meta = meta or {}
    return {
        attackRoll = damageResult and damageResult.hit or nil,
        saveRoll = damageResult and damageResult.save or nil,
        damageRoll = damageResult and damageResult.damageRoll or nil,
        saveType = meta.saveType,
        onSaveSuccess = meta.onSaveSuccess,
    }
end

function BuildPassiveCommon.FormatRollSuffixForLog(rolls, includeDamage)
    if type(rolls) ~= "table" then
        return ""
    end
    local parts = {}
    local checkText = BuildPassiveCommon.FormatAttackRollForLog(rolls.attackRoll)
        or BuildPassiveCommon.FormatSaveRollForLog(rolls.saveRoll, rolls.saveType, {
            onSaveSuccess = rolls.onSaveSuccess,
        })
    if checkText then
        parts[#parts + 1] = checkText
    end
    if includeDamage ~= false then
        local damageText = BuildPassiveCommon.FormatDamageRollForLog(rolls.damageRoll)
        if damageText then
            parts[#parts + 1] = damageText
        end
    end
    if #parts == 0 then
        return ""
    end
    return "（" .. table.concat(parts, "；") .. "）"
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

function BuildPassiveCommon.OpenBonusDamageBucket(hero, target)
    return openBonusDamageBucket(hero, target)
end

function BuildPassiveCommon.CloseBonusDamageBucket(hero)
    return closeBonusDamageBucket(hero)
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
        if not isAlive(hero) or target == nil or not isAlive(target) then
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
        local followUpTarget = target
        local suppressDefaultFollowUp = false
        if type(options.buildCastExtra) == "function" then
            local custom = options.buildCastExtra(hero, target, runtime, extraParam)
            if type(custom) == "table" then
                for key, value in pairs(custom) do
                    if key == "suppressDefaultFollowUp" then
                        suppressDefaultFollowUp = value == true
                    elseif key == "target" then
                        followUpTarget = value
                    else
                        castExtra[key] = value
                    end
                end
            end
        end
        if suppressDefaultFollowUp then
            return
        end
        local BattleSkill = require("modules.battle_skill")
        runtime[inProgressKey] = true
        BattleSkill.CastSmallSkill(hero, followUpTarget, castExtra)
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

function BuildPassiveCommon.SetPendingBasicAttackDamageMultiplier(hero, multiplier, label)
    local amount = tonumber(multiplier) or 1
    if amount <= 0 then
        amount = 1
    end
    local runtime = ensureRuntime(hero)
    runtime.pendingBasicAttackDamageMultiplier = amount
    if type(label) == "string" and label ~= "" then
        runtime.pendingBasicAttackDamageMultiplierLabel = label
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
    if runtime.pendingBasicAttackForceCrit == true then
        opts.forceCrit = true
        publishCombatLog(string.format("%s 触发%s：对 %s 的本次基础攻击自动暴击",
            hero and hero.name or "Unknown",
            runtime.pendingBasicAttackForceCritLabel or "自动暴击",
            target and target.name or "目标"), {
            heroId = hero and (hero.instanceId or hero.id) or nil,
            targetId = target and (target.instanceId or target.id) or nil,
        })
    end
    return opts
end

function BuildPassiveCommon.ResolveProtectedDefender(defender, extraParam)
    local actualDefender = defender
    local protectionMeta = nil
    local okFighter, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
    if okFighter and FighterBuildPassives and FighterBuildPassives.ResolveGuardInterception then
        local resolvedDefender, resolvedMeta = FighterBuildPassives.ResolveGuardInterception(defender, extraParam)
        if resolvedDefender then
            actualDefender = resolvedDefender
            protectionMeta = resolvedMeta
        end
    end
    return actualDefender, protectionMeta
end

function BuildPassiveCommon.RollBasicAttackBonusDamage(hero, target)
    local runtime = ensureRuntime(hero)
    local bonusDice = tostring(runtime.basicAttackBonusDice or "")
    if runtime.pendingBasicAttackBonusDice then
        bonusDice = joinDiceParts(bonusDice, runtime.pendingBasicAttackBonusDice)
    end
    if bonusDice == "" then
        return 0, nil
    end
    if not isAlive(hero) or not isAlive(target) then
        return 0, nil
    end
    -- 5e 风格：基础攻击附加伤害（咆哮加伤、燃焰之拳等）只 roll dice 返回 raw，由 ExecuteDefaultAttackWithPassive
    -- 把 raw 并入主 damage 一次 ApplyDamage 完成减伤+扣血+飘字，避免独立减伤导致的双计与多飘字。
    local BattleSkill = require("modules.battle_skill")
    local result = BattleSkill.ResolveScaledDamage(hero, target, {
        skipCheck = true,
        kind = "physical",
        damageKind = "direct",
        damageDice = bonusDice,
        noWeapon = true,
        noAbilityMod = true,
    })
    return math.max(0, math.floor(tonumber(result and result.damage) or 0)), result and result.damageRoll or nil
end

function BuildPassiveCommon.ApplyBasicAttackBonusDamage(hero, target)
    local bonusDamage = BuildPassiveCommon.RollBasicAttackBonusDamage(hero, target)
    return bonusDamage
end

function BuildPassiveCommon.AfterBasicAttackResolved(hero, target, damage, damageResult)
    local runtime = ensureRuntime(hero)
    runtime.lastBasicAttackHit = (tonumber(damage) or 0) > 0
    runtime.lastBasicAttackRollHit = damageResult and damageResult.hit and damageResult.hit.hit == true or false
    runtime.lastBasicAttackCrit = damageResult and damageResult.isCrit == true or false
    runtime.lastBasicAttackTargetId = target and (target.instanceId or target.id) or nil
    runtime.pendingBasicAttackBonusDice = nil
    runtime.pendingBasicAttackIgnoreAc = nil
    runtime.pendingBasicAttackIgnoreAcLabel = nil
    runtime.pendingBasicAttackHitBonus = nil
    runtime.pendingBasicAttackHitBonusLabel = nil
    runtime.pendingBasicAttackDamageMultiplier = nil
    runtime.pendingBasicAttackDamageMultiplierLabel = nil
    runtime.pendingBasicAttackForceCrit = nil
    runtime.pendingBasicAttackForceCritLabel = nil
end

function BuildPassiveCommon.ResolveQueuedReactions(attacker)
    local ok, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
    if ok and FighterBuildPassives and FighterBuildPassives.ResolveQueuedReactions then
        FighterBuildPassives.ResolveQueuedReactions(attacker)
    end
end

function BuildPassiveCommon.GetDefenderAcBonus(defender, attacker)
    local total = 0
    local okMonk, MonkBuildPassives = pcall(require, "skills.monk_build_passives")
    if okMonk and MonkBuildPassives and MonkBuildPassives.GetShadowStepAcBonus then
        total = total + (tonumber(MonkBuildPassives.GetShadowStepAcBonus(defender, attacker)) or 0)
    end
    local okCleric, ClericBuildPassives = pcall(require, "skills.cleric_build_passives")
    if okCleric and ClericBuildPassives and ClericBuildPassives.GetAuraAcBonus then
        total = total + (tonumber(ClericBuildPassives.GetAuraAcBonus(defender, attacker)) or 0)
    end
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
        total = total - (tonumber(BattleBuff.GetBuffValueBySubType(defender, 890005)) or 0)
    end
    return total
end

function BuildPassiveCommon.GetDefenderSaveBonus(defender, saveType)
    local total = 0
    local okPaladin, PaladinBuildPassives = pcall(require, "skills.paladin_build_passives")
    if okPaladin and PaladinBuildPassives and PaladinBuildPassives.GetAuraSaveBonus then
        total = total + (tonumber(PaladinBuildPassives.GetAuraSaveBonus(defender, saveType)) or 0)
    end
    if saveType == "ref" then
        local okBattleBuff, BattleBuff = pcall(require, "modules.battle_buff")
        if okBattleBuff and BattleBuff and BattleBuff.GetBuffValueBySubType then
            total = total - (tonumber(BattleBuff.GetBuffValueBySubType(defender, 890005)) or 0)
        end
    end
    return total
end

function BuildPassiveCommon.ShouldIgnoreFrontProtection(hero, skill)
    return shouldIgnoreFrontProtection(hero, skill)
end

function BuildPassiveCommon.ApplyTeamProtections(defender, extraParam)
    local okCleric, ClericBuildPassives = pcall(require, "skills.cleric_build_passives")
    if okCleric and ClericBuildPassives and ClericBuildPassives.ApplyClericProtections then
        ClericBuildPassives.ApplyClericProtections(defender, extraParam)
    end
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
