local SkillEffectRegistry = {
    handlers = {},
}

local builtinsRegistered = false
local ApplyDirectSpellDamage

-- §6 各 mod 字段的轻量读取（不引入 FeatModHelper 以避免循环依赖）。
local function getClassModInt(unit, key)
    if not unit then return 0 end
    local buildState = unit.buildState
    if type(buildState) ~= "table" then return 0 end
    local classMods = buildState.classMods
    if type(classMods) ~= "table" then return 0 end
    return math.max(0, math.floor(tonumber(classMods[key]) or 0))
end

local function getSkillModInt(unit, skillId, key)
    if not unit or not skillId then return 0 end
    local buildState = unit.buildState
    if type(buildState) ~= "table" then return 0 end
    local skillMods = buildState.skillMods
    if type(skillMods) ~= "table" then return 0 end
    local entry = skillMods[skillId]
    if type(entry) ~= "table" then return 0 end
    return math.max(0, math.floor(tonumber(entry[key]) or 0))
end

local function getSkillModRaw(unit, skillId, key)
    if not unit or not skillId then return nil end
    local buildState = unit.buildState
    if type(buildState) ~= "table" then return nil end
    local skillMods = buildState.skillMods
    if type(skillMods) ~= "table" then return nil end
    local entry = skillMods[skillId]
    if type(entry) ~= "table" then return nil end
    return entry[key]
end

function SkillEffectRegistry.Register(tag, handler)
    if type(tag) ~= "string" or tag == "" then
        return
    end
    if type(handler) ~= "function" then
        return
    end
    SkillEffectRegistry.handlers[tag] = handler
end

local function GetSpecTag(spec)
    if type(spec) == "string" then
        return spec
    end
    if type(spec) == "table" then
        return spec.tag
    end
    return nil
end

local function GetSpecPhase(spec, defaultPhase)
    if type(spec) == "table" and type(spec.phase) == "string" then
        return spec.phase
    end
    return defaultPhase
end

local function CollectAliveHeroes(list)
    local alive = {}
    for _, unit in ipairs(list or {}) do
        if unit and not unit.isDead then
            table.insert(alive, unit)
        end
    end
    return alive
end

local function ResolveFriendTargets(hero, targets)
    local function IsAlly(unit)
        if not hero or not unit then
            return false
        end
        return hero.isLeft == unit.isLeft
    end

    if targets and #targets > 0 then
        local allies = {}
        for _, unit in ipairs(targets) do
            if unit and not unit.isDead and IsAlly(unit) then
                table.insert(allies, unit)
            end
        end
        if #allies > 0 then
            return allies
        end
    end
    local BattleFormation = require("modules.battle_formation")
    return CollectAliveHeroes(BattleFormation.GetFriendTeam(hero) or {})
end

local function ResolveEnemyTargets(hero, targets)
    if targets and #targets > 0 then
        return CollectAliveHeroes(targets)
    end
    local BattleFormation = require("modules.battle_formation")
    return CollectAliveHeroes(BattleFormation.GetEnemyTeam(hero) or {})
end

local function SortByLowestHpRatio(units)
    table.sort(units, function(a, b)
        local aRatio = (a.hp and a.maxHp and a.maxHp > 0) and (a.hp / a.maxHp) or 1
        local bRatio = (b.hp and b.maxHp and b.maxHp > 0) and (b.hp / b.maxHp) or 1
        if aRatio == bRatio then
            return (a.hp or 0) < (b.hp or 0)
        end
        return aRatio < bRatio
    end)
    return units
end

local function CalculatePercentMaxHpValue(target, rate)
    local maxHp = target and target.maxHp or 0
    if maxHp <= 0 then
        return 0
    end
    return math.max(1, math.floor(maxHp * (tonumber(rate) or 0) / 10000))
end

local function CalculateHealByDice(caster, target, diceExpr)
    local BattleSkill = require("modules.battle_skill")
    return BattleSkill.CalculateHealDice(caster, target, diceExpr)
end

local function EnsurePassiveRuntime(hero)
    if not hero then
        return {}
    end
    hero.passiveRuntime = hero.passiveRuntime or {}
    return hero.passiveRuntime
end

local function GetBattleRound()
    local BattleLogic = require("modules.battle_logic")
    return tonumber(BattleLogic.GetCurRound and BattleLogic.GetCurRound()) or 0
end

local function HasStaticMark(target)
    local BattleBuff = require("modules.battle_buff")
    return target and BattleBuff.GetBuff(target, 890001) ~= nil
end

local function GetWarlockMarkPayoutLimit(hero)
    local configured = math.max(
        getSkillModInt(hero, 80009002, "markPayoutPerRound"),
        getClassModInt(hero, "markPayoutPerRound")
    )
    if configured > 0 then
        return configured
    end
    return 1
end

local function ClaimWarlockMarkPayout(hero, target)
    if not hero or not target then
        return false
    end
    local runtime = EnsurePassiveRuntime(hero)
    local round = GetBattleRound()
    if runtime.warlockMarkedDamageRound ~= round then
        runtime.warlockMarkedDamageRound = round
        runtime.warlockMarkedDamageCount = 0
        runtime.warlockMarkedDamageTargets = {}
    end
    local maxPerRound = GetWarlockMarkPayoutLimit(hero)
    if (tonumber(runtime.warlockMarkedDamageCount) or 0) >= maxPerRound then
        return false
    end
    local targetId = tonumber(target.instanceId or target.id) or 0
    if maxPerRound > 1 and targetId ~= 0 and runtime.warlockMarkedDamageTargets[targetId] == true then
        return false
    end
    runtime.warlockMarkedDamageCount = (tonumber(runtime.warlockMarkedDamageCount) or 0) + 1
    if targetId ~= 0 then
        runtime.warlockMarkedDamageTargets[targetId] = true
    end
    return true
end

local function ApplyWarlockStaticMarkPayout(hero, target, skill)
    if not hero or not target or target.isDead or not HasStaticMark(target) then
        return 0
    end
    if not ClaimWarlockMarkPayout(hero, target) then
        return 0
    end
    local diceExpr = "1d6"
    local bonusDice = getSkillModRaw(hero, 80009002, "markBonusDice")
    if type(bonusDice) == "string" and bonusDice ~= "" then
        diceExpr = diceExpr .. ";" .. bonusDice
    end
    return ApplyDirectSpellDamage(hero, target, diceExpr, "thunder", skill)
