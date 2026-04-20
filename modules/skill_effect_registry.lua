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
    if targets and #targets > 0 then
        return CollectAliveHeroes(targets)
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

local function ResolveBattleIntentBuff(skill)
    local SkillConfig = require("config.skill_config")
    local skillConfig = skill and (skill.skillConfig or SkillConfig.GetSkillConfig(skill.skillId)) or nil
    if skillConfig and skillConfig.SkillLevel == 4 then
        return 840003, 3
    end
    if skillConfig and skillConfig.SkillLevel == 3 then
        return 840002, 3
    end
    return nil, 3
end

local function ApplyChainLightningDirect(hero, hitCount, damageRate)
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local totalDamage = 0
    for _ = 1, hitCount do
        local picked = BattleSkill.SelectRandomAliveEnemies(hero, 1)
        local target = picked and picked[1] or nil
        if target and not target.isDead then
            local damage = BattleSkill.CalculateDamageWithRate(hero, target, damageRate)
            BattleDmgHeal.ApplyDamage(target, damage, hero)
            totalDamage = totalDamage + damage
        end
    end
    return totalDamage
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
        local allies = ResolveFriendTargets(ctx.hero, frameCopy.targets or (ctx and ctx.targets) or {})
        local healCount = ctx.skill and ctx.skill.skillParam and ctx.skill.skillParam[2] or 3
        local healRate = ctx.skill and ctx.skill.skillParam and ctx.skill.skillParam[1] or 2000
        local sortedAllies = SortByLowestHpRatio(allies)
        local selected = {}
        local healed = 0
        for i = 1, math.min(healCount, #sortedAllies) do
            local ally = sortedAllies[i]
            if ally then
                local healAmount = CalculatePercentMaxHpValue(ally, healRate)
                BattleDmgHeal.ApplyHeal(ally, healAmount, ctx.hero)
                healed = healed + healAmount
                table.insert(selected, ally)
            end
        end
        return {
            effectValue = healed,
            healAmount = healed,
            targets = selected,
        }
    end)

    SkillEffectRegistry.Register("holy_light", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local BattleFormation = require("modules.battle_formation")
        local target = frameCopy.targets and frameCopy.targets[1] or nil
        local allies = ResolveFriendTargets(ctx.hero, BattleFormation.GetFriendTeam(ctx.hero) or {})
        local mostInjuredAlly = nil
        local mostMissingHp = 0

        for _, ally in ipairs(allies or {}) do
            local missingHp = math.max(0, (ally.maxHp or 0) - (ally.hp or 0))
            if missingHp > mostMissingHp then
                mostMissingHp = missingHp
                mostInjuredAlly = ally
            end
        end

        -- Holy Light prioritizes healing allies; only attacks enemies when everyone is full HP.
        if mostInjuredAlly and mostMissingHp > 0 then
            target = mostInjuredAlly
        end

        if not target then
            return { damage = 0, healAmount = 0 }
        end

        local isAlly = BattleSkill.IsAlly(ctx.hero, target)
        local damage = 0
        local healAmount = 0
        if isAlly then
            healAmount = CalculatePercentMaxHpValue(target, 1000)
            BattleDmgHeal.ApplyHeal(target, healAmount, ctx.hero)
        else
            damage = BattleSkill.CalculateDamageWithRate(ctx.hero, target, 10000)
            BattleDmgHeal.ApplyDamage(target, damage, ctx.hero, {
                skillId = ctx.skill and ctx.skill.skillId or nil,
                skillName = ctx.skill and ctx.skill.name or nil,
                damageKind = "holy_light",
            })
        end
        return {
            effectValue = isAlly and healAmount or damage,
            damage = damage,
            healAmount = healAmount,
            target = target,
            targets = { target },
        }
    end)

    SkillEffectRegistry.Register("full_heal_cleanse", function(ctx, frameCopy)
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local BattleBuff = require("modules.battle_buff")
        local BattleFormation = require("modules.battle_formation")
        -- Holy Radiance is always a full-team friendly effect. Avoid depending on
        -- upstream selected targets so it never degrades into a single-target heal.
        local allies = CollectAliveHeroes(BattleFormation.GetFriendTeam(ctx.hero) or {})
        local healed = 0
        for _, ally in ipairs(allies) do
            local healAmount = math.max(0, (ally.maxHp or 0) - (ally.hp or 0))
            if healAmount > 0 then
                BattleDmgHeal.ApplyHeal(ally, healAmount, ctx.hero)
                healed = healed + healAmount
            end
            if BattleBuff.RemoveAllDebuffs then
                BattleBuff.RemoveAllDebuffs(ally)
            elseif BattleBuff.ClearAllBuffs then
                BattleBuff.ClearAllBuffs(ally)
            end
        end
        return { effectValue = healed, healAmount = healed, targets = allies }
    end)

    SkillEffectRegistry.Register("battle_intent_buff", function(ctx, frameCopy)
        local BattleSkill = require("modules.battle_skill")
        local BattleFormation = require("modules.battle_formation")
        local targets = CollectAliveHeroes(BattleFormation.GetFriendTeam(ctx.hero) or frameCopy.targets or (ctx and ctx.targets) or {})
        local buffId, duration = ResolveBattleIntentBuff(ctx.skill)
        if not buffId then
            return { effectValue = 0, targets = targets }
        end
        local applied = 0
        for _, target in ipairs(targets) do
            BattleSkill.ApplyBuffFromSkill(ctx.hero, target, buffId, ctx.skill, { duration = duration })
            applied = applied + 1
        end
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
                -- Ultimate burst was too swingy in 6v6; reduce per-stack multiplier.
                local burstDamage = BattleSkill.CalculateDamageWithRate(ctx.hero, enemy, 3500 * stacks)
                BattleDmgHeal.ApplyDamage(enemy, burstDamage, ctx.hero)
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
        for _, t in ipairs(frameCopy.targets or {}) do
            if t and not t.isDead then
                BattleSkill.ApplyBurn(t, stacks, turns, ctx.hero)
            end
        end
        return { buffId = 870001 }
    end)

    SkillEffectRegistry.Register("apply_poison", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local layers = tonumber(p and p.layers) or 1
        for _, t in ipairs(frameCopy.targets or {}) do
            if t and not t.isDead then
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
        for _, t in ipairs(frameCopy.targets or {}) do
            if t and not t.isDead then
                BattleSkill.ApplyFreeze(t, turns, slowPct, ctx.hero)
            end
        end
        return { buffId = 880001 }
    end)

    SkillEffectRegistry.Register("set_damage_rate_passive", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local base = tonumber(p and p.base) or 0
        local key = p and p.key
        if type(key) ~= "string" then
            return nil
        end
        frameCopy.damageRate = BattleSkill.GetPassiveAdjustedRate(ctx.hero, base, key)
        return { damageRate = frameCopy.damageRate }
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
        local p = type(spec) == "table" and spec.param or {}
        local hitCount = tonumber(p and p.hitCount) or 1
        local rate = tonumber(p and p.damageRate) or 10000
        local dmg = ApplyChainLightningDirect(ctx.hero, hitCount, rate)
        local cur = tonumber(frameCopy.damage) or 0
        return { damage = cur + dmg }
    end)

    SkillEffectRegistry.Register("chance_chain_lightning", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local p = type(spec) == "table" and spec.param or {}
        local baseChance = tonumber(p and p.baseChance) or 0
        local key = p and p.key
        local hitCount = tonumber(p and p.hitCount) or 1
        local rate = tonumber(p and p.damageRate) or 10000
        if type(key) ~= "string" then
            return nil
        end
        local chance = BattleSkill.GetPassiveAdjustedChance(ctx.hero, baseChance, key)
        if math.random(1, 10000) <= chance then
            local dmg = ApplyChainLightningDirect(ctx.hero, hitCount, rate)
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
            if t and not t.isDead and math.random(1, 10000) <= chance then
                BattleSkill.ApplyFreeze(t, turns, slowPct, ctx.hero)
            end
        end
        return nil
    end)

    SkillEffectRegistry.Register("random_hits_damage", function(ctx, frameCopy, _, spec)
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local p = type(spec) == "table" and spec.param or {}
        local hits = tonumber(p and p.hits) or 1
        local rate = tonumber(p and p.damageRate) or 10000
        local enablePursuit = p and p.pursuitOnKill == true
        local total = 0
        for _ = 1, hits do
            local picked = BattleSkill.SelectRandomAliveEnemies(ctx.hero, 1)
            local t = picked and picked[1] or nil
            if t and not t.isDead then
                local dmg = BattleSkill.CalculateDamageWithRate(ctx.hero, t, rate)
                BattleDmgHeal.ApplyDamage(t, dmg, ctx.hero)
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
        for _, t in ipairs(frameCopy.targets or {}) do
            if t and not t.isDead then
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
end

return SkillEffectRegistry
