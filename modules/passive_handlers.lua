local BattleSkill = require("modules.battle_skill")
local BattleBuff = require("modules.battle_buff")
local BattleEvent = require("core.battle_event")
local BattleFormation = require("modules.battle_formation")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local Logger = require("utils.logger")
local FighterBuildPassives = require("skills.fighter_build_passives")

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

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        -- 5e 风味：Expertise（简化为战斗内 hit +1）。
        if (tonumber(hero.level) or 1) >= 2 and not hero.__expertiseApplied then
            hero.hit = (tonumber(hero.hit) or 0) + 1
            hero.__expertiseApplied = true
        end
    end

    function self:OnDmgMakeKill(ctx)
        -- 追击逻辑由技能 tag `pursuit_on_kill` 触发（保持技能体系一致性）。
        return
    end

    function self:OnDefBeforeDmg(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        -- Uncanny Dodge：Lv5 后每回合第一次被单体伤害时减半（简单化）。
        if (tonumber(hero.level) or 1) < 5 then
            return
        end
        local BattleLogic = require("modules.battle_logic")
        local round = BattleLogic.GetCurRound()
        local runtime = EnsurePassiveRuntime(hero)
        if runtime.__uncannyRound == round then
            return
        end
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local damage = tonumber(extraParam.damage) or 0
        if damage <= 0 then
            return
        end
        runtime.__uncannyRound = round
        extraParam.damage = math.max(0, math.floor(damage * 0.5))
    end

    return self
end

local function CreateBlockCounterPassive(context)
    local self = BuildContextState(context)

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        -- Action Surge（简化）：战斗开场获得少量能量，体现战士节奏优势。
        if (tonumber(hero.level) or 1) >= 2 and not hero.__actionSurgeApplied then
            local BattleEnergy = require("modules.battle_energy")
            BattleEnergy.AddEnergy(hero, 20, "action_surge", { silent = true })
            hero.__actionSurgeApplied = true
        end
    end

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        -- Second Wind（简化为自动触发一次）：当生命低于 50% 且未触发过时，自疗。
        if (tonumber(hero.level) or 1) < 2 then
            return
        end
        local runtime = EnsurePassiveRuntime(hero)
        if runtime.__secondWindUsed then
            return
        end
        local hp = tonumber(hero.hp) or 0
        local maxHp = tonumber(hero.maxHp) or 1
        if hp <= 0 or maxHp <= 0 then
            return
        end
        if hp / maxHp >= 0.5 then
            return
        end
        runtime.__secondWindUsed = true
        local Dice = require("core.dice")
        local heal = math.max(1, math.floor(Dice.Roll("1d10+2", { crit = false })))
        BattleDmgHeal.ApplyHeal(hero, heal, hero)
    end

    function self:OnNormalAtkFinish(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        -- Extra Attack：Lv5 后每回合第一次普攻结束后追加一次普攻。
        if (tonumber(hero.level) or 1) < 5 then
            return
        end
        local extraParam = ctx and ctx.data and ctx.data.extraParam or {}
        local target = extraParam.target
        if not target or target.isDead then
            return
        end
        local BattleLogic = require("modules.battle_logic")
        local round = BattleLogic.GetCurRound()
        local runtime = EnsurePassiveRuntime(hero)
        if runtime.__extraAttackRound == round or runtime.__inExtraAttack then
            return
        end
        runtime.__extraAttackRound = round
        -- NOTE: __inExtraAttack prevents recursive Extra Attack triggers.
        -- CastSmallSkill may route back to OnNormalAtkFinish; do NOT remove this guard.
        runtime.__inExtraAttack = true
        BattleSkill.CastSmallSkill(hero, target)
        runtime.__inExtraAttack = false
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

local function CreateClericChannelPassive(context)
    local self = BuildContextState(context)

    local function MarkChannelReady(hero)
        if not hero or hero.isDead then
            return
        end
        local runtime = EnsurePassiveRuntime(hero)
        runtime.clericChannelReady = true
    end

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        MarkChannelReady(hero)
    end

    function self:OnSelfTurnBegin(ctx)
        local hero = self.context and self.context.src or nil
        MarkChannelReady(hero)
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
    [80001002] = CreatePursuitPassive,
    [80002002] = CreateBlockCounterPassive,
    [80003002] = CreateComboMasterPassive,
    [80004002] = CreateWarSpiritPassive,
    [80005002] = CreateInfectPassive,
    [80006002] = CreateClericChannelPassive,
    [80007002] = CreateFireAffinityPassive,
    [80008002] = CreateIceAffinityPassive,
    [80009002] = CreateThunderAffinityPassive,
    [80002101] = FighterBuildPassives.CreateSecondWindPassive,
    [80002102] = FighterBuildPassives.CreatePreciseAttackPassive,
    [80002104] = FighterBuildPassives.CreateCounterBasicPassive,
    [80002105] = FighterBuildPassives.CreateGuardCounterPassive,
    [80002107] = FighterBuildPassives.CreateSecondWindMasteryPassive,
    [80002109] = FighterBuildPassives.CreateExtraAttackPassive,
    [80002110] = FighterBuildPassives.CreateSweepingAttackPassive,
}

function PassiveHandlers.Create(classId, context)
    local factory = PassiveHandlers.factories[classId]
    if not factory then
        return nil
    end
    return factory(context)
end

return PassiveHandlers
