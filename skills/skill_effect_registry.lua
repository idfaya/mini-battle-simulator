local SkillEffectRegistry = {
    handlers = {},
}

local builtinsRegistered = false

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
    local SkillConfig = require("config.skill_config")
    local skillConfig = skill and (skill.skillConfig or SkillConfig.GetSkillConfig(skill.skillId)) or nil
    local skillId = tonumber(skill and skill.skillId) or 0
    local skillLevel = tonumber(skill and skill.level)
        or tonumber(skillConfig and skillConfig.SkillLevel)
        or 1
    if skillId == 80004004 then
        return 840003, 2
    end
    if skillId == 80004003 then
        return 840002, 2
    end
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
    local Skill5eMeta = require("config.skill_5e_meta")
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

local function ApplyChainLightningDirect(hero, hitCount, diceExpr)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _ = 1, hitCount do
        local picked = BattleSkill.SelectRandomAliveEnemies(hero, 1)
        local target = picked and picked[1] or nil
        if target and not target.isDead then
            local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
                skipCheck = true,
                kind = "spell",
                damageKind = "spell",
                damageDice = diceExpr,
            })
            local damage = tonumber(damageResult and damageResult.damage) or 0
            BattleDmgHeal.ApplyDamage(target, damage, hero, { damageKind = "spell" })
            totalDamage = totalDamage + damage
        end
    end
    return totalDamage
end

