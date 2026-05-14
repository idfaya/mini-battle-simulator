local SkillRuntimeConfig = require("config.skill_runtime_config")
local BuildPassiveCommon = require("skills.build_passive_common")

local BarbarianBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local MAX_RAGE_STACKS = 5
local BERSERK_DURATION_ROUNDS = 2
local RAGE_BUFF_ID = 890002
local BERSERK_BUFF_ID = 890003

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

local function buildContextState(context)
    return {
        context = context,
    }
end

local function syncRageBuff(hero)
    local BattleBuff = require("modules.battle_buff")
    local BattleSkill = require("modules.battle_skill")
    if not hero then
        return
    end
    local runtime = ensureRuntime(hero)
    local stacks = math.max(0, math.floor(tonumber(runtime.barbarianRageStacks) or 0))
    local buff = BattleBuff.GetBuff(hero, RAGE_BUFF_ID)
    if stacks <= 0 then
        if buff then
            BattleBuff.DelBuffByBuffIdAndCaster(hero, RAGE_BUFF_ID, hero, 1)
        end
        return
    end
    if not buff then
        BattleSkill.ApplyBuffFromSkill(hero, hero, RAGE_BUFF_ID, nil, {
            initialStack = stacks,
            maxStack = MAX_RAGE_STACKS,
            duration = 99,
            isPermanent = true,
        })
        buff = BattleBuff.GetBuff(hero, RAGE_BUFF_ID)
    end
    if buff then
        buff.stackCount = stacks
    end
end

local function syncBerserkBuff(hero)
    local BattleBuff = require("modules.battle_buff")
    local BattleSkill = require("modules.battle_skill")
    if not hero then
        return
    end
    local runtime = ensureRuntime(hero)
    local remain = math.max(0, (tonumber(runtime.barbarianBerserkUntilRound) or -1) - getRound() + 1)
    local buff = BattleBuff.GetBuff(hero, BERSERK_BUFF_ID)
    if remain <= 0 then
        if buff then
            BattleBuff.DelBuffByBuffIdAndCaster(hero, BERSERK_BUFF_ID, hero, 1)
        end
        return
    end
    if not buff then
        BattleSkill.ApplyBuffFromSkill(hero, hero, BERSERK_BUFF_ID, nil, {
            duration = remain,
        })
        buff = BattleBuff.GetBuff(hero, BERSERK_BUFF_ID)
    end
    if buff then
        buff.duration = remain
        buff.maxDuration = math.max(tonumber(buff.maxDuration) or 0, remain)
    end
end

function BarbarianBuildPassives.IsBerserkActive(hero)
    local runtime = ensureRuntime(hero)
    return (tonumber(runtime.barbarianBerserkUntilRound) or -1) >= getRound()
end

function BarbarianBuildPassives.AddRage(hero, amount, reason)
    if not isAlive(hero) or not hasSkill(hero, IDS.barbarian_rage) then
        return 0
    end
    local runtime = ensureRuntime(hero)
    local before = math.max(0, math.floor(tonumber(runtime.barbarianRageStacks) or 0))
    local after = math.min(MAX_RAGE_STACKS, before + math.max(1, math.floor(tonumber(amount) or 1)))
    runtime.barbarianRageStacks = after
    syncRageBuff(hero)
    if after > before then
        BuildPassiveCommon.PublishPassiveTriggered(hero, "狂怒", reason or "积累狂怒", string.format("%d/%d", after, MAX_RAGE_STACKS))
    end
    if after >= MAX_RAGE_STACKS then
        BarbarianBuildPassives.TryActivateBerserk(hero)
    end
    return after - before
end

function BarbarianBuildPassives.TryActivateBerserk(hero)
    if not isAlive(hero) or not hasSkill(hero, IDS.barbarian_berserk) then
        return false
    end
    local runtime = ensureRuntime(hero)
    if runtime.barbarianBerserkUsed == true then
        return false
    end
    if (tonumber(runtime.barbarianRageStacks) or 0) < MAX_RAGE_STACKS then
        return false
    end
    runtime.barbarianBerserkUsed = true
    runtime.barbarianRageStacks = 0
    runtime.barbarianBerserkUntilRound = getRound() + BERSERK_DURATION_ROUNDS - 1
    syncRageBuff(hero)
    syncBerserkBuff(hero)
    BuildPassiveCommon.PublishPassiveTriggered(hero, "狂暴", "怒气爆发", string.format("持续 %d 回合", BERSERK_DURATION_ROUNDS))
    return true
