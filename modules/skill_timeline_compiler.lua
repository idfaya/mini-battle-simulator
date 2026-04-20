local SkillEffectRegistry = require("modules.skill_effect_registry")

local SkillTimelineCompiler = {}

-- Keep timeline damage/heal semantics consistent with the default attack path:
-- - run DefBeforeDmg / DefAfterDmg passives
-- - trigger damage-related buffs
-- - feed pursuit-on-kill and other kill hooks via normal ApplyDamage + hooks
-- This reduces balance skew between scripted timeline skills and fallback attacks.

local function ShallowClone(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

local function ResolveTargets(ctx, frameCopy)
    if frameCopy.target then
        return { frameCopy.target }
    end
    local ref = frameCopy.targetRef
    if ref == "self" then
        return { ctx.hero }
    end
    if ref == "lastHit" then
        return ctx.lastHitTargets or {}
    end
    -- default: selected
    return ctx.targets or {}
end

local function ExecuteOp(ctx, frameCopy)
    if frameCopy and (frameCopy.skip == true or frameCopy.__skip == true) then
        return {}
    end
    local op = frameCopy.op
    if op == "cast" or op == "effect" then
        -- Reset per-cast temporary modifiers so they don't leak into later actions.
        if ctx and ctx.hero then
            ctx.hero.__timelineCritRateBonus = nil
        end
        return {}
    end

    if op == "damage" or op == "chain_damage" then
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local BattlePassiveSkill = require("modules.battle_passive_skill")
        local rate = frameCopy.damageRate
        if not rate and frameCopy.rateKey and ctx.skillDef and ctx.skillDef.params then
            rate = ctx.skillDef.params[frameCopy.rateKey]
        end
        rate = tonumber(rate) or 0
        local total = 0
        local targets = frameCopy.targets or {}
        for _, target in ipairs(targets) do
            if target and not target.isDead then
                local finalRate = rate
                if BattleSkill.ApplyDamageKindBonus then
                    finalRate = BattleSkill.ApplyDamageKindBonus(ctx.hero, target, finalRate, frameCopy.damageKind)
                end
                local dmg = BattleSkill.CalculateDamageWithRate(ctx.hero, target, finalRate)

                -- Allow defender-side passives to modify incoming damage.
                local damageContext = {
                    attacker = ctx.hero,
                    target = target,
                    damage = dmg,
                }
                BattlePassiveSkill.RunSkillOnDefBeforeDmg(target, damageContext)
                dmg = math.max(0, math.floor(damageContext.damage or dmg))

                if dmg > 0 then
                    BattleDmgHeal.ApplyDamage(target, dmg, ctx.hero, {
                        skillId = ctx.skill and ctx.skill.skillId or nil,
                        skillName = ctx.skill and ctx.skill.name or nil,
                        damageKind = frameCopy.damageKind or "direct",
                    })
                    total = total + dmg
                end

                -- Defender after-damage hooks + buff triggers.
                BattlePassiveSkill.RunSkillOnDefAfterDmg(target, { attacker = ctx.hero, damage = dmg })
                BattleSkill.TriggerDamageBuffs(ctx.hero, target, dmg)

                -- Attacker kill hooks (used by several passives).
                if target.isDead or (target.hp or 0) <= 0 then
                    BattlePassiveSkill.RunSkillOnDmgMakeKill(ctx.hero, { target = target })
                end
                ctx.lastHitTargets = { target }
            end
        end
        -- Avoid leaking per-cast crit bonus into later actions when a skill has no explicit "effect" frame.
        if ctx and ctx.hero then
            ctx.hero.__timelineCritRateBonus = nil
        end
        return { damage = total, targets = targets }
    end

    if op == "heal" then
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local BattlePassiveSkill = require("modules.battle_passive_skill")
        local rate = frameCopy.healRate
        if not rate and frameCopy.rateKey and ctx.skillDef and ctx.skillDef.params then
            rate = ctx.skillDef.params[frameCopy.rateKey]
        end
        rate = tonumber(rate) or 0
        local total = 0
        local targets = frameCopy.targets or {}
        for _, target in ipairs(targets) do
            if target and not target.isDead then
                local heal = BattleSkill.CalculateHeal(ctx.hero, target, rate)
                BattleDmgHeal.ApplyHeal(target, heal, ctx.hero)
                total = total + heal
                -- Keep heal-side hooks available for future balance extensions.
                if BattlePassiveSkill.RunSkillOnDefAfterHeal then
                    BattlePassiveSkill.RunSkillOnDefAfterHeal(target, { healer = ctx.hero, heal = heal })
                end
                ctx.lastHitTargets = { target }
            end
        end
        return { healAmount = total, targets = targets }
    end

    return {}
end

function SkillTimelineCompiler.Build(hero, targets, skill, skillDef)
    SkillEffectRegistry.RegisterBuiltins()

    skillDef = skillDef or {}
    local frames = skillDef.frames or {}
    local compiled = {}

    for _, frameDef in ipairs(frames) do
        local defCopy = ShallowClone(frameDef)
        defCopy.execute = nil
        defCopy.frame = defCopy.frame or 0
        defCopy.execute = function(ctx, frameCopy)
                ctx.skillDef = skillDef
                if frameCopy.targets == nil then
                    frameCopy.targets = ResolveTargets(ctx, frameCopy)
                end

                SkillEffectRegistry.Dispatch(ctx, frameCopy, "pre")
                local opResult = ExecuteOp(ctx, frameCopy)
                for k, v in pairs(opResult) do
                    frameCopy[k] = v
                end
                SkillEffectRegistry.Dispatch(ctx, frameCopy, "post")

                return frameCopy
            end,
        table.insert(compiled, defCopy)
    end

    return compiled
end

return SkillTimelineCompiler