local function ApplyDirectSpellDamage(hero, target, diceExpr, damageKind, skill)
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

    SkillEffectRegistry.Register("group_heal", function(ctx, frameCopy)
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local BattleBuff = require("modules.battle_buff")
        local allies = ResolveFriendTargets(ctx.hero, frameCopy.targets or (ctx and ctx.targets) or {})
        local tier = tonumber(ctx and ctx.skill and ctx.skill.level) or 1
        local healCount = (tier >= 2) and 2 or 1
        local Skill5eMeta = require("config.skill_5e_meta")
        local meta = Skill5eMeta.Get(ctx.skill and ctx.skill.skillId or 80006003)
        local healDice = (meta and meta.healDice) or "1d8+2"
        local sortedAllies = SortByLowestHpRatio(allies)
        local selected = {}
        local healed = 0
        local channelReady = IsClericChannelReady(ctx.hero)
        local consumedChannel = false
        for i = 1, math.min(healCount, #sortedAllies) do
            local ally = sortedAllies[i]
            if ally then
                local healAmount = CalculateHealByDice(ctx.hero, ally, healDice)
                if tier >= 4 then
                    healAmount = healAmount + math.max(2, math.floor(healAmount * 0.25))
                end
                if channelReady and not consumedChannel then
                    healAmount = healAmount + math.max(2, math.floor(healAmount * 0.25))
                    consumedChannel = true
                end
                BattleDmgHeal.ApplyHeal(ally, healAmount, ctx.hero)
                if tier >= 3 then
                    BattleBuff.DelBuffBySubType(ally, 850001)
                    BattleBuff.DelBuffBySubType(ally, 870001)
                end
                healed = healed + healAmount
                table.insert(selected, ally)
            end
        end
        if consumedChannel then
            ConsumeClericChannel(ctx.hero)
        end
        return {
            effectValue = healed,
            healAmount = healed,
            targets = selected,
        }
    end)

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

    SkillEffectRegistry.Register("revive_latest_ally", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local Skill5eMeta = require("config.skill_5e_meta")
        local skillId = (ctx.skill and ctx.skill.skillId) or 80006004
        local meta = Skill5eMeta.Get(skillId) or {}
        local tier = tonumber(ctx and ctx.skill and ctx.skill.level) or 1
        local hpPct = tonumber(meta.revivePct) or 0.20
        local turns = tonumber(meta.revivePenaltyTurns) or 2
        local atkMul = tonumber(meta.revivePenaltyAtkMul) or 0.75
        local defMul = tonumber(meta.revivePenaltyDefMul) or 0.75
        local speedMul = tonumber(meta.revivePenaltySpeedMul) or 0.80
        if tier >= 2 then
            hpPct = 0.25
            turns = 1
            atkMul = 0.85
            defMul = 0.85
            speedMul = 0.85
        end
        if tier >= 3 then
            hpPct = 0.30
            turns = 1
            atkMul = 0.90
            defMul = 0.90
            speedMul = 0.90
        end
        local revived = BattleSkill.ReviveLatestDeadAlly(ctx.hero, {
            hpPct = hpPct,
            turns = turns,
            atkMul = atkMul,
            defMul = defMul,
            speedMul = speedMul,
        })
        if not revived then
            return { effectValue = 0, targets = {} }
        end
        return { effectValue = revived.hp or 0, healAmount = revived.hp or 0, targets = { revived }, target = revived }
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
        if phase == "pre" then
            frameCopy.__burningTargets = {}
            for _, t in ipairs(frameCopy.targets or {}) do
                if t and BattleBuff.GetBuff(t, 870001) then
                    frameCopy.__burningTargets[t.instanceId or t.id] = true
                end
            end
            return nil
        end

        local total = 0
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                local wasBurning = frameCopy.__burningTargets and frameCopy.__burningTargets[t.instanceId or t.id]
                if wasBurning then
                    total = total + ApplyDirectSpellDamage(ctx.hero, t, p.bonusDice or "1d8", "fire", ctx.skill)
                    if ClaimSpellLikeStatusApplication(ctx, t, "buff:870001") then
                        BattleSkillStatus.ApplyBurnRefreshOnly(t, turns, ctx.hero)
                    end
                else
                    if ClaimSpellLikeStatusApplication(ctx, t, "buff:870001") then
                        BattleSkillStatus.ApplyBurnRefreshOnly(t, turns, ctx.hero)
                    end
                end
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

    SkillEffectRegistry.Register("apply_frost", function(ctx, frameCopy, _, spec)
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 2
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and ClaimSpellLikeStatusApplication(ctx, t, "frost") then
                seen[targetId] = true
                if not (frameCopy.__savedTargets and frameCopy.__savedTargets[targetId]) then
                    BattleSkillStatus.ApplyFrost(t, turns, ctx.hero)
                end
            end
        end
        return { buffId = 880005 }
    end)

    SkillEffectRegistry.Register("wizard_freezing_nova", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local BattleSkillStatus = require("skills.battle_skill_status")
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId]
                and not (frameCopy.__savedTargets and frameCopy.__savedTargets[targetId])
                and ClaimSpellLikeStatusApplication(ctx, t, "freeze") then
                seen[targetId] = true
                if BattleSkillStatus.HasFrost(t) then
                    BattleSkill.ApplyBuffFromSkill(ctx.hero, t, 880002, ctx.skill, { duration = 1 })
                else
                    BattleSkillStatus.ApplyFrost(t, 2, ctx.hero)
                end
            end
        end
        return { buffId = 880005 }
    end)

    SkillEffectRegistry.Register("wizard_blizzard_settlement", function(ctx, frameCopy, phase, spec)
        local BattleSkill = require("modules.battle_skill")
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        if phase == "pre" then
            frameCopy.__frostedTargets = {}
            for _, t in ipairs(frameCopy.targets or {}) do
                if t and BattleSkillStatus.HasFrost(t) then
                    frameCopy.__frostedTargets[t.instanceId or t.id] = true
                end
            end
            return nil
        end

        local total = 0
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                local wasFrosted = frameCopy.__frostedTargets and frameCopy.__frostedTargets[t.instanceId or t.id]
                if wasFrosted then
                    total = total + ApplyDirectSpellDamage(ctx.hero, t, p.bonusDice or "1d8", "ice", ctx.skill)
                end
                if ClaimSpellLikeStatusApplication(ctx, t, "frost") then
                    BattleSkillStatus.ApplyFrost(t, 2, ctx.hero)
                end
            end
        end
        return {
            damage = (tonumber(frameCopy.damage) or 0) + total,
            effectValue = (tonumber(frameCopy.effectValue) or tonumber(frameCopy.damage) or 0) + total,
            buffId = 880005,
        }
    end)

    SkillEffectRegistry.Register("apply_static_mark", function(ctx, frameCopy, _, spec)
        local BattleSkillStatus = require("skills.battle_skill_status")
        local p = type(spec) == "table" and spec.param or {}
        local turns = tonumber(p and p.turns) or 2
        local seen = {}
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t)
                and ClaimSpellLikeStatusApplication(ctx, t, "buff:890001") then
                seen[targetId] = true
                BattleSkillStatus.ApplyStaticMark(t, turns, ctx.hero)
            end
        end
        return { buffId = 890001 }
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
        for _, t in ipairs(frameCopy.targets or {}) do
            local targetId = t and (t.instanceId or t.id) or nil
            if t and not t.isDead and targetId and not seen[targetId] and DidFrameAffectTarget(frameCopy, t) then
                seen[targetId] = true
                local wasMarked = frameCopy.__staticMarkedTargets and frameCopy.__staticMarkedTargets[t.instanceId or t.id]
                if wasMarked then
                    total = total + ApplyDirectSpellDamage(ctx.hero, t, p.bonusDice or "1d8", "thunder", ctx.skill)
                    BattleBuff.DelBuffBySubType(t, 890001)
                else
                    if ClaimSpellLikeStatusApplication(ctx, t, "buff:890001") then
                        BattleSkillStatus.ApplyStaticMark(t, turns, ctx.hero)
                    end
                end
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

    SkillEffectRegistry.Register("pursuit_on_kill", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        for _, t in ipairs(frameCopy.targets or {}) do
            if t and t.isDead then
                BattleSkill.ProcessPursuitEffect(ctx.hero, t, ctx.skill)
            end
        end
        return nil
    end)

    SkillEffectRegistry.Register("chain_lightning", function(ctx, frameCopy, _, spec)
        local Skill5eMeta = require("config.skill_5e_meta")
        local p = type(spec) == "table" and spec.param or {}
        local hitCount = tonumber(p and p.hitCount) or 1
        local meta = Skill5eMeta.Get(ctx.skill and ctx.skill.skillId or 0) or {}
        local diceExpr = meta.chainDice or "1d6+1"
        local dmg = ApplyChainLightningDirect(ctx.hero, hitCount, diceExpr)
        local cur = tonumber(frameCopy.damage) or 0
        return { damage = cur + dmg }
    end)

    SkillEffectRegistry.Register("chance_chain_lightning", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local Skill5eMeta = require("config.skill_5e_meta")
        local p = type(spec) == "table" and spec.param or {}
        local baseChance = tonumber(p and p.baseChance) or 0
        local key = p and p.key
        local hitCount = tonumber(p and p.hitCount) or 1
        if type(key) ~= "string" then
            return nil
        end
        local chance = BattleSkill.GetPassiveAdjustedChance(ctx.hero, baseChance, key)
        if math.random(1, 10000) <= chance then
            local meta = Skill5eMeta.Get(ctx.skill and ctx.skill.skillId or 0) or {}
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
        local Skill5eMeta = require("config.skill_5e_meta")
        local p = type(spec) == "table" and spec.param or {}
        local hits = tonumber(p and p.hits) or 1
        local enablePursuit = p and p.pursuitOnKill == true
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
                if enablePursuit and t.isDead then
                    BattleSkill.ProcessPursuitEffect(ctx.hero, t, ctx.skill)
                end
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

    SkillEffectRegistry.Register("rogue_execute_strike", function(ctx, frameCopy)
        local RogueBuildPassives = require("skills.rogue_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = RogueBuildPassives.PerformExecuteStrike(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("rogue_trickster_blade", function(ctx, frameCopy)
        local RogueBuildPassives = require("skills.rogue_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = RogueBuildPassives.PerformTricksterBlade(ctx.hero, target, ctx.skill)
        return {
            damage = (tonumber(frameCopy.damage) or 0) + damage,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("rogue_swashbuckler_thrust", function(ctx, frameCopy)
        local RogueBuildPassives = require("skills.rogue_build_passives")
        local target = frameCopy.target or ((frameCopy.targets or {})[1]) or ((ctx.targets or {})[1])
        if not target or target.isDead then
            return nil
        end
        local damage = RogueBuildPassives.PerformSwashbucklerThrust(ctx.hero, target, ctx.skill)
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

    SkillEffectRegistry.Register("paladin_lay_on_hands", function(ctx, frameCopy)
        local PaladinBuildPassives = require("skills.paladin_build_passives")
        local effectValue, healedTarget = PaladinBuildPassives.PerformLayOnHands(ctx.hero, frameCopy.target, ctx.skill)
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
