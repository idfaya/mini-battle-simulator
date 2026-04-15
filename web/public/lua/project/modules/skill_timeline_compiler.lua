local SkillEffectRegistry = require("modules.skill_effect_registry")

local SkillTimelineCompiler = {}

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
    return ctx.targets or {}
end

local function ExecuteOp(ctx, frameCopy)
    if frameCopy and (frameCopy.skip == true or frameCopy.__skip == true) then
        return {}
    end
    local op = frameCopy.op
    if op == "cast" or op == "effect" then
        return {}
    end

    if op == "damage" or op == "chain_damage" then
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local rate = frameCopy.damageRate
        if not rate and frameCopy.rateKey and ctx.skillDef and ctx.skillDef.params then
            rate = ctx.skillDef.params[frameCopy.rateKey]
        end
        rate = tonumber(rate) or 0
        local total = 0
        local targets = frameCopy.targets or {}
        for _, target in ipairs(targets) do
            if target and not target.isDead then
                local dmg = BattleSkill.CalculateDamageWithRate(ctx.hero, target, rate)
                BattleDmgHeal.ApplyDamage(target, dmg, ctx.hero, {
                    skillId = ctx.skill and ctx.skill.skillId or nil,
                    skillName = ctx.skill and ctx.skill.name or nil,
                })
                total = total + dmg
                ctx.lastHitTargets = { target }
            end
        end
        return { damage = total, targets = targets }
    end

    if op == "heal" then
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
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