end

local function IsClericChannelReady(hero)
    local runtime = EnsurePassiveRuntime(hero)
    return runtime.clericChannelReady == true
end

local function ConsumeClericChannel(hero)
    local runtime = EnsurePassiveRuntime(hero)
    runtime.clericChannelReady = false
end

local function GetClassId(unit)
    return tonumber(unit and (unit.class or unit.Class)) or 0
end

local function ResolveBattleIntentBuff(skill)
    local SkillConfig = require("config.tables.skills")
    local skillConfig = skill and (skill.skillConfig or SkillConfig.GetSkillConfig(skill.skillId)) or nil
    local skillId = tonumber(skill and skill.skillId) or 0
    local skillLevel = tonumber(skill and skill.level)
        or tonumber(skillConfig and skillConfig.skillTier)
        or 1
    if skillLevel >= 4 then
        return 840003, 2
    end
    if skillLevel >= 3 then
        return 840002, 2
    end
    return nil, 2
end

local function DidFrameAffectTarget(frameCopy, target)
    if not target then
        return false
    end

    local targetId = target.instanceId or target.id
    local hitMeta = frameCopy and frameCopy.__hitMetaByTarget and frameCopy.__hitMetaByTarget[targetId] or nil
    if hitMeta then
        return (tonumber(hitMeta.damage) or 0) > 0
    end

    if frameCopy and type(frameCopy.damage) == "number" then
        return frameCopy.damage > 0
    end

    return true
end

local SPELL_LIKE_STATUS_DEDUPE_SKILLS = {
    [80007001] = true, -- 火焰弹
    [80008001] = true, -- 寒霜射线
    [80009001] = true, -- 邪能冲击
}

local function ShouldDedupeSpellLikeStatus(ctx)
    local skillId = tonumber(ctx and ctx.skill and ctx.skill.skillId) or 0
    if skillId <= 0 then
        return false
    end
    if SPELL_LIKE_STATUS_DEDUPE_SKILLS[skillId] then
        return true
    end
    local Skill5eMeta = require("config.tables.skill_meta")
    local meta = Skill5eMeta.Get(skillId)
    return meta and meta.kind == "spell"
end

local function ClaimSpellLikeStatusApplication(ctx, target, statusKey)
    if not ShouldDedupeSpellLikeStatus(ctx) then
        return true
    end
    local targetId = target and (target.instanceId or target.id) or nil
    if not targetId then
        return true
    end
    ctx.__spellLikeStatusApplied = ctx.__spellLikeStatusApplied or {}
    local targetMap = ctx.__spellLikeStatusApplied[targetId]
    if not targetMap then
        targetMap = {}
        ctx.__spellLikeStatusApplied[targetId] = targetMap
    end
    if targetMap[statusKey] then
        return false
    end
    targetMap[statusKey] = true
    return true
end

local function ApplyChainLightningDirect(hero, hitCount, diceExpr, opts)
    local BattleBuff = require("modules.battle_buff")
    local BattleFormation = require("modules.battle_formation")
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    opts = type(opts) == "table" and opts or {}
    local totalDamage = 0
    local pickedIds = {}
    local firstTarget = opts.firstTarget
    local preferMarked = opts.preferMarked == true
    local damageMultiplier = tonumber(opts.damageMultiplier) or 1
    for _, excludedId in ipairs(opts.excludeTargetIds or {}) do
        pickedIds[tonumber(excludedId) or 0] = true
    end
    for hitIndex = 1, hitCount do
        local target = nil
        if hitIndex == 1 and firstTarget and not firstTarget.isDead then
            local firstId = tonumber(firstTarget.instanceId or firstTarget.id) or 0
            if firstId == 0 or not pickedIds[firstId] then
                target = firstTarget
            end
        end
        if not target then
            local marked = {}
            local normal = {}
            for _, enemy in ipairs(BattleFormation.GetEnemyTeam(hero) or {}) do
                local enemyId = tonumber(enemy and (enemy.instanceId or enemy.id)) or 0
                if enemy and not enemy.isDead and not pickedIds[enemyId] then
                    normal[#normal + 1] = enemy
                    if preferMarked and BattleBuff.GetBuff(enemy, 890001) then
                        marked[#marked + 1] = enemy
                    end
                end
            end
            local pool = (#marked > 0) and marked or normal
            if #pool > 0 then
                target = pool[math.random(1, #pool)]
            end
        end
        if target and not target.isDead then
            pickedIds[tonumber(target.instanceId or target.id) or 0] = true
            local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
                skipCheck = true,
                kind = "spell",
                damageKind = "spell",
                damageDice = diceExpr,
            })
            local damage = tonumber(damageResult and damageResult.damage) or 0
            if damageMultiplier > 0 and damageMultiplier ~= 1 then
                damage = math.max(0, math.floor(damage * damageMultiplier))
            end
            BattleDmgHeal.ApplyDamage(target, damage, hero, { damageKind = "spell" })
            totalDamage = totalDamage + damage
        else
            break
        end
    end
    return totalDamage
end

ApplyDirectSpellDamage = function(hero, target, diceExpr, damageKind, skill)
    if not hero or not target or target.isDead then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
        skipCheck = true,
        noClassScalar = true,
        kind = "spell",
        damageKind = damageKind or "spell",
        damageDice = diceExpr,
    })
    local damage = tonumber(damageResult and damageResult.damage) or 0
    if damage > 0 then
        BattleDmgHeal.ApplyDamage(target, damage, hero, {
            skillId = skill and skill.skillId or nil,
            skillName = skill and skill.name or nil,
            damageKind = damageKind or "spell",
        })
    end
    return damage
end

local function ApplyDirectSpellDamageScaled(hero, target, diceExpr, damageKind, skill, multiplier)
    if not hero or not target or target.isDead then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
        skipCheck = true,
        noClassScalar = true,
        kind = "spell",
        damageKind = damageKind or "spell",
        damageDice = diceExpr,
    })
    local damage = tonumber(damageResult and damageResult.damage) or 0
    local amount = tonumber(multiplier) or 1
    if amount > 0 and amount ~= 1 then
        damage = math.max(0, math.floor(damage * amount))
    end
    if damage > 0 then
        BattleDmgHeal.ApplyDamage(target, damage, hero, {
            skillId = skill and skill.skillId or nil,
            skillName = skill and skill.name or nil,
            damageKind = damageKind or "spell",
        })
    end
    return damage
