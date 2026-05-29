local SkillRuntimeConfig = require("config.tables.skill_runtime")
local BuildPassiveCommon = require("skills.build_passive_common")
local SkillsTable = require("config.tables.skills")

local BarbarianBuildPassives = {}

local IDS = SkillRuntimeConfig.Ids
local BERSERK_DURATION_ROUNDS = 2
local BERSERK_BUFF_ID = 890002
local HEAVY_STRIKE_AC_DOWN_BUFF_ID = 890014

local function getRageSkillMods(hero)
    local buildState = hero and hero.buildState or nil
    local skillMods = buildState and buildState.skillMods or nil
    local rageMods = skillMods and skillMods[IDS.barbarian_rage] or nil
    if type(rageMods) ~= "table" then
        return nil
    end
    return rageMods
end

local function getRageNumberMod(hero, key, default)
    local value = getRageSkillMods(hero)
    value = value and value[key] or nil
    local num = tonumber(value)
    if num == nil then
        return tonumber(default) or 0
    end
    return num
end

local function getBerserkDuration(hero)
    return math.max(1, BERSERK_DURATION_ROUNDS + getRageNumberMod(hero, "rageDurationDelta", 0))
end

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

function BarbarianBuildPassives.CanTriggerBerserk(hero)
    if not isAlive(hero) or not hasSkill(hero, IDS.barbarian_rage) then
        return false
    end
    local runtime = ensureRuntime(hero)
    if BarbarianBuildPassives.IsBerserkActive(hero) then
        return false
    end
    if runtime.barbarianBerserkUsed == true and not hasSkill(hero, IDS.barbarian_berserk) then
        return false
    end
    return true
end

function BarbarianBuildPassives.TryActivateBerserk(hero)
    if not BarbarianBuildPassives.CanTriggerBerserk(hero) then
        return false
    end
    local runtime = ensureRuntime(hero)
    local duration = getBerserkDuration(hero)
    runtime.barbarianBerserkUsed = true
    runtime.barbarianBerserkUntilRound = getRound() + duration - 1
    syncBerserkBuff(hero)
    BuildPassiveCommon.PublishPassiveTriggered(hero, "狂暴", "怒气爆发", string.format("持续 %d 回合", duration))
    return true
end

function BarbarianBuildPassives.IsPhysicalDamage(extraParam)
    local damageKind = tostring(extraParam and (extraParam.damageKind or extraParam.kind) or "")
    if damageKind == "physical" then
        return true
    end
    local skillId = tonumber(extraParam and extraParam.skillId) or 0
    if skillId == 0 then
        return false
    end
    local skill = SkillsTable.GetSkillConfig(skillId)
    return tostring(skill and skill.rules and skill.rules.kind or "") == "physical"
end

function BarbarianBuildPassives.ApplyBerserkDamageBonus(hero, damage)
    local value = math.max(0, math.floor(tonumber(damage) or 0))
    if value <= 0 or not BarbarianBuildPassives.IsBerserkActive(hero) then
        return value
    end
    local bonus = math.max(0, 2 + getRageNumberMod(hero, "rageBonusDamageDelta", 0))
    return value + bonus
end

function BarbarianBuildPassives.ApplyRageLifesteal(hero, damage, sourceName)
    local value = math.max(0, math.floor(tonumber(damage) or 0))
    if value <= 0 or not BarbarianBuildPassives.IsBerserkActive(hero) then
        return 0
    end
    local pct = math.max(0, getRageNumberMod(hero, "rageLifestealPct", 0))
    if pct <= 0 then
        return 0
    end
    local heal = math.max(0, math.floor(value * pct / 100))
    if heal <= 0 then
        return 0
    end
    BuildPassiveCommon.ApplyHeal(hero, heal)
    BuildPassiveCommon.PublishPassiveTriggered(hero, "狂暴", "狂暴吸血",
        string.format("%s吸血 %d 点（%d%%）", tostring(sourceName or "本次伤害"), heal, pct))
    return heal
end

