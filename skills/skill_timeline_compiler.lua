local SkillEffectRegistry = require("skills.skill_effect_registry")

local SkillTimelineCompiler = {}

local function getSkillModRaw(unit, skillId, key)
    if not unit or not skillId then
        return nil
    end
    local buildState = unit.buildState
    if type(buildState) ~= "table" then
        return nil
    end
    local skillMods = buildState.skillMods
    if type(skillMods) ~= "table" then
        return nil
    end
    local entry = skillMods[skillId]
    if type(entry) ~= "table" then
        return nil
    end
    return entry[key]
end

local function joinDiceParts(a, b)
    a = type(a) == "string" and a or ""
    b = type(b) == "string" and b or ""
    if a == "" then
        return b
    end
    if b == "" then
        return a
    end
    return a .. ";" .. b
end

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

local function ResolveUnitId(unit)
    return unit and (unit.instanceId or unit.id) or nil
end

local function ResolveTargets(ctx, frameCopy)
    if frameCopy.target then
        return { frameCopy.target }
    end
    local dex = frameCopy.targetRef
    if dex == "self" then
        return { ctx.hero }
    end
    if dex == "lastHit" then
        return ctx.lastHitTargets or {}
    end
    -- default: selected（单体技能只取主目标，避免整份 ctx.targets 泄漏到 post 上 buff）
    local targets = ctx.targets or {}
    if #targets <= 1 then
        return targets
    end
    local BattleSkill = require("modules.battle_skill")
    if BattleSkill.IsMultiTargetSkill and BattleSkill.IsMultiTargetSkill(ctx.skill) then
        return targets
    end
    return { targets[1] }
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
        local Skill5eMeta = require("config.tables.skill_meta")
        local total = 0
        local targets = frameCopy.targets or {}
        local savedTargets = {}
        local hitMetaByTarget = {}
        local affectedTargets = {}
        local affectedSeen = {}
        local skillId = tonumber(ctx.skill and ctx.skill.skillId) or 0
        local meta = Skill5eMeta.Get(skillId)
        local attackMode = Skill5eMeta.ResolveAttackMode(meta)
        local diceScale = tonumber(meta and meta.diceScale) or (BattleFormula.GetDiceScale and BattleFormula.GetDiceScale()) or 1
        local skillBonusDamageDice = getSkillModRaw(ctx.hero, skillId, "bonusDamageDice")
        local frameBonusDamageDice = frameCopy.bonusDamageDice
        local effectiveDamageDice = joinDiceParts(
            frameCopy.damageDice or (meta and meta.damageDice) or "",
            joinDiceParts(frameBonusDamageDice, skillBonusDamageDice)
        )
        if effectiveDamageDice == "" then
            effectiveDamageDice = nil
        end
        for _, target in ipairs(targets) do
            if target and not target.isDead then
                local dmg = 0
                local isCrit = false
                local resolvedKind = frameCopy.damageKind or "direct"

                if attackMode == "spell_save" then
                    local BattleEvent = require("core.battle_event")
                    local BattleVisualEvents = require("ui.battle_visual_events")
                    local Logger = require("utils.logger")
                    local effectiveMeta = meta
                    if frameCopy.saveType or frameCopy.onSaveSuccess then
                        effectiveMeta = ShallowClone(meta or {})
                        if type(frameCopy.saveType) == "string" and frameCopy.saveType ~= "" then
                            effectiveMeta.saveType = frameCopy.saveType
                        end
                        if type(frameCopy.onSaveSuccess) == "string" and frameCopy.onSaveSuccess ~= "" then
                            effectiveMeta.onSaveSuccess = frameCopy.onSaveSuccess
                        end
                    end
                    local targetId = ResolveUnitId(target)
                    local saveType = (effectiveMeta and effectiveMeta.saveType) or "dex"
                    local dc = tonumber(ctx.hero and ctx.hero.spellDC) or 10
                    local damageResult = BattleSkill.ResolveScaledDamage(ctx.hero, target, {
                        skill = ctx.skill,
                        meta = effectiveMeta,
                        damageKind = resolvedKind,
                        damageDice = effectiveDamageDice,
                    })
                    local saveResult = damageResult and damageResult.save or nil
                    hitMetaByTarget[targetId] = { save = saveResult, saveType = saveType, dc = dc }
                    if saveResult and saveResult.success then
                        savedTargets[targetId] = true
                    end
                    isCrit = damageResult and damageResult.isCrit == true or false
                    local damageRoll = damageResult and damageResult.damageRoll or nil
                    dmg = math.max(0, math.floor(tonumber(damageResult and damageResult.damage) or 0))
                    if hitMetaByTarget[targetId] then
                        hitMetaByTarget[targetId].damage = dmg
                        hitMetaByTarget[targetId].damageRoll = damageRoll
                    end
                    if dmg > 0 then
                        BattleDmgHeal.ApplyDamage(target, dmg, ctx.hero, {
                            skillId = ctx.skill and ctx.skill.skillId or nil,
                            skillName = ctx.skill and ctx.skill.name or nil,
                            damageKind = resolvedKind,
                            preferSkillColor = true,
                            isCrit = isCrit,
                            saveRoll = hitMetaByTarget[targetId] and hitMetaByTarget[targetId].save or nil,
                            damageRoll = hitMetaByTarget[targetId] and hitMetaByTarget[targetId].damageRoll or nil,
                            saveType = saveType,
                            onSaveSuccess = effectiveMeta and effectiveMeta.onSaveSuccess or nil,
                        })
                        total = total + dmg
                    elseif saveResult and saveResult.success then
                        Logger.Log(string.format("[SAVE] %s 对 %s 豁免成功 (roll=%d total=%d vs DC=%d)",
                            target.name or "Unknown",
                            ctx.hero and ctx.hero.name or "Unknown",
                            saveResult.roll or 0,
                            saveResult.total or 0,
                            saveResult.dc or dc))
                        BattleEvent.Publish(BattleVisualEvents.MISS, BattleVisualEvents.BuildCombatEvent(
                            BattleVisualEvents.MISS,
                            ctx.hero,
                            target,
                            {
                                skillId = ctx.skill and ctx.skill.skillId or nil,
                                skillName = ctx.skill and ctx.skill.name or nil,
                                saveRoll = saveResult,
                                saveType = saveType,
                                onSaveSuccess = effectiveMeta and effectiveMeta.onSaveSuccess or nil,
                            }))
                    end
                    BattlePassiveSkill.RunSkillOnDefAfterDmg(target, { attacker = ctx.hero, damage = dmg })
                    BattleSkill.TriggerDamageBuffs(ctx.hero, target, dmg)
                    if target.isDead or (target.hp or 0) <= 0 then
                        BattlePassiveSkill.RunSkillOnDmgMakeKill(ctx.hero, { target = target })
                    end
                    if targetId and not savedTargets[targetId] and not affectedSeen[targetId] then
                        affectedSeen[targetId] = true
                        affectedTargets[#affectedTargets + 1] = target
                    end
                    ctx.lastHitTargets = { target }
                else
                    local BuildPassiveCommon = require("skills.build_passive_common")
                    local originalTarget = target
                    local actualTarget, protectionMeta = BuildPassiveCommon.ResolveProtectedDefender(target, {
                        attacker = ctx.hero,
                        skill = ctx.skill,
                    })
                    local attackBonus = nil
                    if attackMode == "spell_attack" then
                        attackBonus = tonumber(ctx.hero and ctx.hero.spellAttack) or tonumber(ctx.hero and ctx.hero.hit) or 0
                    else
                        attackBonus = tonumber(ctx.hero and ctx.hero.hit) or 0
                    end
                    local damageResult = BattleSkill.ResolveScaledDamage(ctx.hero, actualTarget, {
                        skill = ctx.skill,
                        meta = meta,
                        damageKind = resolvedKind,
                        damageDice = effectiveDamageDice,
                        attackBonus = attackBonus,
                    })
                    local hitResult = damageResult and damageResult.hit or nil
                    local actualTargetId = ResolveUnitId(actualTarget)
                    hitMetaByTarget[actualTargetId] = {
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
                            actualTarget,
                            {
                                skillId = ctx.skill and ctx.skill.skillId or nil,
                                skillName = ctx.skill and ctx.skill.name or nil,
                                attackRoll = hitResult,
                            }))
                        dmg = 0
                    end
                    if hitMetaByTarget[actualTargetId] then
                        hitMetaByTarget[actualTargetId].damage = dmg
                    end
                    if actualTargetId and hitResult and hitResult.hit and not affectedSeen[actualTargetId] then
                        affectedSeen[actualTargetId] = true
                        affectedTargets[#affectedTargets + 1] = actualTarget
                    end
                    target = actualTarget

                    -- Allow defender-side passives to modify incoming damage.
                    local damageContext = {
                        attacker = ctx.hero,
                        target = actualTarget,
                        originalTarget = originalTarget,
                        damage = dmg,
                        damageKind = ctx.skill and ctx.skill.rules and ctx.skill.rules.kind or nil,
                        skillId = ctx.skill and (ctx.skill.skillId or ctx.skill.id) or nil,
                        attackRoll = hitResult,
                        attackHit = hitResult and hitResult.hit == true or false,
                    }
                    BattlePassiveSkill.RunSkillOnDefBeforeDmg(actualTarget, damageContext)
                    local ok, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
                    if ok and FighterBuildPassives and FighterBuildPassives.ApplyGuardStanceProtection then
                        FighterBuildPassives.ApplyGuardStanceProtection(actualTarget, {
                            attacker = ctx.hero,
                            damageContext = damageContext,
                            skill = ctx.skill,
                            originalDefender = originalTarget,
                            guardDefender = protectionMeta and protectionMeta.guard or nil,
                        })
                    end
                    dmg = math.max(0, math.floor(damageContext.damage or dmg))

                    if dmg > 0 then
                        BattleDmgHeal.ApplyDamage(actualTarget, dmg, ctx.hero, {
                            skillId = ctx.skill and ctx.skill.skillId or nil,
                            skillName = ctx.skill and ctx.skill.name or nil,
                            damageKind = resolvedKind,
                            preferSkillColor = true,
                            isCrit = isCrit,
                            attackRoll = hitMetaByTarget[actualTargetId] and hitMetaByTarget[actualTargetId].hit or nil,
                            damageRoll = hitMetaByTarget[actualTargetId] and hitMetaByTarget[actualTargetId].damageRoll or nil,
                        })
                        total = total + dmg
                    end

                    -- Defender after-damage hooks + buff triggers.
                    BattlePassiveSkill.RunSkillOnDefAfterDmg(actualTarget, { attacker = ctx.hero, damage = dmg })
                    BattleSkill.TriggerDamageBuffs(ctx.hero, actualTarget, dmg)

                    -- Attacker kill hooks (used by several passives).
                    if actualTarget.isDead or (actualTarget.hp or 0) <= 0 then
                        BattlePassiveSkill.RunSkillOnDmgMakeKill(ctx.hero, { target = actualTarget })
                    end
                    ctx.lastHitTargets = { actualTarget }
                end
            end
        end
        frameCopy.__savedTargets = savedTargets
        frameCopy.__hitMetaByTarget = hitMetaByTarget
        -- Avoid leaking per-cast crit bonus into later actions when a skill has no explicit "effect" frame.
        if ctx and ctx.hero then
            ctx.hero.__timelineCritRateBonus = nil
        end
        local resolvedTargets = #affectedTargets > 0 and affectedTargets or targets
        return { damage = total, targets = resolvedTargets }
    end

    if op == "heal" then
        local BattleSkill = require("modules.battle_skill")
        local BattleDmgHeal = require("modules.battle_dmg_heal")
        local BattlePassiveSkill = require("modules.battle_passive_skill")
        local Skill5eMeta = require("config.tables.skill_meta")
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


