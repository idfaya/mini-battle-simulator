local SkillEffectRegistry = require("skills.skill_effect_registry")

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
        local BattleFormula = require("core.battle_formula")
        local Dice = require("core.dice")
        local Skill5eMeta = require("config.skill_5e_meta")
        local total = 0
        local targets = frameCopy.targets or {}
        local savedTargets = {}
        local hitMetaByTarget = {}
        local skillId = tonumber(ctx.skill and ctx.skill.skillId) or 0
        local meta = Skill5eMeta.Get(skillId)
        local diceScale = tonumber(meta and meta.diceScale) or (BattleFormula.GetDiceScale and BattleFormula.GetDiceScale()) or 1
        for _, target in ipairs(targets) do
            if target and not target.isDead then
                local dmg = 0
                local isCrit = false
                local resolvedKind = frameCopy.damageKind or "direct"

                local isSpell = meta and meta.kind == "spell"

                if isSpell then
                    local dc = tonumber(ctx.hero and ctx.hero.spellDC) or 10
                    local saveType = (type(frameCopy.saveType) == "string" and frameCopy.saveType ~= "" and frameCopy.saveType) or (meta and meta.saveType) or "ref"

                    local saveBonus = 0
                    if saveType == "fort" then
                        saveBonus = tonumber(target.saveFort) or 0
                    elseif saveType == "will" then
                        saveBonus = tonumber(target.saveWill) or 0
                    else
                        saveBonus = tonumber(target.saveRef) or 0
                    end

                    local saveResult = BattleFormula.RollSave(target, dc, saveBonus, {
                        ignoreNatRules = (target.__ignoreNatRules == true) or (ctx.hero and ctx.hero.__ignoreNatRules == true),
                    })
                    hitMetaByTarget[target.instanceId] = { save = saveResult, saveType = saveType, dc = dc }
                    if saveResult.success then
                        savedTargets[target.instanceId] = true
                    end

                    local diceExpr = frameCopy.damageDice
                        or (meta and meta.damageDice)
                        or (BattleSkill.GetSpellDamageDice and BattleSkill.GetSpellDamageDice(ctx.hero, ctx.skill, meta and meta.isAOE, resolvedKind))
                        or "1d6+3"
                    local rolled = 0
                    local damageRoll = nil
                    if not saveResult.success then
                        local diceTotal, diceDetail = Dice.Roll(diceExpr, { crit = false })
                        rolled = diceTotal * diceScale
                        damageRoll = {
                            expr = diceExpr,
                            total = diceTotal,
                            scaledTotal = rolled,
                            parts = diceDetail and diceDetail.parts or {},
                            crit = false,
                        }
                    else
                        local successMode = (type(frameCopy.onSaveSuccess) == "string" and frameCopy.onSaveSuccess ~= "" and frameCopy.onSaveSuccess)
                            or (meta and meta.onSaveSuccess)
                            or "half"
                        local diceTotal, diceDetail = Dice.Roll(diceExpr, { crit = false })
                        local full = diceTotal * diceScale
                        damageRoll = {
                            expr = diceExpr,
                            total = diceTotal,
                            scaledTotal = full,
                            parts = diceDetail and diceDetail.parts or {},
                            crit = false,
                        }
                        if successMode == "half" then
                            rolled = math.floor(full / 2)
                        else
                            rolled = 0
                        end
                    end
                    dmg = BattleSkill.ApplyUnifiedDamageScale and BattleSkill.ApplyUnifiedDamageScale(ctx.hero, target, rolled, resolvedKind) or rolled
                    if hitMetaByTarget[target.instanceId] then
                        hitMetaByTarget[target.instanceId].damage = dmg
                        hitMetaByTarget[target.instanceId].damageRoll = damageRoll
                    end
                else
                    local guardTargetAC = nil
                    local ok, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
                    if ok and FighterBuildPassives and FighterBuildPassives.GetGuardStanceAcBonus then
                        local guardAcBonus = tonumber(FighterBuildPassives.GetGuardStanceAcBonus(target, ctx.hero)) or 0
                        if guardAcBonus > 0 then
                            guardTargetAC = (tonumber(target and target.ac) or 0) + guardAcBonus
                        end
                    end
                    local attackBonus = tonumber(ctx.hero and ctx.hero.hit) or 0
                    local damageResult = BattleSkill.ResolveScaledDamage(ctx.hero, target, {
                        skill = ctx.skill,
                        meta = meta,
                        damageKind = resolvedKind,
                        damageDice = frameCopy.damageDice,
                        attackBonus = attackBonus,
                        targetAC = guardTargetAC,
                    })
                    local hitResult = damageResult and damageResult.hit or nil
                    hitMetaByTarget[target.instanceId] = {
                        hit = hitResult,
                        damageRoll = damageResult and damageResult.damageRoll or nil,
                    }
                    if hitResult and hitResult.hit then
                        isCrit = damageResult and damageResult.isCrit == true or false
                        dmg = math.max(0, math.floor(tonumber(damageResult and damageResult.damage) or 0))
                    else
                        local BattleEvent = require("core.battle_event")
                        local BattleVisualEvents = require("ui.battle_visual_events")
                        BattleEvent.Publish(BattleVisualEvents.MISS, BattleVisualEvents.BuildCombatEvent(
                            BattleVisualEvents.MISS,
                            ctx.hero,
                            target,
                            {
                                skillId = ctx.skill and ctx.skill.skillId or nil,
                                skillName = ctx.skill and ctx.skill.name or nil,
                                attackRoll = hitResult,
                            }))
                        dmg = 0
                    end
                    if hitMetaByTarget[target.instanceId] then
                        hitMetaByTarget[target.instanceId].damage = dmg
                    end
                end

                -- Allow defender-side passives to modify incoming damage.
                local damageContext = {
                    attacker = ctx.hero,
                    target = target,
                    damage = dmg,
                }
                BattlePassiveSkill.RunSkillOnDefBeforeDmg(target, damageContext)
                local ok, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
                if ok and FighterBuildPassives and FighterBuildPassives.ApplyGuardStanceProtection then
                    FighterBuildPassives.ApplyGuardStanceProtection(target, {
                        attacker = ctx.hero,
                        damageContext = damageContext,
                        skill = ctx.skill,
                    })
                end
                dmg = math.max(0, math.floor(damageContext.damage or dmg))

                if dmg > 0 then
                    BattleDmgHeal.ApplyDamage(target, dmg, ctx.hero, {
                        skillId = ctx.skill and ctx.skill.skillId or nil,
                        skillName = ctx.skill and ctx.skill.name or nil,
                        damageKind = resolvedKind,
                        isCrit = isCrit,
                        attackRoll = hitMetaByTarget[target.instanceId] and hitMetaByTarget[target.instanceId].hit or nil,
                        saveRoll = hitMetaByTarget[target.instanceId] and hitMetaByTarget[target.instanceId].save or nil,
                        damageRoll = hitMetaByTarget[target.instanceId] and hitMetaByTarget[target.instanceId].damageRoll or nil,
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
        frameCopy.__savedTargets = savedTargets
        frameCopy.__hitMetaByTarget = hitMetaByTarget
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
        local Skill5eMeta = require("config.skill_5e_meta")
        local meta = Skill5eMeta.Get(ctx.skill and ctx.skill.skillId or 0) or {}
        local healDice = frameCopy.healDice or meta.healDice or "1d8+1"
        local total = 0
        local targets = frameCopy.targets or {}
        for _, target in ipairs(targets) do
            if target and not target.isDead then
                local heal = BattleSkill.CalculateHealDice(ctx.hero, target, healDice)
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