function BarbarianBuildPassives.PerformHeavyStrike(hero, target, skill)
    if not isAlive(hero) or not isAlive(target) then
        return 0
    end
    local BattleSkill = require("modules.battle_skill")
    local BattleDmgHeal = require("modules.battle_dmg_heal")
    local BattlePassiveSkill = require("modules.battle_passive_skill")
    local Skill5eMeta = require("config.tables.skill_meta")
    local BattleSkill = require("modules.battle_skill")
    local meta = Skill5eMeta.Get(skill and skill.skillId or IDS.barbarian_heavy_strike)
    local hitPenalty = tonumber(meta and meta.hitPenalty) or 0
    local critMin = tonumber(meta and meta.critMin) or 19
    local damageDice = tostring(meta and meta.damageDice or "")
    local strengthBonus = math.max(0, tonumber(hero.strMod) or 0)
    BattleSkill.ApplyBuffFromSkill(hero, hero, HEAVY_STRIKE_AC_DOWN_BUFF_ID, skill, {
        duration = 1,
        value = 2,
    })
    local damageResult = BattleSkill.ResolveScaledDamage(hero, target, {
        skill = skill,
        meta = meta,
        damageKind = "direct",
        attackBonus = (tonumber(hero.hit) or 0) + hitPenalty,
        damageDice = damageDice,
        critMin = critMin,
    })
    local hitResult = damageResult and damageResult.hit or nil
    if not hitResult or not hitResult.hit then
        BarbarianBuildPassives.AddRage(hero, 1, "重击落空")
        return 0
    end
    local damageContext = {
        attacker = hero,
        target = target,
        damage = math.max(0, math.floor(tonumber(damageResult and damageResult.damage) or 0)) + strengthBonus,
        damageKind = "physical",
        skillId = skill and skill.skillId or IDS.barbarian_heavy_strike,
    }
    damageContext.damage = BarbarianBuildPassives.ApplyBerserkDamageBonus(hero, damageContext.damage)
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
            isCrit = damageResult and damageResult.isCrit == true,
            attackRoll = hitResult,
            damageRoll = damageResult and damageResult.damageRoll or nil,
        })
        BarbarianBuildPassives.ApplyRageLifesteal(hero, damage, skill and skill.name or "重击")
        BattlePassiveSkill.RunSkillOnDefAfterDmg(target, { attacker = hero, damage = damage })
        BattleSkill.TriggerDamageBuffs(hero, target, damage)
        if target.isDead or (tonumber(target.hp) or 0) <= 0 then
            BattlePassiveSkill.RunSkillOnDmgMakeKill(hero, { target = target })
        end
    end
    return damage
end

function BarbarianBuildPassives.CreateRagePassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        local hero = self.context and self.context.src or nil
        local runtime = ensureRuntime(hero)
        runtime.barbarianBerserkUsed = false
        runtime.barbarianBerserkUntilRound = nil
        syncBerserkBuff(hero)
    end

    function self:OnSelfTurnBegin()
        syncBerserkBuff(self.context and self.context.src)
    end

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) then
            return
        end
        if tonumber(extraParam.skillId) ~= IDS.barbarian_basic_attack then
            return
        end
        BarbarianBuildPassives.TryActivateBerserk(hero)
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not isAlive(hero) then
            return
        end
        BarbarianBuildPassives.TryActivateBerserk(hero)
        if not BarbarianBuildPassives.IsBerserkActive(hero) then
            return
        end
        if not BarbarianBuildPassives.IsPhysicalDamage(extraParam) then
            return
        end
        local before = math.max(0, math.floor(tonumber(extraParam.damage) or 0))
        if before <= 0 then
            return
        end
        local damageReduce = math.max(0, 2 + getRageNumberMod(hero, "ragePhysicalReduceDelta", 0))
        extraParam.damage = math.max(0, before - damageReduce)
        BuildPassiveCommon.PublishPassiveTriggered(hero, "狂暴", "狂暴减伤", string.format("%d -> %d", before, extraParam.damage))
    end

    return self
end

function BarbarianBuildPassives.CreateBerserkPassive(context)
    local self = buildContextState(context)

    function self:OnBattleBegin()
        local runtime = ensureRuntime(self.context and self.context.src)
        runtime.barbarianBerserkUsed = false
        runtime.barbarianBerserkUntilRound = nil
        syncBerserkBuff(self.context and self.context.src)
    end

    function self:OnSelfTurnBegin()
        syncBerserkBuff(self.context and self.context.src)
    end

    return self
end

return BarbarianBuildPassives