end

function SkillEffectRegistry.Dispatch(ctx, frameCopy, phase)
    if not frameCopy or not frameCopy.tags then
        return
    end
    for _, spec in ipairs(frameCopy.tags) do
        local tag = GetSpecTag(spec)
        local specPhase = GetSpecPhase(spec, "pre")
        if (specPhase == phase) or (specPhase == "both") then
            local fn = tag and SkillEffectRegistry.handlers[tag] or nil
            if fn then
                local patch = fn(ctx, frameCopy, phase, spec)
                if type(patch) == "table" then
                    for k, v in pairs(patch) do
                        frameCopy[k] = v
                    end
                end
            end
        end
    end
end

function SkillEffectRegistry.RegisterBuiltins()
    if builtinsRegistered then
        return
    end
    builtinsRegistered = true

    SkillEffectRegistry.Register("cleric_radiant_strike", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local tier = tonumber(ctx and ctx.skill and ctx.skill.level) or 1
        if tier < 2 then
            return nil
        end

        local baseDice = (tier >= 3) and "1d6" or "1d4"
        local channelReady = IsClericChannelReady(ctx.hero)
        local bonusDice = channelReady and (baseDice .. "+1d4") or baseDice
        local extraTotal = 0
        local appliedTargets = {}

        for _, target in ipairs(frameCopy.targets or {}) do
            if target and not target.isDead and DidFrameAffectTarget(frameCopy, target) then
                local damageResult = BattleSkill.ResolveScaledDamage(ctx.hero, target, {
                    skipCheck = true,
                    noClassScalar = true,
                    kind = "spell",
                    damageKind = "spell",
                    damageDice = bonusDice,
                })
                local extra = tonumber(damageResult and damageResult.damage) or 0
                if extra > 0 then
                    BattleDmgHeal.ApplyDamage(target, extra, ctx.hero, {
                        skillId = ctx.skill and ctx.skill.skillId or nil,
                        skillName = ctx.skill and ctx.skill.name or nil,
                        damageKind = "spell",
                    })
                    extraTotal = extraTotal + extra
                    table.insert(appliedTargets, target)
                end
            end
        end

        if extraTotal > 0 and channelReady then
            ConsumeClericChannel(ctx.hero)
        end

        if extraTotal <= 0 then
            return nil
        end

        return {
            damage = (tonumber(frameCopy.damage) or 0) + extraTotal,
            effectValue = (tonumber(frameCopy.effectValue) or tonumber(frameCopy.damage) or 0) + extraTotal,
            targets = (#appliedTargets > 0) and appliedTargets or frameCopy.targets,
        }
    end)

    SkillEffectRegistry.Register("battle_intent_buff", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local BattleFormation = require("modules.battle_formation")
        local targets = CollectAliveHeroes(BattleFormation.GetFriendTeam(ctx.hero) or frameCopy.targets or (ctx and ctx.targets) or {})
        local buffId, duration = ResolveBattleIntentBuff(ctx.skill)
        local tier = tonumber(ctx and ctx.skill and ctx.skill.level) or 1
        if not buffId then
            return { effectValue = 0, targets = targets }
        end
        duration = (tonumber(duration) or 2) + math.max(0, tier - 1)
        local applied = 0
        for _, target in ipairs(targets) do
            BattleSkill.ApplyBuffFromSkill(ctx.hero, target, buffId, ctx.skill, { duration = duration })
            applied = applied + 1
        end
        BattleSkill.SetConcentration(ctx.hero, ctx.skill and ctx.skill.skillId, ctx.skill)
        return { effectValue = applied, buffId = buffId, targets = targets }
    end)

    SkillEffectRegistry.Register("poison_burst", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local BattleBuff = require("modules.battle_buff")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local targets = ResolveEnemyTargets(ctx.hero, frameCopy.targets or (ctx and ctx.targets) or {})
        local total = 0
        for _, enemy in ipairs(targets) do
            local stacks = enemy and BattleBuff.GetBuffStackNumBySubType(enemy, 850001) or 0
            if enemy and stacks > 0 then
                local diceExpr = string.format("%dd6", stacks) -- per stack +1d6 burst
                local damageResult = BattleSkill.ResolveScaledDamage(ctx.hero, enemy, {
                    skipCheck = true,
                    noClassScalar = true,
                    kind = "spell",
                    damageKind = "poison",
                    damageDice = diceExpr,
                })
                local burstDamage = tonumber(damageResult and damageResult.damage) or 0
                BattleDmgHeal.ApplyDamage(enemy, burstDamage, ctx.hero, {
                    isCrit = damageResult and damageResult.isCrit or false,
                    isDodged = damageResult and damageResult.isDodged or false,
                    damageKind = "poison",
                })
                total = total + burstDamage
                BattleBuff.DelBuffBySubType(enemy, 850001)
            end
        end
        return { effectValue = total, damage = total, targets = targets }
    end)

    SkillEffectRegistry.Register("apply_burn", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local stacks = tonumber(p and p.stacks) or 1
        local turns = tonumber(p and p.turns) or 2
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and ClaimSpellLikeStatusApplication(ctx, t, "buff:870001") then
                seen[targetId] = true
                BattleSkill.ApplyBurn(t, stacks, turns, ctx.hero)
            end
        end
        return { buffId = 870001 }
    end)

    SkillEffectRegistry.Register("apply_burn_refresh_only", function(ctx, frameCopy, _, spec)
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 2
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and ClaimSpellLikeStatusApplication(ctx, t, "buff:870001") then
                seen[targetId] = true
                BattleSkillStatus.ApplyBurnRefreshOnly(t, turns, ctx.hero)
            end
        end
        return { buffId = 870001 }
    end)

    SkillEffectRegistry.Register("sorcerer_burn_settlement", function(ctx, frameCopy, phase, spec)
        local BattleBuff = require("modules.battle_buff")
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 2
        local skillId = ctx.skill and ctx.skill.skillId or 0
        if phase == "pre" then
            frameCopy.__allTargets = {}
            frameCopy.__burningTargets = {}
            local ignoreDamageOnUnignited = getSkillModRaw(ctx.hero, skillId, "ignoreDamageOnUnignited") == true
            local filteredTargets = {}
            frameCopy.__burnOnlyTargets = {}
            for _, t in ipairs(frameCopy.targets or {}) do
                frameCopy.__allTargets[#frameCopy.__allTargets + 1] = t
                if t and BattleBuff.GetBuff(t, 870001) then
                    frameCopy.__burningTargets[t.instanceId or t.id] = true
                    filteredTargets[#filteredTargets + 1] = t
                elseif ignoreDamageOnUnignited then
                    frameCopy.__burnOnlyTargets[#frameCopy.__burnOnlyTargets + 1] = t
                else
                    filteredTargets[#filteredTargets + 1] = t
                end
            end
            if ignoreDamageOnUnignited then
                frameCopy.targets = filteredTargets
            end
            return nil
        end

        local total = 0
        local seen = {}
        local burstFollowUpPerRound = getSkillModInt(ctx.hero, skillId, "vsBurningFollowupHalfChargesPerRound")
        local bonusVsBurning = getSkillModRaw(ctx.hero, skillId, "vsBurningBonusDice")
        local extendDuration = getSkillModInt(ctx.hero, skillId, "vsBurningExtendDuration")
        local splashAdjacentDice = getSkillModRaw(ctx.hero, skillId, "splashAdjacentDice")
        local targets = frameCopy.__allTargets or frameCopy.targets or {}
        for _, t in ipairs(targets) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                local wasBurning = frameCopy.__burningTargets and frameCopy.__burningTargets[t.instanceId or t.id]
                if wasBurning then
                    local bonusDice = tostring(p.bonusDice or "1d8")
                    if type(bonusVsBurning) == "string" and bonusVsBurning ~= "" then
                        bonusDice = bonusDice .. ";" .. bonusVsBurning
                    end
                    total = total + ApplyDirectSpellDamage(ctx.hero, t, bonusDice, "fire", ctx.skill)
                    if burstFollowUpPerRound > 0 and skillId == 80007003 and ctx.hero then
                        ctx.hero.passiveRuntime = ctx.hero.passiveRuntime or {}
                        local rt = ctx.hero.passiveRuntime
                        local BattleLogic = require("modules.battle_logic")
                        local round = (BattleLogic.GetCurRound and BattleLogic.GetCurRound()) or 0
                        if rt.sorcererBurstFollowUpRound ~= round then
                            rt.sorcererBurstFollowUpRound = round
                            rt.sorcererBurstFollowUpCount = 0
                        end
                        if (tonumber(rt.sorcererBurstFollowUpCount) or 0) < burstFollowUpPerRound then
                            rt.sorcererBurstFollowUpCount = (tonumber(rt.sorcererBurstFollowUpCount) or 0) + 1
                            total = total + ApplyDirectSpellDamageScaled(ctx.hero, t, "1d10", "fire", ctx.skill, 0.5)
                        end
                    end
                    if ClaimSpellLikeStatusApplication(ctx, t, "buff:870001") then
                        BattleSkillStatus.ApplyBurnRefreshOnly(t, turns + extendDuration, ctx.hero)
                    end
                else
                    if ClaimSpellLikeStatusApplication(ctx, t, "buff:870001") then
                        BattleSkillStatus.ApplyBurnRefreshOnly(t, turns, ctx.hero)
                    end
                end
                if type(splashAdjacentDice) == "string" and splashAdjacentDice ~= "" then
                    local BattleSkill = require("modules.battle_skill")
                    local splashTargets = BattleSkill.ExpandAreaTargets(t, { includeRow = true, includeColumn = false })
                    for _, splashTarget in ipairs(splashTargets or {}) do
                        local splashId = splashTarget and (splashTarget.instanceId or splashTarget.id) or nil
                        if splashTarget and not splashTarget.isDead and splashId and splashId ~= targetId then
                            total = total + ApplyDirectSpellDamage(ctx.hero, splashTarget, splashAdjacentDice, "fire", ctx.skill)
                        end
                    end
                end
            end
        end
        for _, t in ipairs(frameCopy.__burnOnlyTargets or {}) do
            if t and not t.isDead and ClaimSpellLikeStatusApplication(ctx, t, "buff:870001") then
                BattleSkillStatus.ApplyBurnRefreshOnly(t, turns, ctx.hero)
            end
        end
        return {
            damage = (tonumber(frameCopy.damage) or 0) + total,
            effectValue = (tonumber(frameCopy.effectValue) or tonumber(frameCopy.damage) or 0) + total,
            buffId = 870001,
        }
    end)

    SkillEffectRegistry.Register("apply_poison", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local layers = tonumber(p and p.layers) or 1
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and ClaimSpellLikeStatusApplication(ctx, t, "buff:850001") then
                seen[targetId] = true
                BattleSkill.ApplyPoison(t, layers, ctx.hero)
            end
        end
        return { buffId = 850001 }
    end)

    SkillEffectRegistry.Register("apply_freeze", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 0
        local slowPct = tonumber(p and p.slowPct) or 0
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and ClaimSpellLikeStatusApplication(ctx, t, "freeze") then
                seen[targetId] = true
                -- Hard control: if the target saved against this spell frame, do not apply.
                if frameCopy.__savedTargets and frameCopy.__savedTargets[targetId] then
                    -- skip
                else
                    BattleSkill.ApplyFreeze(t, turns, slowPct, ctx.hero)
                end
            end
        end
        return { buffId = 880001 }
    end)

    local function runApplySlow(ctx, frameCopy, spec)
        local BattleBuff = require("modules.battle_buff")
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 2
        local penalty = tonumber(p and p.initiativePenalty) or 5
        local seen = {}
        local shieldGranted = false
        local skillId = ctx.skill and ctx.skill.skillId or 0
        local refreshSlowOnFrozenHit = getSkillModRaw(ctx.hero, skillId, "refreshFrostOnFrozenHit") == true
            or getSkillModRaw(ctx.hero, skillId, "refreshSlowOnFrozenHit") == true
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            local allowSlowRefresh = refreshSlowOnFrozenHit and t and BattleBuff.GetBuff(t, 880002) ~= nil
            local canApplySlow = ClaimSpellLikeStatusApplication(ctx, t, "slow")
                or (allowSlowRefresh and ClaimSpellLikeStatusApplication(ctx, t, "slow_refresh"))
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and canApplySlow then
                seen[targetId] = true
                if not (frameCopy.__savedTargets and frameCopy.__savedTargets[targetId]) then
                    BattleSkillStatus.ApplySlow(t, turns, ctx.hero, penalty)
                    if not shieldGranted and ctx.hero then
                        local shieldAmount = getSkillModInt(ctx.hero, skillId, "onCastShield")
                        local maxCharges = getSkillModInt(ctx.hero, skillId, "onCastShieldCharges")
                        if shieldAmount > 0 and maxCharges > 0 then
                            ctx.hero.passiveRuntime = ctx.hero.passiveRuntime or {}
                            local rt = ctx.hero.passiveRuntime
                            rt.wizardFrostArmorShieldUsed = tonumber(rt.wizardFrostArmorShieldUsed) or 0
                            if rt.wizardFrostArmorShieldUsed < maxCharges then
                                rt.wizardFrostArmorShieldUsed = rt.wizardFrostArmorShieldUsed + 1
                                ctx.hero.tempHp = math.max(math.floor(tonumber(ctx.hero.tempHp) or 0), shieldAmount)
                                shieldGranted = true
                            end
                        end
                    end
                end
            end
        end
        return { buffId = 880001 }
    end

    SkillEffectRegistry.Register("apply_slow", function(ctx, frameCopy, _, spec)
        return runApplySlow(ctx, frameCopy, spec)
    end)

    SkillEffectRegistry.Register("apply_frost", function(ctx, frameCopy, _, spec)
        return runApplySlow(ctx, frameCopy, spec)
    end)

    SkillEffectRegistry.Register("wizard_freezing_nova", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local BattleSkillStatus = require("skills.battle_skill_status")
        local seen = {}
        local targets = frameCopy.targets or {}

        -- §6 aoeRadiusDelta：在原有命中目标外按 delta 数量扩展额外敌人。
        local skillId = ctx.skill and ctx.skill.skillId or 0
        local extra = getSkillModInt(ctx.hero, skillId, "aoeRadiusDelta") + getClassModInt(ctx.hero, "aoeRadiusDelta")
        if extra > 0 then
            local BattleFormation = require("modules.battle_formation")
            local existing = {}
            for _, t in ipairs(targets) do
                local tid = t and (t.instanceId or t.id)
                if tid then existing[tid] = true end
            end
            local extended = {}
            for _, e in ipairs(BattleFormation.GetEnemyTeam(ctx.hero) or {}) do
                local eid = e and (e.instanceId or e.id)
                if e and not e.isDead and eid and not existing[eid] then
                    extended[#extended + 1] = e
                    if #extended >= extra then break end
                end
            end
            local merged = {}
            for _, t in ipairs(targets) do merged[#merged + 1] = t end
            for _, t in ipairs(extended) do merged[#merged + 1] = t end
            targets = merged
        end

        for _, t in ipairs(targets) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId]
                and not (frameCopy.__savedTargets and frameCopy.__savedTargets[targetId])
                and ClaimSpellLikeStatusApplication(ctx, t, "freeze") then
                seen[targetId] = true
                if BattleSkillStatus.HasSlow(t) then
                    BattleSkill.ApplyBuffFromSkill(ctx.hero, t, 880002, ctx.skill, { duration = 1 })
                else
                    BattleSkillStatus.ApplySlow(t, 2, ctx.hero)
                end
            end
        end
        return { buffId = 880001 }
    end)

    SkillEffectRegistry.Register("wizard_blizzard_settlement", function(ctx, frameCopy, phase, spec)
        local BattleSkill = require("modules.battle_skill")
        local BattleBuff = require("modules.battle_buff")
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        if phase == "pre" then
            frameCopy.__slowedTargets = {}
            frameCopy.__frozenTargets = {}
            for _, t in ipairs(frameCopy.targets or {}) do
                if t and BattleSkillStatus.HasSlow(t) then
                    frameCopy.__slowedTargets[t.instanceId or t.id] = true
                end
                if t and BattleBuff.GetBuff(t, 880002) then
                    frameCopy.__frozenTargets[t.instanceId or t.id] = true
                end
            end
            return nil
        end

        local total = 0
        local seen = {}
        local skillId = ctx.skill and ctx.skill.skillId or 0
        local frozenExtend = getSkillModInt(ctx.hero, skillId, "vsFrozenExtendDuration")
        local frozenCap = math.max(1, getSkillModInt(ctx.hero, skillId, "vsFrozenExtendCap"))
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                local wasSlowed = frameCopy.__slowedTargets and frameCopy.__slowedTargets[t.instanceId or t.id]
                if wasSlowed then
                    total = total + ApplyDirectSpellDamage(ctx.hero, t, p.bonusDice or "1d8", "ice", ctx.skill)
                end
                if ClaimSpellLikeStatusApplication(ctx, t, "slow") then
                    BattleSkillStatus.ApplySlow(t, 2, ctx.hero)
                end
                if frozenExtend > 0 and frameCopy.__frozenTargets and frameCopy.__frozenTargets[t.instanceId or t.id] then
                    local frozenBuff = BattleBuff.GetBuff(t, 880002)
                    if frozenBuff then
                        local nextDuration = math.min(frozenCap, math.max(tonumber(frozenBuff.duration) or 0, 1) + frozenExtend)
                        frozenBuff.duration = nextDuration
                    else
                        BattleSkill.ApplyBuffFromSkill(ctx.hero, t, 880002, ctx.skill, { duration = math.min(frozenCap, 1 + frozenExtend) })
                    end
                end
            end
        end
        return {
            damage = (tonumber(frameCopy.damage) or 0) + total,
            effectValue = (tonumber(frameCopy.effectValue) or tonumber(frameCopy.damage) or 0) + total,
            buffId = 880001,
        }
    end)

    SkillEffectRegistry.Register("apply_static_mark", function(ctx, frameCopy, _, spec)
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 2

        -- §6 markRecastPerRound：仅当显式配置 > 0 时启用 per-round 限速；默认不变。
        local skillId = ctx.skill and ctx.skill.skillId or 0
        local recastLimit = getSkillModInt(ctx.hero, skillId, "markRecastPerRound")
            + getSkillModInt(ctx.hero, 80009002, "markRecastPerRound")
            + getClassModInt(ctx.hero, "markRecastPerRound")
        local recastUsed = 0
        if recastLimit > 0 and ctx.hero then
            ctx.hero.passiveRuntime = ctx.hero.passiveRuntime or {}
            local rt = ctx.hero.passiveRuntime
            local BattleLogic = require("modules.battle_logic")
            local round = (BattleLogic.GetCurRound and BattleLogic.GetCurRound()) or 0
            if rt.warlockStaticMarkRound ~= round then
                rt.warlockStaticMarkRound = round
                rt.warlockStaticMarkCount = 0
            end
            recastUsed = tonumber(rt.warlockStaticMarkCount) or 0
        end

        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and ClaimSpellLikeStatusApplication(ctx, t, "buff:890001") then
                if recastLimit > 0 and recastUsed >= recastLimit then
                    break
                end
                seen[targetId] = true
                BattleSkillStatus.ApplyStaticMark(t, turns, ctx.hero)
                recastUsed = recastUsed + 1
            end
        end
        if recastLimit > 0 and ctx.hero and ctx.hero.passiveRuntime then
            ctx.hero.passiveRuntime.warlockStaticMarkCount = recastUsed
        end
        return { buffId = 890001 }
    end)

    SkillEffectRegistry.Register("extend_static_mark", function(ctx, frameCopy, _, spec)
        local BattleBuff = require("modules.battle_buff")
        local p = type(spec) == "table" and spec.param or {}
        local turns = math.max(0, math.floor(tonumber(p and p.turns) or 0))
        if turns <= 0 then
            return nil
        end
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                local markBuff = BattleBuff.GetBuff(t, 890001)
                if markBuff then
                    markBuff.duration = math.max(tonumber(markBuff.duration) or 0, 1) + turns
                end
            end
        end
        return { buffId = 890001 }
    end)

    SkillEffectRegistry.Register("warlock_static_mark_payout", function(ctx, frameCopy, phase)
        if phase ~= "post" then
            return nil
        end
        local total = 0
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                total = total + ApplyWarlockStaticMarkPayout(ctx.hero, t, ctx.skill)
            end
        end
        if total <= 0 then
            return nil
        end
        return {
            damage = (tonumber(frameCopy.damage) or 0) + total,
            effectValue = (tonumber(frameCopy.effectValue) or tonumber(frameCopy.damage) or 0) + total,
        }
    end)

    SkillEffectRegistry.Register("warlock_thunderstorm_settlement", function(ctx, frameCopy, phase, spec)
        local BattleBuff = require("modules.battle_buff")
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 2
        if phase == "pre" then
            frameCopy.__staticMarkedTargets = {}
            for _, t in ipairs(frameCopy.targets or {}) do
                if t and BattleSkillStatus.HasStaticMark(t) then
                    frameCopy.__staticMarkedTargets[t.instanceId or t.id] = true
                end
            end
            return nil
        end

        local total = 0
        local seen = {}
        local markedHits = 0
        local hitTargetIds = {}
        local skillId = ctx.skill and ctx.skill.skillId or 0
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                hitTargetIds[#hitTargetIds + 1] = targetId
                local wasMarked = frameCopy.__staticMarkedTargets and frameCopy.__staticMarkedTargets[t.instanceId or t.id]
                if wasMarked then
                    markedHits = markedHits + 1
                    total = total + ApplyWarlockStaticMarkPayout(ctx.hero, t, ctx.skill)
                    total = total + ApplyDirectSpellDamage(ctx.hero, t, p.bonusDice or "1d8", "thunder", ctx.skill)
                    BattleBuff.DelBuffBySubType(t, 890001)
                else
                    if ClaimSpellLikeStatusApplication(ctx, t, "buff:890001") then
                        BattleSkillStatus.ApplyStaticMark(t, turns, ctx.hero)
                    end
                end
            end
        end
        local extraPerMarked = getSkillModInt(ctx.hero, skillId, "onMarkHitChainHalf")
        local extraCap = getSkillModInt(ctx.hero, skillId, "onMarkHitChainHalfPerCast")
        if markedHits > 0 and extraPerMarked > 0 then
            local extraChains = markedHits * extraPerMarked
            if extraCap > 0 then
                extraChains = math.min(extraChains, extraCap)
            end
            if extraChains > 0 then
                total = total + ApplyChainLightningDirect(ctx.hero, extraChains, "1d6+1", {
                    preferMarked = true,
                    damageMultiplier = 0.5,
                    excludeTargetIds = hitTargetIds,
                })
            end
        end
        return {
            damage = (tonumber(frameCopy.damage) or 0) + total,
            effectValue = (tonumber(frameCopy.effectValue) or tonumber(frameCopy.damage) or 0) + total,
            buffId = 890001,
        }
    end)

    SkillEffectRegistry.Register("set_damage_kind", function(_, frameCopy, _, spec)
        local p = type(spec) == "table" and spec.param or {}
        local kind = p and p.kind
        if type(kind) == "string" and kind ~= "" then
            frameCopy.damageKind = kind
            return { damageKind = kind }
        end
        return nil
    end)

    SkillEffectRegistry.Register("set_targets_all_alive_enemies", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local targets = BattleSkill.SelectAllAliveTargets(ctx.hero) or {}
        frameCopy.targets = targets
        return { targets = targets }
    end)

    SkillEffectRegistry.Register("crit_rate_bonus", function(ctx, frameCopy, _, spec)
        local p = type(spec) == "table" and spec.param or {}
        local amount = tonumber(p and p.amount) or 0
        if ctx and ctx.hero and amount ~= 0 then
            ctx.hero.__timelineCritRateBonus = (ctx.hero.__timelineCritRateBonus or 0) + amount
        end
        return nil
    end)

    SkillEffectRegistry.Register("expand_area_targets", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local anchor = (frameCopy.targets and frameCopy.targets[1]) or (ctx.targets and ctx.targets[1]) or nil
        if not anchor then
            frameCopy.targets = {}
            return { targets = {} }
        end
        local area = BattleSkill.ExpandAreaTargets(anchor, {
            includeRow = p.includeRow ~= false,
            includeColumn = p.includeColumn == true,
        })
        frameCopy.targets = area or {}
        return { targets = frameCopy.targets }
    end)

    SkillEffectRegistry.Register("select_lowest_hp_enemy", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local t = BattleSkill.SelectLowestHpEnemy(ctx.hero)
        if not t then
            frameCopy.targets = {}
            return { targets = {} }
        end
        frameCopy.targets = { t }
        frameCopy.target = t
        return { targets = { t }, target = t }
    end)

    SkillEffectRegistry.Register("chain_lightning", function(ctx, frameCopy, _, spec)
        local Skill5eMeta = require("config.tables.skill_meta")
        local p = type(spec) == "table" and spec.param or {}
        local hitCount = tonumber(p and p.hitCount) or 1
        -- §6 chainCountDelta：雷链跳数受 feat 加成。
        local skillId = ctx.skill and ctx.skill.skillId or 0
        hitCount = hitCount + getSkillModInt(ctx.hero, skillId, "chainCountDelta") + getClassModInt(ctx.hero, "chainCountDelta")
        local meta = Skill5eMeta.Get(skillId) or {}
        local diceExpr = meta.chainDice or "1d6+1"
        local dmg = ApplyChainLightningDirect(ctx.hero, hitCount, diceExpr)
        local cur = tonumber(frameCopy.damage) or 0
        return { damage = cur + dmg }
    end)

    SkillEffectRegistry.Register("chance_chain_lightning", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local Skill5eMeta = require("config.tables.skill_meta")
        local p = type(spec) == "table" and spec.param or {}
        local baseChance = tonumber(p and p.baseChance) or 0
        local key = p and p.key
        local hitCount = tonumber(p and p.hitCount) or 1
        if type(key) ~= "string" then
            return nil
        end
        local chance = BattleSkill.GetPassiveAdjustedChance(ctx.hero, baseChance, key)
        if math.random(1, 10000) <= chance then
            local skillId = ctx.skill and ctx.skill.skillId or 0
            -- §6 chainCountDelta：触发型雷链同样受 feat 加成。
            hitCount = hitCount + getSkillModInt(ctx.hero, skillId, "chainCountDelta") + getClassModInt(ctx.hero, "chainCountDelta")
            local meta = Skill5eMeta.Get(skillId) or {}
            local diceExpr = meta.chainDice or "1d6+1"
            local dmg = ApplyChainLightningDirect(ctx.hero, hitCount, diceExpr)
            local cur = tonumber(frameCopy.damage) or 0
            return { damage = cur + dmg }
        end
        return nil
    end)

    SkillEffectRegistry.Register("chance_apply_freeze", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local baseChance = tonumber(p and p.baseChance) or 0
        local key = p and p.key
        local turns = tonumber(p and p.turns) or 1
        local slowPct = tonumber(p and p.slowPct) or 0
        if type(key) ~= "string" then
            return nil
        end
        local chance = BattleSkill.GetPassiveAdjustedChance(ctx.hero, baseChance, key)
        for _, t in ipairs(frameCopy.targets or {}) do
            if t and not t.isDead then
                if frameCopy.__savedTargets and frameCopy.__savedTargets[t.instanceId] then
                    -- Hard control: saved -> immune to control.
                elseif math.random(1, 10000) <= chance then
                    BattleSkill.ApplyFreeze(t, turns, slowPct, ctx.hero)
                end
            end
        end
        return nil
    end)

    SkillEffectRegistry.Register("random_hits_damage", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local Skill5eMeta = require("config.tables.skill_meta")
        local p = type(spec) == "table" and spec.param or {}
        local hits = tonumber(p and p.hits) or 1
        local total = 0
        local meta = Skill5eMeta.Get(ctx.skill and ctx.skill.skillId or 0) or {}
        local diceExpr = meta.multiHitDice or meta.damageDice
        for _ = 1, hits do
            local picked = BattleSkill.SelectRandomAliveEnemies(ctx.hero, 1)
            local t = picked and picked[1] or nil
            if t and not t.isDead then
                local damageResult = BattleSkill.ResolveScaledDamage(ctx.hero, t, {
                    skill = ctx.skill,
                    damageKind = "direct",
                    damageDice = diceExpr,
                })
                local dmg = tonumber(damageResult and damageResult.damage) or 0
                BattleDmgHeal.ApplyDamage(t, dmg, ctx.hero, {
                    damageKind = "direct",
                })
                total = total + dmg
            end
        end
        return { damage = (tonumber(frameCopy.damage) or 0) + total }
    end)

    SkillEffectRegistry.Register("apply_buff_self", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local buffId = tonumber(p and p.buffId) or 0
        if buffId > 0 then
            BattleSkill.ApplyBuffFromSkill(ctx.hero, ctx.hero, buffId, ctx.skill)
        end
        return nil
    end)

    SkillEffectRegistry.Register("apply_buff_all_enemies", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local BattleFormation = require("modules.battle_formation")
        local p = type(spec) == "table" and spec.param or {}
        local buffId = tonumber(p and p.buffId) or 0
        if buffId <= 0 then
            return nil
        end
        for _, enemy in ipairs(BattleFormation.GetEnemyTeam(ctx.hero) or {}) do
            if enemy and not enemy.isDead then
                BattleSkill.ApplyBuffFromSkill(ctx.hero, enemy, buffId, ctx.skill)
            end
        end
        return nil
    end)

    SkillEffectRegistry.Register("remove_buff_by_subtype", function(ctx, frameCopy, _, spec)
        local BattleBuff = require("modules.battle_buff")
        local p = type(spec) == "table" and spec.param or {}
        local subType = tonumber(p and p.subType) or 0
        if subType > 0 then
            BattleBuff.DelBuffBySubType(ctx.hero, subType)
        end
        return nil
    end)

    SkillEffectRegistry.Register("apply_buff_targets", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local buffId = tonumber(p and p.buffId) or 0
        if buffId <= 0 then
            return nil
        end
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                BattleSkill.ApplyBuffFromSkill(ctx.hero, t, buffId, ctx.skill)
            end
        end
        return { buffId = buffId }
    end)

    SkillEffectRegistry.Register("select_random_enemies", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local count = tonumber(p and p.count) or 1
        local picked = BattleSkill.SelectRandomAliveEnemies(ctx.hero, count) or {}
        frameCopy.targets = picked
        return { targets = picked }
    end)

    SkillEffectRegistry.Register("combo_additional_damage", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local targets = frameCopy.targets or {}
        for _, t in ipairs(targets) do
            if t and not t.isDead then
                local extraHits = BattleSkill.ProcessComboEffect(ctx.hero, { t }, ctx.skill)
                for _ = 1, (extraHits or 0) do
                    BattleSkill.CastSmallSkill(ctx.hero, t)
                end
            end
        end
        return nil
    end)

    SkillEffectRegistry.Register("repeat_basic_attack", function(ctx, frameCopy, _, spec)
        local FighterBuildPassives = require("skills.fighter_build_passives")
        local p = type(spec) == "table" and spec.param or {}
        local count = tonumber(p and p.count) or 1
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = FighterBuildPassives.CastBasicAttackRepeated(ctx.hero, target, count)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("basic_attack_action", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local FighterBuildPassives = require("skills.fighter_build_passives")
        local p = type(spec) == "table" and spec.param or {}
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        if p.actionSource == "action_surge" then
            FighterBuildPassives.PublishCombatLog(string.format("%s 发动动作激增：获得额外攻击行动，重新锁定 %s",
                ctx.hero and ctx.hero.name or "Unknown",
                target.name or "目标"))
        end
        local ok, result = BattleSkill.CastBasicAttackAction(ctx.hero, target, {
            basicAttackActionSource = p.actionSource or "extra_action",
        })
        return {
            damage = (tonumber(frameCopy.damage) or 0) + (ok and math.max(0, math.floor(tonumber(result and result.totalDamage) or 0)) or 0),
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("fighter_pressure_strike", function(ctx, frameCopy)
        local FighterBuildPassives = require("skills.fighter_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = FighterBuildPassives.PerformPressureStrike(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("activate_guard_stance", function(ctx, frameCopy)
        local FighterBuildPassives = require("skills.fighter_build_passives")
        FighterBuildPassives.ActivateGuardStance(ctx.hero)
        return {
            effectValue = 1,
            statusEffect = "guard_stance",
            targets = { ctx.hero },
        }
    end)

    SkillEffectRegistry.Register("rogue_cunning_strike", function(ctx, frameCopy)
        local RogueBuildPassives = require("skills.rogue_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = RogueBuildPassives.PerformCunningStrike(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("monk_open_hand_strike", function(ctx, frameCopy)
        local MonkBuildPassives = require("skills.monk_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = MonkBuildPassives.PerformOpenHandStrike(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("monk_shadow_combo", function(ctx, frameCopy)
        local MonkBuildPassives = require("skills.monk_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = MonkBuildPassives.PerformShadowCombo(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("monk_harmonize", function(ctx, frameCopy)
        local MonkBuildPassives = require("skills.monk_build_passives")
        local target = frameCopy.target or ctx.hero
        local effectValue = MonkBuildPassives.PerformHarmonize(target, ctx.skill)
        return {
            effectValue = effectValue,
            healAmount = effectValue,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("paladin_lay_on_hands", function(ctx, frameCopy)
        local PaladinBuildPassives = require("skills.paladin_build_passives")
        local target = ((ctx.targets or {})[1]) or ((frameCopy.targets or {})[1]) or frameCopy.target or ctx.hero
        local effectValue, healedTarget = PaladinBuildPassives.PerformLayOnHands(ctx.hero, target, ctx.skill)
        return {
            effectValue = effectValue,
            healAmount = effectValue,
            targets = healedTarget and { healedTarget } or {},
        }
    end)

    SkillEffectRegistry.Register("paladin_vengeance_smite", function(ctx, frameCopy)
        local PaladinBuildPassives = require("skills.paladin_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = PaladinBuildPassives.PerformVengeanceSmite(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("activate_guardian_aura", function(ctx, frameCopy)
        local PaladinBuildPassives = require("skills.paladin_build_passives")
        PaladinBuildPassives.ActivateGuardianAura(ctx.hero)
        return {
            targets = { ctx.hero },
        }
    end)

    SkillEffectRegistry.Register("ranger_hunter_shot", function(ctx, frameCopy)
        local RangerBuildPassives = require("skills.ranger_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = RangerBuildPassives.PerformHunterShot(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("ranger_shadow_shot", function(ctx, frameCopy)
        local RangerBuildPassives = require("skills.ranger_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = RangerBuildPassives.PerformShadowShot(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("ranger_snare_shot", function(ctx, frameCopy)
        local RangerBuildPassives = require("skills.ranger_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = RangerBuildPassives.PerformSnareShot(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("ranger_arrow_rain", function(ctx, frameCopy)
        local RangerBuildPassives = require("skills.ranger_build_passives")
        local damage = RangerBuildPassives.PerformArrowRain(ctx.hero, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = {},
        }
    end)

    SkillEffectRegistry.Register("barbarian_heavy_strike", function(ctx, frameCopy)
        local BarbarianBuildPassives = require("skills.barbarian_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = BarbarianBuildPassives.PerformHeavyStrike(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)
end

return SkillEffectRegistry