end

function BarbarianBuildPassives.PerformHeavyStrike(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleFormula = require("core.battle_formula")
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local Dice = require("core.dice")
    local Skill5eMeta = require("config.skill_5e_meta")
    local meta = Skill5eMeta.Get(skill and skill.skillId or IDS.barbarian_heavy_strike)
    local acBonus = BuildPassiveCommon.GetDefenderAcBonus(target, hero)
    local hitPenalty = tonumber(meta and meta.hitPenalty) or -2
    local critMin = tonumber(meta and meta.critMin) or 19
    local damageDice = tostring(meta and meta.damageDice or "1d12+3")
    if BarbarianBuildPassives.IsBerserkActive(hero) then
        damageDice = BuildPassiveCommon.JoinDiceParts(damageDice, "1d6")
    end
    local hitResult = BattleFormula.RollHit(hero, target, {
        attackBonus = (tonumber(hero.hit) or 0) + hitPenalty,
        targetAC = (tonumber(target.ac) or 10) + acBonus,
        ignoreNatRules = hero.__ignoreNatRules == true,
    })
    hitResult.crit = hitResult.crit or ((tonumber(hitResult.roll) or 0) >= critMin)
    if not hitResult.hit then
        BarbarianBuildPassives.AddRage(hero, 1, "重击落空")
        return 0
    end
    local diceTotal, diceDetail = Dice.Roll(damageDice, { crit = hitResult.crit == true })
    local rolled = BattleSkill.ApplyUnifiedDamageScale and BattleSkill.ApplyUnifiedDamageScale(hero, target, diceTotal, "direct") or diceTotal
    local damageContext = {
        attacker = hero,
        target = target,
        damage = math.max(0, math.floor(tonumber(rolled) or 0)),
    }
    BattlePassiveSkill.RunSkillOnDefBeforeDmg(target, damageContext)
    BuildPassiveCommon.ApplyTeamProtections(target, {
        attacker = hero,
        damageContext = damageContext,
        skill = skill,
    })
    local damage = math.max(0, math.floor(tonumber(damageContext.damage) or 0))
    if damage > 0 then
        BattleDmgHeal.ApplyDamage(target, damage, hero, {
            skillId = skill and skill.skillId or IDS.barbarian_heavy_strike,
            skillName = skill and skill.name or "重击",
            damageKind = "direct",
            isCrit = hitResult.crit == true,
            attackRoll = hitResult,
            damageRoll = {
                expr = damageDice,
                total = diceTotal,
                parts = diceDetail and diceDetail.parts or {},
                crit = hitResult.crit == true,
            },
        })
        BattlePassiveSkill.RunSkillOnDefAfterDmg(target, { attacker = hero, damage = damage })
        BattleSkill.TriggerDamageBuffs(hero, target, damage)
        if target.isDead or (tonumber(target.hp) or 0) <= 0 then
            BattlePassiveSkill.RunSkillOnDmgMakeKill(hero, { target = target })
        end
    end
    BarbarianBuildPassives.AddRage(hero, 1, "重击")
    return damage
end

function BarbarianBuildPassives.CreateRagePassive(context)
    local self = buildContextState(context)

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.barbarian_basic_attack then
            return
        end
        BarbarianBuildPassives.AddRage(hero, 1, "主动攻击")
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) or not isAlive(extraParam.attacker) then
            return
        end
        BarbarianBuildPassives.AddRage(hero, 1, "受到攻击")
    end

    return self
end

function BarbarianBuildPassives.CreateBerserkPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        local runtime = ensureRuntime(self.context and self.context.src)
        runtime.barbarianBerserkUsed = false
        runtime.barbarianBerserkUntilRound = nil
        runtime.barbarianRageStacks = 0
        syncRageBuff(self.context and self.context.src)
        syncBerserkBuff(self.context and self.context.src)
    end

    function self:OnSelfTurnBegin()
        BarbarianBuildPassives.TryActivateBerserk(self.context and self.context.src)
        syncBerserkBuff(self.context and self.context.src)
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) or not BarbarianBuildPassives.IsBerserkActive(hero) then
            return
        end
        local before = math.max(0, math.floor(tonumber(extraParam.damage) or 0))
        if before <= 0 then
            return
        end
        extraParam.damage = math.max(0, before - 2)
        BuildPassiveCommon.PublishPassiveTriggered(hero, "狂暴", "狂暴减伤", string.format("%d -> %d", before, extraParam.damage))
    end

    return self
end

return BarbarianBuildPassives
