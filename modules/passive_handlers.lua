local BattleSkill = require("modules.battle_skill")
local BattleBuff = require("modules.battle_buff")
local BattleEvent = require("core.battle_event")
local BattleFormation = require("modules.battle_formation")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local Logger = require("utils.logger")

local PassiveHandlers = {}

local function BuildContextState(context)
    return {
        context = context,
        data = context and context.data or {},
    }
end

local function EnsurePassiveRuntime(hero)
    if not hero then
        return nil
    end
    if not hero.passiveRuntime then
        hero.passiveRuntime = {}
    end
    return hero.passiveRuntime
end

local function CreateBlockPassive(context)
    local self = BuildContextState(context)

    function self:OnDefBeforeDmg(ctx)
        local data = ctx and ctx.data or self.data
        local extraParam = data.extraParam or {}
        local skillParam = data.OwnerSkillCsv or {}
        local triggerProb = skillParam.param1 or 2000
        local reduceRate = skillParam.param2 or 5000
        local hero = BattleFormation.FindHeroByInstanceId(data.OwnerUnitID)

        if not hero then
            return
        end

        local roll = math.random(1, 10000)
        if roll > triggerProb then
            return
        end

        Logger.Log(string.format("[Passive_8000020] 格挡触发! 概率:%.1f%% 随机值:%d", triggerProb / 100, roll))

        hero.isBlocking = true
        hero.blockReduceRate = reduceRate

        BattleEvent.Publish("PassiveSkillTriggered", {
            eventType = "PassiveSkillTriggered",
            heroId = data.OwnerUnitID,
            heroName = hero.name,
            skillName = "格挡",
            triggerType = "伤害减免",
            extraInfo = string.format("减伤%.1f%%", reduceRate / 100),
        })
    end

    return self
end

local function CreatePursuitPassive(context)
    local self = BuildContextState(context)

    function self:OnDmgMakeKill(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam and extraParam.target or nil
        if not hero or hero.isDead or not target then
            return
        end
        BattleSkill.ProcessPursuitEffect(hero, target, nil)
    end

    return self
end

local function CreateBlockCounterPassive(context)
    local self = BuildContextState(context)

    function self:OnSelfTurnBegin(ctx)
        return
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        if not hero or hero.isDead or not extraParam then
            return
        end
        local attacker = extraParam.attacker
        if not attacker or attacker.isDead then
            return
        end

        if BattleBuff.GetBuffBySubType(hero, 820003) then
            extraParam.damage = math.max(0, math.floor((extraParam.damage or 0) * 0.65))
            extraParam.blocked = true
            local damageResult = BattleSkill.ResolveScaledDamage(hero, attacker, {
                meta = { kind = "physical", damageDice = "1d8+2" },
                damageKind = "direct",
                noWeapon = true,
            })
            BattleDmgHeal.ApplyDamage(attacker, tonumber(damageResult and damageResult.damage) or 0, hero, { damageKind = "direct" })
            return
        end

        if BattleBuff.GetBuffBySubType(hero, 820002) then
            BattleBuff.DelBuffBySubType(hero, 820002, 1)
            local damageResult = BattleSkill.ResolveScaledDamage(hero, attacker, {
                meta = { kind = "physical", damageDice = "1d8+2" },
                damageKind = "direct",
                noWeapon = true,
            })
            BattleDmgHeal.ApplyDamage(attacker, tonumber(damageResult and damageResult.damage) or 0, hero, { damageKind = "direct" })
            return
        end

        local roll = math.random(1, 10000)
        if roll > 2500 then
            return
        end
        extraParam.damage = math.max(0, math.floor((extraParam.damage or 0) * 0.5))
        extraParam.blocked = true
        BattleSkill.CastSmallSkill(hero, attacker)
    end

    return self
end

local function CreateWarSpiritPassive(context)
    local self = BuildContextState(context)

    function self:OnDmgMakeKill(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        if BattleBuff.GetBuff(hero, 840001) then
            BattleBuff.ModifyBuffStack(hero, 840001, 1)
        else
            BattleSkill.ApplyBuffFromSkill(hero, hero, 840001, nil)
        end
    end

    return self
end

local function CreateComboMasterPassive(context)
    local self = BuildContextState(context)

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        local runtime = EnsurePassiveRuntime(hero)
        runtime.comboMasterMinRate = 5000
    end

    return self
end

local function CreateInfectPassive(context)
    local self = BuildContextState(context)

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        local enemyTeam = BattleFormation.GetEnemyTeam(hero)
        for _, enemy in ipairs(enemyTeam) do
            if enemy and not enemy.isDead then
                BattleSkill.ProcessInfectEffect(enemy)
            end
        end
    end

    return self
end

local function CreateAffinityHealPassive(context)
    local self = BuildContextState(context)

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        if not BattleBuff.GetBuff(hero, 860001) then
            BattleSkill.ApplyBuffFromSkill(hero, hero, 860001, nil)
        end
    end

    return self
end

local function CreateFireAffinityPassive(context)
    local self = BuildContextState(context)

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        if not BattleBuff.GetBuff(hero, 870002) then
            BattleSkill.ApplyBuffFromSkill(hero, hero, 870002, nil)
        end
    end

    return self
end

local function CreateIceAffinityPassive(context)
    local self = BuildContextState(context)

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        local runtime = EnsurePassiveRuntime(hero)
        runtime.iceDamageBonusPct = 1000
        runtime.iceFreezeChanceBonus = 1000
    end

    return self
end

local function CreateThunderAffinityPassive(context)
    local self = BuildContextState(context)

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        local runtime = EnsurePassiveRuntime(hero)
        runtime.thunderChainChanceBonus = 2000
        runtime.thunderChainDecayReductionPct = 1000
    end

    return self
end

PassiveHandlers.factories = {
    [8000020] = CreateBlockPassive,
    [8000100] = CreatePursuitPassive,
    [8000200] = CreateBlockCounterPassive,
    [8000300] = CreateComboMasterPassive,
    [8000400] = CreateWarSpiritPassive,
    [8000500] = CreateInfectPassive,
    [8000600] = CreateAffinityHealPassive,
    [8000700] = CreateFireAffinityPassive,
    [8000800] = CreateIceAffinityPassive,
    [8000900] = CreateThunderAffinityPassive,
}

function PassiveHandlers.Create(classId, context)
    local factory = PassiveHandlers.factories[classId]
    if not factory then
        return nil
    end
    return factory(context)
end

return PassiveHandlers
